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
    @State private var attachmentError: String?

    private var settings: OrganizationSettings? { allSettings.first }

    private var report: SessionReport {
        SessionReport(session: session, organization: settings)
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                if attachmentError != nil {
                    attachmentErrorBanner
                }
                SessionReportDocumentView(report: report)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .shadow(radius: 2)
                    .padding()
            }
            .frame(maxWidth: 700)
            .frame(maxWidth: .infinity)
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle(session.displayName)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItemGroup(placement: .primaryAction) {
                if MailComposer.canSendMail {
                    Button {
                        showingMail = true
                    } label: {
                        Label("Email to bookkeeper", systemImage: "envelope")
                    }
                    .disabled(attachmentURLs.isEmpty)
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

    /// Shown when the PDF/CSV files could not be created, so the user knows why
    /// sharing is unavailable and can retry.
    private var attachmentErrorBanner: some View {
        HStack(spacing: 12) {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundStyle(.yellow)
            VStack(alignment: .leading, spacing: 2) {
                Text("The report files could not be created.")
                    .font(.subheadline.weight(.semibold))
                if let attachmentError {
                    Text(attachmentError)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            Spacer()
            Button("Try again") { prepareAttachmentFiles() }
        }
        .padding(12)
        .background(.yellow.opacity(0.15), in: RoundedRectangle(cornerRadius: 12))
        .padding([.horizontal, .top])
    }

    private var recipients: [String] {
        let email = settings?.bookkeeperEmail.trimmingCharacters(in: .whitespaces) ?? ""
        return email.isEmpty ? [] : [email]
    }

    private var mailSubject: String {
        String(localized: "Session report — \(session.displayName)")
    }

    private var mailBody: String {
        let report = report
        return String(localized: """
        Hi,

        Attached is session report \(report.sessionName) \
        (\(report.startedAt.formatted(date: .long, time: .omitted))).

        Orders: \(report.orderCount)
        Gross receipts: \(report.grossReceipts.currencyString)
        Cash: \(report.cashTotal.currencyString) — Electronic: \(report.electronicTotal.currencyString)

        PDF for the records, CSV for import.
        """)
    }

    /// Reuses the files written by `prepareAttachmentFiles()` so the mail and
    /// share flows always offer the same attachments.
    private func mailAttachments() -> [MailComposer.Attachment] {
        attachmentURLs.compactMap { url in
            guard let data = try? Data(contentsOf: url) else { return nil }
            return MailComposer.Attachment(
                data: data,
                mimeType: url.pathExtension == "pdf" ? "application/pdf" : "text/csv",
                fileName: url.lastPathComponent
            )
        }
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
            attachmentError = nil
        } catch {
            attachmentURLs = []
            attachmentError = error.localizedDescription
        }
    }
}
