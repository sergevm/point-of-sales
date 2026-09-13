import SwiftUI
import SwiftData

/// The ticket panel: the live, editable cart by default, with paging arrows to
/// step back through the session's past orders (most recent first) in the
/// same pane. Past orders reuse the same line-item layout but are read-only —
/// no steppers, no swipe-to-remove, no Clear/Charge.
struct CartPanelView: View {
    let session: SaleSession
    let cart: Cart

    /// `nil` shows the live cart. `0` is the most recent order in
    /// ``SaleSession/ordersByNewest``, `1` the one before that, and so on.
    /// Bound from the register so it can disable the product grid while a
    /// past order is being viewed.
    @Binding var historyIndex: Int?

    /// Called to reveal a linked order (the original a credit corrects, or the
    /// credit that corrects it) in the session sales list.
    var onShowLinkedOrder: (Order) -> Void = { _ in }

    @Environment(\.modelContext) private var context
    @State private var choosingPayment = false
    @State private var choosingCorrection = false
    @State private var confirmingClear = false
    @State private var chargeFailed = false

    private var orders: [Order] { session.ordersByNewest }

    /// The order being viewed, or `nil` when viewing the live cart.
    private var viewedOrder: Order? {
        guard let historyIndex, orders.indices.contains(historyIndex) else { return nil }
        return orders[historyIndex]
    }

    private var isViewingHistory: Bool { viewedOrder != nil }

    /// Red for a credit ticket (live or past), the app accent otherwise.
    private var accent: Color {
        (viewedOrder?.isCorrection ?? cart.isCorrection) ? .red : .accentColor
    }

    /// Whether the back arrow (deeper into history) has anywhere to go.
    private var canGoBack: Bool {
        guard !orders.isEmpty else { return false }
        guard let historyIndex else { return true }
        return historyIndex + 1 < orders.count
    }

    /// Whether the forward arrow (towards the live ticket) has anywhere to go.
    private var canGoForward: Bool { historyIndex != nil }

    var body: some View {
        VStack(spacing: 0) {
            header
            Divider()

            if let order = viewedOrder {
                List {
                    ForEach(order.items.sorted { $0.productName < $1.productName }) { item in
                        historyLineRow(item)
                    }
                }
                .listStyle(.plain)
                correctionLinks(for: order)
            } else if cart.isEmpty {
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
                        cartLineRow(line)
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
        VStack(spacing: 8) {
            TicketPagingHeader(
                title: headerTitle,
                titleColor: accent == .red ? .red : .primary,
                backEnabled: canGoBack,
                forwardEnabled: canGoForward,
                backAccessibilityLabel: "Show older ticket",
                forwardAccessibilityLabel: "Show newer ticket",
                onBack: goBack,
                onForward: goForward
            )
            subheader
        }
        .padding()
    }

    private var headerTitle: String {
        guard let order = viewedOrder else {
            return cart.isCorrection ? "Credit ticket" : "Current ticket"
        }
        guard let number = order.numberLabel else {
            return order.isCorrection ? "Credit ticket" : "Past ticket"
        }
        return order.isCorrection ? "Credit \(number)" : "Ticket \(number)"
    }

    @ViewBuilder
    private var subheader: some View {
        if let order = viewedOrder {
            HStack(spacing: 6) {
                Image(systemName: order.isCorrection ? "arrow.uturn.backward.circle" : order.paymentMethod.systemImage)
                    .font(.subheadline)
                    .foregroundStyle(order.isCorrection ? Color.red : Color.accentColor)
                    .accessibilityLabel(Text("Paid by \(order.paymentMethod.displayName)"))
                Text(order.createdAt.formatted(date: .omitted, time: .shortened))
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        } else if cart.isEmpty {
            Picker("Ticket type", selection: Binding(
                get: { cart.isCorrection },
                set: { cart.isCorrection = $0 }
            )) {
                Text("Sale").tag(false)
                Text("Credit").tag(true)
            }
            .pickerStyle(.segmented)
        } else {
            Text("\(cart.itemCount) items")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
    }

    private func goBack() {
        historyIndex = (historyIndex ?? -1) + 1
    }

    private func goForward() {
        guard let historyIndex else { return }
        self.historyIndex = historyIndex > 0 ? historyIndex - 1 : nil
    }

    private func cartLineRow(_ line: Cart.Line) -> some View {
        TicketLineRow(
            name: line.product.name,
            unitPrice: line.product.price,
            quantity: line.quantity,
            lineTotal: Decimal(cart.sign) * line.lineTotal,
            totalTint: cart.isCorrection ? .red : .primary,
            onIncrement: { cart.increment(line) },
            onDecrement: { cart.decrement(line) },
            onRemove: { cart.remove(line) }
        )
    }

    private func historyLineRow(_ item: OrderItem) -> some View {
        TicketLineRow(
            name: item.productName,
            unitPrice: item.unitPrice,
            quantity: abs(item.quantity),
            lineTotal: item.lineTotal,
            totalTint: (viewedOrder?.isCorrection ?? false) ? .red : .primary
        )
    }

    /// Tappable link between a past order and its correction counterpart, when
    /// one has been marked, so staff can jump to the related ticket.
    @ViewBuilder
    private func correctionLinks(for order: Order) -> some View {
        if order.isCorrection, let original = order.correctedOrder {
            Divider()
            Button {
                onShowLinkedOrder(original)
            } label: {
                Label(
                    "Corrects order \(original.referenceLabel)",
                    systemImage: "arrow.up.left"
                )
                .font(.subheadline)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal)
                .padding(.vertical, 8)
            }
            .buttonStyle(.plain)
            .foregroundStyle(.tint)
        } else if order.hasCorrection, let credit = order.corrections.max(by: { $0.createdAt < $1.createdAt }) {
            Divider()
            Button {
                onShowLinkedOrder(credit)
            } label: {
                Label(
                    "Corrected by credit \(credit.referenceLabel) — view",
                    systemImage: "arrow.down.right"
                )
                .font(.subheadline)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal)
                .padding(.vertical, 8)
            }
            .buttonStyle(.plain)
            .foregroundStyle(.red)
        }
    }

    private var footer: some View {
        VStack(spacing: 12) {
            HStack {
                Text(footerIsCorrection ? "Credit" : "Total")
                    .font(.title3.bold())
                Spacer()
                Text(footerTotal.currencyString)
                    .font(.title2.bold().monospacedDigit())
                    .foregroundStyle(footerIsCorrection ? .red : .primary)
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
                .disabled(isViewingHistory || cart.isEmpty)
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
                .disabled(isViewingHistory || cart.isEmpty)
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

    private var footerIsCorrection: Bool { viewedOrder?.isCorrection ?? cart.isCorrection }
    private var footerTotal: Decimal { viewedOrder?.total ?? cart.signedTotal }

    /// Cash shows the legally rounded amount so the seller announces the right
    /// total, e.g. "Cash — €12.95" for an exact total of €12.93.
    private func paymentButtonTitle(for method: PaymentMethod) -> String {
        "\(method.displayName) — \(cart.chargeTotal(for: method).currencyString)"
    }

    /// Charges the cart and pages the panel to the newly recorded order, which
    /// doubles as the confirmation. `correctedOrder` and `reason` apply only to
    /// credit tickets.
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
            historyIndex = 0
        } catch {
            chargeFailed = true
        }
    }
}

/// One product line on a ticket: name, unit price, quantity, and line total.
/// Shared by the live, editable cart and read-only past orders — pass `nil`
/// for the stepper/remove callbacks to render the same row disabled, so a
/// past ticket looks like the current one without being editable.
private struct TicketLineRow: View {
    let name: String
    let unitPrice: Decimal
    let quantity: Int
    let lineTotal: Decimal
    var totalTint: Color = .primary
    var onIncrement: (() -> Void)?
    var onDecrement: (() -> Void)?
    var onRemove: (() -> Void)?

    var body: some View {
        HStack(spacing: 10) {
            VStack(alignment: .leading, spacing: 2) {
                Text(name)
                    .font(.body.weight(.medium))
                    .lineLimit(1)
                Text(unitPrice.currencyString)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer()

            stepperButton("minus.circle.fill", action: onDecrement, label: "Remove one \(name)")

            Text("\(quantity)")
                .font(.body.monospacedDigit())
                .frame(minWidth: 24)
                .accessibilityLabel(Text("Quantity \(quantity)"))

            stepperButton("plus.circle.fill", action: onIncrement, label: "Add one \(name)")

            Text(lineTotal.currencyString)
                .font(.body.monospacedDigit())
                .foregroundStyle(totalTint)
                .frame(minWidth: 64, alignment: .trailing)
        }
        .swipeActions {
            if let onRemove {
                Button(role: .destructive, action: onRemove) {
                    Label("Remove", systemImage: "trash")
                }
            }
        }
    }

    private func stepperButton(_ systemImage: String, action: (() -> Void)?, label: String) -> some View {
        Button {
            action?()
        } label: {
            Image(systemName: systemImage)
                .shadow(color: .black.opacity(0.2), radius: 2, x: 0, y: 1)
        }
        .buttonStyle(.plain)
        .disabled(action == nil)
        .opacity(action == nil ? 0.35 : 1)
        .accessibilityLabel(Text(label))
    }
}
