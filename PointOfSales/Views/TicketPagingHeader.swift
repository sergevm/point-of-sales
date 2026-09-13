import SwiftUI

/// A centered title flanked by paging arrows, used by ``CartPanelView`` to
/// step between the live ticket and past orders in the same pane. The two
/// arrows are independent — back steps deeper into history, forward steps
/// back towards the live ticket — and either can be disabled at its end of
/// the history.
struct TicketPagingHeader: View {
    let title: String
    var titleColor: Color = .primary
    var backEnabled: Bool = true
    var forwardEnabled: Bool = true
    let backAccessibilityLabel: String
    let forwardAccessibilityLabel: String
    let onBack: () -> Void
    let onForward: () -> Void

    var body: some View {
        HStack {
            pageButton("chevron.left", enabled: backEnabled, label: backAccessibilityLabel, action: onBack)
            Spacer()
            Text(title)
                .font(.headline)
                .foregroundStyle(titleColor)
            Spacer()
            pageButton("chevron.right", enabled: forwardEnabled, label: forwardAccessibilityLabel, action: onForward)
        }
    }

    private func pageButton(_ systemImage: String, enabled: Bool, label: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: systemImage)
                .font(.subheadline.bold())
                .foregroundStyle(.secondary)
                .frame(width: 32, height: 32)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .disabled(!enabled)
        .accessibilityLabel(Text(label))
    }
}
