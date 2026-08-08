import SwiftUI
import SwiftData

/// Products belonging to a single category, with add / edit / delete.
struct CategoryProductsView: View {
    @Bindable var category: ProductCategory

    @Environment(\.modelContext) private var context

    @State private var editingProduct: Product?
    @State private var creatingProduct = false
    @State private var pendingDeletion: IndexSet?

    /// Measured height of the unassigned products section, so the empty state
    /// can claim the rest of the list and still leave it visible underneath.
    @State private var unassignedSectionHeight: CGFloat = 0

    /// Products left behind when their category was deleted; offered here so
    /// they can be re-assigned instead of recreated.
    @Query(
        filter: #Predicate<Product> { $0.category == nil },
        sort: \Product.name
    )
    private var unassignedProducts: [Product]

    private var products: [Product] {
        category.products.sorted { ($0.sortOrder, $0.name) < ($1.sortOrder, $1.name) }
    }

    var body: some View {
        GeometryReader { proxy in
            List {
                if products.isEmpty {
                    emptyProducts(height: emptyProductsHeight(in: proxy.size.height))
                }
                ForEach(products) { product in
                    Button {
                        editingProduct = product
                    } label: {
                        productRow(product)
                    }
                    .buttonStyle(.plain)
                }
                .onDelete { offsets in pendingDeletion = offsets }
                .onMove(perform: moveProducts)

                // Kept with this category's products, above the unassigned
                // section, so it stays clear which list it adds to. With no
                // products it moves into the empty state instead.
                if !products.isEmpty {
                    Button {
                        creatingProduct = true
                    } label: {
                        Label("Add product", systemImage: "plus")
                    }
                }

                if !unassignedProducts.isEmpty {
                    Section {
                        ForEach(unassignedProducts) { product in
                            unassignedRow(product)
                                .measuredListRowBackground()
                        }
                    } header: {
                        Text("Unassigned products")
                            .measuringOccupiedHeight()
                    } footer: {
                        Text("Products whose category was deleted. Add them to this category, or open another category to add them there.")
                            .measuringOccupiedHeight()
                    }
                }
            }
            .onPreferenceChange(OccupiedListHeightKey.self) { unassignedSectionHeight = $0 }
        }
        .navigationTitle(category.name)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) { EditButton() }
        }
        .sheet(isPresented: $creatingProduct) {
            ProductEditView(product: nil, category: category, nextSortOrder: products.count)
        }
        .sheet(item: $editingProduct) { product in
            ProductEditView(product: product, category: category, nextSortOrder: products.count)
        }
        .confirmationDialog(
            deletionTitle,
            isPresented: Binding(
                get: { pendingDeletion != nil },
                set: { if !$0 { pendingDeletion = nil } }
            ),
            titleVisibility: .visible
        ) {
            Button("Delete product", role: .destructive, action: deletePendingProducts)
            Button("Cancel", role: .cancel) { pendingDeletion = nil }
        } message: {
            Text("Past sales keep their records. To hide a product from the register without deleting it, turn off “Available on register” instead.")
        }
    }

    // MARK: - Empty state

    /// Mirrors the empty categories list: the placeholder fills the list so it
    /// reads as the screen's subject, with the add action along its bottom
    /// edge. List rows size to their content, so the height is handed in.
    private func emptyProducts(height: CGFloat) -> some View {
        Text("No products defined")
            .foregroundStyle(.secondary)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .overlay(alignment: .bottom) {
                Button {
                    creatingProduct = true
                } label: {
                    Label("Add product", systemImage: "plus")
                        .labelStyle(.titleAndIcon)
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
            }
            .padding(.vertical, 12)
            .frame(height: height)
    }

    /// What is left of the list once the unassigned section and the list's own
    /// chrome have taken their share. There is no header above the products, so
    /// the chrome is the list's padding plus, when the unassigned section is
    /// showing, the gap before it.
    private func emptyProductsHeight(in listHeight: CGFloat) -> CGFloat {
        let chrome: CGFloat = unassignedProducts.isEmpty ? 100 : 135
        return max(220, listHeight - unassignedSectionHeight - chrome)
    }

    private var deletionTitle: Text {
        let pending = pendingProducts
        if pending.count == 1, let product = pending.first {
            return Text("Delete “\(product.name)”?")
        }
        return Text("Delete \(pending.count) products?")
    }

    private var pendingProducts: [Product] {
        guard let pendingDeletion else { return [] }
        return pendingDeletion.compactMap { products.indices.contains($0) ? products[$0] : nil }
    }

    private func unassignedRow(_ product: Product) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(product.name)
                Text(product.price.currencyString)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            Button {
                product.category = category
                product.sortOrder = products.count
            } label: {
                Label("Add", systemImage: "plus.circle")
            }
            .buttonStyle(.borderless)
            .accessibilityLabel(Text("Add \(product.name) to \(category.name)"))
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

    private func deletePendingProducts() {
        for product in pendingProducts {
            context.delete(product)
        }
        pendingDeletion = nil
    }

    private func moveProducts(_ offsets: IndexSet, _ destination: Int) {
        var reordered = products
        reordered.move(fromOffsets: offsets, toOffset: destination)
        for (index, product) in reordered.enumerated() {
            product.sortOrder = index
        }
    }
}
