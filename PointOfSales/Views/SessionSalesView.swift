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

    /// An order to scroll to and briefly highlight when the view appears, e.g.
    /// when navigating in from a linked credit ticket.
    var focusOrderID: PersistentIdentifier?

    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    @State private var confirmingEnd = false
    @State private var voidingOrder: Order?
    @State private var voidReason = ""
    @State private var highlightedOrderID: PersistentIdentifier?
    @State private var saveFailed = false

    private var orders: [Order] { session.ordersByNewest }

    var body: some View {
        NavigationStack {
            content
            .navigationTitle(session.name ?? String(localized: "Current session"))
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
            .alert("Change could not be saved", isPresented: $saveFailed) {
                Button("OK", role: .cancel) {}
            } message: {
                Text("Please try again.")
            }
        }
    }

    @ViewBuilder
    private var content: some View {
        if orders.isEmpty {
            ContentUnavailableView(
                "No sales yet",
                systemImage: "list.bullet.rectangle",
                description: Text("Charged orders will appear here.")
            )
        } else {
            ScrollViewReader { proxy in
                List {
                    Section {
                        ForEach(orders) { order in
                            orderRow(order)
                                .id(order.persistentModelID)
                                .listRowBackground(rowBackground(order))
                        }
                    } header: {
                        summaryHeader
                    }
                }
                .onAppear { highlightedOrderID = focusOrderID }
                .onChange(of: highlightedOrderID) { _, id in
                    guard let id else { return }
                    withAnimation { proxy.scrollTo(id, anchor: .center) }
                }
            }
        }
    }

    private func rowBackground(_ order: Order) -> Color? {
        highlightedOrderID == order.persistentModelID
            ? Color.accentColor.opacity(0.15)
            : nil
    }

    private var summaryHeader: some View {
        HStack {
            Text("\(session.orderCount) orders")
            if session.correctionCount > 0 {
                Text("· \(session.correctionCount) credits \(session.correctionsTotal.currencyString)")
                    .foregroundStyle(.red)
            }
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
            orderRowHeader(order)
            orderItems(order)
            correctionLinks(order)
            if order.isVoided {
                Label(
                    "Voided — \(order.voidReason ?? String(localized: "no reason given"))",
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

    private func orderRowHeader(_ order: Order) -> some View {
        HStack {
            if let number = order.numberLabel {
                Text(verbatim: number)
                    .font(.subheadline.weight(.semibold).monospacedDigit())
            }
            Text(order.createdAt.formatted(date: .omitted, time: .standard))
                .font(.subheadline.weight(order.hasTicketNumber ? .regular : .semibold))
                .foregroundStyle(order.hasTicketNumber ? .secondary : .primary)
            Image(systemName: order.paymentMethod.systemImage)
                .font(.caption)
                .foregroundStyle(.secondary)
                .accessibilityLabel(Text("Paid by \(order.paymentMethod.displayName)"))
            if order.isCorrection {
                Text("Credit")
                    .font(.caption2.bold())
                    .foregroundStyle(.red)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(.red.opacity(0.12), in: Capsule())
            }
            Spacer()
            Text(order.total.currencyString)
                .font(.subheadline.bold().monospacedDigit())
                .strikethrough(order.isVoided)
                .foregroundStyle(order.isCorrection ? .red : .primary)
        }
    }

    private func orderItems(_ order: Order) -> some View {
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

    /// Tappable cross-links between a credit ticket and the order it corrects.
    @ViewBuilder
    private func correctionLinks(_ order: Order) -> some View {
        if let reason = order.correctionReason, !reason.isEmpty {
            Text(reason)
                .font(.caption.italic())
                .foregroundStyle(.secondary)
        }
        if order.isCorrection, let original = order.correctedOrder {
            Button {
                highlightedOrderID = original.persistentModelID
            } label: {
                Label(
                    "Corrects order \(original.referenceLabel)",
                    systemImage: "arrow.up.left"
                )
                .font(.caption)
            }
            .buttonStyle(.plain)
            .foregroundStyle(.tint)
        }
        if order.hasCorrection {
            ForEach(order.corrections.sorted { $0.createdAt < $1.createdAt }) { credit in
                Button {
                    highlightedOrderID = credit.persistentModelID
                } label: {
                    Label(
                        "Corrected by credit \(credit.referenceLabel)",
                        systemImage: "arrow.down.right"
                    )
                    .font(.caption)
                }
                .buttonStyle(.plain)
                .foregroundStyle(.tint)
            }
        }
    }

    private func voidOrder() {
        guard let order = voidingOrder else { return }
        order.voidedAt = .now
        let trimmed = voidReason.trimmingCharacters(in: .whitespacesAndNewlines)
        order.voidReason = trimmed.isEmpty ? nil : trimmed
        voidingOrder = nil
        do {
            try context.save()
        } catch {
            // Only never-voided orders can be voided, so reverting means clearing.
            order.voidedAt = nil
            order.voidReason = nil
            saveFailed = true
        }
    }

    private func endSession() {
        session.endedAt = .now
        // Closing a session finalizes its report; persist immediately rather
        // than relying on autosave.
        do {
            try context.save()
        } catch {
            session.endedAt = nil
            saveFailed = true
            return
        }
        dismiss()
        onEnded?(session)
    }
}
