import SwiftUI
import SwiftData

/// Shown when no session is open. Lets the user name and start a new session.
struct StartSessionView: View {
    @Environment(\.modelContext) private var context

    @Query(sort: \ProductCategory.sortOrder) private var categories: [ProductCategory]
    @State private var name = ""

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
            .buttonStyle(.borderedProminent)

            if !hasProducts {
                Text("Tip: add categories and products from Configure first.")
                    .font(.callout)
                    .foregroundStyle(.secondary)
                    .padding(.top, 8)
            }
        }
        .padding(40)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private func startSession() {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        let session = SaleSession(
            name: trimmed.isEmpty ? nil : trimmed,
            sequenceNumber: SaleSession.nextSequenceNumber(in: context)
        )
        context.insert(session)
        name = ""
    }
}
