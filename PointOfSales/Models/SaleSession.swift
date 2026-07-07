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

    /// Human-facing name for display and reports. Uses the stored name when set;
    /// otherwise falls back to the session's start date in the same `YY-MM-dd`
    /// format the default naming uses (legacy sessions with no stored name).
    var displayName: String {
        name ?? SaleSession.dateFormatter.string(from: startedAt)
    }

    /// Orders that count towards revenue. Includes credit tickets, whose
    /// negative totals net against sales.
    var validOrders: [Order] { orders.filter { !$0.isVoided } }

    var voidedOrders: [Order] { orders.filter(\.isVoided) }

    /// Non-voided sales (positive tickets).
    var saleOrders: [Order] { validOrders.filter { !$0.isCorrection } }

    /// Non-voided credit tickets (negative tickets).
    var correctionOrders: [Order] { validOrders.filter(\.isCorrection) }

    /// Total revenue recorded so far in this session (voided orders excluded,
    /// credit tickets netted in).
    var total: Decimal {
        validOrders.reduce(Decimal.zero) { $0 + $1.total }
    }

    /// Gross sales before corrections are applied.
    var salesTotal: Decimal {
        saleOrders.reduce(Decimal.zero) { $0 + $1.total }
    }

    /// Combined (negative) total of the credit tickets in this session.
    var correctionsTotal: Decimal {
        correctionOrders.reduce(Decimal.zero) { $0 + $1.total }
    }

    /// Number of credit tickets in this session.
    var correctionCount: Int { correctionOrders.count }

    /// Number of non-voided sale orders charged in this session.
    var orderCount: Int { saleOrders.count }

    var voidedCount: Int { voidedOrders.count }

    var voidedTotal: Decimal {
        voidedOrders.reduce(Decimal.zero) { $0 + $1.total }
    }

    /// Orders newest-first for display (including voided ones).
    var ordersByNewest: [Order] {
        orders.sorted { $0.createdAt > $1.createdAt }
    }

    /// A sensible default name when the user doesn't provide one: today's date
    /// as `YY-MM-dd`, suffixed with `(session x)` for the 2nd and later sessions
    /// of the same day.
    static func defaultName(in context: ModelContext, on date: Date = .now) -> String {
        let calendar = Calendar.current
        let dayStart = calendar.startOfDay(for: date)
        guard let dayEnd = calendar.date(byAdding: .day, value: 1, to: dayStart) else {
            return dateFormatter.string(from: date)
        }

        let descriptor = FetchDescriptor<SaleSession>(
            predicate: #Predicate { $0.startedAt >= dayStart && $0.startedAt < dayEnd }
        )
        let priorCount = (try? context.fetchCount(descriptor)) ?? 0

        let base = dateFormatter.string(from: date)
        // priorCount sessions already exist today, so this is session priorCount + 1.
        return priorCount == 0 ? base : String(localized: "\(base) (session \(priorCount + 1))")
    }

    private static let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "yy-MM-dd"
        return formatter
    }()

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
