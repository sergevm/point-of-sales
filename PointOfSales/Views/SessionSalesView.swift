import SwiftUI
import SwiftData

/// Lists the orders recorded in the current session, with the session total and
/// a control to close the session.
struct SessionSalesView: View {
    let session: SaleSession

    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    @State private var confirmingEnd = false

    private var orders: [Order] { session.ordersByNewest }

    var body: some View {
        NavigationStack {
            Group {
                if orders.isEmpty {
                    ContentUnavailableView(
                        "No sales yet",
                        systemImage: "list.bullet.rectangle",
                        description: Text("Charged orders will appear here.")
                    )
                } else {
                    List {
                        Section {
                            ForEach(orders) { order in
                                orderRow(order)
                            }
                        } header: {
                            summaryHeader
                        }
                    }
                }
            }
            .navigationTitle(session.name ?? "Current session")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("End session", role: .destructive) {
                        confirmingEnd = true
                    }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
            .confirmationDialog(
                "End this session? You won't be able to add more sales to it.",
                isPresented: $confirmingEnd,
                titleVisibility: .visible
            ) {
                Button("End session", role: .destructive, action: endSession)
                Button("Cancel", role: .cancel) {}
            }
        }
    }

    private var summaryHeader: some View {
        HStack {
            Text("\(session.orderCount) order\(session.orderCount == 1 ? "" : "s")")
            Spacer()
            Text("Total \(session.total.currencyString)")
                .font(.headline)
                .foregroundStyle(.primary)
        }
        .textCase(nil)
        .font(.subheadline)
        .padding(.vertical, 4)
    }

    private func orderRow(_ order: Order) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(order.createdAt.formatted(date: .omitted, time: .standard))
                    .font(.subheadline.weight(.semibold))
                Spacer()
                Text(order.total.currencyString)
                    .font(.subheadline.bold().monospacedDigit())
            }
            ForEach(order.items.sorted { $0.productName < $1.productName }) { item in
                HStack {
                    Text("\(item.quantity)×  \(item.productName)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Spacer()
                    Text(item.lineTotal.currencyString)
                        .font(.caption.monospacedDigit())
                        .foregroundStyle(.secondary)
                }
            }
        }
        .padding(.vertical, 2)
    }

    private func endSession() {
        session.endedAt = .now
        dismiss()
    }
}
