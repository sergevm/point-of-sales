import SwiftUI

extension Color {
    /// Builds a colour from a 6-digit hex string like "FF8800". Returns nil for
    /// invalid input so callers can fall back to a default tint.
    init?(hex: String?) {
        guard let hex else { return nil }
        let cleaned = hex.trimmingCharacters(in: CharacterSet(charactersIn: "# ")).uppercased()
        guard cleaned.count == 6, let value = UInt32(cleaned, radix: 16) else { return nil }
        self.init(
            red: Double((value >> 16) & 0xFF) / 255,
            green: Double((value >> 8) & 0xFF) / 255,
            blue: Double(value & 0xFF) / 255
        )
    }
}

/// A small fixed palette offered when creating/editing a category.
enum CategoryPalette {
    /// Hex values shown as swatches in the category editor.
    static let hexes: [String] = [
        "E53935", "FB8C00", "FDD835", "43A047",
        "00ACC1", "1E88E5", "5E35B1", "8E24AA",
        "6D4C41", "546E7A"
    ]
}
