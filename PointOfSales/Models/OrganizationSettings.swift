import Foundation
import SwiftData

/// Details of the vzw, shown on session reports, plus the bookkeeper's email
/// address. A single instance exists; use `current(in:)` to fetch or create it.
@Model
final class OrganizationSettings {
    var name: String = ""
    var address: String = ""
    var enterpriseNumber: String = ""
    var bookkeeperEmail: String = ""

    init() {}

    /// The single settings instance, created on first access.
    static func current(in context: ModelContext) -> OrganizationSettings {
        if let existing = try? context.fetch(FetchDescriptor<OrganizationSettings>()).first {
            return existing
        }
        let settings = OrganizationSettings()
        context.insert(settings)
        return settings
    }
}
