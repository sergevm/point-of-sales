import SwiftUI
import SwiftData

/// Per-calendar-day totals across all sessions: the numbers the bookkeeper
/// copies into the daily receipts book (dagontvangstenboek), with the
/// cash/electronic split. Days containing an item sold at more than €250 per
/// unit are flagged, since such sales must be individually recorded (the
/// underlying order tickets satisfy that).
struct DailyReceiptsView: View {
    @Query(sort: \Order.createdAt, order: .reverse) private var orders: [Order]

    private struct DayTotal: Identifiable {
        let day: Date
        var gross: Decimal = 0
        var cash: Decimal = 0
        var electronic: Decimal = 0
        var orderCount: Int = 0
        var hasLargeSale = false

        var id: Date { day }
    }

    private var days: [DayTotal] {
        var byDay: [Date: DayTotal] = [:]
        let calendar = Calendar.current

        for order in orders where !order.isVoided {
            let day = calendar.startOfDay(for: order.createdAt)
            var total = byDay[day] ?? DayTotal(day: day)
            total.gross += order.total
            if order.paymentMethod.isElectronic {
                total.electronic += order.total
            } else {
                total.cash += order.total
            }
            total.orderCount += 1
            if order.items.contains(where: { $0.unitPrice > 250 }) {
                total.hasLargeSale = true
            }
            byDay[day] = total
        }

        return byDay.values.sorted { $0.day > $1.day }
    }

    var body: some View {
        List {
            if days.isEmpty {
                ContentUnavailableView(
                    "No receipts yet",
                    systemImage: "calendar",
                    description: Text("Daily totals appear here once orders are charged.")
                )
            }
            ForEach(days) { day in
                dayRow(day)
            }
        }
        .navigationTitle("Daily receipts")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func dayRow(_ day: DayTotal) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(day.day.formatted(date: .complete, time: .omitted))
                    .font(.body.weight(.medium))
                Spacer()
                Text(day.gross.currencyString)
                    .font(.body.bold().monospacedDigit())
            }
            HStack {
                Text("\(day.orderCount) orders — cash \(day.cash.currencyString), electronic \(day.electronic.currencyString)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Spacer()
                if day.hasLargeSale {
                    Label("Sale over €250", systemImage: "exclamationmark.triangle")
                        .font(.caption)
                        .foregroundStyle(.orange)
                }
            }
        }
        .padding(.vertical, 2)
    }
}
