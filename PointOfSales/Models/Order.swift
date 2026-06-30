import Foundation
import SwiftData

/// A single charged ticket: one or more line items recorded together.
@Model
final class Order {
    var createdAt: Date

    /// Total charged, snapshotted at charge time so later price/product edits
    /// never change historical revenue.
    var total: Decimal

    var session: SaleSession?

    /// Line items on this ticket. Deleting the order deletes its items.
    @Relationship(deleteRule: .cascade, inverse: \OrderItem.order)
    var items: [OrderItem] = []

    init(createdAt: Date = .now, total: Decimal = .zero, session: SaleSession? = nil) {
        self.createdAt = createdAt
        self.total = total
        self.session = session
    }

    /// Total number of units across all line items.
    var itemCount: Int {
        items.reduce(0) { $0 + $1.quantity }
    }
}
