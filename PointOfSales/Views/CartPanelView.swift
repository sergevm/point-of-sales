import SwiftUI
import SwiftData

/// The current ticket: line items with quantity steppers, running total, and the
/// Charge / Clear actions.
struct CartPanelView: View {
    let session: SaleSession
    let cart: Cart

    @Environment(\.modelContext) private var context
    @State private var showChargedConfirmation = false
    @State private var choosingPayment = false

    var body: some View {
        VStack(spacing: 0) {
            header
            Divider()

            if cart.isEmpty {
                ContentUnavailableView(
                    "Empty ticket",
                    systemImage: "cart",
                    description: Text("Tap products to add them.")
                )
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                List {
                    ForEach(cart.lines) { line in
                        lineRow(line)
                    }
                }
                .listStyle(.plain)
            }

            Divider()
            footer
        }
        .background(.background)
        .overlay(alignment: .top) {
            if showChargedConfirmation {
                chargedBanner
            }
        }
    }

    private var header: some View {
        HStack {
            Text("Current ticket")
                .font(.headline)
            Spacer()
            if !cart.isEmpty {
                Text("\(cart.itemCount) item\(cart.itemCount == 1 ? "" : "s")")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
        }
        .padding()
    }

    private func lineRow(_ line: Cart.Line) -> some View {
        HStack(spacing: 10) {
            VStack(alignment: .leading, spacing: 2) {
                Text(line.product.name)
                    .font(.body.weight(.medium))
                    .lineLimit(1)
                Text(line.product.price.currencyString)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer()

            Button {
                cart.decrement(line)
            } label: {
                Image(systemName: "minus.circle.fill")
                    .shadow(color: .black.opacity(0.2), radius: 2, x: 0, y: 1)
            }
            .buttonStyle(.plain)

            Text("\(line.quantity)")
                .font(.body.monospacedDigit())
                .frame(minWidth: 24)

            Button {
                cart.increment(line)
            } label: {
                Image(systemName: "plus.circle.fill")
                    .shadow(color: .black.opacity(0.2), radius: 2, x: 0, y: 1)
            }
            .buttonStyle(.plain)

            Text(line.lineTotal.currencyString)
                .font(.body.monospacedDigit())
                .frame(minWidth: 64, alignment: .trailing)
        }
        .swipeActions {
            Button(role: .destructive) {
                cart.remove(line)
            } label: {
                Label("Remove", systemImage: "trash")
            }
        }
    }

    private var footer: some View {
        VStack(spacing: 12) {
            HStack {
                Text("Total")
                    .font(.title3.bold())
                Spacer()
                Text(cart.total.currencyString)
                    .font(.title2.bold().monospacedDigit())
            }

            HStack(spacing: 12) {
                Button(role: .destructive) {
                    cart.clear()
                } label: {
                    Text("Clear")
                        .font(.headline)
                        .foregroundStyle(.red)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .background(
                            .red.opacity(0.12),
                            in: RoundedRectangle(cornerRadius: 14)
                        )
                }
                .buttonStyle(.depth(.red.opacity(0.25)))
                .disabled(cart.isEmpty)

                Button {
                    choosingPayment = true
                } label: {
                    Text("Charge")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                }
                .buttonStyle(.prominentDepth(tint: .accentColor))
                .disabled(cart.isEmpty)
                .confirmationDialog(
                    "How is this paid?",
                    isPresented: $choosingPayment,
                    titleVisibility: .visible
                ) {
                    ForEach(PaymentMethod.allCases) { method in
                        Button(paymentButtonTitle(for: method)) {
                            charge(method)
                        }
                    }
                    Button("Cancel", role: .cancel) {}
                }
            }
        }
        .padding()
    }

    /// Cash shows the legally rounded amount so the seller announces the right
    /// total, e.g. "Cash — €12.95" for an exact total of €12.93.
    private func paymentButtonTitle(for method: PaymentMethod) -> String {
        "\(method.displayName) — \(cart.chargeTotal(for: method).currencyString)"
    }

    private var chargedBanner: some View {
        Label("Order recorded", systemImage: "checkmark.circle.fill")
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(.green, in: Capsule())
            .foregroundStyle(.white)
            .padding(.top, 8)
            .transition(.move(edge: .top).combined(with: .opacity))
    }

    private func charge(_ method: PaymentMethod) {
        guard cart.charge(into: context, session: session, method: method) != nil else { return }
        withAnimation { showChargedConfirmation = true }
        Task {
            try? await Task.sleep(for: .seconds(1.5))
            withAnimation { showChargedConfirmation = false }
        }
    }
}
