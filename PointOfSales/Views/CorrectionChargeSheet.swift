import SwiftUI
import SwiftData

/// Charge flow for a credit ticket. Lets the seller optionally link the credit
/// to an earlier order in the session, add a reason for the bookkeeper, and pick
/// how the refund is paid out. Presented instead of the plain payment
/// confirmation dialog when the cart is in correction mode.
struct CorrectionChargeSheet: View {
    let session: SaleSession
    let cart: Cart

    /// Called with the chosen method, the optional linked order, and the
    /// optional trimmed reason when the seller confirms the credit.
    var onCharge: (PaymentMethod, Order?, String?) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var linkedOrderID: PersistentIdentifier?
    @State private var reason = ""
    @State private var method: PaymentMethod = .cash

    /// Sale orders from the current session that a credit can be linked to
    /// (voided orders and other credit tickets are excluded).
    private var linkableOrders: [Order] {
        session.ordersByNewest.filter { !$0.isVoided && !$0.isCorrection }
    }

    private var linkedOrder: Order? {
        guard let id = linkedOrderID else { return nil }
        return linkableOrders.first { $0.persistentModelID == id }
    }

    var body: some View {
        NavigationStack {
            Form {
                linkSection
                reasonSection
                paymentSection
            }
            .navigationTitle("Credit ticket")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Charge") { confirm() }
                }
            }
        }
        .presentationDetents([.large])
    }

    @ViewBuilder
    private var linkSection: some View {
        Section {
            if linkableOrders.isEmpty {
                Text("No earlier orders in this session to link to.")
                    .foregroundStyle(.secondary)
            } else {
                Button {
                    linkedOrderID = nil
                } label: {
                    linkRow(title: "Don't link", subtitle: nil, isSelected: linkedOrderID == nil)
                }
                .buttonStyle(.plain)

                ForEach(linkableOrders) { order in
                    Button {
                        linkedOrderID = order.persistentModelID
                    } label: {
                        linkRow(
                            title: linkTitle(order),
                            subtitle: itemSummary(order),
                            isSelected: linkedOrderID == order.persistentModelID
                        )
                    }
                    .buttonStyle(.plain)
                }
            }
        } header: {
            Text("Correct a previous order (optional)")
        }
    }

    /// Row title like "#3 · 14:30 · €12,50".
    private func linkTitle(_ order: Order) -> String {
        Order.ticketLabel(number: order.sequenceNumber, time: order.createdAt)
            + " · " + order.total.currencyString
    }

    private func linkRow(title: String, subtitle: String?, isSelected: Bool) -> some View {
        HStack(alignment: .firstTextBaseline) {
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .foregroundStyle(.primary)
                if let subtitle, !subtitle.isEmpty {
                    Text(subtitle)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
            }
            Spacer()
            if isSelected {
                Image(systemName: "checkmark")
                    .foregroundStyle(.tint)
                    .fontWeight(.semibold)
            }
        }
        .contentShape(Rectangle())
    }

    private func itemSummary(_ order: Order) -> String {
        order.items
            .sorted { $0.productName < $1.productName }
            .map { "\($0.quantity)× \($0.productName)" }
            .joined(separator: ", ")
    }

    private var reasonSection: some View {
        Section {
            TextField("Reason (e.g. wrong order, spilled drink)", text: $reason)
        } header: {
            Text("Reason (optional)")
        }
    }

    private var paymentSection: some View {
        Section {
            Picker("Paid out by", selection: $method) {
                ForEach(PaymentMethod.allCases) { method in
                    Text(method.displayName).tag(method)
                }
            }
            HStack {
                Text("Amount credited")
                Spacer()
                Text(cart.chargeTotal(for: method).currencyString)
                    .font(.headline.monospacedDigit())
                    .foregroundStyle(.red)
            }
        } header: {
            Text("Refund")
        }
    }

    private func confirm() {
        let trimmed = reason.trimmingCharacters(in: .whitespacesAndNewlines)
        onCharge(method, linkedOrder, trimmed.isEmpty ? nil : trimmed)
        dismiss()
    }
}
