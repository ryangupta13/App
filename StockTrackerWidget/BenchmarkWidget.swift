import WidgetKit
import SwiftUI
import AppIntents

// MARK: - Intent

struct BenchmarkTimeFrameIntent: AppIntent, WidgetConfigurationIntent {
    static var title: LocalizedStringResource = "Benchmark Widget"
    static var description: IntentDescription = "Shows performance vs your benchmark"

    @Parameter(title: "Time Frame", default: .oneMonth)
    var timeFrame: BenchmarkTimeFrameOption

    init() {}

    init(timeFrame: BenchmarkTimeFrameOption) {
        self.timeFrame = timeFrame
    }

    func perform() async throws -> some IntentResult {
        .result()
    }
}

enum BenchmarkTimeFrameOption: String, AppEnum {
    case day = "1D"
    case week = "1W"
    case oneMonth = "1M"
    case threeMonths = "3M"
    case ytd = "YTD"
    case oneYear = "1Y"
    case fiveYears = "5Y"

    static var typeDisplayRepresentation: TypeDisplayRepresentation = "Time Frame"

    static var caseDisplayRepresentations: [BenchmarkTimeFrameOption: DisplayRepresentation] = [
        .day: "1 Day",
        .week: "1 Week",
        .oneMonth: "1 Month",
        .threeMonths: "3 Months",
        .ytd: "Year to Date",
        .oneYear: "1 Year",
        .fiveYears: "5 Years",
    ]

    var toWidgetTimeFrame: WidgetTimeFrame {
        switch self {
        case .day: return .day
        case .week: return .week
        case .oneMonth: return .oneMonth
        case .threeMonths: return .threeMonths
        case .ytd: return .ytd
        case .oneYear: return .oneYear
        case .fiveYears: return .fiveYears
        }
    }
}

// MARK: - Timeline Entry

struct BenchmarkEntry: TimelineEntry {
    let date: Date
    let timeFrameLabel: String
    let benchmarkSymbol: String
    let benchmarkPrice: Double
    let benchmarkChange: Double
    let comparisons: [WidgetAPIService.BenchmarkTickerData]
    let isPlaceholder: Bool

    static var placeholder: BenchmarkEntry {
        BenchmarkEntry(
            date: .now,
            timeFrameLabel: "1M",
            benchmarkSymbol: "AAPL",
            benchmarkPrice: 245.00,
            benchmarkChange: 3.20,
            comparisons: [
                .init(symbol: "TSLA", displaySymbol: "TSLA", name: "Tesla Inc.", assetType: "stock", currentPrice: 180.50, tickerChange: -1.20, benchmarkChange: 3.20, relativeChange: -4.40),
                .init(symbol: "MSFT", displaySymbol: "MSFT", name: "Microsoft Corp.", assetType: "stock", currentPrice: 415.30, tickerChange: 5.00, benchmarkChange: 3.20, relativeChange: 1.80),
                .init(symbol: "NVDA", displaySymbol: "NVDA", name: "NVIDIA Corp.", assetType: "stock", currentPrice: 890.20, tickerChange: 8.40, benchmarkChange: 3.20, relativeChange: 5.20),
                .init(symbol: "GOOGL", displaySymbol: "GOOGL", name: "Alphabet Inc.", assetType: "stock", currentPrice: 175.60, tickerChange: 1.50, benchmarkChange: 3.20, relativeChange: -1.70),
                .init(symbol: "AMZN", displaySymbol: "AMZN", name: "Amazon.com", assetType: "stock", currentPrice: 205.00, tickerChange: 4.80, benchmarkChange: 3.20, relativeChange: 1.60),
            ],
            isPlaceholder: true
        )
    }
}

// MARK: - Timeline Provider

struct BenchmarkProvider: AppIntentTimelineProvider {
    typealias Entry = BenchmarkEntry
    typealias Intent = BenchmarkTimeFrameIntent

    func placeholder(in context: Context) -> BenchmarkEntry {
        .placeholder
    }

    func snapshot(for configuration: BenchmarkTimeFrameIntent, in context: Context) async -> BenchmarkEntry {
        if context.isPreview { return .placeholder }
        return await fetchEntry(for: configuration)
    }

    func timeline(for configuration: BenchmarkTimeFrameIntent, in context: Context) async -> Timeline<BenchmarkEntry> {
        let entry = await fetchEntry(for: configuration)

        let calendar = Calendar.current
        let hour = calendar.component(.hour, from: .now)
        let refreshMinutes = (hour >= 9 && hour < 17) ? 15 : 60
        let nextUpdate = calendar.date(byAdding: .minute, value: refreshMinutes, to: .now) ?? .now

        return Timeline(entries: [entry], policy: .after(nextUpdate))
    }

    private func fetchEntry(for configuration: BenchmarkTimeFrameIntent) async -> BenchmarkEntry {
        let savedTickers = WidgetDataStore.loadTickers()
        guard !savedTickers.isEmpty else {
            return BenchmarkEntry(
                date: .now, timeFrameLabel: configuration.timeFrame.rawValue,
                benchmarkSymbol: "--", benchmarkPrice: 0, benchmarkChange: 0,
                comparisons: [], isPlaceholder: false
            )
        }

        let timeFrame = configuration.timeFrame.toWidgetTimeFrame
        let (benchmark, comparisons) = await WidgetAPIService.shared.fetchBenchmarkData(tickers: savedTickers, timeFrame: timeFrame)

        return BenchmarkEntry(
            date: .now,
            timeFrameLabel: configuration.timeFrame.rawValue,
            benchmarkSymbol: benchmark?.symbol ?? savedTickers[0].symbol,
            benchmarkPrice: benchmark?.currentPrice ?? 0,
            benchmarkChange: benchmark?.periodChange ?? 0,
            comparisons: comparisons,
            isPlaceholder: false
        )
    }
}

// MARK: - Widget Views

struct BenchmarkWidgetView: View {
    @Environment(\.widgetFamily) var family
    let entry: BenchmarkEntry

    var maxTickers: Int {
        switch family {
        case .systemSmall: return 1
        case .systemMedium: return 3
        case .systemLarge: return 5
        default: return 3
        }
    }

    var body: some View {
        Group {
            if family == .systemSmall {
                smallView
            } else {
                listView
            }
        }
        .containerBackground(WidgetTheme.background, for: .widget)
    }

    // MARK: - Small Widget

    private var smallView: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text("vs \(entry.benchmarkSymbol)")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundStyle(WidgetTheme.benchmark)
                Spacer()
                Text(entry.timeFrameLabel)
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(WidgetTheme.accent)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(WidgetTheme.accent.opacity(0.15))
                    .clipShape(Capsule())
            }

            if let ticker = entry.comparisons.first {
                Spacer()

                Text(ticker.displaySymbol)
                    .font(.system(size: 15, weight: .bold, design: .rounded))
                    .foregroundStyle(WidgetTheme.textPrimary)

                Text(ticker.name)
                    .font(.system(size: 10, weight: .medium))
                    .foregroundStyle(WidgetTheme.textSecondary)
                    .lineLimit(1)

                Spacer()

                Text(WidgetTheme.formatPrice(ticker.currentPrice))
                    .font(.system(size: 18, weight: .bold, design: .rounded))
                    .foregroundStyle(WidgetTheme.textPrimary)
                    .minimumScaleFactor(0.7)

                HStack(spacing: 4) {
                    Text("vs \(entry.benchmarkSymbol)")
                        .font(.system(size: 10, weight: .medium))
                        .foregroundStyle(WidgetTheme.textTertiary)
                    Text(WidgetTheme.formatChange(ticker.relativeChange))
                        .font(.system(size: 13, weight: .bold, design: .rounded))
                        .foregroundStyle(WidgetTheme.changeColor(for: ticker.relativeChange))
                }
            } else {
                Spacer()
                emptyState
                Spacer()
            }
        }
        .padding(2)
    }

    // MARK: - Medium / Large Widget

    private var listView: some View {
        VStack(spacing: 0) {
            // Header with benchmark info
            HStack(alignment: .center) {
                HStack(spacing: 6) {
                    Text("vs \(entry.benchmarkSymbol)")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundStyle(WidgetTheme.benchmark)

                    if entry.benchmarkPrice > 0 {
                        Text(WidgetTheme.formatPrice(entry.benchmarkPrice))
                            .font(.system(size: 11, weight: .semibold, design: .rounded))
                            .foregroundStyle(WidgetTheme.textSecondary)
                    }
                }

                Spacer()

                Text(entry.timeFrameLabel)
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(WidgetTheme.accent)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(WidgetTheme.accent.opacity(0.15))
                    .clipShape(Capsule())
            }
            .padding(.bottom, 8)

            if entry.comparisons.isEmpty {
                Spacer()
                emptyState
                Spacer()
            } else {
                let visibleTickers = Array(entry.comparisons.prefix(maxTickers))
                ForEach(Array(visibleTickers.enumerated()), id: \.element.symbol) { index, ticker in
                    benchmarkRow(ticker: ticker)
                    if index < visibleTickers.count - 1 {
                        Divider()
                            .background(WidgetTheme.textTertiary.opacity(0.3))
                    }
                }

                if family == .systemLarge {
                    Spacer(minLength: 0)
                }
            }
        }
        .padding(2)
    }

    private func benchmarkRow(ticker: WidgetAPIService.BenchmarkTickerData) -> some View {
        HStack(spacing: 8) {
            VStack(alignment: .leading, spacing: 2) {
                Text(ticker.displaySymbol)
                    .font(.system(size: 14, weight: .bold, design: .rounded))
                    .foregroundStyle(WidgetTheme.textPrimary)
                Text(ticker.name)
                    .font(.system(size: 10, weight: .medium))
                    .foregroundStyle(WidgetTheme.textSecondary)
                    .lineLimit(1)
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 2) {
                Text(WidgetTheme.formatPrice(ticker.currentPrice))
                    .font(.system(size: 13, weight: .semibold, design: .rounded))
                    .foregroundStyle(WidgetTheme.textPrimary)

                Text(WidgetTheme.formatChange(ticker.relativeChange))
                    .font(.system(size: 11, weight: .bold, design: .rounded))
                    .foregroundStyle(WidgetTheme.changeColor(for: ticker.relativeChange))
            }
        }
        .padding(.vertical, family == .systemLarge ? 6 : 5)
    }

    private var emptyState: some View {
        VStack(spacing: 4) {
            Image(systemName: "chart.bar.xaxis")
                .font(.system(size: 20))
                .foregroundStyle(WidgetTheme.textTertiary)
            Text("Add 2+ tickers to compare")
                .font(.system(size: 11))
                .foregroundStyle(WidgetTheme.textTertiary)
        }
    }
}

// MARK: - Widget Definition

struct BenchmarkWidget: Widget {
    let kind = "BenchmarkWidget"

    var body: some WidgetConfiguration {
        AppIntentConfiguration(kind: kind, intent: BenchmarkTimeFrameIntent.self, provider: BenchmarkProvider()) { entry in
            BenchmarkWidgetView(entry: entry)
        }
        .configurationDisplayName("Benchmark")
        .description("Compare your tickers against your benchmark over any timeframe.")
        .supportedFamilies([.systemSmall, .systemMedium, .systemLarge])
    }
}
