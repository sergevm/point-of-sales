import Foundation
import SwiftData

/// One line on a ticket. Name and unit price are snapshotted from the product at
/// charge time, so editing or deleting the product later does not alter the sale.
@Model
final class OrderItem {
    var productName: String
    var unitPrice: Decimal
    var quantity: Int

    var order: Order?

    /// Reference back to the originating product, if it still exists. Uses the
    /// default nullify rule: deleting the product clears this without deleting
    /// the line item.
    var product: Product?

    init(
        productName: String,
        unitPrice: Decimal,
        quantity: Int,
        product: Product? = nil,
        order: Order? = nil
    ) {
        self.productName = productName
        self.unitPrice = unitPrice
        self.quantity = quantity
        self.product = product
        self.order = order
    }

    var lineTotal: Decimal { unitPrice * Decimal(quantity) }
}
