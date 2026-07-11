import SwiftUI
import SwiftData

/// Shown when no session is open. Lets the user name and start a new session.
struct StartSessionView: View {
    /// Called to open the configuration sheet, so the no-products hint can take
    /// the user straight to set-up instead of describing the toolbar icon.
    var onOpenConfiguration: () -> Void = {}

    @Environment(\.modelContext) private var context

    @Query(sort: \ProductCategory.sortOrder) private var categories: [ProductCategory]
    @State private var name = ""
    @State private var startFailed = false

    private var hasProducts: Bool {
        categories.contains { !$0.products.isEmpty }
    }

    var body: some View {
        VStack(spacing: 24) {
            Image(systemName: "cart.badge.plus")
                .font(.system(size: 64))
                .foregroundStyle(.tint)

            Text("No open session")
                .font(.largeTitle.bold())

            Text("Start a session to begin recording sales.")
                .foregroundStyle(.secondary)

            TextField("Session name (optional)", text: $name)
                .textFieldStyle(.roundedBorder)
                .frame(maxWidth: 360)

            Button(action: startSession) {
                Label("Start session", systemImage: "play.fill")
                    .font(.title3.bold())
                    .padding(.horizontal, 24)
                    .padding(.vertical, 12)
            }
            .buttonStyle(.prominentDepth(tint: .accentColor))

            if !hasProducts {
                Button(action: onOpenConfiguration) {
                    Label("Add categories and products first", systemImage: "slider.horizontal.3")
                        .font(.callout)
                }
                .padding(.top, 8)
            }
        }
        .padding(40)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .alert("Session could not be started", isPresented: $startFailed) {
            Button("OK", role: .cancel) {}
        } message: {
            Text("Please try again.")
        }
    }

    private func startSession() {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        let sessionName = trimmed.isEmpty ? SaleSession.defaultName(in: context) : trimmed
        let session = SaleSession(
            name: sessionName,
            sequenceNumber: SaleSession.nextSequenceNumber(in: context)
        )
        context.insert(session)
        do {
            try context.save()
            name = ""
        } catch {
            context.delete(session)
            startFailed = true
        }
    }
}
