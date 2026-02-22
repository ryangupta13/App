import SwiftUI
import Charts

struct ComparisonRowView: View {
    let comparison: TickerComparison

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

                        Text("/")
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

            // Ratio Chart with interactive scrubbing
            RatioChartView(
                ratioPoints: comparison.ratioPoints,
                tickerSymbol: comparison.ticker.symbol,
                benchmarkSymbol: comparison.benchmarkTicker.symbol
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

// MARK: - Ratio Chart with Interactive Scrubbing

struct RatioChartView: View {
    let ratioPoints: [RatioPoint]
    let tickerSymbol: String
    let benchmarkSymbol: String

    @State private var scrubIndex: Int?

    private var currentRatio: Double {
        ratioPoints.last?.ratio ?? 0
    }

    private var scrubRatio: Double? {
        guard let idx = scrubIndex, idx < ratioPoints.count else { return nil }
        return ratioPoints[idx].ratio
    }

    private var scrubDate: Date? {
        guard let idx = scrubIndex, idx < ratioPoints.count else { return nil }
        return ratioPoints[idx].date
    }

    var body: some View {
        if ratioPoints.count >= 2 {
            VStack(spacing: 4) {
                // Scrub info overlay
                if let ratio = scrubRatio, let date = scrubDate {
                    HStack {
                        Text(date.formatted(date: .abbreviated, time: .omitted))
                            .font(.system(size: 10, weight: .medium))
                            .foregroundStyle(Theme.textTertiary)
                        Spacer()
                        Text(String(format: "%.4f", ratio))
                            .font(.system(size: 12, weight: .bold, design: .rounded))
                            .foregroundStyle(Theme.accent)
                    }
                }

                ratioChart
            }
        } else {
            RoundedRectangle(cornerRadius: 8)
                .fill(Theme.cardBorder.opacity(0.2))
                .overlay(
                    Text("No data")
                        .font(.system(size: 11))
                        .foregroundStyle(Theme.textTertiary)
                )
        }
    }

    private var ratioChart: some View {
        let isUp = (ratioPoints.last?.ratio ?? 0) >= (ratioPoints.first?.ratio ?? 0)
        let lineColor = isUp ? Theme.positive : Theme.negative

        return Chart {
            ForEach(Array(ratioPoints.enumerated()), id: \.offset) { index, point in
                LineMark(
                    x: .value("Time", index),
                    y: .value("Ratio", point.ratio)
                )
                .foregroundStyle(lineColor)
                .interpolationMethod(.catmullRom)
                .lineStyle(StrokeStyle(lineWidth: 2))
            }

            // Current ratio annotation at rightmost point
            if let last = ratioPoints.last {
                PointMark(
                    x: .value("Time", ratioPoints.count - 1),
                    y: .value("Ratio", last.ratio)
                )
                .foregroundStyle(lineColor)
                .symbolSize(24)
                .annotation(position: .topLeading, spacing: 4) {
                    Text(String(format: "%.4f", last.ratio))
                        .font(.system(size: 10, weight: .bold, design: .rounded))
                        .foregroundStyle(lineColor)
                        .padding(.horizontal, 4)
                        .padding(.vertical, 2)
                        .background(Theme.cardBackground.opacity(0.9))
                        .clipShape(RoundedRectangle(cornerRadius: 4))
                }
            }

            // Scrub line
            if let idx = scrubIndex, idx < ratioPoints.count {
                RuleMark(x: .value("Scrub", idx))
                    .foregroundStyle(Theme.textTertiary.opacity(0.5))
                    .lineStyle(StrokeStyle(lineWidth: 1))

                PointMark(
                    x: .value("Time", idx),
                    y: .value("Ratio", ratioPoints[idx].ratio)
                )
                .foregroundStyle(Theme.accent)
                .symbolSize(36)
            }
        }
        .chartXAxis(.hidden)
        .chartYAxis {
            AxisMarks(position: .trailing) { value in
                AxisValueLabel {
                    if let v = value.as(Double.self) {
                        Text(String(format: "%.3f", v))
                            .font(.system(size: 8, design: .rounded))
                            .foregroundStyle(Theme.textTertiary)
                    }
                }
            }
        }
        .chartLegend(.hidden)
        .chartOverlay { proxy in
            GeometryReader { _ in
                Rectangle()
                    .fill(Color.clear)
                    .contentShape(Rectangle())
                    .gesture(
                        DragGesture(minimumDistance: 0)
                            .onChanged { value in
                                if let idx: Int = proxy.value(atX: value.location.x) {
                                    scrubIndex = max(0, min(idx, ratioPoints.count - 1))
                                }
                            }
                            .onEnded { _ in
                                scrubIndex = nil
                            }
                    )
            }
        }
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
    ZStack {
        Theme.background.ignoresSafeArea()
        Text("Preview")
            .foregroundStyle(.white)
    }
    .preferredColorScheme(.dark)
}
