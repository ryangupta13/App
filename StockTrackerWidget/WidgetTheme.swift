import SwiftUI

enum WidgetTheme {
    static let background = Color(red: 0.035, green: 0.035, blue: 0.043)
    static let cardBackground = Color(red: 0.094, green: 0.094, blue: 0.106)
    static let textPrimary = Color.white
    static let textSecondary = Color(red: 0.631, green: 0.631, blue: 0.667)
    static let textTertiary = Color(red: 0.45, green: 0.45, blue: 0.50)
    static let positive = Color(red: 0.133, green: 0.773, blue: 0.369)
    static let negative = Color(red: 0.937, green: 0.267, blue: 0.267)
    static let benchmark = Color(red: 0.231, green: 0.51, blue: 0.965)
    static let accent = Color(red: 0.545, green: 0.361, blue: 0.965)

    static func changeColor(for value: Double) -> Color {
        value >= 0 ? positive : negative
    }

    static func formatPrice(_ price: Double) -> String {
        if price >= 10000 {
            return String(format: "$%.0f", price)
        } else if price >= 1000 {
            return String(format: "$%,.2f", price)
        } else if price >= 1 {
            return String(format: "$%.2f", price)
        } else if price > 0 {
            return String(format: "$%.4f", price)
        } else {
            return "N/A"
        }
    }

    static func formatChange(_ change: Double) -> String {
        let sign = change >= 0 ? "+" : ""
        return String(format: "%@%.2f%%", sign, change)
    }
}
