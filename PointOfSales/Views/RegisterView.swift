import SwiftUI
import SwiftData

/// The main register. In a regular-width layout (iPad, large iPhones in
/// landscape) the categories + product grid sit on the left with the ticket
/// panel permanently on the right. In a compact-width layout (iPhone) the grid
/// fills the screen, a bottom bar summarizes the ticket, and the panel opens
/// as a sheet. In both layouts the panel's own paging arrows step back
/// through past orders in place, so there's no separate last-order screen.
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
    @State private var showingCart = false

    /// `nil` shows the live cart; a non-negative index pages the ticket panel
    /// into the session's past orders (0 = most recent). Lifted up from
    /// ``CartPanelView`` so tapping a product while browsing history can jump
    /// back to the live ticket before adding to it.
    @State private var historyIndex: Int?

    private var selectedCategory: ProductCategory? {
        if let id = selectedCategoryID,
           let match = categories.first(where: { $0.persistentModelID == id }) {
            return match
        }
        return categories.first
    }

    var body: some View {
        Group {
            if horizontalSizeClass == .compact {
                compactLayout
            } else {
                regularLayout
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
                Divider()
                nonPayingToggleBar
            }
            .frame(maxWidth: .infinity)

            Divider()

            CartPanelView(
                session: session,
                cart: cart,
                historyIndex: $historyIndex,
                onShowLinkedOrder: onShowOrderInSales
            )
            .frame(width: 340)
        }
    }

    // MARK: - Compact width (iPhone)

    private var compactLayout: some View {
        VStack(spacing: 0) {
            categoryBar
            Divider()
            productGrid
            Divider()
            nonPayingToggleBar
            Divider()
            ticketBar
        }
        .sheet(isPresented: $showingCart, onDismiss: {
            historyIndex = nil
        }) {
            CartPanelView(
                session: session,
                cart: cart,
                historyIndex: $historyIndex,
                onShowLinkedOrder: onShowOrderInSales
            )
            .presentationDetents([.medium, .large])
        }
    }

    /// Bottom summary of the ticket being built; tapping it opens the full
    /// cart sheet.
    private var ticketBar: some View {
        Button {
            showingCart = true
        } label: {
            HStack(spacing: 12) {
                Image(systemName: "cart.fill")
                    .font(.title3)
                    .foregroundStyle(Color.accentColor)
                VStack(alignment: .leading, spacing: 1) {
                    Text("Current ticket")
                        .font(.headline)
                    Text("\(cart.itemCount) items")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                Text(cart.signedTotal.currencyString)
                    .font(.title3.bold().monospacedDigit())
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

    /// Sticky control under the product grid. While on, tapping a product adds
    /// it as a non-paying line — a staff drink, a tasting — still recorded as
    /// a consumption but excluded from the ticket total and, downstream, from
    /// the accountant's revenue figures. Styled to be unmissable when active
    /// so it's never left on by accident.
    private var nonPayingToggleBar: some View {
        Button {
            cart.isAddingNonPaying.toggle()
        } label: {
            Label(
                cart.isAddingNonPaying ? "Adding non-paying items" : "Add as non-paying",
                systemImage: cart.isAddingNonPaying ? "gift.fill" : "gift"
            )
            .font(.subheadline.weight(.semibold))
            .frame(maxWidth: .infinity)
            .padding(.vertical, 10)
        }
        .buttonStyle(.plain)
        .foregroundStyle(cart.isAddingNonPaying ? Color.white : Color.orange)
        .background(cart.isAddingNonPaying ? Color.orange : Color.orange.opacity(0.12))
    }

    private var productGrid: some View {
        ProductGridView(
            category: selectedCategory,
            onSelect: { product in
                // Tapping a product while browsing a past, read-only ticket
                // jumps back to the live one and adds there, rather than
                // requiring a manual page-back first.
                historyIndex = nil
                cart.add(product)
            },
            onOpenConfiguration: onOpenConfiguration
        )
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
