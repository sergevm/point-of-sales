import Foundation
import SwiftData

/// A register session: opened when the bar starts selling, closed at the end of
/// the evening. Only one session is active (open) at a time.
@Model
final class SaleSession {
    /// Optional label, e.g. "Friday club night".
    var name: String?

    var startedAt: Date

    /// `nil` while the session is open; set when it is closed.
    var endedAt: Date?

    /// Orders recorded during this session. Deleting a session deletes its orders.
    @Relationship(deleteRule: .cascade, inverse: \Order.session)
    var orders: [Order] = []

    init(name: String? = nil, startedAt: Date = .now) {
        self.name = name
        self.startedAt = startedAt
        self.endedAt = nil
    }

    var isActive: Bool { endedAt == nil }

    /// Total revenue recorded so far in this session.
    var total: Decimal {
        orders.reduce(Decimal.zero) { $0 + $1.total }
    }

    /// Number of orders charged in this session.
    var orderCount: Int { orders.count }

    /// Orders newest-first for display.
    var ordersByNewest: [Order] {
        orders.sorted { $0.createdAt > $1.createdAt }
    }
}
