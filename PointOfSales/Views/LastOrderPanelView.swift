import SwiftUI
import SwiftData

/// A read-optimized view of the most recently charged order, shown in the
/// register's inspector so staff can see what to prepare and serve after the
/// ticket has been cleared. Deliberately larger and more glanceable than the
/// audit-style rows in ``SessionSalesView``.
struct LastOrderPanelView: View {
    let order: Order

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

            Divider()
            footer
        }
        .background(.background)
    }

    private var header: some View {
        HStack(spacing: 10) {
            Image(systemName: order.paymentMethod.systemImage)
                .font(.title3)
                .foregroundStyle(.tint)
            VStack(alignment: .leading, spacing: 2) {
                Text("Last order")
                    .font(.headline)
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
