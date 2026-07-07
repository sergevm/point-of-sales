import Foundation

/// Belgian bookkeeping thresholds used by the daily receipts view.
enum BelgianReporting {
    /// Unit price above which a sale must be individually recorded in the
    /// daily receipts book (dagontvangstenboek); days containing one are
    /// flagged so the bookkeeper knows to keep the order tickets.
    static let largeSaleUnitPrice: Decimal = 250
}
