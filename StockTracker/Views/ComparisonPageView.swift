import SwiftUI

struct ComparisonPageView: View {
    @Environment(StockViewModel.self) var viewModel
    let timeFrame: TimeFrame

    var body: some View {
        VStack(spacing: 0) {
            // Header
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(timeFrame.fullTitle)
                        .font(.system(size: 28, weight: .bold, design: .rounded))
                        .foregroundStyle(Theme.textPrimary)
                    Spacer()
                    Text("vs \(viewModel.benchmarkTicker?.symbol ?? "—")")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(Theme.benchmark)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(
                            Capsule()
                                .fill(Theme.benchmark.opacity(0.12))
                        )
                }
                Text("Performance compared to top ticker")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(Theme.textTertiary)
            }
            .padding(.horizontal, 20)
            .padding(.top, 4)
            .padding(.bottom, 12)

            if viewModel.tickers.count < 2 {
                needMoreTickers
            } else {
                // Benchmark card
                if let benchmark = viewModel.benchmarkTicker {
                    BenchmarkCardView(ticker: benchmark, timeFrame: timeFrame)
                        .padding(.horizontal, 16)
                        .padding(.bottom, 8)
                }

                // Comparison list
                let comparisons = viewModel.comparisons(for: timeFrame)
                ScrollView {
                    LazyVStack(spacing: 8) {
                        ForEach(comparisons) { comparison in
                            ComparisonRowView(comparison: comparison, timeFrame: timeFrame)
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.bottom, 20)
                }
            }
        }
    }

    private var needMoreTickers: some View {
        VStack(spacing: 16) {
            Spacer()
            Image(systemName: "arrow.triangle.swap")
                .font(.system(size: 44))
                .foregroundStyle(Theme.textTertiary)
            Text("Add at least 2 assets")
                .font(.system(size: 17, weight: .semibold))
                .foregroundStyle(Theme.textSecondary)
            Text("Comparisons show how each asset\nperforms against the top ticker")
                .font(.system(size: 14))
                .foregroundStyle(Theme.textTertiary)
                .multilineTextAlignment(.center)
            Spacer()
        }
    }
}

// MARK: - Benchmark Card

struct BenchmarkCardView: View {
    @Environment(StockViewModel.self) var viewModel
    let ticker: Ticker
    let timeFrame: TimeFrame

    var body: some View {
        HStack(spacing: 14) {
            VStack(alignment: .leading, spacing: 6) {
                HStack(spacing: 8) {
                    Image(systemName: "crown.fill")
                        .font(.system(size: 12))
                        .foregroundStyle(Color.yellow.opacity(0.8))
                    Text("BENCHMARK")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundStyle(Theme.benchmark.opacity(0.8))
                        .tracking(1.2)
                }

                HStack(spacing: 8) {
                    Text(ticker.symbol)
                        .font(.system(size: 20, weight: .bold, design: .rounded))
                        .foregroundStyle(Theme.textPrimary)
                    Text(ticker.name)
                        .font(.system(size: 13, weight: .medium))
                        .foregroundStyle(Theme.textSecondary)
                        .lineLimit(1)
                }

                Text(Theme.formatPrice(ticker.currentPrice))
                    .font(.system(size: 15, weight: .semibold, design: .rounded))
                    .foregroundStyle(Theme.textSecondary)
            }

            Spacer()

            MiniChartView(
                data: viewModel.sparkline(for: ticker),
                isPositive: ticker.isPositive
            )
            .frame(width: 64, height: 36)
        }
        .padding(16)
        .background(Theme.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: Theme.cornerRadius, style: .continuous))
        .glowBorder(color: Theme.benchmark, radius: 10)
    }
}

#Preview {
    ZStack {
        Theme.background.ignoresSafeArea()
        ComparisonPageView(timeFrame: .week)
            .environment(StockViewModel())
    }
    .preferredColorScheme(.dark)
}
