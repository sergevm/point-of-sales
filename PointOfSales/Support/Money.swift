import Foundation

/// Currency used throughout the app. Change this single value to re-denominate.
enum Money {
    static let currencyCode = "EUR"

    /// Formats a decimal amount as a localized currency string, e.g. "€3.50".
    static func string(_ amount: Decimal) -> String {
        amount.formatted(.currency(code: currencyCode))
    }
}

extension Decimal {
    /// Convenience for formatting any amount as currency.
    var currencyString: String { Money.string(self) }
}
