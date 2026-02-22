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
