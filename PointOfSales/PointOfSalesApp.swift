import SwiftUI
import SwiftData

@main
struct PointOfSalesApp: App {
    var body: some Scene {
        WindowGroup {
            RootView()
        }
        .modelContainer(
            for: [
                ProductCategory.self,
                Product.self,
                SaleSession.self,
                Order.self,
                OrderItem.self
            ]
        )
    }
}
