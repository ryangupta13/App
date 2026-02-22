import SwiftUI

struct ComparisonRowView: View {
    let comparison: TickerComparison
    let timeFrame: TimeFrame

    private var isOutperforming: Bool {
        comparison.relativePerformance >= 0
    }

    var body: some View {
        VStack(spacing: 12) {
            // Top row: ticker info + relative performance
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 6) {
                        Text(comparison.ticker.symbol)
                            .font(.system(size: 17, weight: .bold, design: .rounded))
                            .foregroundStyle(Theme.textPrimary)

                        Text("vs")
                            .font(.system(size: 11, weight: .medium))
                            .foregroundStyle(Theme.textTertiary)

                        Text(comparison.benchmarkTicker.symbol)
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundStyle(Theme.benchmark)
                    }

                    Text(comparison.ticker.name)
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(Theme.textSecondary)
                        .lineLimit(1)
                }

                Spacer()

                // Relative performance badge
                VStack(alignment: .trailing, spacing: 4) {
                    HStack(spacing: 4) {
                        Image(systemName: isOutperforming ? "arrow.up.right" : "arrow.down.right")
                            .font(.system(size: 11, weight: .bold))
                        Text(Theme.formatChange(comparison.relativePerformance))
                            .font(.system(size: 16, weight: .bold, design: .rounded))
                    }
                    .foregroundStyle(Theme.changeColor(for: comparison.relativePerformance))

                    Text(isOutperforming ? "Outperforming" : "Underperforming")
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundStyle(Theme.changeColor(for: comparison.relativePerformance).opacity(0.8))
                }
            }

            // Chart
            ComparisonChartView(
                tickerData: comparison.tickerNormalized,
                benchmarkData: comparison.benchmarkNormalized,
                tickerSymbol: comparison.ticker.symbol,
                benchmarkSymbol: comparison.benchmarkTicker.symbol,
                isOutperforming: isOutperforming
            )
            .frame(height: 100)

            // Bottom metrics
            HStack(spacing: 0) {
                ComparisonMetric(
                    label: comparison.ticker.symbol,
                    value: Theme.formatChange(comparison.tickerReturn),
                    color: Theme.changeColor(for: comparison.tickerReturn)
                )

                Divider()
                    .frame(height: 24)
                    .overlay(Theme.cardBorder)

                ComparisonMetric(
                    label: comparison.benchmarkTicker.symbol,
                    value: Theme.formatChange(comparison.benchmarkReturn),
                    color: Theme.changeColor(for: comparison.benchmarkReturn)
                )

                Divider()
                    .frame(height: 24)
                    .overlay(Theme.cardBorder)

                ComparisonMetric(
                    label: "Spread",
                    value: Theme.formatChange(comparison.relativePerformance),
                    color: Theme.changeColor(for: comparison.relativePerformance)
                )
            }
        }
        .padding(16)
        .cardStyle()
    }
}

// MARK: - Comparison Metric

struct ComparisonMetric: View {
    let label: String
    let value: String
    let color: Color

    var body: some View {
        VStack(spacing: 3) {
            Text(label)
                .font(.system(size: 10, weight: .medium))
                .foregroundStyle(Theme.textTertiary)
            Text(value)
                .font(.system(size: 13, weight: .bold, design: .rounded))
                .foregroundStyle(color)
        }
        .frame(maxWidth: .infinity)
    }
}

#Preview {
    let vm = StockViewModel()
    let comparisons = vm.comparisons(for: .week)

    ZStack {
        Theme.background.ignoresSafeArea()
        if let comparison = comparisons.first {
            ComparisonRowView(comparison: comparison, timeFrame: .week)
                .padding()
        }
    }
    .preferredColorScheme(.dark)
}
