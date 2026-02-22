import SwiftUI

struct ComparisonPageView: View {
    @Environment(StockViewModel.self) var viewModel
    let pageIndex: Int

    var timeFrame: TimeFrame {
        viewModel.pageTimeFrames[pageIndex] ?? .week
    }

    @State private var showTimeFramePicker = false

    var body: some View {
        VStack(spacing: 0) {
            // Header
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(timeFrame.fullTitle)
                        .font(.system(size: 28, weight: .bold, design: .rounded))
                        .foregroundStyle(Theme.textPrimary)
                    Spacer()

                    // Timeframe picker button
                    Button {
                        showTimeFramePicker = true
                    } label: {
                        HStack(spacing: 4) {
                            Text(timeFrame.label)
                                .font(.system(size: 13, weight: .bold))
                            Image(systemName: "chevron.down")
                                .font(.system(size: 10, weight: .bold))
                        }
                        .foregroundStyle(Theme.accent)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(Capsule().fill(Theme.accent.opacity(0.12)))
                    }

                    if let bench = viewModel.benchmarkTicker {
                        Text("vs \(bench.symbol)")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundStyle(Theme.benchmark)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(Capsule().fill(Theme.benchmark.opacity(0.12)))
                    }
                }
                Text("Price ratio vs benchmark (ticker / benchmark)")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(Theme.textTertiary)
            }
            .padding(.horizontal, 20)
            .padding(.top, 4)
            .padding(.bottom, 12)

            if viewModel.tickers.count < 2 {
                needMoreTickers
            } else if viewModel.comparisonLoading[pageIndex] == true {
                Spacer()
                ProgressView()
                    .tint(Theme.textTertiary)
                Spacer()
            } else {
                // Benchmark card
                if let benchmark = viewModel.benchmarkTicker {
                    BenchmarkCardView(ticker: benchmark)
                        .padding(.horizontal, 16)
                        .padding(.bottom, 8)
                }

                // Comparison list
                let comparisons = viewModel.comparisons(for: pageIndex)
                if comparisons.isEmpty {
                    VStack(spacing: 12) {
                        Spacer()
                        Text("Loading comparison data...")
                            .font(.system(size: 14))
                            .foregroundStyle(Theme.textTertiary)
                        Spacer()
                    }
                } else {
                    ScrollView {
                        LazyVStack(spacing: 8) {
                            ForEach(comparisons) { comparison in
                                ComparisonRowView(comparison: comparison)
                            }
                        }
                        .padding(.horizontal, 16)
                        .padding(.bottom, 20)
                    }
                }
            }
        }
        .task {
            await viewModel.loadComparisons(for: pageIndex)
        }
        .onChange(of: viewModel.pageTimeFrames[pageIndex]) { _, _ in
            Task { await viewModel.loadComparisons(for: pageIndex) }
        }
        .sheet(isPresented: $showTimeFramePicker) {
            TimeFramePickerView(
                selectedTimeFrame: timeFrame,
                onSelect: { tf in
                    viewModel.setTimeFrame(tf, for: pageIndex)
                    showTimeFramePicker = false
                }
            )
            .presentationDetents([.medium])
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

// MARK: - Time Frame Picker

struct TimeFramePickerView: View {
    let selectedTimeFrame: TimeFrame
    let onSelect: (TimeFrame) -> Void

    var body: some View {
        NavigationStack {
            ZStack {
                Theme.background.ignoresSafeArea()
                ScrollView {
                    LazyVGrid(columns: [
                        GridItem(.flexible()),
                        GridItem(.flexible()),
                        GridItem(.flexible()),
                    ], spacing: 12) {
                        ForEach(TimeFrame.allCases) { tf in
                            Button {
                                onSelect(tf)
                            } label: {
                                VStack(spacing: 4) {
                                    Text(tf.label)
                                        .font(.system(size: 18, weight: .bold, design: .rounded))
                                    Text(tf.fullTitle)
                                        .font(.system(size: 11, weight: .medium))
                                        .lineLimit(1)
                                }
                                .foregroundStyle(tf == selectedTimeFrame ? Theme.textPrimary : Theme.textSecondary)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 16)
                                .background(tf == selectedTimeFrame ? Theme.accent.opacity(0.2) : Theme.surfaceElevated)
                                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                                        .stroke(tf == selectedTimeFrame ? Theme.accent : Theme.cardBorder, lineWidth: tf == selectedTimeFrame ? 1.5 : 0.5)
                                )
                            }
                        }
                    }
                    .padding(16)
                }
            }
            .navigationTitle("Select Time Frame")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(Theme.background, for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
        }
    }
}

#Preview {
    ZStack {
        Theme.background.ignoresSafeArea()
        ComparisonPageView(pageIndex: 1)
            .environment(StockViewModel())
    }
    .preferredColorScheme(.dark)
}
