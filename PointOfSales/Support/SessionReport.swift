import Foundation
import SwiftData

/// Everything the bookkeeper needs about one closed (or running) session,
/// computed once from the stored orders. Numbers reconcile as:
/// sum of product-line revenue + cash rounding = gross receipts.
struct SessionReport {
    struct MethodTotal: Identifiable {
        let method: PaymentMethod
        let orderCount: Int
        let total: Decimal

        var id: String { method.rawValue }
    }

    struct ProductLine: Identifiable {
        let categoryName: String
        let productName: String
        let quantity: Int
        let revenue: Decimal
        let cost: Decimal

        var margin: Decimal { revenue - cost }
        var id: String { "\(categoryName)|\(productName)" }
    }

    struct VoidedOrder: Identifiable {
        let id: PersistentIdentifier
        let time: Date
        let total: Decimal
        let reason: String?
    }

    let reportNumber: Int
    let sessionName: String
    let startedAt: Date
    let endedAt: Date?

    let organizationName: String
    let organizationAddress: String
    let enterpriseNumber: String

    let orderCount: Int
    let grossReceipts: Decimal
    let roundingTotal: Decimal
    let methodTotals: [MethodTotal]
    let productLines: [ProductLine]
    let totalCost: Decimal
    let voidedOrders: [VoidedOrder]
    let voidedTotal: Decimal

    /// Gross receipts minus the snapshotted cost of goods sold.
    var netRevenue: Decimal { grossReceipts - totalCost }

    var cashTotal: Decimal {
        methodTotals.filter { !$0.method.isElectronic }.reduce(.zero) { $0 + $1.total }
    }

    var electronicTotal: Decimal {
        methodTotals.filter(\.method.isElectronic).reduce(.zero) { $0 + $1.total }
    }

    init(session: SaleSession, organization: OrganizationSettings?) {
        reportNumber = session.sequenceNumber
        sessionName = session.displayName
        startedAt = session.startedAt
        endedAt = session.endedAt

        organizationName = organization?.name ?? ""
        organizationAddress = organization?.address ?? ""
        enterpriseNumber = organization?.enterpriseNumber ?? ""

        let valid = session.validOrders

        orderCount = valid.count
        grossReceipts = valid.reduce(.zero) { $0 + $1.total }
        roundingTotal = valid.reduce(.zero) { $0 + $1.roundingAdjustment }
        totalCost = valid.reduce(.zero) { $0 + $1.totalCost }

        methodTotals = PaymentMethod.allCases.compactMap { method in
            let orders = valid.filter { $0.paymentMethod == method }
            guard !orders.isEmpty else { return nil }
            return MethodTotal(
                method: method,
                orderCount: orders.count,
                total: orders.reduce(.zero) { $0 + $1.total }
            )
        }

        var lines: [String: ProductLine] = [:]
        for item in valid.flatMap(\.items) {
            let categoryName = item.product?.category?.name ?? "Other"
            let key = "\(categoryName)|\(item.productName)"
            let existing = lines[key]
            lines[key] = ProductLine(
                categoryName: categoryName,
                productName: item.productName,
                quantity: (existing?.quantity ?? 0) + item.quantity,
                revenue: (existing?.revenue ?? .zero) + item.lineTotal,
                cost: (existing?.cost ?? .zero) + item.lineCost
            )
        }
        productLines = lines.values.sorted {
            ($0.categoryName, $0.productName) < ($1.categoryName, $1.productName)
        }

        voidedOrders = session.voidedOrders
            .sorted { $0.createdAt < $1.createdAt }
            .map {
                VoidedOrder(
                    id: $0.persistentModelID,
                    time: $0.createdAt,
                    total: $0.total,
                    reason: $0.voidReason
                )
            }
        voidedTotal = session.voidedTotal
    }
}
