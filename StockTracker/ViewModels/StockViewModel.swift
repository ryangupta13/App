import SwiftUI
import Observation

@Observable
final class StockViewModel {
    var tickers: [Ticker] = []
    var currentPage: Int = 0
    var showingAddTicker = false
    var isEditing = false
    var isLoading = false
    var errorMessage: String?

    // Sparkline cache: symbol -> [Double]
    var sparklines: [String: [Double]] = [:]

    // Comparison data cache: pageIndex -> [TickerComparison]
    var comparisonCache: [Int: [TickerComparison]] = [:]
    var comparisonLoading: [Int: Bool] = [:]

    // Customizable timeframe for each comparison page (4 pages, indices 1-4)
    var pageTimeFrames: [Int: TimeFrame] = [
        1: .week,
        2: .oneMonth,
        3: .ytd,
        4: .fiveYears
    ]

    // Customizable home screen metrics
    var homeMetrics: [TickerMetric] = TickerMetric.defaultHomeMetrics

    // Search (async)
    var searchQuery = ""
    var searchResults: [TickerSearchItem] = []
    var isSearching = false
    var addingSymbol: String?

    // Fundamentals cache
    var fundamentalsCache: [String: FinanceAPIService.FundamentalData] = [:]

    private let service = StockDataService.shared
    private let storageKey = "savedTickers"
    private let metricsKey = "homeMetrics"
    private let timeFramesKey = "pageTimeFrames"

    // MARK: - Pages

    var pages: [PageType] {
        var result: [PageType] = [.watchlist]
        for i in 1...4 {
            let tf = pageTimeFrames[i] ?? TimeFrame.defaultComparisonFrames[i - 1]
            result.append(.comparison(tf, pageIndex: i))
        }
        return result
    }

    enum PageType: Hashable {
        case watchlist
        case comparison(TimeFrame, pageIndex: Int)

        var title: String {
            switch self {
            case .watchlist: return "Watchlist"
            case .comparison(let tf, _): return tf.label
            }
        }

        var pageIndex: Int {
            switch self {
            case .watchlist: return 0
            case .comparison(_, let idx): return idx
            }
        }
    }

    // MARK: - Lifecycle

    init() {
        loadTickers()
        loadMetricPreferences()
        loadTimeFramePreferences()
    }

    // MARK: - Initial Data Load

    func loadInitialData() async {
        await MainActor.run { isLoading = true }

        if tickers.isEmpty {
            // First launch: fetch defaults from API
            let defaults = await service.buildDefaultTickers()
            await MainActor.run {
                tickers = defaults
                saveTickers()
                isLoading = false
            }
        } else {
            // Refresh existing tickers with live data
            await refreshPrices()
        }

        // Load sparklines
        await loadSparklines()
    }

    // MARK: - Refresh Prices

    func refreshPrices() async {
        await MainActor.run { isLoading = true }
        let refreshed = await service.refreshTickers(tickers)
        await MainActor.run {
            tickers = refreshed
            saveTickers()
            isLoading = false
        }
        await loadSparklines()
    }

    // MARK: - Sparklines

    func loadSparklines() async {
        for ticker in tickers {
            let data = await service.fetchSparkline(for: ticker)
            await MainActor.run {
                sparklines[ticker.yahooSymbol] = data
            }
        }
    }

    func sparkline(for ticker: Ticker) -> [Double] {
        sparklines[ticker.yahooSymbol] ?? []
    }

    // MARK: - Ticker Management

    func addTicker(from searchItem: TickerSearchItem) async {
        guard !tickers.contains(where: { $0.yahooSymbol == searchItem.yahooSymbol }) else { return }
        await MainActor.run { addingSymbol = searchItem.yahooSymbol }

        if let ticker = await service.fetchTicker(
            yahooSymbol: searchItem.yahooSymbol,
            displaySymbol: searchItem.displaySymbol,
            name: searchItem.name,
            assetType: searchItem.assetType
        ) {
            await MainActor.run {
                withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                    tickers.append(ticker)
                }
                saveTickers()
                addingSymbol = nil
            }
            // Fetch sparkline for the new ticker
            let data = await service.fetchSparkline(for: ticker)
            await MainActor.run {
                sparklines[ticker.yahooSymbol] = data
            }
        } else {
            await MainActor.run { addingSymbol = nil }
        }
    }

    func removeTicker(at offsets: IndexSet) {
        withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
            tickers.remove(atOffsets: offsets)
        }
        saveTickers()
    }

    func removeTicker(id: UUID) {
        withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
            tickers.removeAll { $0.id == id }
        }
        saveTickers()
    }

    func moveTicker(from source: IndexSet, to destination: Int) {
        tickers.move(fromOffsets: source, toOffset: destination)
        saveTickers()
    }

    // MARK: - Search

    func performSearch(query: String) async {
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            await MainActor.run { searchResults = [] }
            return
        }
        await MainActor.run { isSearching = true }
        let results = await service.searchTickers(query: trimmed)
        let existing = Set(tickers.map { $0.yahooSymbol })
        let filtered = results.filter { !existing.contains($0.yahooSymbol) }
        await MainActor.run {
            searchResults = filtered
            isSearching = false
        }
    }

    // MARK: - Benchmark

    var benchmarkTicker: Ticker? {
        tickers.first
    }

    // MARK: - Comparisons

    func loadComparisons(for pageIndex: Int) async {
        let tf = pageTimeFrames[pageIndex] ?? .week
        await MainActor.run { comparisonLoading[pageIndex] = true }
        let comparisons = await service.generateComparisons(tickers: tickers, timeFrame: tf)
        await MainActor.run {
            comparisonCache[pageIndex] = comparisons
            comparisonLoading[pageIndex] = false
        }
    }

    func comparisons(for pageIndex: Int) -> [TickerComparison] {
        comparisonCache[pageIndex] ?? []
    }

    // MARK: - Customizable Timeframes

    func setTimeFrame(_ tf: TimeFrame, for pageIndex: Int) {
        pageTimeFrames[pageIndex] = tf
        comparisonCache[pageIndex] = nil
        saveTimeFramePreferences()
    }

    // MARK: - Customizable Metrics

    func setHomeMetrics(_ metrics: [TickerMetric]) {
        homeMetrics = metrics
        saveMetricPreferences()
    }

    // MARK: - Fundamentals

    func loadFundamentals(for ticker: Ticker) async -> FinanceAPIService.FundamentalData? {
        if let cached = fundamentalsCache[ticker.yahooSymbol] {
            return cached
        }
        let data = await service.fetchFundamentals(for: ticker)
        if let data = data {
            await MainActor.run {
                fundamentalsCache[ticker.yahooSymbol] = data
            }
        }
        return data
    }

    // MARK: - Persistence

    private func saveTickers() {
        if let data = try? JSONEncoder().encode(tickers) {
            UserDefaults.standard.set(data, forKey: storageKey)
        }
    }

    private func loadTickers() {
        if let data = UserDefaults.standard.data(forKey: storageKey),
           let saved = try? JSONDecoder().decode([Ticker].self, from: data) {
            tickers = saved
        }
    }

    private func saveMetricPreferences() {
        if let data = try? JSONEncoder().encode(homeMetrics) {
            UserDefaults.standard.set(data, forKey: metricsKey)
        }
    }

    private func loadMetricPreferences() {
        if let data = UserDefaults.standard.data(forKey: metricsKey),
           let saved = try? JSONDecoder().decode([TickerMetric].self, from: data) {
            homeMetrics = saved
        }
    }

    private func saveTimeFramePreferences() {
        let raw = pageTimeFrames.mapValues { $0.rawValue }
        UserDefaults.standard.set(raw, forKey: timeFramesKey)
    }

    private func loadTimeFramePreferences() {
        if let raw = UserDefaults.standard.dictionary(forKey: timeFramesKey) as? [String: Int] {
            for (key, value) in raw {
                if let idx = Int(key), let tf = TimeFrame(rawValue: value) {
                    pageTimeFrames[idx] = tf
                }
            }
        }
    }
}
