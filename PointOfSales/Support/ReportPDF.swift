import SwiftUI

/// Renders a session report to PDF data for the email attachment.
enum ReportPDF {
    struct RenderingFailed: LocalizedError {
        var errorDescription: String? {
            String(localized: "The report PDF could not be generated.")
        }
    }

    /// A4 width in PDF points; the page height follows the content.
    private static let pageWidth: CGFloat = 595

    @MainActor
    static func data(for report: SessionReport) throws -> Data {
        let renderer = ImageRenderer(
            content: SessionReportDocumentView(report: report)
                .frame(width: pageWidth)
        )
        renderer.proposedSize = ProposedViewSize(width: pageWidth, height: nil)

        let pdfData = NSMutableData()
        renderer.render { size, renderInContext in
            var mediaBox = CGRect(origin: .zero, size: size)
            guard
                let consumer = CGDataConsumer(data: pdfData),
                let context = CGContext(consumer: consumer, mediaBox: &mediaBox, nil)
            else { return }
            context.beginPDFPage(nil)
            renderInContext(context)
            context.endPDFPage()
            context.closePDF()
        }
        guard pdfData.length > 0 else { throw RenderingFailed() }
        return pdfData as Data
    }
}
