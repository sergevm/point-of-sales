import Foundation

/// How an order was paid. The cash vs electronic split is what the bookkeeper
/// needs for the daily receipts record, and cash totals are legally rounded to
/// 5 cents in Belgium.
enum PaymentMethod: String, CaseIterable, Identifiable, Codable {
    case cash
    case card
    case payconiq

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .cash: String(localized: "Cash")
        case .card: String(localized: "Card")
        case .payconiq: "Payconiq" // Brand name, never translated.
        }
    }

    var systemImage: String {
        switch self {
        case .cash: "banknote"
        case .card: "creditcard"
        case .payconiq: "qrcode"
        }
    }

    var isElectronic: Bool { self != .cash }
}
