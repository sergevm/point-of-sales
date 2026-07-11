#if DEBUG
import Foundation
import SwiftData
import UIKit

/// Seeds the store with presentable demo content when the app is launched with
/// the `-demoData` argument (debug builds only), for App Store and support-site
/// screenshots: a product catalog with realistic prices, organization settings,
/// one closed session with a full evening of orders (including a credit ticket
/// and a voided order), and one open session mid-evening.
///
/// Seeding is skipped when any category already exists, so relaunching with the
/// argument never duplicates data.
enum DemoData {
    static func seedIfRequested(in context: ModelContext) {
        guard ProcessInfo.processInfo.arguments.contains("-demoData") else { return }
        let categoryCount = (try? context.fetchCount(FetchDescriptor<ProductCategory>())) ?? 0
        guard categoryCount == 0 else { return }

        let settings = OrganizationSettings.current(in: context)
        settings.name = "Vrolijke vrienden vzw"
        settings.address = "Kerkstraat 12, 9000 Gent"
        settings.enterpriseNumber = "0745.678.986"
        settings.bookkeeperEmail = "mail@vrolijkevrienden.be"

        let products = seedCatalog(in: context)
        seedClosedSession(in: context, products: products)
        seedOpenSession(in: context, products: products)
        try? context.save()
    }

    /// Rotates the simulator to landscape when launched with `-demoLandscape`,
    /// so full-screen screenshots can be taken without manual interaction.
    /// SpringBoard reverts the faked orientation after a few seconds, so keep
    /// re-asserting it for as long as the app runs.
    @MainActor
    static func forceLandscapeIfRequested() async {
        guard ProcessInfo.processInfo.arguments.contains("-demoLandscape") else { return }
        while !Task.isCancelled {
            UIDevice.current.setValue(UIDeviceOrientation.landscapeLeft.rawValue, forKey: "orientation")
            try? await Task.sleep(for: .seconds(2))
        }
    }

    // MARK: - Catalog

    private static func eur(_ cents: Int) -> Decimal {
        Decimal(cents) / 100
    }

    /// Demo names follow the app language so screenshots read naturally in
    /// every store localization.
    private static var isDutch: Bool {
        Bundle.main.preferredLocalizations.first?.hasPrefix("nl") == true
    }

    /// Picks the English or Dutch variant of a demo name.
    private static func L(_ en: String, _ nl: String) -> String {
        isDutch ? nl : en
    }

    /// (name, price in cents, cost in cents) per category.
    private static var catalog: [(category: String, colorHex: String, products: [(String, Int, Int)])] {
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

    private static func seedCatalog(in context: ModelContext) -> [String: Product] {
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

    // MARK: - Sessions

    private static func seedClosedSession(in context: ModelContext, products: [String: Product]) {
        let calendar = Calendar.current
        guard let yesterday = calendar.date(byAdding: .day, value: -1, to: .now) else { return }
        let start = calendar.date(bySettingHour: 19, minute: 0, second: 0, of: yesterday) ?? yesterday

        let session = SaleSession(
            name: L("Friday bar", "Vrijdagbar"),
            sequenceNumber: 1,
            startedAt: start
        )
        session.endedAt = start.addingTimeInterval(4.5 * 3600)
        context.insert(session)

        func at(_ minutes: Int) -> Date { start.addingTimeInterval(Double(minutes) * 60) }

        let doubleEntry = addOrder(
            to: session, number: 1, at: at(12), method: .cash,
            lines: [(L("Port", "Porto"), 2)], products: products, in: context
        )
        doubleEntry.voidedAt = at(14)
        doubleEntry.voidReason = L("Entered twice", "Dubbel ingegeven")

        addOrder(to: session, number: 2, at: at(15), method: .cash,
                 lines: [(L("Port", "Porto"), 2)], products: products, in: context)
        addOrder(to: session, number: 3, at: at(21), method: .cash,
                 lines: [(L("Coffee", "Koffie"), 2), (L("Apple juice", "Appelsap"), 1)], products: products, in: context)
        addOrder(to: session, number: 4, at: at(29), method: .payconiq,
                 lines: [("Coca-Cola", 3), ("Water", 1)], products: products, in: context)
        addOrder(to: session, number: 5, at: at(38), method: .cash,
                 lines: [(L("Red wine", "Rode wijn"), 2), (L("Salted crisps", "Chips zout"), 1)], products: products, in: context)
        addOrder(to: session, number: 6, at: at(52), method: .card,
                 lines: [(L("Tomato soup", "Tomatensoep"), 2), (L("Sparkling water", "Spuitwater"), 1)], products: products, in: context)
        let fantaOrder = addOrder(
            to: session, number: 7, at: at(66), method: .cash,
            lines: [("Fanta", 1), ("Sprite", 1), (L("Paprika crisps", "Chips paprika"), 2)], products: products, in: context
        )
        addOrder(to: session, number: 8, at: at(83), method: .payconiq,
                 lines: [(L("White wine", "Witte wijn"), 3), (L("Dried sausage", "Droge worst"), 1)], products: products, in: context)
        addOrder(to: session, number: 9, at: at(101), method: .cash,
                 lines: [(L("Chocolate milk", "Chocomelk"), 2), (L("Hot chocolate", "Warme chocomelk"), 1)], products: products, in: context)
        addOrder(to: session, number: 10, at: at(124), method: .card,
                 lines: [(L("Curry soup", "Currysoep"), 2), ("Cola Zero", 1)], products: products, in: context)
        addOrder(to: session, number: 11, at: at(149), method: .payconiq,
                 lines: [("Tonic", 2), (L("Orange juice", "Sinaasappelsap"), 1)], products: products, in: context)
        addOrder(to: session, number: 12, at: at(178), method: .cash,
                 lines: [("Fanta", -1)], products: products, in: context,
                 correcting: fantaOrder, reason: L("Wrong order", "Verkeerde bestelling"))
        addOrder(to: session, number: 13, at: at(205), method: .cash,
                 lines: [(L("Tea", "Thee"), 2), (L("Decaf", "Deca"), 1)], products: products, in: context)
    }

    private static func seedOpenSession(in context: ModelContext, products: [String: Product]) {
        let start = Date.now.addingTimeInterval(-75 * 60)
        let session = SaleSession(
            name: L("Saturday bar", "Zaterdagbar"),
            sequenceNumber: 2,
            startedAt: start
        )
        context.insert(session)

        addOrder(to: session, number: 1, at: .now.addingTimeInterval(-58 * 60), method: .cash,
                 lines: [("Coca-Cola", 2), (L("Salted crisps", "Chips zout"), 1)], products: products, in: context)
        addOrder(to: session, number: 2, at: .now.addingTimeInterval(-34 * 60), method: .payconiq,
                 lines: [(L("Coffee", "Koffie"), 2)], products: products, in: context)
        addOrder(to: session, number: 3, at: .now.addingTimeInterval(-11 * 60), method: .card,
                 lines: [(L("White wine", "Witte wijn"), 2), (L("Dried sausage", "Droge worst"), 1)], products: products, in: context)
    }

    /// Quantities are positive for sales; pass negative quantities together with
    /// `correcting`/`reason` for a credit ticket.
    @discardableResult
    private static func addOrder(
        to session: SaleSession,
        number: Int,
        at date: Date,
        method: PaymentMethod,
        lines: [(String, Int)],
        products: [String: Product],
        in context: ModelContext,
        correcting original: Order? = nil,
        reason: String? = nil
    ) -> Order {
        let isCorrection = lines.contains { $0.1 < 0 }
        let order = Order(
            sequenceNumber: number,
            createdAt: date,
            paymentMethod: method,
            isCorrection: isCorrection,
            correctionReason: reason,
            correctedOrder: original,
            session: session
        )
        context.insert(order)

        var total = Decimal.zero
        for (name, quantity) in lines {
            guard let product = products[name] else { continue }
            let item = OrderItem(
                productName: product.name,
                unitPrice: product.price,
                unitCost: product.costPrice,
                quantity: quantity,
                product: product,
                order: order
            )
            context.insert(item)
            total += product.price * Decimal(quantity)
        }
        if method == .cash {
            let adjustment = CashRounding.adjustment(for: total)
            order.roundingAdjustment = adjustment
            total += adjustment
        }
        order.total = total
        return order
    }
}
#endif
