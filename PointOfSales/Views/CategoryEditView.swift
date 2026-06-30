import SwiftUI
import SwiftData

/// Create or edit a category (name + colour). Pass `nil` to create a new one.
struct CategoryEditView: View {
    let category: ProductCategory?
    let nextSortOrder: Int

    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss

    @State private var name: String
    @State private var colorHex: String?

    init(category: ProductCategory?, nextSortOrder: Int) {
        self.category = category
        self.nextSortOrder = nextSortOrder
        _name = State(initialValue: category?.name ?? "")
        _colorHex = State(initialValue: category?.colorHex ?? CategoryPalette.hexes.first)
    }

    private var isEditing: Bool { category != nil }

    private var trimmedName: String {
        name.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Name") {
                    TextField("Category name", text: $name)
                }
                Section("Colour") {
                    swatchGrid
                }
            }
            .navigationTitle(isEditing ? "Edit category" : "New category")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save", action: save)
                        .disabled(trimmedName.isEmpty)
                }
            }
        }
    }

    private var swatchGrid: some View {
        LazyVGrid(columns: [GridItem(.adaptive(minimum: 44), spacing: 12)], spacing: 12) {
            ForEach(CategoryPalette.hexes, id: \.self) { hex in
                Circle()
                    .fill(Color(hex: hex) ?? .gray)
                    .frame(width: 40, height: 40)
                    .overlay {
                        if hex == colorHex {
                            Image(systemName: "checkmark")
                                .foregroundStyle(.white)
                                .font(.headline)
                        }
                    }
                    .onTapGesture { colorHex = hex }
            }
        }
        .padding(.vertical, 4)
    }

    private func save() {
        if let category {
            category.name = trimmedName
            category.colorHex = colorHex
        } else {
            let new = ProductCategory(
                name: trimmedName,
                colorHex: colorHex,
                sortOrder: nextSortOrder
            )
            context.insert(new)
        }
        dismiss()
    }
}
