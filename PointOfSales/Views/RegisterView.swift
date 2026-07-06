import SwiftUI
import SwiftData

/// The main register: categories + product grid on the left, current ticket on
/// the right. Designed for landscape iPad.
struct RegisterView: View {
    let session: SaleSession
    let cart: Cart

    /// Called to reveal a linked order (an original or its credit) in the
    /// session sales list, for navigating between corrections and their originals.
    var onShowOrderInSales: (Order) -> Void = { _ in }

    @Query(sort: \ProductCategory.sortOrder) private var categories: [ProductCategory]
    @State private var selectedCategoryID: PersistentIdentifier?
    @State private var showingLastOrder = false

    private var selectedCategory: ProductCategory? {
        if let id = selectedCategoryID,
           let match = categories.first(where: { $0.persistentModelID == id }) {
            return match
        }
        return categories.first
    }

    /// The most recently charged order in this session, shown in the inspector.
    private var lastOrder: Order? { session.ordersByNewest.first }

    var body: some View {
        HStack(spacing: 0) {
            VStack(spacing: 0) {
                categoryBar
                Divider()
                ProductGridView(category: selectedCategory) { product in
                    cart.add(product)
                    showingLastOrder = false
                }
            }
            .frame(maxWidth: .infinity)

            Divider()

            CartPanelView(session: session, cart: cart) {
                showingLastOrder = true
            }
            .frame(width: 340)
        }
        .inspector(isPresented: $showingLastOrder) {
            Group {
                if let order = lastOrder {
                    LastOrderPanelView(order: order, onShowLinkedOrder: onShowOrderInSales)
                } else {
                    ContentUnavailableView(
                        "No orders yet",
                        systemImage: "checklist",
                        description: Text("Charged orders appear here so you can serve them.")
                    )
                }
            }
            .inspectorColumnWidth(min: 280, ideal: 320, max: 420)
        }
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    showingLastOrder.toggle()
                } label: {
                    Label("Last order", systemImage: "checklist")
                }
                .disabled(lastOrder == nil)
            }
        }
    }

    private var categoryBar: some View {
        FlowLayout(spacing: 12) {
            if categories.isEmpty {
                Text("No categories yet — add some in Configure.")
                    .foregroundStyle(.secondary)
                    .padding(.vertical, 12)
            }
            ForEach(categories) { category in
                let color = Color(hex: category.colorHex) ?? .accentColor
                let isSelected = category.persistentModelID == selectedCategory?.persistentModelID
                Button {
                    selectedCategoryID = category.persistentModelID
                    showingLastOrder = false
                } label: {
                    Text(category.name)
                        .font(.headline)
                        .padding(.horizontal, 18)
                        .padding(.vertical, 12)
                        .background(color.opacity(isSelected ? 1 : 0.18))
                        .foregroundStyle(isSelected ? .white : .primary)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                }
                .buttonStyle(.depth(color.opacity(isSelected ? 0.45 : 0.15)))
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(12)
    }
}
