import Foundation
import SwiftData

/// A single charged ticket: one or more line items recorded together.
@Model
final class Order {
    var createdAt: Date

    /// Total charged, snapshotted at charge time so later price/product edits
    /// never change historical revenue. For cash payments this is the amount
    /// after 5-cent rounding.
    var total: Decimal

    /// Raw value of `PaymentMethod`.
    var paymentMethodRaw: String = PaymentMethod.cash.rawValue

    /// Cash-rounding difference included in `total`
    /// (`total` = exact item sum + `roundingAdjustment`).
    var roundingAdjustment: Decimal = 0

    /// Set when the order is voided. Voided orders stay recorded as an audit
    /// trail but are excluded from revenue.
    var voidedAt: Date?
    var voidReason: String?

    var session: SaleSession?

    /// Line items on this ticket. Deleting the order deletes its items.
    @Relationship(deleteRule: .cascade, inverse: \OrderItem.order)
    var items: [OrderItem] = []

    init(
        createdAt: Date = .now,
        total: Decimal = .zero,
        paymentMethod: PaymentMethod = .cash,
        roundingAdjustment: Decimal = .zero,
        session: SaleSession? = nil
    ) {
        self.createdAt = createdAt
        self.total = total
        self.paymentMethodRaw = paymentMethod.rawValue
        self.roundingAdjustment = roundingAdjustment
        self.session = session
    }

    var paymentMethod: PaymentMethod {
        get { PaymentMethod(rawValue: paymentMethodRaw) ?? .cash }
        set { paymentMethodRaw = newValue.rawValue }
    }

    var isVoided: Bool { voidedAt != nil }

    /// Total number of units across all line items.
    var itemCount: Int {
        items.reduce(0) { $0 + $1.quantity }
    }

    /// Cost of goods on this ticket, from snapshotted unit costs.
    var totalCost: Decimal {
        items.reduce(Decimal.zero) { $0 + $1.lineCost }
    }
}
