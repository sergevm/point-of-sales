import SwiftUI
import SwiftData

/// Create or edit a product within a category. Pass `nil` to create a new one.
struct ProductEditView: View {
    let product: Product?
    let category: ProductCategory
    let nextSortOrder: Int

    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss

    @Query(sort: \ProductCategory.sortOrder) private var categories: [ProductCategory]

    @State private var name: String
    @State private var price: Decimal
    @State private var costPrice: Decimal
    @State private var isActive: Bool
    @State private var selectedCategory: ProductCategory?

    init(product: Product?, category: ProductCategory, nextSortOrder: Int) {
        self.product = product
        self.category = category
        self.nextSortOrder = nextSortOrder
        _name = State(initialValue: product?.name ?? "")
        _price = State(initialValue: product?.price ?? 0)
        _costPrice = State(initialValue: product?.costPrice ?? 0)
        _isActive = State(initialValue: product?.isActive ?? true)
        _selectedCategory = State(initialValue: product?.category ?? category)
    }

    private var isEditing: Bool { product != nil }

    private var trimmedName: String {
        name.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    /// Another product with the same name in the chosen category.
    private var isDuplicateName: Bool {
        guard let selectedCategory else { return false }
        return selectedCategory.products.contains {
            $0 !== product && $0.name.caseInsensitiveCompare(trimmedName) == .orderedSame
        }
    }

    private var canSave: Bool {
        !trimmedName.isEmpty && price > 0 && costPrice >= 0 && !isDuplicateName
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("Product name", text: $name)
                } header: {
                    Text("Name")
                } footer: {
                    if isDuplicateName {
                        Text("A product with this name already exists in this category.")
                            .foregroundStyle(.red)
                    }
                }
                Section("Price") {
                    TextField(
                        "Price",
                        value: $price,
                        format: .currency(code: Money.currencyCode)
                    )
                    .keyboardType(.decimalPad)
                }
                Section {
                    TextField(
                        "Cost price",
                        value: $costPrice,
                        format: .currency(code: Money.currencyCode)
                    )
                    .keyboardType(.decimalPad)
                } header: {
                    Text("Cost price")
                } footer: {
                    if costPrice < 0 {
                        Text("The cost price can't be negative.")
                            .foregroundStyle(.red)
                    } else {
                        Text("What you pay per unit to stock this product. Used for net-revenue reporting; never shown on the register.")
                    }
                }
                Section {
                    Picker("Category", selection: $selectedCategory) {
                        Text("None").tag(ProductCategory?.none)
                        ForEach(categories) { category in
                            Text(category.name).tag(Optional(category))
                        }
                    }
                } footer: {
                    if selectedCategory == nil {
                        Text("Without a category this product won't appear on the register.")
                    }
                }
                Section {
                    Toggle("Available on register", isOn: $isActive)
                } footer: {
                    Text("Turn off to hide this product without deleting it or its past sales.")
                }
            }
            .navigationTitle(isEditing ? "Edit product" : "New product")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save", action: save)
                        .disabled(!canSave)
                }
            }
        }
    }

    private func save() {
        if let product {
            product.name = trimmedName
            product.price = price
            product.costPrice = costPrice
            product.isActive = isActive
            product.category = selectedCategory
        } else {
            let new = Product(
                name: trimmedName,
                price: price,
                sortOrder: nextSortOrder,
                isActive: isActive,
                category: selectedCategory
            )
            new.costPrice = costPrice
            context.insert(new)
        }
        dismiss()
    }
}
