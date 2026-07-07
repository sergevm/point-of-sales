import SwiftUI

/// The printable/mailable session report. Rendered on screen inside
/// `SessionReportScreen` and into the PDF attachment by `ReportPDF`.
struct SessionReportDocumentView: View {
    let report: SessionReport

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            header
            Divider()
            summary
            paymentMethods
            productTable
            if !report.corrections.isEmpty {
                correctionsSection
            }
            if !report.voidedOrders.isEmpty {
                voidedSection
            }
            Divider()
            footer
        }
        .padding(32)
        .background(Color.white)
        .foregroundStyle(.black)
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 2) {
                    Text(report.organizationName.isEmpty ? String(localized: "Session report") : report.organizationName)
                        .font(.title2.bold())
                    if !report.organizationAddress.isEmpty {
                        Text(report.organizationAddress)
                            .font(.footnote)
                    }
                    if !report.enterpriseNumber.isEmpty {
                        Text("Enterprise no. \(report.enterpriseNumber)")
                            .font(.footnote)
                    }
                }
                Spacer()
                VStack(alignment: .trailing, spacing: 2) {
                    Text(report.sessionName)
                        .font(.title3.bold())
                    Text("Report #\(report.reportNumber)")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
            }

            Text(periodText)
                .font(.footnote)
                .foregroundStyle(.secondary)
        }
    }

    private var periodText: String {
        let start = report.startedAt.formatted(date: .long, time: .shortened)
        if let end = report.endedAt {
            return "\(start) – \(end.formatted(date: .omitted, time: .shortened))"
        }
        return String(localized: "\(start) – session still open")
    }

    private var summary: some View {
        VStack(alignment: .leading, spacing: 6) {
            reportRow(String(localized: "Orders"), "\(report.orderCount)")
            if !report.corrections.isEmpty {
                reportRow(String(localized: "Sales"), report.salesTotal.currencyString)
                reportRow(
                    String(localized: "Corrections (\(report.corrections.count))"),
                    report.correctionsTotal.currencyString
                )
            }
            reportRow(String(localized: "Gross receipts"), report.grossReceipts.currencyString, bold: true)
            if report.roundingTotal != 0 {
                reportRow(String(localized: "of which cash rounding"), report.roundingTotal.currencyString)
            }
            reportRow(String(localized: "Cost of goods sold"), report.totalCost.currencyString)
            reportRow(String(localized: "Net revenue"), report.netRevenue.currencyString, bold: true)
        }
    }

    private var paymentMethods: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Receipts by payment method")
                .font(.headline)
            if report.methodTotals.isEmpty {
                Text("No orders recorded.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
            ForEach(report.methodTotals) { entry in
                reportRow(
                    "\(entry.method.displayName) (\(entry.orderCount))",
                    entry.total.currencyString
                )
            }
        }
    }

    private var productTable: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Sales by product")
                .font(.headline)
            Grid(alignment: .leading, horizontalSpacing: 12, verticalSpacing: 4) {
                GridRow {
                    Text("Category").gridColumnAlignment(.leading)
                    Text("Product")
                    Text("Qty").gridColumnAlignment(.trailing)
                    Text("Revenue").gridColumnAlignment(.trailing)
                    Text("Cost").gridColumnAlignment(.trailing)
                    Text("Margin").gridColumnAlignment(.trailing)
                }
                .font(.caption.bold())
                Divider()
                ForEach(report.productLines) { line in
                    GridRow {
                        Text(line.categoryName)
                        Text(line.productName)
                        Text("\(line.quantity)")
                        Text(line.revenue.currencyString)
                        Text(line.cost.currencyString)
                        Text(line.margin.currencyString)
                    }
                    .font(.caption)
                }
            }
        }
    }

    private var correctionsSection: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Corrections (credited to clients)")
                .font(.headline)
            ForEach(report.corrections) { correction in
                reportRow(
                    correctionLabel(correction),
                    correction.total.currencyString
                )
            }
            reportRow(String(localized: "Corrections total"), report.correctionsTotal.currencyString)
        }
    }

    private func correctionLabel(_ correction: SessionReport.CorrectionOrder) -> String {
        var label = Order.ticketLabel(number: correction.number, time: correction.time)
        if let linked = correction.linkedOrderReference {
            label += String(localized: " — for order \(linked)")
        }
        if let reason = correction.reason, !reason.isEmpty {
            label += " (\(reason))"
        }
        return label
    }

    private var voidedSection: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Voided orders (excluded from receipts)")
                .font(.headline)
            ForEach(report.voidedOrders) { voided in
                reportRow(
                    Order.ticketLabel(number: voided.number, time: voided.time)
                        + " — \(voided.reason ?? String(localized: "no reason given"))",
                    voided.total.currencyString
                )
            }
            reportRow(String(localized: "Voided total"), report.voidedTotal.currencyString)
        }
    }

    private var footer: some View {
        Text("Special VAT exemption scheme for small businesses — no VAT charged.")
            .font(.caption2)
            .foregroundStyle(.secondary)
    }

    private func reportRow(_ label: String, _ value: String, bold: Bool = false) -> some View {
        HStack {
            Text(label)
            Spacer()
            Text(value).monospacedDigit()
        }
        .font(bold ? .subheadline.bold() : .subheadline)
    }
}
