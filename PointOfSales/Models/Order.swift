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

    /// A correction (credit) ticket: its items carry negative quantities, so its
    /// `total` is negative and nets against session revenue. Recorded when the
    /// client is reimbursed for something that went wrong in an earlier order.
    var isCorrection: Bool = false

    /// Why the credit was issued (optional), for the bookkeeper's audit trail.
    var correctionReason: String?

    /// The original order this credit corrects, if the seller linked one at
    /// charge time. Optional — a credit can be recorded without a link.
    var correctedOrder: Order?

    /// Credit orders linked back to this one. A non-empty list is what marks an
    /// order as "corrected".
    @Relationship(inverse: \Order.correctedOrder)
    var corrections: [Order] = []

    var session: SaleSession?

    /// Line items on this ticket. Deleting the order deletes its items.
    @Relationship(deleteRule: .cascade, inverse: \OrderItem.order)
    var items: [OrderItem] = []

    init(
        createdAt: Date = .now,
        total: Decimal = .zero,
        paymentMethod: PaymentMethod = .cash,
        roundingAdjustment: Decimal = .zero,
        isCorrection: Bool = false,
        correctionReason: String? = nil,
        correctedOrder: Order? = nil,
        session: SaleSession? = nil
    ) {
        self.createdAt = createdAt
        self.total = total
        self.paymentMethodRaw = paymentMethod.rawValue
        self.roundingAdjustment = roundingAdjustment
        self.isCorrection = isCorrection
        self.correctionReason = correctionReason
        self.correctedOrder = correctedOrder
        self.session = session
    }

    var paymentMethod: PaymentMethod {
        get { PaymentMethod(rawValue: paymentMethodRaw) ?? .cash }
        set { paymentMethodRaw = newValue.rawValue }
    }

    var isVoided: Bool { voidedAt != nil }

    /// True when at least one credit ticket has been linked back to this order.
    var hasCorrection: Bool { !corrections.isEmpty }

    /// Total number of units across all line items.
    var itemCount: Int {
        items.reduce(0) { $0 + $1.quantity }
    }

    /// Cost of goods on this ticket, from snapshotted unit costs.
    var totalCost: Decimal {
        items.reduce(Decimal.zero) { $0 + $1.lineCost }
    }
}
