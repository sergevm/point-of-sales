import SwiftUI
import SwiftData

/// Lists the orders recorded in the current session, with the session total,
/// a void action per order (audit trail instead of deletion), and a control to
/// close the session and hand off to the report.
struct SessionSalesView: View {
    let session: SaleSession

    /// Called after the session has been closed, so the presenter can show the
    /// report / email flow.
    var onEnded: ((SaleSession) -> Void)?

    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    @State private var confirmingEnd = false
    @State private var voidingOrder: Order?
    @State private var voidReason = ""

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
                "End this session? You won't be able to add more sales to it, and its report is final.",
                isPresented: $confirmingEnd,
                titleVisibility: .visible
            ) {
                Button("End session", role: .destructive, action: endSession)
                Button("Cancel", role: .cancel) {}
            }
            .alert(
                "Void this order?",
                isPresented: Binding(
                    get: { voidingOrder != nil },
                    set: { if !$0 { voidingOrder = nil } }
                )
            ) {
                TextField("Reason (e.g. wrong entry)", text: $voidReason)
                Button("Void order", role: .destructive, action: voidOrder)
                Button("Cancel", role: .cancel) { voidingOrder = nil }
            } message: {
                Text("The order stays on record but no longer counts towards receipts.")
            }
        }
    }

    private var summaryHeader: some View {
        HStack {
            Text("\(session.orderCount) order\(session.orderCount == 1 ? "" : "s")")
            if session.voidedCount > 0 {
                Text("· \(session.voidedCount) voided")
                    .foregroundStyle(.secondary)
            }
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
                Image(systemName: order.paymentMethod.systemImage)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Spacer()
                Text(order.total.currencyString)
                    .font(.subheadline.bold().monospacedDigit())
                    .strikethrough(order.isVoided)
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
            if order.isVoided {
                Label(
                    "Voided — \(order.voidReason?.isEmpty == false ? order.voidReason! : "no reason given")",
                    systemImage: "xmark.circle"
                )
                .font(.caption)
                .foregroundStyle(.red)
            }
        }
        .padding(.vertical, 2)
        .opacity(order.isVoided ? 0.6 : 1)
        .swipeActions {
            if !order.isVoided && session.isActive {
                Button(role: .destructive) {
                    voidReason = ""
                    voidingOrder = order
                } label: {
                    Label("Void", systemImage: "xmark.circle")
                }
            }
        }
    }

    private func voidOrder() {
        guard let order = voidingOrder else { return }
        order.voidedAt = .now
        let trimmed = voidReason.trimmingCharacters(in: .whitespacesAndNewlines)
        order.voidReason = trimmed.isEmpty ? nil : trimmed
        voidingOrder = nil
        try? context.save()
    }

    private func endSession() {
        session.endedAt = .now
        // Closing a session finalizes its report; persist immediately rather
        // than relying on autosave.
        try? context.save()
        dismiss()
        onEnded?(session)
    }
}
