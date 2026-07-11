import Foundation
import SwiftData

/// The demo product catalog (categories and products) shared between the
/// debug screenshot seeder (`DemoData`) and the user-facing "create demo
/// setup" action offered on the start screen when the store is empty.
///
/// Names follow the app language so the catalog reads naturally in both the
/// English and Dutch localizations.
enum DemoCatalog {
    static func eur(_ cents: Int) -> Decimal {
        Decimal(cents) / 100
    }

    private static var isDutch: Bool {
        Bundle.main.preferredLocalizations.first?.hasPrefix("nl") == true
    }

    /// Picks the English or Dutch variant of a demo name.
    static func L(_ en: String, _ nl: String) -> String {
        isDutch ? nl : en
    }

    /// (name, price in cents, cost in cents) per category.
    static var catalog: [(category: String, colorHex: String, products: [(String, Int, Int)])] {
        [
            (L("Cold drinks", "Koude dranken"), "1E88E5", [
                ("Coca-Cola", 220, 75),
                ("Cola Zero", 220, 75),
                ("Sprite", 220, 75),
                ("Fanta", 220, 75),
                (L("Water", "Water"), 180, 45),
                (L("Sparkling water", "Spuitwater"), 180, 45),
                ("Tonic", 250, 90),
                (L("Apple juice", "Appelsap"), 220, 80),
                (L("Orange juice", "Sinaasappelsap"), 220, 80),
                (L("Chocolate milk", "Chocomelk"), 220, 85),
            ]),
            (L("Hot drinks", "Warme dranken"), "FB8C00", [
                (L("Coffee", "Koffie"), 200, 40),
                (L("Decaf", "Deca"), 200, 40),
                (L("Tea", "Thee"), 200, 35),
                (L("Hot chocolate", "Warme chocomelk"), 250, 90),
                (L("Rosehip tea", "Rozenbottelthee"), 220, 40),
                (L("Curry soup", "Currysoep"), 350, 120),
                (L("Tomato soup", "Tomatensoep"), 350, 110),
            ]),
            ("Snacks", "FDD835", [
                (L("Salted crisps", "Chips zout"), 150, 60),
                (L("Paprika crisps", "Chips paprika"), 150, 60),
                (L("Dried sausage", "Droge worst"), 350, 180),
            ]),
            (L("Wine", "Wijn"), "8E24AA", [
                (L("Red wine", "Rode wijn"), 350, 130),
                (L("White wine", "Witte wijn"), 350, 130),
                (L("Port", "Porto"), 400, 150),
            ]),
        ]
    }

    /// Inserts the demo categories and products, returning them keyed by name
    /// so callers (the debug seeder) can build orders against them.
    @discardableResult
    static func seedCatalog(in context: ModelContext) -> [String: Product] {
        var byName: [String: Product] = [:]
        for (categoryIndex, entry) in catalog.enumerated() {
            let category = ProductCategory(
                name: entry.category,
                colorHex: entry.colorHex,
                sortOrder: categoryIndex
            )
            context.insert(category)
            for (productIndex, item) in entry.products.enumerated() {
                let product = Product(
                    name: item.0,
                    price: eur(item.1),
                    sortOrder: productIndex,
                    category: category
                )
                product.costPrice = eur(item.2)
                context.insert(product)
                byName[item.0] = product
            }
        }
        return byName
    }

    /// Number of categories and products the demo setup creates, for the
    /// confirmation prompt shown to the user.
    static var categoryCount: Int { catalog.count }
    static var productCount: Int { catalog.reduce(0) { $0 + $1.products.count } }

    /// Creates the demo catalog for a user who taps "create demo setup" on the
    /// start screen. Only seeds when the store has no categories *and* no
    /// products (products can exist unassigned to a category), so the action is
    /// idempotent even if the UI state is momentarily stale.
    static func createDemoSetup(in context: ModelContext) throws {
        let categoryCount = try context.fetchCount(FetchDescriptor<ProductCategory>())
        let productCount = try context.fetchCount(FetchDescriptor<Product>())
        guard categoryCount == 0, productCount == 0 else { return }
        seedCatalog(in: context)
        try context.save()
    }
}
