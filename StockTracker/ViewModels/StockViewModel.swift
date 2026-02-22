import SwiftUI
import Observation

@Observable
final class StockViewModel {
    var tickers: [Ticker] = []
    var currentPage: Int = 0
    var showingAddTicker = false
    var searchQuery = ""
    var isEditing = false

    private let service = StockDataService.shared
    private let storageKey = "savedTickers"

    // MARK: - Pages

    var pages: [PageType] {
        var result: [PageType] = [.watchlist]
        result.append(contentsOf: TimeFrame.allCases.map { .comparison($0) })
        return result
    }

    enum PageType: Hashable {
        case watchlist
        case comparison(TimeFrame)

        var title: String {
            switch self {
            case .watchlist: return "Watchlist"
            case .comparison(let tf): return tf.label
            }
        }
    }

    // MARK: - Lifecycle

    init() {
        loadTickers()
    }

    // MARK: - Ticker Management

    func addTicker(_ ticker: Ticker) {
        guard !tickers.contains(where: { $0.symbol == ticker.symbol }) else { return }
        withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
            tickers.append(ticker)
        }
        saveTickers()
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

    var searchResults: [Ticker] {
        let available = service.searchTickers(query: searchQuery)
        let existing = Set(tickers.map { $0.symbol })
        return available.filter { !existing.contains($0.symbol) }
    }

    // MARK: - Benchmark

    var benchmarkTicker: Ticker? {
        tickers.first
    }

    // MARK: - Comparisons

    func comparisons(for timeFrame: TimeFrame) -> [TickerComparison] {
        service.generateComparisons(tickers: tickers, timeFrame: timeFrame)
    }

    // MARK: - Sparkline

    func sparkline(for ticker: Ticker) -> [Double] {
        service.generateSparkline(for: ticker)
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
        } else {
            tickers = service.defaultTickers()
        }
    }
}
