import SwiftUI

struct TickerRowView: View {
    @Environment(StockViewModel.self) var viewModel
    let ticker: Ticker

    var body: some View {
        HStack(spacing: 12) {
            // Left: Symbol + Name + Type badge
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 6) {
                    Text(ticker.symbol)
                        .font(.system(size: 16, weight: .bold, design: .rounded))
                        .foregroundStyle(Theme.textPrimary)

                    Image(systemName: ticker.assetType.icon)
                        .font(.system(size: 9))
                        .foregroundStyle(Theme.textTertiary)
                }

                Text(ticker.name)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(Theme.textSecondary)
                    .lineLimit(1)

                // Metrics row
                HStack(spacing: 8) {
                    MetricPill(label: "MA50", value: Theme.formatPrice(ticker.movingAverage50))
                    MetricPill(label: "Vol", value: Theme.formatVolume(ticker.volume))
                    MetricPill(label: "MCap", value: Theme.formatMarketCap(ticker.marketCap))
                }
            }

            Spacer(minLength: 4)

            // Center: Sparkline
            MiniChartView(
                data: viewModel.sparkline(for: ticker),
                isPositive: ticker.isPositive
            )
            .frame(width: 56, height: 32)

            // Right: Price + Change
            VStack(alignment: .trailing, spacing: 4) {
                Text(Theme.formatPrice(ticker.currentPrice))
                    .font(.system(size: 16, weight: .bold, design: .rounded))
                    .foregroundStyle(Theme.textPrimary)

                HStack(spacing: 3) {
                    Image(systemName: ticker.isPositive ? "arrow.up.right" : "arrow.down.right")
                        .font(.system(size: 9, weight: .bold))
                    Text(Theme.formatChange(ticker.dayChangePercent))
                        .font(.system(size: 12, weight: .semibold, design: .rounded))
                }
                .foregroundStyle(Theme.changeColor(for: ticker.dayChangePercent))
                .padding(.horizontal, 8)
                .padding(.vertical, 3)
                .background(
                    Capsule()
                        .fill(Theme.changeColor(for: ticker.dayChangePercent).opacity(0.15))
                )
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .cardStyle()
    }
}

// MARK: - Metric Pill

struct MetricPill: View {
    let label: String
    let value: String

    var body: some View {
        HStack(spacing: 3) {
            Text(label)
                .font(.system(size: 9, weight: .medium))
                .foregroundStyle(Theme.textTertiary)
            Text(value)
                .font(.system(size: 9, weight: .semibold, design: .rounded))
                .foregroundStyle(Theme.textSecondary)
        }
        .padding(.horizontal, 6)
        .padding(.vertical, 2)
        .background(
            Capsule()
                .fill(Theme.background.opacity(0.6))
        )
    }
}

#Preview {
    ZStack {
        Theme.background.ignoresSafeArea()
        TickerRowView(ticker: StockDataService.shared.defaultTickers()[0])
            .environment(StockViewModel())
            .padding()
    }
    .preferredColorScheme(.dark)
}
