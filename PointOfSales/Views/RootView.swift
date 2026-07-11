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

    /// Order to scroll to when the sales list opens, set when navigating in from
    /// a linked correction/original in the register's last-order panel.
    @State private var salesFocusOrderID: PersistentIdentifier?

    /// Session whose report should be shown once the sales sheet has finished
    /// dismissing; presenting both at once would drop the second sheet.
    @State private var pendingReportSession: SaleSession?

    private var activeSession: SaleSession? { openSessions.first }

    var body: some View {
        NavigationStack {
            Group {
                if let session = activeSession {
                    RegisterView(
                        session: session,
                        cart: cart,
                        onShowOrderInSales: { order in
                            salesFocusOrderID = order.persistentModelID
                            showingSales = true
                        },
                        onOpenConfiguration: { showingConfiguration = true }
                    )
                } else {
                    StartSessionView(onOpenConfiguration: { showingConfiguration = true })
                }
            }
            .navigationTitle("")
            .toolbar { toolbarContent }
        }
        .sheet(isPresented: $showingConfiguration) {
            ConfigurationView()
        }
        .sheet(isPresented: $showingSales, onDismiss: {
            salesFocusOrderID = nil
            presentPendingReport()
        }) {
            if let session = activeSession {
                SessionSalesView(
                    session: session,
                    onEnded: { endedSession in
                        pendingReportSession = endedSession
                    },
                    focusOrderID: salesFocusOrderID
                )
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
        .task {
            #if DEBUG
            DemoData.seedIfRequested(in: context)
            await DemoData.forceLandscapeIfRequested()
            #endif
        }
    }

    /// After a session is closed its sales sheet dismisses itself; the report
    /// sheet is presented from that dismissal so the two never overlap.
    private func presentPendingReport() {
        reportSession = pendingReportSession
        pendingReportSession = nil
    }

    @ToolbarContentBuilder
    private var toolbarContent: some ToolbarContent {
        ToolbarItem(placement: .topBarLeading) {
            if let session = activeSession {
                HStack(spacing: 8) {
                    Image(systemName: "cart.fill")
                        .foregroundStyle(.tint)
                    VStack(alignment: .leading, spacing: 1) {
                        Text(session.name ?? String(localized: "Session"))
                            .font(.headline)
                            .lineLimit(1)
                        Text("Started \(session.startedAt.formatted(date: .omitted, time: .shortened))")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                    }
                    .fixedSize(horizontal: true, vertical: false)
                }
            } else {
                Text("Point of Sales")
                    .font(.headline)
                    .fixedSize(horizontal: true, vertical: false)
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
