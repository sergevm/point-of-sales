import SwiftUI
import SwiftData

/// Create or edit a category (name + colour). Pass `nil` to create a new one.
struct CategoryEditView: View {
    let category: ProductCategory?
    let nextSortOrder: Int

    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss

    @Query private var allCategories: [ProductCategory]

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

    /// Category names are unique; catching a duplicate here beats the silent
    /// save failure the unique constraint would produce otherwise.
    private var isDuplicateName: Bool {
        allCategories.contains {
            $0 !== category && $0.name.caseInsensitiveCompare(trimmedName) == .orderedSame
        }
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("Category name", text: $name)
                } header: {
                    Text("Name")
                } footer: {
                    if isDuplicateName {
                        Text("A category with this name already exists.")
                            .foregroundStyle(.red)
                    }
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
                        .disabled(trimmedName.isEmpty || isDuplicateName)
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
                    .accessibilityElement()
                    .accessibilityLabel(Text("Colour \(hex)"))
                    .accessibilityAddTraits(hex == colorHex ? [.isButton, .isSelected] : .isButton)
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
