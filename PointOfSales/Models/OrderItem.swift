import Foundation
import SwiftData

/// One line on a ticket. Name, unit price and unit cost are snapshotted from
/// the product at charge time, so editing or deleting the product later does
/// not alter the sale or its margin.
@Model
final class OrderItem {
    var productName: String
    var unitPrice: Decimal

    /// Purchase cost per unit at charge time, for net-revenue reporting.
    var unitCost: Decimal = 0

    var quantity: Int

    var order: Order?

    /// Reference back to the originating product, if it still exists. Uses the
    /// default nullify rule: deleting the product clears this without deleting
    /// the line item.
    var product: Product?

    init(
        productName: String,
        unitPrice: Decimal,
        unitCost: Decimal = .zero,
        quantity: Int,
        product: Product? = nil,
        order: Order? = nil
    ) {
        self.productName = productName
        self.unitPrice = unitPrice
        self.unitCost = unitCost
        self.quantity = quantity
        self.product = product
        self.order = order
    }

    var lineTotal: Decimal { unitPrice * Decimal(quantity) }
    var lineCost: Decimal { unitCost * Decimal(quantity) }
}
