import WidgetKit
import SwiftUI
import AppIntents

// MARK: - Intent

struct WatchlistTimeFrameIntent: AppIntent, WidgetConfigurationIntent {
    static var title: LocalizedStringResource = "Watchlist Widget"
    static var description: IntentDescription = "Shows your watchlist with price changes"

    @Parameter(title: "Time Frame", default: .day)
    var timeFrame: WatchlistTimeFrameOption

    init() {}

    init(timeFrame: WatchlistTimeFrameOption) {
        self.timeFrame = timeFrame
    }

    func perform() async throws -> some IntentResult {
        .result()
    }
}

enum WatchlistTimeFrameOption: String, AppEnum {
    case day = "1D"
    case week = "1W"
    case oneMonth = "1M"
    case threeMonths = "3M"
    case ytd = "YTD"
    case oneYear = "1Y"
    case fiveYears = "5Y"

    static var typeDisplayRepresentation: TypeDisplayRepresentation = "Time Frame"

    static var caseDisplayRepresentations: [WatchlistTimeFrameOption: DisplayRepresentation] = [
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

struct WatchlistEntry: TimelineEntry {
    let date: Date
    let timeFrameLabel: String
    let tickers: [WidgetAPIService.TickerWidgetData]
    let isPlaceholder: Bool

    static var placeholder: WatchlistEntry {
        WatchlistEntry(
            date: .now,
            timeFrameLabel: "1D",
            tickers: [
                .init(symbol: "AAPL", displaySymbol: "AAPL", name: "Apple Inc.", assetType: "stock", currentPrice: 245.00, periodChange: 1.23),
                .init(symbol: "TSLA", displaySymbol: "TSLA", name: "Tesla Inc.", assetType: "stock", currentPrice: 180.50, periodChange: -2.10),
                .init(symbol: "MSFT", displaySymbol: "MSFT", name: "Microsoft Corp.", assetType: "stock", currentPrice: 415.30, periodChange: 0.85),
                .init(symbol: "NVDA", displaySymbol: "NVDA", name: "NVIDIA Corp.", assetType: "stock", currentPrice: 890.20, periodChange: 3.45),
                .init(symbol: "GOOGL", displaySymbol: "GOOGL", name: "Alphabet Inc.", assetType: "stock", currentPrice: 175.60, periodChange: -0.32),
                .init(symbol: "AMZN", displaySymbol: "AMZN", name: "Amazon.com", assetType: "stock", currentPrice: 205.00, periodChange: 1.78),
            ],
            isPlaceholder: true
        )
    }
}

// MARK: - Timeline Provider

struct WatchlistProvider: AppIntentTimelineProvider {
    typealias Entry = WatchlistEntry
    typealias Intent = WatchlistTimeFrameIntent

    func placeholder(in context: Context) -> WatchlistEntry {
        .placeholder
    }

    func snapshot(for configuration: WatchlistTimeFrameIntent, in context: Context) async -> WatchlistEntry {
        if context.isPreview { return .placeholder }
        return await fetchEntry(for: configuration)
    }

    func timeline(for configuration: WatchlistTimeFrameIntent, in context: Context) async -> Timeline<WatchlistEntry> {
        let entry = await fetchEntry(for: configuration)

        // Refresh every 15 minutes during market hours, every hour otherwise
        let calendar = Calendar.current
        let hour = calendar.component(.hour, from: .now)
        let refreshMinutes = (hour >= 9 && hour < 17) ? 15 : 60
        let nextUpdate = calendar.date(byAdding: .minute, value: refreshMinutes, to: .now) ?? .now

        return Timeline(entries: [entry], policy: .after(nextUpdate))
    }

    private func fetchEntry(for configuration: WatchlistTimeFrameIntent) async -> WatchlistEntry {
        let savedTickers = WidgetDataStore.loadTickers()
        guard !savedTickers.isEmpty else {
            return WatchlistEntry(date: .now, timeFrameLabel: configuration.timeFrame.rawValue, tickers: [], isPlaceholder: false)
        }

        let timeFrame = configuration.timeFrame.toWidgetTimeFrame
        let data = await WidgetAPIService.shared.fetchWatchlistData(tickers: savedTickers, timeFrame: timeFrame)

        return WatchlistEntry(
            date: .now,
            timeFrameLabel: configuration.timeFrame.rawValue,
            tickers: data,
            isPlaceholder: false
        )
    }
}

// MARK: - Widget Views

struct WatchlistWidgetView: View {
    @Environment(\.widgetFamily) var family
    let entry: WatchlistEntry

    var maxTickers: Int {
        switch family {
        case .systemSmall: return 1
        case .systemMedium: return 3
        case .systemLarge: return 6
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
        VStack(alignment: .leading, spacing: 6) {
            if let ticker = entry.tickers.first {
                HStack {
                    Text(ticker.displaySymbol)
                        .font(.system(size: 15, weight: .bold, design: .rounded))
                        .foregroundStyle(WidgetTheme.textPrimary)
                    Spacer()
                    Text(entry.timeFrameLabel)
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundStyle(WidgetTheme.accent)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(WidgetTheme.accent.opacity(0.15))
                        .clipShape(Capsule())
                }

                Text(ticker.name)
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(WidgetTheme.textSecondary)
                    .lineLimit(1)

                Spacer()

                Text(WidgetTheme.formatPrice(ticker.currentPrice))
                    .font(.system(size: 22, weight: .bold, design: .rounded))
                    .foregroundStyle(WidgetTheme.textPrimary)
                    .minimumScaleFactor(0.7)

                Text(WidgetTheme.formatChange(ticker.periodChange))
                    .font(.system(size: 14, weight: .bold, design: .rounded))
                    .foregroundStyle(WidgetTheme.changeColor(for: ticker.periodChange))
            } else {
                emptyState
            }
        }
        .padding(2)
    }

    // MARK: - Medium / Large Widget

    private var listView: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text("Watchlist")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundStyle(WidgetTheme.textPrimary)
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

            if entry.tickers.isEmpty {
                Spacer()
                emptyState
                Spacer()
            } else {
                let visibleTickers = Array(entry.tickers.prefix(maxTickers))
                ForEach(Array(visibleTickers.enumerated()), id: \.element.symbol) { index, ticker in
                    watchlistRow(ticker: ticker)
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

    private func watchlistRow(ticker: WidgetAPIService.TickerWidgetData) -> some View {
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

                Text(WidgetTheme.formatChange(ticker.periodChange))
                    .font(.system(size: 11, weight: .bold, design: .rounded))
                    .foregroundStyle(WidgetTheme.changeColor(for: ticker.periodChange))
            }
        }
        .padding(.vertical, family == .systemLarge ? 6 : 5)
    }

    private var emptyState: some View {
        VStack(spacing: 4) {
            Image(systemName: "chart.line.uptrend.xyaxis")
                .font(.system(size: 20))
                .foregroundStyle(WidgetTheme.textTertiary)
            Text("Open app to add tickers")
                .font(.system(size: 11))
                .foregroundStyle(WidgetTheme.textTertiary)
        }
    }
}

// MARK: - Widget Definition

struct WatchlistWidget: Widget {
    let kind = "WatchlistWidget"

    var body: some WidgetConfiguration {
        AppIntentConfiguration(kind: kind, intent: WatchlistTimeFrameIntent.self, provider: WatchlistProvider()) { entry in
            WatchlistWidgetView(entry: entry)
        }
        .configurationDisplayName("Watchlist")
        .description("Track your watchlist with price changes over any timeframe.")
        .supportedFamilies([.systemSmall, .systemMedium, .systemLarge])
    }
}
