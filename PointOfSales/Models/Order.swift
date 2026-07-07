import Foundation
import SwiftData

/// A single charged ticket: one or more line items recorded together.
@Model
final class Order {
    /// Per-session ticket number (1, 2, 3… within the session), assigned at
    /// charge time. Never reused, so voided tickets keep their number and the
    /// series stays unbroken for the audit trail. `0` for orders recorded
    /// before numbering existed.
    var sequenceNumber: Int = 0

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
        sequenceNumber: Int = 0,
        createdAt: Date = .now,
        total: Decimal = .zero,
        paymentMethod: PaymentMethod = .cash,
        roundingAdjustment: Decimal = .zero,
        isCorrection: Bool = false,
        correctionReason: String? = nil,
        correctedOrder: Order? = nil,
        session: SaleSession? = nil
    ) {
        self.sequenceNumber = sequenceNumber
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

    /// False for orders recorded before per-session numbering existed.
    var hasTicketNumber: Bool { sequenceNumber > 0 }

    /// "#3" — or nil when the order predates per-session numbering.
    var numberLabel: String? { Order.numberLabel(sequenceNumber) }

    /// Compact reference used wherever this ticket is shown or linked to,
    /// e.g. "#3". Falls back to the charge time for orders recorded before
    /// per-session numbering existed.
    var referenceLabel: String {
        numberLabel ?? createdAt.formatted(date: .omitted, time: .shortened)
    }

    /// "#3" — or nil for the `0` marker of orders that predate numbering.
    /// The static variants exist so report snapshots can format a ticket
    /// without holding the model object.
    static func numberLabel(_ number: Int) -> String? {
        number > 0 ? "#\(number)" : nil
    }

    /// Fuller display label, "#3 · 14:30" (just the time for legacy orders).
    static func ticketLabel(number: Int, time: Date) -> String {
        let timeText = time.formatted(date: .omitted, time: .shortened)
        guard let numberText = numberLabel(number) else { return timeText }
        return "\(numberText) · \(timeText)"
    }

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
