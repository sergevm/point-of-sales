import SwiftUI
import SwiftData

/// Products belonging to a single category, with add / edit / delete.
struct CategoryProductsView: View {
    @Bindable var category: ProductCategory

    @Environment(\.modelContext) private var context

    @State private var editingProduct: Product?
    @State private var creatingProduct = false

    private var products: [Product] {
        category.products.sorted { ($0.sortOrder, $0.name) < ($1.sortOrder, $1.name) }
    }

    var body: some View {
        List {
            if products.isEmpty {
                ContentUnavailableView(
                    "No products",
                    systemImage: "tray",
                    description: Text("Add the items sold in this category.")
                )
            }
            ForEach(products) { product in
                Button {
                    editingProduct = product
                } label: {
                    productRow(product)
                }
                .buttonStyle(.plain)
            }
            .onDelete(perform: deleteProducts)
            .onMove(perform: moveProducts)
        }
        .navigationTitle(category.name)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) { EditButton() }
            ToolbarItem(placement: .bottomBar) {
                Button {
                    creatingProduct = true
                } label: {
                    Label("Add product", systemImage: "plus")
                }
            }
        }
        .sheet(isPresented: $creatingProduct) {
            ProductEditView(product: nil, category: category, nextSortOrder: products.count)
        }
        .sheet(item: $editingProduct) { product in
            ProductEditView(product: product, category: category, nextSortOrder: products.count)
        }
    }

    private func productRow(_ product: Product) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(product.name)
                    .foregroundStyle(product.isActive ? .primary : .secondary)
                if !product.isActive {
                    Text("Hidden from register")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            Spacer()
            Text(product.price.currencyString)
                .monospacedDigit()
                .foregroundStyle(.secondary)
        }
    }

    private func deleteProducts(_ offsets: IndexSet) {
        for index in offsets {
            context.delete(products[index])
        }
    }

    private func moveProducts(_ offsets: IndexSet, _ destination: Int) {
        var reordered = products
        reordered.move(fromOffsets: offsets, toOffset: destination)
        for (index, product) in reordered.enumerated() {
            product.sortOrder = index
        }
    }
}
