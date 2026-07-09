import SwiftUI
import SwiftData

/// The main register. In a regular-width layout (iPad, large iPhones in
/// landscape) the categories + product grid sit on the left with the current
/// ticket permanently on the right and the last order in an inspector. In a
/// compact-width layout (iPhone) the grid fills the screen, a bottom bar
/// summarizes the ticket, and both the ticket and the last order open as sheets.
struct RegisterView: View {
    let session: SaleSession
    let cart: Cart

    /// Called to reveal a linked order (an original or its credit) in the
    /// session sales list, for navigating between corrections and their originals.
    var onShowOrderInSales: (Order) -> Void = { _ in }

    /// Called to open the configuration sheet, so empty states can offer the
    /// set-up step directly instead of describing the toolbar icon.
    var onOpenConfiguration: () -> Void = {}

    @Environment(\.horizontalSizeClass) private var horizontalSizeClass

    @Query(sort: \ProductCategory.sortOrder) private var categories: [ProductCategory]
    @State private var selectedCategoryID: PersistentIdentifier?
    @State private var showingLastOrder = false
    @State private var showingCart = false

    /// Compact only: an order was charged from the cart sheet, so the last-order
    /// sheet should be presented once the cart sheet has finished dismissing;
    /// presenting both at once would drop the second sheet.
    @State private var showLastOrderAfterCart = false

    /// Compact only: linked order to reveal in the sales list once the
    /// last-order sheet has finished dismissing, for the same reason.
    @State private var pendingLinkedOrder: Order?

    private var selectedCategory: ProductCategory? {
        if let id = selectedCategoryID,
           let match = categories.first(where: { $0.persistentModelID == id }) {
            return match
        }
        return categories.first
    }

    /// The most recently charged order in this session, shown in the
    /// inspector (regular) or the last-order sheet (compact).
    private var lastOrder: Order? { session.ordersByNewest.first }

    var body: some View {
        Group {
            if horizontalSizeClass == .compact {
                compactLayout
            } else {
                regularLayout
            }
        }
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    showingLastOrder.toggle()
                } label: {
                    Label("Last order", systemImage: "checklist")
                }
                .disabled(lastOrder == nil)
            }
        }
    }

    // MARK: - Regular width (iPad)

    private var regularLayout: some View {
        HStack(spacing: 0) {
            VStack(spacing: 0) {
                categoryBar
                Divider()
                productGrid
            }
            .frame(maxWidth: .infinity)

            Divider()

            CartPanelView(session: session, cart: cart) {
                showingLastOrder = true
            }
            .frame(width: 340)
        }
        .inspector(isPresented: $showingLastOrder) {
            lastOrderContent { order in
                onShowOrderInSales(order)
            }
            .inspectorColumnWidth(min: 280, ideal: 320, max: 420)
        }
    }

    // MARK: - Compact width (iPhone)

    private var compactLayout: some View {
        VStack(spacing: 0) {
            categoryBar
            Divider()
            productGrid
            Divider()
            ticketBar
        }
        .sheet(isPresented: $showingCart, onDismiss: {
            if showLastOrderAfterCart {
                showLastOrderAfterCart = false
                showingLastOrder = true
            }
        }) {
            CartPanelView(session: session, cart: cart) {
                showLastOrderAfterCart = true
                showingCart = false
            }
        }
        .sheet(isPresented: $showingLastOrder, onDismiss: {
            if let order = pendingLinkedOrder {
                pendingLinkedOrder = nil
                onShowOrderInSales(order)
            }
        }) {
            lastOrderContent { order in
                pendingLinkedOrder = order
                showingLastOrder = false
            }
            .presentationDetents([.medium, .large])
        }
    }

    /// Bottom summary of the ticket being built; tapping it opens the full
    /// cart sheet (also when empty, to switch between sale and credit).
    private var ticketBar: some View {
        Button {
            showingCart = true
        } label: {
            HStack(spacing: 12) {
                Image(systemName: cart.isCorrection ? "arrow.uturn.backward.circle" : "cart.fill")
                    .font(.title3)
                    .foregroundStyle(cart.isCorrection ? Color.red : Color.accentColor)
                VStack(alignment: .leading, spacing: 1) {
                    Text(cart.isCorrection ? "Credit ticket" : "Current ticket")
                        .font(.headline)
                        .foregroundStyle(cart.isCorrection ? .red : .primary)
                    Text("\(cart.itemCount) items")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                Text(cart.signedTotal.currencyString)
                    .font(.title3.bold().monospacedDigit())
                    .foregroundStyle(cart.isCorrection ? .red : .primary)
                Image(systemName: "chevron.up")
                    .font(.footnote.bold())
                    .foregroundStyle(.secondary)
            }
            .padding()
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .background(.background)
        .accessibilityElement(children: .combine)
        .accessibilityAddTraits(.isButton)
    }

    // MARK: - Shared pieces

    private var productGrid: some View {
        ProductGridView(
            category: selectedCategory,
            onSelect: { product in
                cart.add(product)
                showingLastOrder = false
            },
            onOpenConfiguration: onOpenConfiguration
        )
    }

    private func lastOrderContent(onShowLinkedOrder: @escaping (Order) -> Void) -> some View {
        Group {
            if let order = lastOrder {
                LastOrderPanelView(order: order, onShowLinkedOrder: onShowLinkedOrder)
            } else {
                ContentUnavailableView(
                    "No orders yet",
                    systemImage: "checklist",
                    description: Text("Charged orders appear here so you can serve them.")
                )
            }
        }
    }

    private var categoryBar: some View {
        Group {
            if categories.isEmpty {
                // Outside the FlowLayout, which sizes children to their ideal
                // width for chip layout and would keep this on a single line.
                Text("No categories yet — add some in Configure.")
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
            } else {
                categoryChips
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .padding(12)
    }

    private var categoryChips: some View {
        FlowLayout(spacing: 12) {
            ForEach(categories) { category in
                let color = Color(hex: category.colorHex) ?? .accentColor
                let isSelected = category.persistentModelID == selectedCategory?.persistentModelID
                Button {
                    selectedCategoryID = category.persistentModelID
                    showingLastOrder = false
                } label: {
                    Text(category.name)
                        .font(.headline)
                        .padding(.horizontal, 18)
                        .padding(.vertical, 12)
                        .background(color.opacity(isSelected ? 1 : 0.18))
                        .foregroundStyle(isSelected ? .white : .primary)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                }
                .buttonStyle(.depth(color.opacity(isSelected ? 0.45 : 0.15)))
                .accessibilityLabel(Text(category.name))
                .accessibilityAddTraits(isSelected ? .isSelected : [])
            }
        }
    }
}
