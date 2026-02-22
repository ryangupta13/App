import SwiftUI
import Charts

// MARK: - Sparkline for ticker rows

struct MiniChartView: View {
    let data: [Double]
    let isPositive: Bool

    var body: some View {
        if data.count >= 2 {
            Chart {
                ForEach(Array(data.enumerated()), id: \.offset) { index, value in
                    LineMark(
                        x: .value("Time", index),
                        y: .value("Price", value)
                    )
                    .foregroundStyle(isPositive ? Theme.positive : Theme.negative)
                    .interpolationMethod(.catmullRom)

                    AreaMark(
                        x: .value("Time", index),
                        y: .value("Price", value)
                    )
                    .foregroundStyle(
                        .linearGradient(
                            colors: [
                                (isPositive ? Theme.positive : Theme.negative).opacity(0.3),
                                (isPositive ? Theme.positive : Theme.negative).opacity(0.0)
                            ],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .interpolationMethod(.catmullRom)
                }
            }
            .chartXAxis(.hidden)
            .chartYAxis(.hidden)
            .chartLegend(.hidden)
            .chartYScale(domain: (data.min()! * 0.998)...(data.max()! * 1.002))
        } else {
            Rectangle()
                .fill(Theme.cardBorder.opacity(0.3))
        }
    }
}

// MARK: - Comparison Chart

struct ComparisonChartView: View {
    let tickerData: [NormalizedPoint]
    let benchmarkData: [NormalizedPoint]
    let tickerSymbol: String
    let benchmarkSymbol: String
    let isOutperforming: Bool

    var body: some View {
        if tickerData.count >= 2 && benchmarkData.count >= 2 {
            Chart {
                // Benchmark line
                ForEach(benchmarkData) { point in
                    LineMark(
                        x: .value("Time", point.index),
                        y: .value("Return", point.value),
                        series: .value("Series", benchmarkSymbol)
                    )
                    .foregroundStyle(Theme.benchmark.opacity(0.5))
                    .interpolationMethod(.catmullRom)
                    .lineStyle(StrokeStyle(lineWidth: 1.5, dash: [4, 3]))
                }

                // Ticker line
                ForEach(tickerData) { point in
                    LineMark(
                        x: .value("Time", point.index),
                        y: .value("Return", point.value),
                        series: .value("Series", tickerSymbol)
                    )
                    .foregroundStyle(isOutperforming ? Theme.positive : Theme.negative)
                    .interpolationMethod(.catmullRom)
                    .lineStyle(StrokeStyle(lineWidth: 2))
                }

                // Zero line
                RuleMark(y: .value("Zero", 0))
                    .foregroundStyle(Theme.textTertiary.opacity(0.3))
                    .lineStyle(StrokeStyle(lineWidth: 0.5))
            }
            .chartXAxis(.hidden)
            .chartYAxis {
                AxisMarks(position: .trailing) { value in
                    AxisValueLabel {
                        if let v = value.as(Double.self) {
                            Text(String(format: "%.0f%%", v))
                                .font(.system(size: 8, design: .rounded))
                                .foregroundStyle(Theme.textTertiary)
                        }
                    }
                }
            }
            .chartLegend(.hidden)
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
}

#Preview {
    ZStack {
        Theme.background.ignoresSafeArea()
        VStack {
            MiniChartView(data: [100, 102, 101, 104, 103, 107, 105, 108], isPositive: true)
                .frame(width: 60, height: 30)
            MiniChartView(data: [108, 105, 107, 103, 104, 101, 102, 100], isPositive: false)
                .frame(width: 60, height: 30)
        }
    }
    .preferredColorScheme(.dark)
}
