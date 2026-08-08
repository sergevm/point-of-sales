import SwiftUI

/// Sums the heights of the views sharing a list with an empty state that wants
/// to fill it. List rows size to their content, so an empty state can only take
/// the remaining height if it is told how much the rest already occupies.
struct OccupiedListHeightKey: PreferenceKey {
    static var defaultValue: CGFloat = 0

    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value += nextValue()
    }
}

extension View {
    /// Reports this view's height into `OccupiedListHeightKey`. For section
    /// headers and footers, which are not rows.
    func measuringOccupiedHeight() -> some View {
        background {
            GeometryReader { proxy in
                Color.clear.preference(
                    key: OccupiedListHeightKey.self,
                    value: proxy.size.height
                )
            }
        }
    }

    /// Reports this row's height into `OccupiedListHeightKey`, keeping the
    /// standard grouped background. Measuring the row background rather than
    /// the row's content includes the padding the list adds around it.
    func measuredListRowBackground() -> some View {
        listRowBackground(
            Color(.secondarySystemGroupedBackground).measuringOccupiedHeight()
        )
    }
}
