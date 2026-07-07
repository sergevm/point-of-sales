import SwiftUI
import SwiftData

/// Edits the vzw details shown on reports and the bookkeeper's email address.
struct OrganizationSettingsView: View {
    @Environment(\.modelContext) private var context

    @Query private var allSettings: [OrganizationSettings]

    var body: some View {
        Form {
            if let settings = allSettings.first {
                @Bindable var settings = settings

                Section {
                    TextField("Name (vzw)", text: $settings.name)
                    TextField("Address", text: $settings.address, axis: .vertical)
                        .lineLimit(2...4)
                    TextField("Enterprise number", text: $settings.enterpriseNumber)
                        .keyboardType(.numbersAndPunctuation)
                        .autocorrectionDisabled()
                } header: {
                    Text("Organization")
                } footer: {
                    if settings.name.trimmingCharacters(in: .whitespaces).isEmpty {
                        Text("Without a name, session reports have no organization header.")
                            .foregroundStyle(.orange)
                    }
                }

                Section {
                    TextField("Bookkeeper email", text: $settings.bookkeeperEmail)
                        .keyboardType(.emailAddress)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                } header: {
                    Text("Bookkeeper")
                } footer: {
                    if hasImplausibleEmail(settings.bookkeeperEmail) {
                        Text("This doesn't look like a valid email address.")
                            .foregroundStyle(.red)
                    } else {
                        Text("Session reports are emailed to this address. These details appear in the report header.")
                    }
                }
            }
        }
        .navigationTitle("Organization")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            if allSettings.isEmpty {
                _ = OrganizationSettings.current(in: context)
            }
        }
    }

    /// Loose plausibility check — flags obvious typos without rejecting
    /// unusual but valid addresses. Empty is fine (email is optional).
    private func hasImplausibleEmail(_ email: String) -> Bool {
        let trimmed = email.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return false }
        let parts = trimmed.split(separator: "@")
        return parts.count != 2 || !parts[1].contains(".") || trimmed.contains(" ")
    }
}
