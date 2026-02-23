import Foundation

final class StockDataService: @unchecked Sendable {
    static let shared = StockDataService()

    private let api = FinanceAPIService.shared

    // MARK: - Default Tickers (shown on first launch)

    private let defaultSymbols: [(yahoo: String, display: String, name: String, type: Ticker.AssetType)] = [
        ("AAPL", "AAPL", "Apple Inc.", .stock),
        ("GOOGL", "GOOGL", "Alphabet Inc.", .stock),
        ("MSFT", "MSFT", "Microsoft Corp.", .stock),
        ("TSLA", "TSLA", "Tesla Inc.", .stock),
        ("NVDA", "NVDA", "NVIDIA Corp.", .stock),
    ]

    // MARK: - Search (API-backed)

    func searchTickers(query: String) async -> [TickerSearchItem] {
        guard !query.isEmpty else { return [] }
        do {
            let results = try await api.searchSymbols(query: query)
            return results.map { r in
                TickerSearchItem(
                    yahooSymbol: r.symbol,
                    displaySymbol: r.displaySymbol,
                    name: r.name,
                    assetType: r.assetType,
                    exchange: r.exchange
                )
            }
        } catch {
            return []
        }
    }

    // MARK: - Fetch a Full Ticker from Yahoo Symbol

    func fetchTicker(yahooSymbol: String, displaySymbol: String, name: String, assetType: Ticker.AssetType) async -> Ticker? {
        do {
            let quote = try await api.fetchQuote(symbol: yahooSymbol)
            return Ticker(
                symbol: displaySymbol,
                yahooSymbol: yahooSymbol,
                name: quote.name.isEmpty ? name : quote.name,
                assetType: assetType,
                currentPrice: quote.currentPrice,
                previousClose: quote.previousClose,
                dayChangePercent: quote.dayChangePercent,
                movingAverage50: quote.movingAverage50,
                volume: quote.volume,
                marketCap: quote.marketCap,
                fiftyTwoWeekHigh: quote.fiftyTwoWeekHigh,
                fiftyTwoWeekLow: quote.fiftyTwoWeekLow,
                averageVolume: quote.averageVolume
            )
        } catch {
            return nil
        }
    }

    // MARK: - Refresh existing tickers with live data

    func refreshTickers(_ tickers: [Ticker]) async -> [Ticker] {
        let quotes = await api.fetchQuotes(symbols: tickers.map { $0.yahooSymbol })
        return tickers.map { ticker in
            guard let q = quotes[ticker.yahooSymbol] else { return ticker }
            var updated = ticker
            updated.currentPrice = q.currentPrice
            updated.previousClose = q.previousClose
            updated.dayChangePercent = q.dayChangePercent
            updated.movingAverage50 = q.movingAverage50
            updated.volume = q.volume
            if q.marketCap > 0 { updated.marketCap = q.marketCap }
            if q.fiftyTwoWeekHigh > 0 { updated.fiftyTwoWeekHigh = q.fiftyTwoWeekHigh }
            if q.fiftyTwoWeekLow > 0 { updated.fiftyTwoWeekLow = q.fiftyTwoWeekLow }
            if q.averageVolume > 0 { updated.averageVolume = q.averageVolume }
            return updated
        }
    }

    // MARK: - Price History (API)

    func fetchPriceHistory(for ticker: Ticker, timeFrame: TimeFrame) async -> [PricePoint] {
        do {
            var points = try await api.fetchPriceHistory(symbol: ticker.yahooSymbol, timeFrame: timeFrame)

            // For QTD, filter to start of current quarter
            if timeFrame == .qtd {
                let now = Date()
                let calendar = Calendar.current
                let month = calendar.component(.month, from: now)
                let quarterStartMonth = ((month - 1) / 3) * 3 + 1
                var comps = calendar.dateComponents([.year], from: now)
                comps.month = quarterStartMonth
                comps.day = 1
                if let qStart = calendar.date(from: comps) {
                    points = points.filter { $0.date >= qStart }
                }
            }

            return points
        } catch {
            return []
        }
    }

    // MARK: - Sparkline

    func fetchSparkline(for ticker: Ticker) async -> [Double] {
        let history = await fetchPriceHistory(for: ticker, timeFrame: .day)
        guard !history.isEmpty else { return [] }
        return history.map { $0.price }
    }

    // MARK: - Ratio-Based Comparisons

    func generateComparisons(tickers: [Ticker], timeFrame: TimeFrame) async -> [TickerComparison] {
        guard let benchmark = tickers.first else { return [] }

        let benchmarkHistory = await fetchPriceHistory(for: benchmark, timeFrame: timeFrame)
        guard !benchmarkHistory.isEmpty,
              let benchmarkStart = benchmarkHistory.first?.price, benchmarkStart > 0,
              let benchmarkEnd = benchmarkHistory.last?.price else { return [] }

        let benchmarkReturn = ((benchmarkEnd - benchmarkStart) / benchmarkStart) * 100

        var comparisons: [TickerComparison] = []

        for ticker in tickers.dropFirst() {
            let tickerHistory = await fetchPriceHistory(for: ticker, timeFrame: timeFrame)
            guard !tickerHistory.isEmpty,
                  let tickerStart = tickerHistory.first?.price, tickerStart > 0,
                  let tickerEnd = tickerHistory.last?.price else { continue }

            let tickerReturn = ((tickerEnd - tickerStart) / tickerStart) * 100

            // Build ratio points: tickerPrice / benchmarkPrice
            let minCount = min(tickerHistory.count, benchmarkHistory.count)
            var ratioPoints: [RatioPoint] = []
            for i in 0..<minCount {
                let bPrice = benchmarkHistory[i].price
                let tPrice = tickerHistory[i].price
                guard bPrice > 0 else { continue }
                let ratio = tPrice / bPrice
                ratioPoints.append(RatioPoint(index: i, date: tickerHistory[i].date, ratio: ratio))
            }

            comparisons.append(TickerComparison(
                ticker: ticker,
                benchmarkTicker: benchmark,
                tickerReturn: tickerReturn,
                benchmarkReturn: benchmarkReturn,
                ratioPoints: ratioPoints
            ))
        }
        return comparisons
    }

    // MARK: - Fundamentals

    func fetchFundamentals(for ticker: Ticker) async -> FinanceAPIService.FundamentalData? {
        do {
            return try await api.fetchFundamentals(symbol: ticker.yahooSymbol)
        } catch {
            return nil
        }
    }

    // MARK: - Build Default Tickers

    func buildDefaultTickers() async -> [Ticker] {
        var tickers: [Ticker] = []
        for def in defaultSymbols {
            if let t = await fetchTicker(yahooSymbol: def.yahoo, displaySymbol: def.display, name: def.name, assetType: def.type) {
                tickers.append(t)
            }
        }
        return tickers
    }
}

// MARK: - Search Item

struct TickerSearchItem: Identifiable, Sendable {
    let id = UUID()
    let yahooSymbol: String
    let displaySymbol: String
    let name: String
    let assetType: Ticker.AssetType
    let exchange: String
}
