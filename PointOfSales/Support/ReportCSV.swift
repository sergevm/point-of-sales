import Foundation

/// CSV export of a session's orders, importable by the bookkeeper's software.
/// Plain comma-separated with quoted fields and dot decimals.
enum ReportCSV {
    static func ordersCSV(session: SaleSession) -> String {
        var rows: [String] = [
            "report,order_time,items,payment_method,total,rounding_adjustment,voided,void_reason"
        ]

        for order in session.orders.sorted(by: { $0.createdAt < $1.createdAt }) {
            let items = order.items
                .sorted { $0.productName < $1.productName }
                .map { "\($0.quantity)x \($0.productName)" }
                .joined(separator: "; ")

            rows.append(
                [
                    "\(session.sequenceNumber)",
                    order.createdAt.formatted(.iso8601),
                    quoted(items),
                    order.paymentMethod.rawValue,
                    amount(order.total),
                    amount(order.roundingAdjustment),
                    order.isVoided ? "yes" : "no",
                    quoted(order.voidReason ?? "")
                ].joined(separator: ",")
            )
        }

        return rows.joined(separator: "\n") + "\n"
    }

    private static func amount(_ value: Decimal) -> String {
        value.formatted(.number.precision(.fractionLength(2)).locale(Locale(identifier: "en_US_POSIX")))
    }

    private static func quoted(_ field: String) -> String {
        "\"" + field.replacingOccurrences(of: "\"", with: "\"\"") + "\""
    }
}
