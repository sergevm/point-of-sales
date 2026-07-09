import SwiftUI
import SwiftData

/// Frees up storage by permanently deleting closed sessions older than a
/// chosen retention period. Deleting a session cascades to its orders and
/// their items. Nothing is deleted automatically: the user picks a period,
/// reviews a preview of what would go, and confirms an explicit warning.
struct DataCleanupView: View {
    @Environment(\.modelContext) private var context

    /// Retention period in months; persisted so the choice sticks.
    @AppStorage("dataRetentionMonths") private var retentionMonths = 12

    @Query private var sessions: [SaleSession]

    @State private var confirmingDeletion = false
    @State private var deletedCount: Int?
    @State private var deletionFailed = false

    var body: some View {
        Form {
            Section {
                Stepper(value: $retentionMonths, in: 1...60) {
                    Text("Older than \(retentionMonths) months")
                }
            } header: {
                Text("Retention period")
            } footer: {
                Text("Nothing is deleted automatically. Below you can permanently delete every session that was closed longer ago than this.")
            }

            Section {
                if expiredSessions.isEmpty {
                    Text("No closed sessions are older than this.")
                        .foregroundStyle(.secondary)
                } else {
                    LabeledContent("Sessions", value: "\(expiredSessions.count)")
                    LabeledContent("Orders", value: "\(expiredOrderCount)")
                    if let period = expiredPeriod {
                        LabeledContent("Period", value: period)
                    }
                }
            } header: {
                Text("To be deleted")
            }

            Section {
                Button(role: .destructive) {
                    confirmingDeletion = true
                } label: {
                    Label("Delete old sessions", systemImage: "trash")
                }
                .disabled(expiredSessions.isEmpty)
            } footer: {
                Text("Deleted sessions and their orders disappear permanently from the history and reports. This cannot be undone. An open session is never deleted.")
            }
        }
        .navigationTitle("Old data")
        .navigationBarTitleDisplayMode(.inline)
        .confirmationDialog(
            Text("Delete \(expiredSessions.count) sessions?"),
            isPresented: $confirmingDeletion,
            titleVisibility: .visible
        ) {
            Button("Delete permanently", role: .destructive, action: deleteExpiredSessions)
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("These sessions and every order recorded in them will be gone forever. This cannot be undone.")
        }
        .alert(
            "Old sessions deleted",
            isPresented: Binding(
                get: { deletedCount != nil },
                set: { if !$0 { deletedCount = nil } }
            )
        ) {
            Button("OK") { deletedCount = nil }
        } message: {
            Text("Deleted \(deletedCount ?? 0) sessions.")
        }
        .alert("Deletion failed", isPresented: $deletionFailed) {
            Button("OK", role: .cancel) {}
        } message: {
            Text("The data could not be deleted. No changes were made.")
        }
    }

    private var cutoffDate: Date {
        // Falling back to .distantPast makes the filter match nothing.
        Calendar.current.date(byAdding: .month, value: -retentionMonths, to: .now) ?? .distantPast
    }

    /// Closed sessions whose end date falls before the cutoff. An open session
    /// (`endedAt == nil`) never qualifies, whatever its age.
    private var expiredSessions: [SaleSession] {
        let cutoff = cutoffDate
        return sessions.filter { session in
            guard let endedAt = session.endedAt else { return false }
            return endedAt < cutoff
        }
    }

    private var expiredOrderCount: Int {
        expiredSessions.reduce(0) { $0 + $1.orders.count }
    }

    private var expiredPeriod: String? {
        let dates = expiredSessions.map(\.startedAt)
        guard let first = dates.min(), let last = dates.max() else { return nil }
        if Calendar.current.isDate(first, inSameDayAs: last) {
            return first.formatted(date: .abbreviated, time: .omitted)
        }
        return (first..<last).formatted(date: .abbreviated, time: .omitted)
    }

    private func deleteExpiredSessions() {
        let expired = expiredSessions
        guard !expired.isEmpty else { return }
        for session in expired {
            context.delete(session)
        }
        do {
            try context.save()
            deletedCount = expired.count
        } catch {
            context.rollback()
            deletionFailed = true
        }
    }
}
