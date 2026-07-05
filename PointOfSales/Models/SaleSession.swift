import Foundation
import SwiftData

/// A register session: opened when the bar starts selling, closed at the end of
/// the evening. Only one session is active (open) at a time. Once closed, a
/// session is immutable and becomes the basis of a numbered report for the
/// bookkeeper.
@Model
final class SaleSession {
    /// Optional label, e.g. "Friday club night".
    var name: String?

    /// Sequential report number, assigned at creation. Gives the bookkeeper an
    /// unbroken series so missing reports are detectable.
    var sequenceNumber: Int = 0

    var startedAt: Date

    /// `nil` while the session is open; set when it is closed.
    var endedAt: Date?

    /// Orders recorded during this session. Deleting a session deletes its orders.
    @Relationship(deleteRule: .cascade, inverse: \Order.session)
    var orders: [Order] = []

    init(name: String? = nil, sequenceNumber: Int = 0, startedAt: Date = .now) {
        self.name = name
        self.sequenceNumber = sequenceNumber
        self.startedAt = startedAt
        self.endedAt = nil
    }

    var isActive: Bool { endedAt == nil }

    /// Orders that count towards revenue.
    var validOrders: [Order] { orders.filter { !$0.isVoided } }

    var voidedOrders: [Order] { orders.filter(\.isVoided) }

    /// Total revenue recorded so far in this session (voided orders excluded).
    var total: Decimal {
        validOrders.reduce(Decimal.zero) { $0 + $1.total }
    }

    /// Number of non-voided orders charged in this session.
    var orderCount: Int { validOrders.count }

    var voidedCount: Int { voidedOrders.count }

    var voidedTotal: Decimal {
        voidedOrders.reduce(Decimal.zero) { $0 + $1.total }
    }

    /// Orders newest-first for display (including voided ones).
    var ordersByNewest: [Order] {
        orders.sorted { $0.createdAt > $1.createdAt }
    }

    /// The next free sequential report number.
    static func nextSequenceNumber(in context: ModelContext) -> Int {
        var descriptor = FetchDescriptor<SaleSession>(
            sortBy: [SortDescriptor(\.sequenceNumber, order: .reverse)]
        )
        descriptor.fetchLimit = 1
        let highest = (try? context.fetch(descriptor).first?.sequenceNumber) ?? 0
        return highest + 1
    }
}
