import SwiftUI

/// Grid of product buttons for the selected category. Tapping a product adds it
/// to the cart.
struct ProductGridView: View {
    let category: ProductCategory?
    let onSelect: (Product) -> Void

    /// Opens the configuration sheet from the empty state, so a first-time
    /// user doesn't have to find the toolbar icon.
    var onOpenConfiguration: () -> Void = {}

    private let columns = [GridItem(.adaptive(minimum: 150, maximum: 220), spacing: 12)]

    private var products: [Product] {
        category?.activeProducts ?? []
    }

    /// Category colour used to tint the product buttons; falls back to the accent.
    private var tint: Color {
        Color(hex: category?.colorHex) ?? .accentColor
    }

    var body: some View {
        if products.isEmpty {
            ContentUnavailableView {
                Label("No products", systemImage: "tray")
            } description: {
                Text(category == nil
                     ? "Add a category and products to start selling."
                     : "This category has no active products.")
            } actions: {
                Button("Open Configure", action: onOpenConfiguration)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        } else {
            ScrollView {
                LazyVGrid(columns: columns, spacing: 12) {
                    ForEach(products) { product in
                        Button {
                            onSelect(product)
                        } label: {
                            VStack(spacing: 6) {
                                Text(product.name)
                                    .font(.headline)
                                    .multilineTextAlignment(.center)
                                    .lineLimit(2)
                                Text(product.price.currencyString)
                                    .font(.subheadline)
                                    .foregroundStyle(.white.opacity(0.85))
                            }
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity, minHeight: 90)
                            .padding(8)
                            .background(
                                LinearGradient(
                                    colors: [tint, tint.opacity(0.85)],
                                    startPoint: .top,
                                    endPoint: .bottom
                                ),
                                in: RoundedRectangle(cornerRadius: 14)
                            )
                        }
                        .buttonStyle(.depth(tint.opacity(0.5)))
                        .accessibilityLabel(Text("Add \(product.name), \(product.price.currencyString)"))
                    }
                }
                .padding(12)
            }
        }
    }
}
