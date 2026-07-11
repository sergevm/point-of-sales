import SwiftUI
import SwiftData

/// Manage categories and products. Presented as a sheet from the register.
struct ConfigurationView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss

    @Query(sort: \ProductCategory.sortOrder) private var categories: [ProductCategory]
    @Query private var products: [Product]

    @State private var editingCategory: ProductCategory?
    @State private var creatingCategory = false
    @State private var pendingDeletion: IndexSet?
    @State private var confirmingDemoSetup = false
    @State private var demoSetupFailed = false

    /// Nothing has been set up yet: no categories *and* no products (products
    /// can exist without a category). Only then do we offer the demo setup.
    private var isCatalogEmpty: Bool {
        categories.isEmpty && products.isEmpty
    }

    var body: some View {
        NavigationStack {
            List {
                Section("Categories") {
                    if categories.isEmpty {
                        ContentUnavailableView(
                            "No categories",
                            systemImage: "square.grid.2x2",
                            description: Text("Add a category to start building your menu.")
                        )
                        if isCatalogEmpty {
                            Button {
                                confirmingDemoSetup = true
                            } label: {
                                Label("Or try it with a demo setup", systemImage: "wand.and.stars")
                                    .frame(maxWidth: .infinity, alignment: .center)
                            }
                        }
                    }
                    ForEach(categories) { category in
                        NavigationLink {
                            CategoryProductsView(category: category)
                        } label: {
                            categoryRow(category)
                        }
                    }
                    .onDelete { offsets in pendingDeletion = offsets }
                    .onMove(perform: moveCategories)
                }

                Section {
                    NavigationLink {
                        OrganizationSettingsView()
                    } label: {
                        Label("Organization & bookkeeper", systemImage: "building.2")
                    }
                }
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
            .confirmationDialog(
                deletionTitle,
                isPresented: Binding(
                    get: { pendingDeletion != nil },
                    set: { if !$0 { pendingDeletion = nil } }
                ),
                titleVisibility: .visible
            ) {
                Button("Delete category", role: .destructive, action: deletePendingCategories)
                Button("Cancel", role: .cancel) { pendingDeletion = nil }
            } message: {
                Text("Its products are kept and become unassigned. You can re-assign them from any category's product list.")
            }
            .confirmationDialog(
                "Create demo setup?",
                isPresented: $confirmingDemoSetup,
                titleVisibility: .visible
            ) {
                Button("Create demo setup", action: createDemoSetup)
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("This adds \(DemoCatalog.categoryCount) sample categories with \(DemoCatalog.productCount) products. You can edit or delete them at any time.")
            }
            .alert("Demo setup could not be created", isPresented: $demoSetupFailed) {
                Button("OK", role: .cancel) {}
            } message: {
                Text("Please try again.")
            }
        }
    }

    private func createDemoSetup() {
        do {
            try DemoCatalog.createDemoSetup(in: context)
        } catch {
            demoSetupFailed = true
        }
    }

    private var deletionTitle: Text {
        let pending = pendingCategories
        if pending.count == 1, let category = pending.first {
            return Text("Delete “\(category.name)”?")
        }
        return Text("Delete \(pending.count) categories?")
    }

    private var pendingCategories: [ProductCategory] {
        guard let pendingDeletion else { return [] }
        return pendingDeletion.compactMap { categories.indices.contains($0) ? categories[$0] : nil }
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

    private func deletePendingCategories() {
        for category in pendingCategories {
            context.delete(category)
        }
        pendingDeletion = nil
    }

    private func moveCategories(_ offsets: IndexSet, _ destination: Int) {
        var reordered = categories
        reordered.move(fromOffsets: offsets, toOffset: destination)
        for (index, category) in reordered.enumerated() {
            category.sortOrder = index
        }
    }
}
