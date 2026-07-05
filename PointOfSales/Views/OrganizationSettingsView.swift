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

                Section("Organization") {
                    TextField("Name (vzw)", text: $settings.name)
                    TextField("Address", text: $settings.address, axis: .vertical)
                        .lineLimit(2...4)
                    TextField("Enterprise number", text: $settings.enterpriseNumber)
                        .keyboardType(.numbersAndPunctuation)
                        .autocorrectionDisabled()
                }

                Section {
                    TextField("Bookkeeper email", text: $settings.bookkeeperEmail)
                        .keyboardType(.emailAddress)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                } header: {
                    Text("Bookkeeper")
                } footer: {
                    Text("Session reports are emailed to this address. These details appear in the report header.")
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
}
