import Foundation
import SwiftData

/// A single item for sale at a fixed price.
@Model
final class Product {
    var name: String

    /// Unit price. Stored as `Decimal` to avoid floating-point money errors.
    var price: Decimal

    /// What the vzw pays per unit to stock this product. Used for net-revenue
    /// reporting; never shown on the register.
    var costPrice: Decimal = 0

    /// Manual ordering within a category.
    var sortOrder: Int

    /// Inactive products stay in storage (and in past orders) but are hidden
    /// from the register.
    var isActive: Bool

    var category: ProductCategory?

    init(
        name: String,
        price: Decimal,
        sortOrder: Int = 0,
        isActive: Bool = true,
        category: ProductCategory? = nil
    ) {
        self.name = name
        self.price = price
        self.sortOrder = sortOrder
        self.isActive = isActive
        self.category = category
    }
}
