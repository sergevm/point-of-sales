import SwiftUI
import SwiftData

/// Closed sessions, newest first, each opening its report. Also gives access
/// to the daily receipts overview. Closed sessions cannot be edited or
/// deleted: they are the bookkeeping record.
struct SessionHistoryView: View {
    @Environment(\.dismiss) private var dismiss

    @Query(
        filter: #Predicate<SaleSession> { $0.endedAt != nil },
        sort: \SaleSession.startedAt,
        order: .reverse
    )
    private var sessions: [SaleSession]

    var body: some View {
        NavigationStack {
            List {
                Section {
                    NavigationLink {
                        DailyReceiptsView()
                    } label: {
                        Label("Daily receipts", systemImage: "calendar")
                    }
                }

                Section("Closed sessions") {
                    if sessions.isEmpty {
                        Text("No closed sessions yet.")
                            .foregroundStyle(.secondary)
                    }
                    ForEach(sessions) { session in
                        NavigationLink {
                            SessionReportScreen(session: session)
                        } label: {
                            sessionRow(session)
                        }
                    }
                }
            }
            .navigationTitle("History")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }

    private func sessionRow(_ session: SaleSession) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text("#\(session.sequenceNumber)  \(session.name ?? "Session")")
                    .font(.body.weight(.medium))
                Text(session.startedAt.formatted(date: .abbreviated, time: .shortened))
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            VStack(alignment: .trailing, spacing: 2) {
                Text(session.total.currencyString)
                    .font(.body.monospacedDigit())
                Text("\(session.orderCount) order\(session.orderCount == 1 ? "" : "s")")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }
}
