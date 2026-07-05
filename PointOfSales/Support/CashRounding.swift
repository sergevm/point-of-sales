import Foundation

/// Belgian rounding of cash payments to the nearest 5 cents, mandatory since
/// 1 December 2019 for payments in the customer's physical presence:
/// 1–2 rounds down, 3–4 rounds up to 5, 6–7 rounds down to 5, 8–9 rounds up.
enum CashRounding {
    /// Rounds an amount to the nearest multiple of €0.05.
    static func rounded(_ amount: Decimal) -> Decimal {
        let behavior = NSDecimalNumberHandler(
            roundingMode: .plain,
            scale: 0,
            raiseOnExactness: false,
            raiseOnOverflow: false,
            raiseOnUnderflow: false,
            raiseOnDivideByZero: false
        )
        let twentieths = NSDecimalNumber(decimal: amount * 20)
        return twentieths.rounding(accordingToBehavior: behavior).decimalValue / 20
    }

    /// Difference the rounding adds to (positive) or removes from (negative)
    /// the exact amount.
    static func adjustment(for amount: Decimal) -> Decimal {
        rounded(amount) - amount
    }
}
