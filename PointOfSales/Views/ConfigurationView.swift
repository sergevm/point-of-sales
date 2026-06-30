import SwiftUI
import SwiftData

/// Manage categories and products. Presented as a sheet from the register.
struct ConfigurationView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss

    @Query(sort: \ProductCategory.sortOrder) private var categories: [ProductCategory]

    @State private var editingCategory: ProductCategory?
    @State private var creatingCategory = false

    var body: some View {
        NavigationStack {
            List {
                if categories.isEmpty {
                    ContentUnavailableView(
                        "No categories",
                        systemImage: "square.grid.2x2",
                        description: Text("Add a category to start building your menu.")
                    )
                }
                ForEach(categories) { category in
                    NavigationLink {
                        CategoryProductsView(category: category)
                    } label: {
                        categoryRow(category)
                    }
                }
                .onDelete(perform: deleteCategories)
                .onMove(perform: moveCategories)
            }
            .navigationTitle("Configuration")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    EditButton()
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                }
                ToolbarItem(placement: .bottomBar) {
                    Button {
                        creatingCategory = true
                    } label: {
                        Label("Add category", systemImage: "plus")
                    }
                }
            }
            .sheet(isPresented: $creatingCategory) {
                CategoryEditView(category: nil, nextSortOrder: categories.count)
            }
            .sheet(item: $editingCategory) { category in
                CategoryEditView(category: category, nextSortOrder: categories.count)
            }
        }
    }

    private func categoryRow(_ category: ProductCategory) -> some View {
        HStack(spacing: 12) {
            RoundedRectangle(cornerRadius: 6)
                .fill(Color(hex: category.colorHex) ?? .accentColor)
                .frame(width: 22, height: 22)
            Text(category.name)
            Spacer()
            Text("\(category.products.count)")
                .foregroundStyle(.secondary)
            Button {
                editingCategory = category
            } label: {
                Image(systemName: "pencil")
            }
            .buttonStyle(.borderless)
        }
    }

    private func deleteCategories(_ offsets: IndexSet) {
        for index in offsets {
            context.delete(categories[index])
        }
    }

    private func moveCategories(_ offsets: IndexSet, _ destination: Int) {
        var reordered = categories
        reordered.move(fromOffsets: offsets, toOffset: destination)
        for (index, category) in reordered.enumerated() {
            category.sortOrder = index
        }
    }
}
