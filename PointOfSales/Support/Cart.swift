import Foundation
import SwiftData
import Observation

/// In-memory ticket being built on the register. Not persisted until charged.
@Observable
final class Cart {

    /// One product and its quantity in the current ticket. Two lines can exist
    /// for the same product — one paying, one not — so identity is a fresh
    /// UUID per line rather than the product's own identifier.
    struct Line: Identifiable {
        let id = UUID()
        let product: Product
        var quantity: Int

        /// True for a line given away rather than sold — a staff drink, a
        /// tasting — still recorded as a consumption but excluded from
        /// ``total`` and, downstream, from revenue reported to the accountant.
        var isNonPaying: Bool = false

        var lineTotal: Decimal { product.price * Decimal(quantity) }
    }

    private(set) var lines: [Line] = []

    /// When true, this is a credit ticket: everything on it is charged as a
    /// negative amount to reimburse the client. Items are always added the
    /// normal way; the seller flips this on at charge time by choosing "Charge
    /// as credit" (enforced by the UI), and it's reset when the cart is
    /// cleared or the credit charge is cancelled.
    var isCorrection = false

    /// When true, products tapped in the grid are added as non-paying rather
    /// than as a normal sale line. Toggled from a sticky control under the
    /// product grid; lives on the cart (not the view) so it resets along with
    /// everything else when the ticket is cleared or charged, rather than
    /// silently carrying into the next one.
    var isAddingNonPaying = false

    var isEmpty: Bool { lines.isEmpty }

    /// Total number of units in the ticket (for a badge). Includes non-paying
    /// lines — they're still a consumption even though nobody pays for them.
    var itemCount: Int { lines.reduce(0) { $0 + $1.quantity } }

    /// Total non-paying units in the ticket, for a subtle reminder in the UI.
    var nonPayingItemCount: Int {
        lines.filter(\.isNonPaying).reduce(0) { $0 + $1.quantity }
    }

    /// The unsigned sum of the paying line totals. Non-paying lines don't
    /// contribute — nobody is charged for them. Always positive; use
    /// ``signedTotal`` for anything that must reflect a credit ticket's
    /// negative amount.
    var total: Decimal {
        lines.reduce(Decimal.zero) { $0 + ($1.isNonPaying ? .zero : $1.lineTotal) }
    }

    /// `-1` for a credit ticket, `+1` for a normal sale.
    var sign: Int { isCorrection ? -1 : 1 }

    /// The amount the ticket represents, signed: negative for a credit ticket.
    var signedTotal: Decimal { Decimal(sign) * total }

    /// Adds one unit of a product, merging with an existing line for the same
    /// product and paying/non-paying state, if one is present. Whether the
    /// new unit is non-paying follows ``isAddingNonPaying``.
    func add(_ product: Product) {
        let nonPaying = isAddingNonPaying
        if let index = lines.firstIndex(where: { $0.product == product && $0.isNonPaying == nonPaying }) {
            lines[index].quantity += 1
        } else {
            lines.append(Line(product: product, quantity: 1, isNonPaying: nonPaying))
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

    /// Flips a line between paying and non-paying (e.g. correcting a mis-tap),
    /// merging into a matching line if one already exists for the same
    /// product and the new state.
    func toggleNonPaying(_ line: Line) {
        guard let index = lines.firstIndex(where: { $0.id == line.id }) else { return }
        var updated = lines[index]
        updated.isNonPaying.toggle()

        if let matchIndex = lines.firstIndex(where: {
            $0.id != updated.id && $0.product == updated.product && $0.isNonPaying == updated.isNonPaying
        }) {
            lines[matchIndex].quantity += updated.quantity
            lines.remove(at: index)
        } else {
            lines[index] = updated
        }
    }

    func clear() {
        lines.removeAll()
        isCorrection = false
        isAddingNonPaying = false
    }

    /// The amount actually charged for a given payment method: cash totals are
    /// rounded to 5 cents as Belgian law requires, electronic ones are exact.
    /// Signed, so a credit ticket returns a negative amount.
    func chargeTotal(for method: PaymentMethod) -> Decimal {
        method == .cash ? CashRounding.rounded(signedTotal) : signedTotal
    }

    /// Persists the ticket as an `Order` (with snapshotted line items) attached to
    /// the active session, then empties the cart. No-op when the cart is empty.
    ///
    /// For a credit ticket (``isCorrection``) the line items are stored with
    /// negative quantities so every downstream total nets correctly, and an
    /// optional `correctedOrder`/`reason` records the link and rationale.
    ///
    /// Throws when the order cannot be saved; the ticket is kept intact so the
    /// seller can retry.
    @discardableResult
    func charge(
        into context: ModelContext,
        session: SaleSession,
        method: PaymentMethod,
        correctedOrder: Order? = nil,
        reason: String? = nil
    ) throws -> Order? {
        guard !isEmpty else { return nil }

        let charged = chargeTotal(for: method)
        let order = Order(
            sequenceNumber: session.nextTicketNumber,
            total: charged,
            paymentMethod: method,
            roundingAdjustment: charged - signedTotal,
            isCorrection: isCorrection,
            correctionReason: isCorrection ? reason : nil,
            correctedOrder: isCorrection ? correctedOrder : nil,
            session: session
        )
        context.insert(order)

        for line in lines {
            let item = OrderItem(
                productName: line.product.name,
                unitPrice: line.product.price,
                unitCost: line.product.costPrice,
                quantity: sign * line.quantity,
                isNonPaying: line.isNonPaying,
                product: line.product,
                order: order
            )
            context.insert(item)
        }

        // Flush to disk immediately: a charged order must not be lost to
        // autosave timing if the app is killed right after the sale.
        do {
            try context.save()
        } catch {
            // Take the failed order back out so it doesn't linger in the UI or
            // get picked up by a later autosave; deleting it cascades to its items.
            context.delete(order)
            throw error
        }

        clear()
        return order
    }
}
