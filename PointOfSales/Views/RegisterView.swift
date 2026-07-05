import SwiftUI
import SwiftData

/// The main register: categories + product grid on the left, current ticket on
/// the right. Designed for landscape iPad.
struct RegisterView: View {
    let session: SaleSession
    let cart: Cart

    @Query(sort: \ProductCategory.sortOrder) private var categories: [ProductCategory]
    @State private var selectedCategoryID: PersistentIdentifier?

    private var selectedCategory: ProductCategory? {
        if let id = selectedCategoryID,
           let match = categories.first(where: { $0.persistentModelID == id }) {
            return match
        }
        return categories.first
    }

    var body: some View {
        HStack(spacing: 0) {
            VStack(spacing: 0) {
                categoryBar
                Divider()
                ProductGridView(category: selectedCategory) { product in
                    cart.add(product)
                }
            }
            .frame(maxWidth: .infinity)

            Divider()

            CartPanelView(session: session, cart: cart)
                .frame(width: 340)
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
