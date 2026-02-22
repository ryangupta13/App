import SwiftUI
import Charts

struct TickerDetailView: View {
    @Environment(StockViewModel.self) var viewModel
    @Environment(\.dismiss) var dismiss
    let ticker: Ticker

    @State private var fundamentals: FinanceAPIService.FundamentalData?
    @State private var isLoadingFundamentals = true
    @State private var selectedTimeFrame: TimeFrame = .oneMonth
    @State private var priceHistory: [PricePoint] = []
    @State private var isLoadingChart = true
    @State private var scrubIndex: Int?

    private let service = StockDataService.shared

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    priceHeader
                    chartSection
                    metricsSection
                    fundamentalsSection
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 30)
            }
            .background(Theme.background.ignoresSafeArea())
            .navigationTitle(ticker.symbol)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(Theme.accent)
                }
            }
            .toolbarBackground(Theme.background, for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .task {
                await loadData()
            }
        }
    }

    // MARK: - Price Header

    private var priceHeader: some View {
        VStack(spacing: 8) {
            HStack(spacing: 10) {
                ZStack {
                    Circle()
                        .fill(typeColor.opacity(0.15))
                        .frame(width: 44, height: 44)
                    Image(systemName: ticker.assetType.icon)
                        .font(.system(size: 18, weight: .medium))
                        .foregroundStyle(typeColor)
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text(ticker.name)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(Theme.textPrimary)
                        .lineLimit(1)
                    Text("\(ticker.assetType.rawValue)")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(Theme.textTertiary)
                }

                Spacer()
            }

            HStack(alignment: .firstTextBaseline, spacing: 12) {
                Text(Theme.formatPrice(ticker.currentPrice))
                    .font(.system(size: 32, weight: .bold, design: .rounded))
                    .foregroundStyle(Theme.textPrimary)

                HStack(spacing: 4) {
                    Image(systemName: ticker.isPositive ? "arrow.up.right" : "arrow.down.right")
                        .font(.system(size: 12, weight: .bold))
                    Text("\(Theme.formatPriceSigned(ticker.dayChange)) (\(Theme.formatChange(ticker.dayChangePercent)))")
                        .font(.system(size: 14, weight: .semibold, design: .rounded))
                }
                .foregroundStyle(Theme.changeColor(for: ticker.dayChangePercent))

                Spacer()
            }
        }
        .padding(16)
        .cardStyle()
    }

    // MARK: - Chart

    private var chartSection: some View {
        VStack(spacing: 12) {
            // Time frame selector
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 6) {
                    ForEach(TimeFrame.allCases) { tf in
                        Button {
                            selectedTimeFrame = tf
                            Task { await loadChart() }
                        } label: {
                            Text(tf.label)
                                .font(.system(size: 12, weight: selectedTimeFrame == tf ? .bold : .medium))
                                .foregroundStyle(selectedTimeFrame == tf ? Theme.textPrimary : Theme.textTertiary)
                                .padding(.horizontal, 10)
                                .padding(.vertical, 6)
                                .background(
                                    Capsule().fill(selectedTimeFrame == tf ? Theme.surfaceElevated : Color.clear)
                                )
                        }
                    }
                }
            }

            // Chart
            if isLoadingChart {
                ProgressView()
                    .tint(Theme.textTertiary)
                    .frame(height: 200)
                    .frame(maxWidth: .infinity)
            } else if priceHistory.count >= 2 {
                detailChart
                    .frame(height: 200)
            } else {
                RoundedRectangle(cornerRadius: 8)
                    .fill(Theme.cardBorder.opacity(0.2))
                    .frame(height: 200)
                    .overlay(
                        Text("No chart data available")
                            .font(.system(size: 13))
                            .foregroundStyle(Theme.textTertiary)
                    )
            }

            // Scrub info
            if let idx = scrubIndex, idx < priceHistory.count {
                let point = priceHistory[idx]
                HStack {
                    Text(point.date.formatted(date: .abbreviated, time: selectedTimeFrame == .day ? .shortened : .omitted))
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(Theme.textTertiary)
                    Spacer()
                    Text(Theme.formatPrice(point.price))
                        .font(.system(size: 14, weight: .bold, design: .rounded))
                        .foregroundStyle(Theme.textPrimary)
                }
            }
        }
        .padding(16)
        .cardStyle()
    }

    private var detailChart: some View {
        let isUp = (priceHistory.last?.price ?? 0) >= (priceHistory.first?.price ?? 0)
        let color = isUp ? Theme.positive : Theme.negative

        return Chart {
            ForEach(Array(priceHistory.enumerated()), id: \.offset) { index, point in
                LineMark(
                    x: .value("Time", index),
                    y: .value("Price", point.price)
                )
                .foregroundStyle(color)
                .interpolationMethod(.catmullRom)

                AreaMark(
                    x: .value("Time", index),
                    y: .value("Price", point.price)
                )
                .foregroundStyle(
                    .linearGradient(
                        colors: [color.opacity(0.2), color.opacity(0.0)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .interpolationMethod(.catmullRom)
            }

            if let idx = scrubIndex, idx < priceHistory.count {
                RuleMark(x: .value("Scrub", idx))
                    .foregroundStyle(Theme.textTertiary.opacity(0.5))
                    .lineStyle(StrokeStyle(lineWidth: 1))
            }
        }
        .chartXAxis(.hidden)
        .chartYAxis {
            AxisMarks(position: .trailing) { value in
                AxisValueLabel {
                    if let v = value.as(Double.self) {
                        Text(Theme.formatPrice(v))
                            .font(.system(size: 8, design: .rounded))
                            .foregroundStyle(Theme.textTertiary)
                    }
                }
            }
        }
        .chartLegend(.hidden)
        .chartOverlay { proxy in
            GeometryReader { geo in
                Rectangle()
                    .fill(Color.clear)
                    .contentShape(Rectangle())
                    .gesture(
                        DragGesture(minimumDistance: 0)
                            .onChanged { value in
                                let x = value.location.x
                                if let idx: Int = proxy.value(atX: x) {
                                    scrubIndex = max(0, min(idx, priceHistory.count - 1))
                                }
                            }
                            .onEnded { _ in
                                scrubIndex = nil
                            }
                    )
            }
        }
    }

    // MARK: - Basic Metrics

    private var metricsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Key Metrics")
                .font(.system(size: 16, weight: .bold))
                .foregroundStyle(Theme.textPrimary)

            LazyVGrid(columns: [
                GridItem(.flexible(), spacing: 12),
                GridItem(.flexible(), spacing: 12)
            ], spacing: 10) {
                metricCell("Market Cap", ticker.marketCap > 0 ? Theme.formatMarketCap(ticker.marketCap) : "***")
                metricCell("52W High", ticker.fiftyTwoWeekHigh > 0 ? Theme.formatPrice(ticker.fiftyTwoWeekHigh) : "***")
                metricCell("52W Low", ticker.fiftyTwoWeekLow > 0 ? Theme.formatPrice(ticker.fiftyTwoWeekLow) : "***")
                metricCell("Volume", ticker.volume > 0 ? Theme.formatVolume(ticker.volume) : "***")
                metricCell("Avg Volume", ticker.averageVolume > 0 ? Theme.formatVolume(ticker.averageVolume) : "***")
                metricCell("50-Day MA", ticker.movingAverage50 > 0 ? Theme.formatPrice(ticker.movingAverage50) : "***")
            }
        }
        .padding(16)
        .cardStyle()
    }

    // MARK: - Fundamentals

    private var fundamentalsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Fundamentals")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundStyle(Theme.textPrimary)
                Spacer()
                if isLoadingFundamentals {
                    ProgressView().tint(Theme.textTertiary).scaleEffect(0.7)
                }
            }

            if let f = fundamentals {
                LazyVGrid(columns: [
                    GridItem(.flexible(), spacing: 12),
                    GridItem(.flexible(), spacing: 12)
                ], spacing: 10) {
                    metricCell("P/E (Trailing)", formatOptional(f.trailingPE, format: "%.2f"))
                    metricCell("Forward P/E", formatOptional(f.forwardPE, format: "%.2f"))
                    metricCell("EPS (Trailing)", formatOptionalPrice(f.trailingEPS))
                    metricCell("Revenue (TTM)", formatOptionalLarge(f.revenueTTM))
                    metricCell("Rev Growth (YoY)", formatOptionalPercent(f.revenueGrowthYoY))
                    metricCell("Net Margin", formatOptionalPercent(f.netMargin))
                    metricCell("Free Cash Flow", formatOptionalLarge(f.freeCashFlow))
                    metricCell("Debt/Equity", formatOptional(f.debtToEquity, format: "%.2f"))
                    metricCell("Dividend Yield", formatOptionalPercent(f.dividendYield))
                    metricCell("Beta", formatOptional(f.beta, format: "%.2f"))
                    metricCell("Short Interest", formatOptionalPercent(f.shortPercentFloat))
                    metricCell("Analyst Rating", f.analystRating?.capitalized ?? "***")
                    metricCell("Avg Target", formatOptionalPrice(f.averagePriceTarget))
                    metricCell("52W Change", formatOptionalPercent(f.fiftyTwoWeekChange))
                    metricCell("EV/EBITDA", formatOptional(f.evToEBITDA, format: "%.2f"))
                    if let mc = f.marketCap, mc > 0 {
                        metricCell("Market Cap", Theme.formatMarketCap(mc))
                    }
                }
            } else if !isLoadingFundamentals {
                Text("Fundamental data not available for this asset")
                    .font(.system(size: 13))
                    .foregroundStyle(Theme.textTertiary)
            }
        }
        .padding(16)
        .cardStyle()
    }

    // MARK: - Helpers

    private func metricCell(_ label: String, _ value: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label)
                .font(.system(size: 10, weight: .medium))
                .foregroundStyle(Theme.textTertiary)
            Text(value)
                .font(.system(size: 14, weight: .semibold, design: .rounded))
                .foregroundStyle(value == "***" ? Theme.textTertiary : Theme.textPrimary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(10)
        .background(Theme.surfaceElevated.opacity(0.5))
        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
    }

    private func formatOptional(_ val: Double?, format: String) -> String {
        guard let v = val else { return "***" }
        return String(format: format, v)
    }

    private func formatOptionalPrice(_ val: Double?) -> String {
        guard let v = val else { return "***" }
        return Theme.formatPrice(v)
    }

    private func formatOptionalPercent(_ val: Double?) -> String {
        guard let v = val else { return "***" }
        return String(format: "%.2f%%", v)
    }

    private func formatOptionalLarge(_ val: Double?) -> String {
        guard let v = val else { return "***" }
        return Theme.formatMarketCap(v)
    }

    private var typeColor: Color {
        switch ticker.assetType {
        case .stock: return Theme.benchmark
        case .crypto: return Color.orange
        case .etf: return Theme.accentSecondary
        case .commodity: return Color.yellow
        }
    }

    private func loadData() async {
        async let chartTask: () = loadChart()
        async let fundTask: () = loadFundamentals()
        _ = await (chartTask, fundTask)
    }

    private func loadChart() async {
        await MainActor.run { isLoadingChart = true }
        let history = await service.fetchPriceHistory(for: ticker, timeFrame: selectedTimeFrame)
        await MainActor.run {
            priceHistory = history
            isLoadingChart = false
        }
    }

    private func loadFundamentals() async {
        await MainActor.run { isLoadingFundamentals = true }
        let data = await viewModel.loadFundamentals(for: ticker)
        await MainActor.run {
            fundamentals = data
            isLoadingFundamentals = false
        }
    }
}

#Preview {
    TickerDetailView(ticker: Ticker(
        symbol: "AAPL", yahooSymbol: "AAPL", name: "Apple Inc.",
        assetType: .stock, currentPrice: 245.0, previousClose: 242.0,
        dayChangePercent: 1.24, movingAverage50: 238.0, volume: 54_000_000,
        marketCap: 3_800_000_000_000, fiftyTwoWeekHigh: 260.0, fiftyTwoWeekLow: 164.0,
        averageVolume: 48_000_000
    ))
    .environment(StockViewModel())
    .preferredColorScheme(.dark)
}
