import SwiftUI

struct TickerRowView: View {
    @Environment(StockViewModel.self) var viewModel
    let ticker: Ticker
    @State private var showDetail = false

    var body: some View {
        Button {
            showDetail = true
        } label: {
            VStack(spacing: 8) {
                // Top row: Symbol, sparkline, price
                HStack(spacing: 12) {
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
                    }

                    Spacer(minLength: 4)

                    MiniChartView(
                        data: viewModel.sparkline(for: ticker),
                        isPositive: ticker.isPositive
                    )
                    .frame(width: 56, height: 32)

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

                // Bottom row: customizable metric pills
                HStack(spacing: 6) {
                    ForEach(viewModel.homeMetrics.filter({ $0 != .currentPrice && $0 != .dayChange }), id: \.self) { metric in
                        metricPill(for: metric)
                    }
                    Spacer()
                }
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 12)
            .cardStyle()
        }
        .buttonStyle(.plain)
        .sheet(isPresented: $showDetail) {
            TickerDetailView(ticker: ticker)
                .environment(viewModel)
        }
    }

    @ViewBuilder
    private func metricPill(for metric: TickerMetric) -> some View {
        let (label, value) = metricDisplay(metric)
        MetricPill(label: label, value: value)
    }

    private func metricDisplay(_ metric: TickerMetric) -> (String, String) {
        switch metric {
        case .currentPrice:
            return ("Price", Theme.formatPrice(ticker.currentPrice))
        case .dayChange:
            return ("Chg", "\(Theme.formatPriceSigned(ticker.dayChange)) (\(Theme.formatChange(ticker.dayChangePercent)))")
        case .marketCap:
            return ("MCap", ticker.marketCap > 0 ? Theme.formatMarketCap(ticker.marketCap) : "***")
        case .fiftyTwoWeekRange:
            if ticker.fiftyTwoWeekLow > 0 && ticker.fiftyTwoWeekHigh > 0 {
                return ("52W", "\(Theme.formatPrice(ticker.fiftyTwoWeekLow)) - \(Theme.formatPrice(ticker.fiftyTwoWeekHigh))")
            }
            return ("52W", "***")
        case .volumeVsAverage:
            let vol = Theme.formatVolume(ticker.volume)
            let avg = ticker.averageVolume > 0 ? Theme.formatVolume(ticker.averageVolume) : "***"
            return ("Vol", "\(vol) / \(avg)")
        case .movingAvg50:
            return ("MA50", ticker.movingAverage50 > 0 ? Theme.formatPrice(ticker.movingAverage50) : "***")
        default:
            return (String(metric.rawValue.prefix(6)), "***")
        }
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
        TickerRowView(ticker: Ticker(
            symbol: "AAPL", yahooSymbol: "AAPL", name: "Apple Inc.",
            assetType: .stock, currentPrice: 245.0, previousClose: 242.0,
            dayChangePercent: 1.24, movingAverage50: 238.0, volume: 54_000_000,
            marketCap: 3_800_000_000_000, fiftyTwoWeekHigh: 260.0, fiftyTwoWeekLow: 164.0,
            averageVolume: 48_000_000
        ))
        .environment(StockViewModel())
        .padding()
    }
    .preferredColorScheme(.dark)
}
