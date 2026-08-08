import SwiftUI
import SwiftData

/// Manage categories and products. Presented as a sheet from the register.
struct ConfigurationView: View {
    @Environment(\.modelContext) private var context

    @Query(sort: \ProductCategory.sortOrder) private var categories: [ProductCategory]
    @Query private var products: [Product]

    @State private var editingCategory: ProductCategory?
    @State private var creatingCategory = false
    @State private var pendingDeletion: IndexSet?
    @State private var confirmingDemoSetup = false
    @State private var demoSetupFailed = false

    /// Measured height of the settings rows, so the empty categories state can
    /// claim the rest of the list and still leave them visible underneath.
    @State private var settingsRowsHeight: CGFloat = 0

    /// Nothing has been set up yet: no categories *and* no products (products
    /// can exist without a category). Only then do we offer the demo setup.
    private var isCatalogEmpty: Bool {
        categories.isEmpty && products.isEmpty
    }

    var body: some View {
        NavigationStack {
            GeometryReader { proxy in
                List {
                    Section("Categories") {
                        if categories.isEmpty {
                            emptyCategories(height: emptyCategoriesHeight(in: proxy.size.height))
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

                        // The add action lives in the list it acts on, so it
                        // stays tied to the categories even with other sections
                        // on screen. When there are none it moves into the
                        // empty state instead.
                        if !categories.isEmpty {
                            Button {
                                creatingCategory = true
                            } label: {
                                Label("Add category", systemImage: "plus")
                            }
                        }
                    }

                    Section {
                        NavigationLink {
                            OrganizationSettingsView()
                        } label: {
                            Label("Organization & bookkeeper", systemImage: "building.2")
                        }
                        .listRowBackground(measuredRowBackground)
                        NavigationLink {
                            DataCleanupView()
                        } label: {
                            Label("Clean up old data", systemImage: "clock.arrow.circlepath")
                        }
                        .listRowBackground(measuredRowBackground)
                    }
                }
                .onPreferenceChange(SettingsRowsHeightKey.self) { settingsRowsHeight = $0 }
            }
            .navigationTitle("Configuration")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    EditButton()
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

    // MARK: - Empty state

    /// The empty categories state fills the list so the section reads as the
    /// screen's subject, while the settings section stays visible below it.
    /// List rows size to their content, so the height has to be handed in.
    private func emptyCategories(height: CGFloat) -> some View {
        Text("No categories defined")
            .foregroundStyle(.secondary)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .overlay(alignment: .bottom) {
                VStack(spacing: 12) {
                    Button {
                        creatingCategory = true
                    } label: {
                        // Without an explicit style the prominent button drops
                        // the icon, leaving the two buttons inconsistent.
                        Label("Add category", systemImage: "plus")
                            .labelStyle(.titleAndIcon)
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)

                    if isCatalogEmpty {
                        Button {
                            confirmingDemoSetup = true
                        } label: {
                            Label("Or try it with a demo setup", systemImage: "wand.and.stars")
                                .labelStyle(.titleAndIcon)
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.bordered)
                    }
                }
            }
            .padding(.vertical, 12)
            .frame(height: height)
    }

    /// What is left of the list once the settings rows and the list's own
    /// chrome (section header, the gap between sections, top and bottom
    /// padding) have taken their share.
    private func emptyCategoriesHeight(in listHeight: CGFloat) -> CGFloat {
        let chrome: CGFloat = 96
        return max(220, listHeight - settingsRowsHeight - chrome)
    }

    /// A standard grouped-row background that also reports the row's height.
    private var measuredRowBackground: some View {
        Color(.secondarySystemGroupedBackground)
            .overlay {
                GeometryReader { proxy in
                    Color.clear.preference(
                        key: SettingsRowsHeightKey.self,
                        value: proxy.size.height
                    )
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

/// Sums the heights of the settings rows so the empty categories state knows
/// how much of the list it can claim without pushing them off screen.
private struct SettingsRowsHeightKey: PreferenceKey {
    static var defaultValue: CGFloat = 0

    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value += nextValue()
    }
}
