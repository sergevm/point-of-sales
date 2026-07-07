import SwiftUI
import SwiftData

/// The current ticket: line items with quantity steppers, running total, and the
/// Charge / Clear actions.
struct CartPanelView: View {
    let session: SaleSession
    let cart: Cart

    /// Called after an order is successfully charged, so the register can reveal
    /// the just-completed order in its inspector.
    var onCharged: () -> Void = {}

    @Environment(\.modelContext) private var context
    @State private var choosingPayment = false
    @State private var choosingCorrection = false
    @State private var confirmingClear = false
    @State private var chargeFailed = false

    /// Red for a credit ticket, the app accent for a normal sale.
    private var accent: Color { cart.isCorrection ? .red : .accentColor }

    var body: some View {
        VStack(spacing: 0) {
            header
            Divider()

            if cart.isEmpty {
                ContentUnavailableView(
                    cart.isCorrection ? "Empty credit ticket" : "Empty ticket",
                    systemImage: cart.isCorrection ? "arrow.uturn.backward.circle" : "cart",
                    description: Text(
                        cart.isCorrection
                            ? "Tap products to credit them back to the client."
                            : "Tap products to add them."
                    )
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
        .sheet(isPresented: $choosingCorrection) {
            CorrectionChargeSheet(session: session, cart: cart) { method, correctedOrder, reason in
                charge(method, correctedOrder: correctedOrder, reason: reason)
            }
        }
        .alert("Order could not be saved", isPresented: $chargeFailed) {
            Button("OK", role: .cancel) {}
        } message: {
            Text("The ticket was kept. Please try charging again.")
        }
    }

    private var header: some View {
        HStack {
            Text(cart.isCorrection ? "Credit ticket" : "Current ticket")
                .font(.headline)
                .foregroundStyle(cart.isCorrection ? .red : .primary)
            Spacer()
            if cart.isEmpty {
                Picker("Ticket type", selection: Binding(
                    get: { cart.isCorrection },
                    set: { cart.isCorrection = $0 }
                )) {
                    Text("Sale").tag(false)
                    Text("Credit").tag(true)
                }
                .pickerStyle(.segmented)
                .fixedSize()
            } else {
                Text("\(cart.itemCount) items")
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
            .accessibilityLabel(Text("Remove one \(line.product.name)"))

            Text("\(line.quantity)")
                .font(.body.monospacedDigit())
                .frame(minWidth: 24)
                .accessibilityLabel(Text("Quantity \(line.quantity)"))

            Button {
                cart.increment(line)
            } label: {
                Image(systemName: "plus.circle.fill")
                    .shadow(color: .black.opacity(0.2), radius: 2, x: 0, y: 1)
            }
            .buttonStyle(.plain)
            .accessibilityLabel(Text("Add one \(line.product.name)"))

            Text((Decimal(cart.sign) * line.lineTotal).currencyString)
                .font(.body.monospacedDigit())
                .foregroundStyle(cart.isCorrection ? .red : .primary)
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
                Text(cart.isCorrection ? "Credit" : "Total")
                    .font(.title3.bold())
                Spacer()
                Text(cart.signedTotal.currencyString)
                    .font(.title2.bold().monospacedDigit())
                    .foregroundStyle(cart.isCorrection ? .red : .primary)
            }

            HStack(spacing: 12) {
                Button(role: .destructive) {
                    confirmingClear = true
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
                .confirmationDialog(
                    "Clear all items from this ticket?",
                    isPresented: $confirmingClear,
                    titleVisibility: .visible
                ) {
                    Button("Clear ticket", role: .destructive) {
                        cart.clear()
                    }
                    Button("Cancel", role: .cancel) {}
                }

                Button {
                    if cart.isCorrection {
                        choosingCorrection = true
                    } else {
                        choosingPayment = true
                    }
                } label: {
                    Text(cart.isCorrection ? "Charge credit" : "Charge")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                }
                .buttonStyle(.prominentDepth(tint: accent))
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

    /// Charges the cart and reveals the recorded order in the register's
    /// last-order panel, which doubles as the confirmation. `correctedOrder` and
    /// `reason` apply only to credit tickets.
    private func charge(
        _ method: PaymentMethod,
        correctedOrder: Order? = nil,
        reason: String? = nil
    ) {
        do {
            guard try cart.charge(
                into: context,
                session: session,
                method: method,
                correctedOrder: correctedOrder,
                reason: reason
            ) != nil else { return }
            onCharged()
        } catch {
            chargeFailed = true
        }
    }
}
