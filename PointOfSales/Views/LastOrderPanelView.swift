import SwiftUI
import SwiftData

/// A read-optimized view of the most recently charged order, shown in the
/// register's inspector so staff can see what to prepare and serve after the
/// ticket has been cleared. Deliberately larger and more glanceable than the
/// audit-style rows in ``SessionSalesView``.
struct LastOrderPanelView: View {
    let order: Order

    /// Called to reveal a linked order in the session sales list (the original
    /// this credit corrects, or a credit that corrects this order).
    var onShowLinkedOrder: (Order) -> Void = { _ in }

    private var items: [OrderItem] {
        order.items.sorted { $0.productName < $1.productName }
    }

    var body: some View {
        VStack(spacing: 0) {
            header
            Divider()

            List {
                ForEach(items) { item in
                    itemRow(item)
                }
            }
            .listStyle(.plain)

            correctionLinks

            Divider()
            footer
        }
        .background(.background)
    }

    /// Tappable link between this order and its correction counterpart, when one
    /// has been marked, so staff can jump to the related ticket in the sales list.
    @ViewBuilder
    private var correctionLinks: some View {
        if order.isCorrection, let original = order.correctedOrder {
            Divider()
            Button {
                onShowLinkedOrder(original)
            } label: {
                Label(
                    "Corrects the \(original.createdAt.formatted(date: .omitted, time: .shortened)) order",
                    systemImage: "arrow.up.left"
                )
                .font(.subheadline)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal)
                .padding(.vertical, 8)
            }
            .buttonStyle(.plain)
            .foregroundStyle(.tint)
        } else if order.hasCorrection, let credit = order.corrections.sorted(by: { $0.createdAt > $1.createdAt }).first {
            Divider()
            Button {
                onShowLinkedOrder(credit)
            } label: {
                Label(
                    "Corrected by a credit ticket — view",
                    systemImage: "arrow.down.right"
                )
                .font(.subheadline)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal)
                .padding(.vertical, 8)
            }
            .buttonStyle(.plain)
            .foregroundStyle(.red)
        }
    }

    private var header: some View {
        HStack(spacing: 10) {
            Image(systemName: order.isCorrection ? "arrow.uturn.backward.circle" : order.paymentMethod.systemImage)
                .font(.title3)
                .foregroundStyle(order.isCorrection ? Color.red : Color.accentColor)
                .accessibilityLabel(Text("Paid by \(order.paymentMethod.displayName)"))
            VStack(alignment: .leading, spacing: 2) {
                Text(order.isCorrection ? "Credit ticket" : "Last order")
                    .font(.headline)
                    .foregroundStyle(order.isCorrection ? .red : .primary)
                Text(order.createdAt.formatted(date: .omitted, time: .shortened))
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer()
        }
        .padding()
    }

    private func itemRow(_ item: OrderItem) -> some View {
        HStack(spacing: 12) {
            Text("\(item.quantity)")
                .font(.title3.bold().monospacedDigit())
                .frame(minWidth: 34, alignment: .trailing)
            Text("×")
                .font(.title3)
                .foregroundStyle(.secondary)
            Text(item.productName)
                .font(.title3.weight(.medium))
                .lineLimit(2)
            Spacer()
            Text(item.lineTotal.currencyString)
                .font(.body.monospacedDigit())
                .foregroundStyle(.secondary)
        }
        .padding(.vertical, 4)
    }

    private var footer: some View {
        VStack(spacing: 4) {
            HStack {
                Text("Total")
                    .font(.title3.bold())
                Spacer()
                Text(order.total.currencyString)
                    .font(.title2.bold().monospacedDigit())
            }
            if order.roundingAdjustment != 0 {
                HStack {
                    Spacer()
                    Text("incl. cash rounding")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .padding()
    }
}
