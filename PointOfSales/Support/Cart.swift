import Foundation
import SwiftData
import Observation

/// In-memory ticket being built on the register. Not persisted until charged.
@Observable
final class Cart {

    /// One product and its quantity in the current ticket.
    struct Line: Identifiable {
        let product: Product
        var quantity: Int

        var id: PersistentIdentifier { product.persistentModelID }
        var lineTotal: Decimal { product.price * Decimal(quantity) }
    }

    private(set) var lines: [Line] = []

    var isEmpty: Bool { lines.isEmpty }

    /// Total number of units in the ticket (for a badge).
    var itemCount: Int { lines.reduce(0) { $0 + $1.quantity } }

    var total: Decimal {
        lines.reduce(Decimal.zero) { $0 + $1.lineTotal }
    }

    /// Adds one unit of a product, merging with an existing line if present.
    func add(_ product: Product) {
        if let index = lines.firstIndex(where: { $0.product == product }) {
            lines[index].quantity += 1
        } else {
            lines.append(Line(product: product, quantity: 1))
        }
    }

    func increment(_ line: Line) {
        guard let index = lines.firstIndex(where: { $0.id == line.id }) else { return }
        lines[index].quantity += 1
    }

    /// Removes one unit; drops the line entirely when it reaches zero.
    func decrement(_ line: Line) {
        guard let index = lines.firstIndex(where: { $0.id == line.id }) else { return }
        lines[index].quantity -= 1
        if lines[index].quantity <= 0 {
            lines.remove(at: index)
        }
    }

    func remove(_ line: Line) {
        lines.removeAll { $0.id == line.id }
    }

    func clear() {
        lines.removeAll()
    }

    /// The amount actually charged for a given payment method: cash totals are
    /// rounded to 5 cents as Belgian law requires, electronic ones are exact.
    func chargeTotal(for method: PaymentMethod) -> Decimal {
        method == .cash ? CashRounding.rounded(total) : total
    }

    /// Persists the ticket as an `Order` (with snapshotted line items) attached to
    /// the active session, then empties the cart. No-op when the cart is empty.
    @discardableResult
    func charge(into context: ModelContext, session: SaleSession, method: PaymentMethod) -> Order? {
        guard !isEmpty else { return nil }

        let charged = chargeTotal(for: method)
        let order = Order(
            total: charged,
            paymentMethod: method,
            roundingAdjustment: charged - total,
            session: session
        )
        context.insert(order)

        for line in lines {
            let item = OrderItem(
                productName: line.product.name,
                unitPrice: line.product.price,
                unitCost: line.product.costPrice,
                quantity: line.quantity,
                product: line.product,
                order: order
            )
            context.insert(item)
        }

        // Flush to disk immediately: a charged order must not be lost to
        // autosave timing if the app is killed right after the sale.
        try? context.save()

        clear()
        return order
    }
}
