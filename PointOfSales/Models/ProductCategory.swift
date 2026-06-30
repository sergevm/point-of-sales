import Foundation
import SwiftData

/// A group of products shown together on the register (e.g. "Beers", "Soft drinks").
///
/// Named `ProductCategory` rather than `Category` to avoid colliding with the
/// Objective-C runtime's `Category` type.
@Model
final class ProductCategory {
    /// Display name. Unique so the same category can't be created twice.
    @Attribute(.unique) var name: String

    /// Optional hex colour (e.g. "FF8800") used to tint the category button.
    var colorHex: String?

    /// Manual ordering of categories on the register.
    var sortOrder: Int

    /// Products in this category. Deleting a category deletes its products.
    @Relationship(deleteRule: .cascade, inverse: \Product.category)
    var products: [Product] = []

    init(name: String, colorHex: String? = nil, sortOrder: Int = 0) {
        self.name = name
        self.colorHex = colorHex
        self.sortOrder = sortOrder
    }

    /// Active products, sorted for display.
    var activeProducts: [Product] {
        products
            .filter(\.isActive)
            .sorted { ($0.sortOrder, $0.name) < ($1.sortOrder, $1.name) }
    }
}
