import SwiftUI

/// Centralized color palette for the Meal Planner app.
extension Color {
    /// The main app background color (teal)
    static let appBackground = Color(hex: "#17A2B8")
    /// The primary button background color (coral)
    static let buttonBackground = Color(hex: "#FF6F61")
    /// The main text color (white)
    static let mainText = Color.white
    /// The accent/highlight color (warm yellow)
    static let accent = Color(hex: "#FFE066")
}

// MARK: - Hex Color Initializer
extension Color {
    /// Initialize a Color from a hex string (e.g., "#RRGGBB" or "RRGGBB").
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let r, g, b: UInt64
        switch hex.count {
        case 6: // RRGGBB
            (r, g, b) = ((int >> 16) & 0xFF, (int >> 8) & 0xFF, int & 0xFF)
        default:
            (r, g, b) = (1, 1, 0)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: 1
        )
    }
} 