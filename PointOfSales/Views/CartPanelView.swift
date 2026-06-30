import SwiftUI
import SwiftData

/// The current ticket: line items with quantity steppers, running total, and the
/// Charge / Clear actions.
struct CartPanelView: View {
    let session: SaleSession
    let cart: Cart

    @Environment(\.modelContext) private var context
    @State private var showChargedConfirmation = false

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
            }
            .buttonStyle(.plain)

            Text("\(line.quantity)")
                .font(.body.monospacedDigit())
                .frame(minWidth: 24)

            Button {
                cart.increment(line)
            } label: {
                Image(systemName: "plus.circle.fill")
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
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 8)
                }
                .buttonStyle(.bordered)
                .disabled(cart.isEmpty)

                Button(action: charge) {
                    Text("Charge")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 8)
                }
                .buttonStyle(.borderedProminent)
                .disabled(cart.isEmpty)
            }
        }
        .padding()
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

    private func charge() {
        guard cart.charge(into: context, session: session) != nil else { return }
        withAnimation { showChargedConfirmation = true }
        Task {
            try? await Task.sleep(for: .seconds(1.5))
            withAnimation { showChargedConfirmation = false }
        }
    }
}
