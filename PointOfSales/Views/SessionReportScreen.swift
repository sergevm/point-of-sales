import SwiftUI
import SwiftData

/// Shows a session's report with actions to get it to the bookkeeper: a
/// pre-addressed Apple Mail composer when Mail is configured, and a share
/// sheet (Gmail, AirDrop, Save to Files, …) that always works. Push this
/// inside a `NavigationStack` (history) or wrap it in one when presenting as
/// a sheet (end of session).
struct SessionReportScreen: View {
    let session: SaleSession

    @Query private var allSettings: [OrganizationSettings]

    @State private var showingMail = false
    @State private var attachmentURLs: [URL] = []

    private var settings: OrganizationSettings? { allSettings.first }

    private var report: SessionReport {
        SessionReport(session: session, organization: settings)
    }

    var body: some View {
        ScrollView {
            SessionReportDocumentView(report: report)
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .shadow(radius: 2)
                .padding()
                .frame(maxWidth: 700)
                .frame(maxWidth: .infinity)
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle("Report #\(session.sequenceNumber)")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItemGroup(placement: .primaryAction) {
                if MailComposer.canSendMail {
                    Button {
                        showingMail = true
                    } label: {
                        Label("Email to bookkeeper", systemImage: "envelope")
                    }
                }
                ShareLink(
                    items: attachmentURLs,
                    subject: Text(mailSubject),
                    message: Text(mailBody)
                ) {
                    Label("Share report", systemImage: "square.and.arrow.up")
                }
                .disabled(attachmentURLs.isEmpty)
            }
        }
        .task { prepareAttachmentFiles() }
        .sheet(isPresented: $showingMail) {
            MailComposer(
                recipients: recipients,
                subject: mailSubject,
                body: mailBody,
                attachments: mailAttachments(),
                isPresented: $showingMail
            )
        }
    }

    private var recipients: [String] {
        let email = settings?.bookkeeperEmail.trimmingCharacters(in: .whitespaces) ?? ""
        return email.isEmpty ? [] : [email]
    }

    private var mailSubject: String {
        let day = session.startedAt.formatted(date: .numeric, time: .omitted)
        return "Session report #\(session.sequenceNumber) — \(day)"
    }

    private var mailBody: String {
        let report = report
        return """
        Hi,

        Attached is session report #\(report.reportNumber) \
        (\(report.startedAt.formatted(date: .long, time: .omitted))).

        Orders: \(report.orderCount)
        Gross receipts: \(report.grossReceipts.currencyString)
        Cash: \(report.cashTotal.currencyString) — Electronic: \(report.electronicTotal.currencyString)

        PDF for the records, CSV for import.
        """
    }

    private func mailAttachments() -> [MailComposer.Attachment] {
        [
            MailComposer.Attachment(
                data: ReportPDF.data(for: report),
                mimeType: "application/pdf",
                fileName: pdfFileName
            ),
            MailComposer.Attachment(
                data: Data(ReportCSV.ordersCSV(session: session).utf8),
                mimeType: "text/csv",
                fileName: csvFileName
            )
        ]
    }

    private var pdfFileName: String { "session-report-\(session.sequenceNumber).pdf" }
    private var csvFileName: String { "session-report-\(session.sequenceNumber)-orders.csv" }

    /// Writes the PDF and CSV to the temporary directory so the share sheet
    /// can hand them to any app as named files.
    private func prepareAttachmentFiles() {
        let directory = FileManager.default.temporaryDirectory
        let pdfURL = directory.appendingPathComponent(pdfFileName)
        let csvURL = directory.appendingPathComponent(csvFileName)
        do {
            try ReportPDF.data(for: report).write(to: pdfURL)
            try Data(ReportCSV.ordersCSV(session: session).utf8).write(to: csvURL)
            attachmentURLs = [pdfURL, csvURL]
        } catch {
            attachmentURLs = []
        }
    }
}
