import SwiftUI

enum Theme {
    // MARK: - Colors
    static let background = Color(red: 0.035, green: 0.035, blue: 0.043)
    static let cardBackground = Color(red: 0.094, green: 0.094, blue: 0.106)
    static let cardBorder = Color(red: 0.153, green: 0.153, blue: 0.165)
    static let surfaceElevated = Color(red: 0.12, green: 0.12, blue: 0.14)

    static let textPrimary = Color.white
    static let textSecondary = Color(red: 0.631, green: 0.631, blue: 0.667)
    static let textTertiary = Color(red: 0.45, green: 0.45, blue: 0.50)

    static let positive = Color(red: 0.133, green: 0.773, blue: 0.369)
    static let negative = Color(red: 0.937, green: 0.267, blue: 0.267)
    static let benchmark = Color(red: 0.231, green: 0.51, blue: 0.965)
    static let accent = Color(red: 0.545, green: 0.361, blue: 0.965)
    static let accentSecondary = Color(red: 0.0, green: 0.737, blue: 0.831)

    // MARK: - Gradients
    static let positiveGradient = LinearGradient(
        colors: [positive.opacity(0.2), positive.opacity(0.0)],
        startPoint: .top,
        endPoint: .bottom
    )

    static let negativeGradient = LinearGradient(
        colors: [negative.opacity(0.2), negative.opacity(0.0)],
        startPoint: .top,
        endPoint: .bottom
    )

    static let benchmarkGradient = LinearGradient(
        colors: [benchmark.opacity(0.15), benchmark.opacity(0.0)],
        startPoint: .top,
        endPoint: .bottom
    )

    static let cardGradient = LinearGradient(
        colors: [cardBackground, cardBackground.opacity(0.8)],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    // MARK: - Corner Radius
    static let cornerRadius: CGFloat = 16
    static let cornerRadiusSmall: CGFloat = 10

    // MARK: - Formatting
    static func formatPrice(_ price: Double) -> String {
        if price >= 10000 {
            return String(format: "$%.0f", price)
        } else if price >= 1000 {
            return String(format: "$%.1f", price)
        } else if price >= 1 {
            return String(format: "$%.2f", price)
        } else {
            return String(format: "$%.4f", price)
        }
    }

    static func formatChange(_ change: Double) -> String {
        let sign = change >= 0 ? "+" : ""
        return String(format: "%@%.2f%%", sign, change)
    }

    static func formatVolume(_ volume: Double) -> String {
        if volume >= 1_000_000_000 {
            return String(format: "%.1fB", volume / 1_000_000_000)
        } else if volume >= 1_000_000 {
            return String(format: "%.1fM", volume / 1_000_000)
        } else if volume >= 1_000 {
            return String(format: "%.1fK", volume / 1_000)
        } else {
            return String(format: "%.0f", volume)
        }
    }

    static func formatMarketCap(_ cap: Double) -> String {
        if cap >= 1_000_000_000_000 {
            return String(format: "$%.2fT", cap / 1_000_000_000_000)
        } else if cap >= 1_000_000_000 {
            return String(format: "$%.1fB", cap / 1_000_000_000)
        } else if cap >= 1_000_000 {
            return String(format: "$%.1fM", cap / 1_000_000)
        } else {
            return String(format: "$%.0f", cap)
        }
    }

    static func changeColor(for value: Double) -> Color {
        value >= 0 ? positive : negative
    }
}

// MARK: - View Extensions
extension View {
    func cardStyle() -> some View {
        self
            .background(Theme.cardBackground)
            .clipShape(RoundedRectangle(cornerRadius: Theme.cornerRadius, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: Theme.cornerRadius, style: .continuous)
                    .stroke(Theme.cardBorder.opacity(0.5), lineWidth: 0.5)
            )
    }

    func glowBorder(color: Color, radius: CGFloat = 8) -> some View {
        self
            .overlay(
                RoundedRectangle(cornerRadius: Theme.cornerRadius, style: .continuous)
                    .stroke(color.opacity(0.6), lineWidth: 1.5)
            )
            .shadow(color: color.opacity(0.2), radius: radius, x: 0, y: 0)
    }
}
