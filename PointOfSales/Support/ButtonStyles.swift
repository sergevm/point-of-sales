import SwiftUI

/// Gives flat, self-tinted tile buttons (product tiles, category chips) physical
/// depth: a soft drop shadow that lifts the surface off the page plus a tactile
/// press animation — the tile dips down and its shadow collapses on touch.
///
/// The button's own `label` supplies the shape and fill; this style only adds
/// the shadow and press feedback, so it's a drop-in replacement for `.plain`.
struct DepthButtonStyle: ButtonStyle {
    /// Tint the shadow to match the tile for a richer, less muddy look.
    var shadowColor: Color = .black.opacity(0.28)

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.96 : 1)
            .shadow(
                color: shadowColor,
                radius: configuration.isPressed ? 2 : 7,
                x: 0,
                y: configuration.isPressed ? 1 : 4
            )
            .animation(.spring(response: 0.3, dampingFraction: 0.6),
                       value: configuration.isPressed)
    }
}

extension ButtonStyle where Self == DepthButtonStyle {
    /// Depth style with a neutral shadow.
    static var depth: DepthButtonStyle { DepthButtonStyle() }

    /// Depth style whose shadow is tinted to match the tile colour.
    static func depth(_ shadowColor: Color) -> DepthButtonStyle {
        DepthButtonStyle(shadowColor: shadowColor)
    }
}

/// A filled, prominent action button (Charge, Start session) with a subtle
/// top-to-bottom gradient, a coloured drop shadow, and the same tactile press
/// animation as ``DepthButtonStyle``. Dims when disabled.
struct ProminentDepthButtonStyle: ButtonStyle {
    var tint: Color = .accentColor
    var cornerRadius: CGFloat = 14

    func makeBody(configuration: Configuration) -> some View {
        StyleBody(configuration: configuration, tint: tint, cornerRadius: cornerRadius)
    }

    struct StyleBody: View {
        let configuration: ButtonStyleConfiguration
        let tint: Color
        let cornerRadius: CGFloat
        @Environment(\.isEnabled) private var isEnabled

        var body: some View {
            configuration.label
                .foregroundStyle(.white)
                .background(
                    LinearGradient(
                        colors: [tint, tint.opacity(0.82)],
                        startPoint: .top,
                        endPoint: .bottom
                    ),
                    in: RoundedRectangle(cornerRadius: cornerRadius)
                )
                .opacity(isEnabled ? 1 : 0.5)
                .scaleEffect(configuration.isPressed ? 0.97 : 1)
                .shadow(
                    color: tint.opacity(isEnabled ? 0.45 : 0),
                    radius: configuration.isPressed ? 3 : 9,
                    x: 0,
                    y: configuration.isPressed ? 1 : 5
                )
                .animation(.spring(response: 0.3, dampingFraction: 0.6),
                           value: configuration.isPressed)
        }
    }
}

extension ButtonStyle where Self == ProminentDepthButtonStyle {
    static var prominentDepth: ProminentDepthButtonStyle { ProminentDepthButtonStyle() }

    static func prominentDepth(tint: Color) -> ProminentDepthButtonStyle {
        ProminentDepthButtonStyle(tint: tint)
    }
}
