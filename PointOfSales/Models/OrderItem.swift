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

    /// True when this line was given away rather than sold: a staff drink, a
    /// tasting. Still recorded as a consumption (``quantity`` and cost are
    /// unaffected), but ``lineTotal`` reports zero so it doesn't count towards
    /// revenue in reports handed to the accountant.
    var isNonPaying: Bool = false

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
        isNonPaying: Bool = false,
        product: Product? = nil,
        order: Order? = nil
    ) {
        self.productName = productName
        self.unitPrice = unitPrice
        self.unitCost = unitCost
        self.quantity = quantity
        self.isNonPaying = isNonPaying
        self.product = product
        self.order = order
    }

    /// Zero for a non-paying line: nobody is charged for it, so it must not
    /// contribute to revenue even though ``unitPrice`` is still snapshotted
    /// (useful once a stock/consumption report needs the would-be value).
    var lineTotal: Decimal { isNonPaying ? .zero : unitPrice * Decimal(quantity) }
    var lineCost: Decimal { unitCost * Decimal(quantity) }
}
