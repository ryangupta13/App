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

                        let change = viewModel.changeForTicker(ticker)
                        HStack(spacing: 3) {
                            Image(systemName: change >= 0 ? "arrow.up.right" : "arrow.down.right")
                                .font(.system(size: 9, weight: .bold))
                            Text(Theme.formatChange(change))
                                .font(.system(size: 12, weight: .semibold, design: .rounded))
                        }
                        .foregroundStyle(Theme.changeColor(for: change))
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3)
                        .background(
                            Capsule()
                                .fill(Theme.changeColor(for: change).opacity(0.15))
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
        let fund = viewModel.fundamentalsCache[ticker.yahooSymbol]

        switch metric {
        case .currentPrice:
            return ("Price", Theme.formatPrice(ticker.currentPrice))
        case .dayChange:
            return ("Chg", "\(Theme.formatPriceSigned(ticker.dayChange)) (\(Theme.formatChange(ticker.dayChangePercent)))")
        case .marketCap:
            let cap = fund?.marketCap ?? ticker.marketCap
            return ("MCap", cap > 0 ? Theme.formatMarketCap(cap) : "***")
        case .fiftyTwoWeekRange:
            let low = fund?.fiftyTwoWeekLow ?? ticker.fiftyTwoWeekLow
            let high = fund?.fiftyTwoWeekHigh ?? ticker.fiftyTwoWeekHigh
            if low > 0 && high > 0 {
                return ("52W", "\(Theme.formatPrice(low)) - \(Theme.formatPrice(high))")
            }
            return ("52W", "***")
        case .volumeVsAverage:
            let vol = Theme.formatVolume(ticker.volume)
            let avgVol = fund?.averageVolume ?? ticker.averageVolume
            let avg = avgVol > 0 ? Theme.formatVolume(avgVol) : "***"
            return ("Vol", "\(vol) / \(avg)")
        case .movingAvg50:
            return ("MA50", ticker.movingAverage50 > 0 ? Theme.formatPrice(ticker.movingAverage50) : "***")
        case .trailingPE:
            if let pe = fund?.trailingPE {
                return ("P/E", String(format: "%.2f", pe))
            }
            return ("P/E", "***")
        case .forwardPE:
            if let pe = fund?.forwardPE {
                return ("Fwd P/E", String(format: "%.2f", pe))
            }
            return ("Fwd P/E", "***")
        case .trailingEPS:
            if let eps = fund?.trailingEPS {
                return ("EPS", String(format: "$%.2f", eps))
            }
            return ("EPS", "***")
        case .revenueTTM:
            if let rev = fund?.revenueTTM, rev > 0 {
                return ("Rev", Theme.formatMarketCap(rev))
            }
            return ("Rev", "***")
        case .revenueGrowthYoY:
            if let growth = fund?.revenueGrowthYoY {
                return ("RevGr", Theme.formatChange(growth))
            }
            return ("RevGr", "***")
        case .netMargin:
            if let margin = fund?.netMargin {
                return ("Margin", String(format: "%.1f%%", margin))
            }
            return ("Margin", "***")
        case .freeCashFlow:
            if let fcf = fund?.freeCashFlow {
                return ("FCF", Theme.formatMarketCap(fcf))
            }
            return ("FCF", "***")
        case .debtToEquity:
            if let de = fund?.debtToEquity {
                return ("D/E", String(format: "%.1f", de))
            }
            return ("D/E", "***")
        case .dividendYield:
            if let dy = fund?.dividendYield {
                return ("Div", String(format: "%.2f%%", dy))
            }
            return ("Div", "***")
        case .beta:
            if let b = fund?.beta {
                return ("Beta", String(format: "%.2f", b))
            }
            return ("Beta", "***")
        case .shortInterest:
            if let si = fund?.shortPercentFloat {
                return ("Short", String(format: "%.1f%%", si))
            }
            return ("Short", "***")
        case .analystRating:
            if let rating = fund?.analystRating, !rating.isEmpty {
                return ("Rating", rating.capitalized)
            }
            return ("Rating", "***")
        case .avgPriceTarget:
            if let target = fund?.averagePriceTarget, target > 0 {
                return ("Target", Theme.formatPrice(target))
            }
            return ("Target", "***")
        case .fiftyTwoWeekChange:
            if let change = fund?.fiftyTwoWeekChange {
                return ("52WΔ", Theme.formatChange(change))
            }
            return ("52WΔ", "***")
        case .evToEBITDA:
            if let ev = fund?.evToEBITDA {
                return ("EV/EB", String(format: "%.1f", ev))
            }
            return ("EV/EB", "***")
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
