import SwiftUI
import SwiftData

/// Top-level shell. Shows the start-session screen when no session is open,
/// otherwise the register. Provides access to configuration and session sales.
struct RootView: View {
    @Environment(\.modelContext) private var context

    // The single open session (if any): the one without an end date.
    @Query(filter: #Predicate<SaleSession> { $0.endedAt == nil })
    private var openSessions: [SaleSession]

    @State private var cart = Cart()
    @State private var showingConfiguration = false
    @State private var showingSales = false
    @State private var showingHistory = false
    @State private var reportSession: SaleSession?

    private var activeSession: SaleSession? { openSessions.first }

    var body: some View {
        NavigationStack {
            Group {
                if let session = activeSession {
                    RegisterView(session: session, cart: cart)
                } else {
                    StartSessionView()
                }
            }
            .navigationTitle("")
            .toolbar { toolbarContent }
        }
        .sheet(isPresented: $showingConfiguration) {
            ConfigurationView()
        }
        .sheet(isPresented: $showingSales) {
            if let session = activeSession {
                SessionSalesView(session: session, onEnded: presentReport)
            }
        }
        .sheet(isPresented: $showingHistory) {
            SessionHistoryView()
        }
        .sheet(item: $reportSession) { session in
            NavigationStack {
                SessionReportScreen(session: session)
            }
        }
    }

    /// After a session is closed its sales sheet dismisses itself; wait for
    /// that transition before presenting the report sheet.
    private func presentReport(for session: SaleSession) {
        Task { @MainActor in
            try? await Task.sleep(for: .seconds(0.5))
            reportSession = session
        }
    }

    @ToolbarContentBuilder
    private var toolbarContent: some ToolbarContent {
        ToolbarItem(placement: .topBarLeading) {
            if let session = activeSession {
                VStack(alignment: .leading, spacing: 0) {
                    Text(session.name ?? "Session")
                        .font(.headline)
                    Text("Started \(session.startedAt.formatted(date: .omitted, time: .shortened))")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            } else {
                Text("Point of Sale").font(.headline)
            }
        }

        ToolbarItemGroup(placement: .topBarTrailing) {
            if activeSession != nil {
                Button {
                    showingSales = true
                } label: {
                    Label("Sales", systemImage: "list.bullet.rectangle")
                }
            }
            Button {
                showingHistory = true
            } label: {
                Label("History", systemImage: "clock.arrow.circlepath")
            }
            Button {
                showingConfiguration = true
            } label: {
                Label("Configure", systemImage: "slider.horizontal.3")
            }
        }
    }
}
