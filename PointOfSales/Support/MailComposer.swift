import SwiftUI
import MessageUI

/// SwiftUI wrapper around the system mail composer, used to send the session
/// report to the bookkeeper. Check `canSendMail` first; when mail is not set
/// up, fall back to the share sheet.
struct MailComposer: UIViewControllerRepresentable {
    struct Attachment {
        let data: Data
        let mimeType: String
        let fileName: String
    }

    let recipients: [String]
    let subject: String
    let body: String
    let attachments: [Attachment]

    /// The presenting sheet's flag; reset when the composer finishes so the
    /// action can be used again.
    @Binding var isPresented: Bool

    static var canSendMail: Bool { MFMailComposeViewController.canSendMail() }

    func makeUIViewController(context: Context) -> MFMailComposeViewController {
        let controller = MFMailComposeViewController()
        controller.mailComposeDelegate = context.coordinator
        controller.setToRecipients(recipients)
        controller.setSubject(subject)
        controller.setMessageBody(body, isHTML: false)
        for attachment in attachments {
            controller.addAttachmentData(
                attachment.data,
                mimeType: attachment.mimeType,
                fileName: attachment.fileName
            )
        }
        return controller
    }

    func updateUIViewController(_ controller: MFMailComposeViewController, context: Context) {}

    func makeCoordinator() -> Coordinator { Coordinator(isPresented: $isPresented) }

    final class Coordinator: NSObject, MFMailComposeViewControllerDelegate {
        private let isPresented: Binding<Bool>

        init(isPresented: Binding<Bool>) {
            self.isPresented = isPresented
        }

        func mailComposeController(
            _ controller: MFMailComposeViewController,
            didFinishWith result: MFMailComposeResult,
            error: Error?
        ) {
            isPresented.wrappedValue = false
        }
    }
}
