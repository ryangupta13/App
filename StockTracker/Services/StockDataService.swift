import Foundation

final class StockDataService {
    static let shared = StockDataService()

    // MARK: - Available Tickers Catalog

    private let tickerCatalog: [Ticker] = [
        Ticker(id: UUID(uuidString: "00000000-0000-0000-0000-000000000001")!,
               symbol: "AAPL", name: "Apple Inc.", assetType: .stock,
               currentPrice: 189.84, previousClose: 187.12, dayChangePercent: 1.45,
               movingAverage50: 182.35, volume: 54_230_000, marketCap: 2_950_000_000_000),
        Ticker(id: UUID(uuidString: "00000000-0000-0000-0000-000000000002")!,
               symbol: "GOOGL", name: "Alphabet Inc.", assetType: .stock,
               currentPrice: 141.80, previousClose: 140.25, dayChangePercent: 1.11,
               movingAverage50: 138.90, volume: 22_150_000, marketCap: 1_780_000_000_000),
        Ticker(id: UUID(uuidString: "00000000-0000-0000-0000-000000000003")!,
               symbol: "MSFT", name: "Microsoft Corp.", assetType: .stock,
               currentPrice: 378.91, previousClose: 375.50, dayChangePercent: 0.91,
               movingAverage50: 370.20, volume: 19_870_000, marketCap: 2_810_000_000_000),
        Ticker(id: UUID(uuidString: "00000000-0000-0000-0000-000000000004")!,
               symbol: "TSLA", name: "Tesla Inc.", assetType: .stock,
               currentPrice: 248.42, previousClose: 253.18, dayChangePercent: -1.88,
               movingAverage50: 240.60, volume: 98_450_000, marketCap: 789_000_000_000),
        Ticker(id: UUID(uuidString: "00000000-0000-0000-0000-000000000005")!,
               symbol: "NVDA", name: "NVIDIA Corp.", assetType: .stock,
               currentPrice: 495.22, previousClose: 488.90, dayChangePercent: 1.29,
               movingAverage50: 475.80, volume: 41_320_000, marketCap: 1_220_000_000_000),
        Ticker(id: UUID(uuidString: "00000000-0000-0000-0000-000000000006")!,
               symbol: "AMZN", name: "Amazon.com Inc.", assetType: .stock,
               currentPrice: 153.42, previousClose: 151.94, dayChangePercent: 0.97,
               movingAverage50: 148.65, volume: 45_670_000, marketCap: 1_590_000_000_000),
        Ticker(id: UUID(uuidString: "00000000-0000-0000-0000-000000000007")!,
               symbol: "META", name: "Meta Platforms", assetType: .stock,
               currentPrice: 326.49, previousClose: 322.10, dayChangePercent: 1.36,
               movingAverage50: 315.40, volume: 17_890_000, marketCap: 838_000_000_000),
        Ticker(id: UUID(uuidString: "00000000-0000-0000-0000-000000000008")!,
               symbol: "BTC", name: "Bitcoin", assetType: .crypto,
               currentPrice: 43_250.00, previousClose: 42_800.00, dayChangePercent: 1.05,
               movingAverage50: 41_200.00, volume: 28_500_000_000, marketCap: 847_000_000_000),
        Ticker(id: UUID(uuidString: "00000000-0000-0000-0000-000000000009")!,
               symbol: "ETH", name: "Ethereum", assetType: .crypto,
               currentPrice: 2_285.50, previousClose: 2_310.00, dayChangePercent: -1.06,
               movingAverage50: 2_180.00, volume: 12_300_000_000, marketCap: 274_000_000_000),
        Ticker(id: UUID(uuidString: "00000000-0000-0000-0000-00000000000A")!,
               symbol: "SOL", name: "Solana", assetType: .crypto,
               currentPrice: 98.45, previousClose: 95.80, dayChangePercent: 2.77,
               movingAverage50: 88.90, volume: 2_450_000_000, marketCap: 42_000_000_000),
        Ticker(id: UUID(uuidString: "00000000-0000-0000-0000-00000000000B")!,
               symbol: "SPY", name: "S&P 500 ETF", assetType: .etf,
               currentPrice: 456.78, previousClose: 454.32, dayChangePercent: 0.54,
               movingAverage50: 448.90, volume: 72_340_000, marketCap: 412_000_000_000),
        Ticker(id: UUID(uuidString: "00000000-0000-0000-0000-00000000000C")!,
               symbol: "QQQ", name: "Nasdaq 100 ETF", assetType: .etf,
               currentPrice: 388.15, previousClose: 385.42, dayChangePercent: 0.71,
               movingAverage50: 378.50, volume: 48_560_000, marketCap: 198_000_000_000),
        Ticker(id: UUID(uuidString: "00000000-0000-0000-0000-00000000000D")!,
               symbol: "AMD", name: "Advanced Micro Devices", assetType: .stock,
               currentPrice: 118.35, previousClose: 120.50, dayChangePercent: -1.78,
               movingAverage50: 112.80, volume: 56_780_000, marketCap: 191_000_000_000),
        Ticker(id: UUID(uuidString: "00000000-0000-0000-0000-00000000000E")!,
               symbol: "DOGE", name: "Dogecoin", assetType: .crypto,
               currentPrice: 0.0812, previousClose: 0.0798, dayChangePercent: 1.75,
               movingAverage50: 0.0745, volume: 890_000_000, marketCap: 11_500_000_000),
        Ticker(id: UUID(uuidString: "00000000-0000-0000-0000-00000000000F")!,
               symbol: "JPM", name: "JPMorgan Chase", assetType: .stock,
               currentPrice: 172.53, previousClose: 170.88, dayChangePercent: 0.97,
               movingAverage50: 165.40, volume: 8_920_000, marketCap: 498_000_000_000),
        Ticker(id: UUID(uuidString: "00000000-0000-0000-0000-000000000010")!,
               symbol: "V", name: "Visa Inc.", assetType: .stock,
               currentPrice: 262.18, previousClose: 260.45, dayChangePercent: 0.66,
               movingAverage50: 255.80, volume: 6_340_000, marketCap: 538_000_000_000),
    ]

    // MARK: - Seed-based Price History

    func allAvailableTickers() -> [Ticker] {
        tickerCatalog
    }

    func defaultTickers() -> [Ticker] {
        Array(tickerCatalog.prefix(5))
    }

    func searchTickers(query: String) -> [Ticker] {
        guard !query.isEmpty else { return tickerCatalog }
        let lowered = query.lowercased()
        return tickerCatalog.filter {
            $0.symbol.lowercased().contains(lowered) ||
            $0.name.lowercased().contains(lowered)
        }
    }

    func ticker(for symbol: String) -> Ticker? {
        tickerCatalog.first { $0.symbol == symbol }
    }

    // MARK: - Generate Price History

    func generatePriceHistory(for ticker: Ticker, timeFrame: TimeFrame) -> [PricePoint] {
        let seed = tickerSeed(ticker.symbol, timeFrame)
        var rng = SeededRandomNumberGenerator(seed: seed)
        let count = timeFrame.dataPointCount
        let volatility = timeFrame.volatilityFactor
        let trendBias = tickerTrendBias(ticker.symbol, timeFrame)

        var prices: [PricePoint] = []
        var price = ticker.currentPrice

        // Work backwards from current price
        let calendar = Calendar.current
        let now = Date()

        // Generate prices from past to present
        var priceValues: [Double] = [price]
        for _ in 1..<count {
            let change = price * volatility * (Double.random(in: -1...1, using: &rng) + trendBias * 0.1)
            price = max(price * 0.5, price - change)
            priceValues.append(price)
        }
        priceValues.reverse()

        for i in 0..<count {
            let date: Date
            switch timeFrame {
            case .day:
                date = calendar.date(byAdding: .hour, value: -(count - 1 - i), to: now)!
            case .week:
                date = calendar.date(byAdding: .day, value: -(count - 1 - i), to: now)!
            case .ytd:
                date = calendar.date(byAdding: .weekOfYear, value: -(count - 1 - i), to: now)!
            case .fiveYears:
                date = calendar.date(byAdding: .month, value: -(count - 1 - i), to: now)!
            }
            prices.append(PricePoint(date: date, price: priceValues[i]))
        }

        return prices
    }

    // MARK: - Generate Comparisons

    func generateComparisons(tickers: [Ticker], timeFrame: TimeFrame) -> [TickerComparison] {
        guard let benchmark = tickers.first else { return [] }

        let benchmarkHistory = generatePriceHistory(for: benchmark, timeFrame: timeFrame)
        guard let benchmarkStart = benchmarkHistory.first?.price,
              let benchmarkEnd = benchmarkHistory.last?.price,
              benchmarkStart > 0 else { return [] }

        let benchmarkReturn = ((benchmarkEnd - benchmarkStart) / benchmarkStart) * 100
        let benchmarkNorm = benchmarkHistory.enumerated().map { i, point in
            NormalizedPoint(index: i, value: ((point.price / benchmarkStart) - 1) * 100, date: point.date)
        }

        return tickers.dropFirst().map { ticker in
            let history = generatePriceHistory(for: ticker, timeFrame: timeFrame)
            guard let start = history.first?.price, start > 0,
                  let end = history.last?.price else {
                return TickerComparison(
                    ticker: ticker, benchmarkTicker: benchmark,
                    tickerReturn: 0, benchmarkReturn: benchmarkReturn,
                    tickerNormalized: [], benchmarkNormalized: benchmarkNorm
                )
            }

            let tickerReturn = ((end - start) / start) * 100
            let tickerNorm = history.enumerated().map { i, point in
                NormalizedPoint(index: i, value: ((point.price / start) - 1) * 100, date: point.date)
            }

            return TickerComparison(
                ticker: ticker, benchmarkTicker: benchmark,
                tickerReturn: tickerReturn, benchmarkReturn: benchmarkReturn,
                tickerNormalized: tickerNorm, benchmarkNormalized: benchmarkNorm
            )
        }
    }

    // MARK: - Sparkline for main list

    func generateSparkline(for ticker: Ticker) -> [Double] {
        let history = generatePriceHistory(for: ticker, timeFrame: .day)
        return history.map { $0.price }
    }

    // MARK: - Private Helpers

    private func tickerSeed(_ symbol: String, _ timeFrame: TimeFrame) -> UInt64 {
        var hash: UInt64 = 5381
        for char in symbol.unicodeScalars {
            hash = ((hash << 5) &+ hash) &+ UInt64(char.value)
        }
        hash = hash &+ UInt64(timeFrame.rawValue * 1000)
        return hash
    }

    private func tickerTrendBias(_ symbol: String, _ timeFrame: TimeFrame) -> Double {
        // Give each ticker a characteristic trend
        let biases: [String: [TimeFrame: Double]] = [
            "AAPL": [.day: 0.3, .week: 0.4, .ytd: 0.6, .fiveYears: 0.8],
            "GOOGL": [.day: 0.2, .week: 0.3, .ytd: 0.5, .fiveYears: 0.7],
            "MSFT": [.day: 0.1, .week: 0.3, .ytd: 0.5, .fiveYears: 0.9],
            "TSLA": [.day: -0.4, .week: -0.2, .ytd: 0.3, .fiveYears: 1.2],
            "NVDA": [.day: 0.5, .week: 0.6, .ytd: 1.0, .fiveYears: 1.5],
            "AMZN": [.day: 0.2, .week: 0.2, .ytd: 0.4, .fiveYears: 0.7],
            "META": [.day: 0.3, .week: 0.5, .ytd: 0.8, .fiveYears: 0.5],
            "BTC": [.day: 0.2, .week: 0.4, .ytd: 0.9, .fiveYears: 2.0],
            "ETH": [.day: -0.2, .week: 0.3, .ytd: 0.7, .fiveYears: 1.8],
            "SOL": [.day: 0.6, .week: 0.5, .ytd: 1.2, .fiveYears: 1.5],
            "SPY": [.day: 0.1, .week: 0.2, .ytd: 0.3, .fiveYears: 0.5],
            "QQQ": [.day: 0.2, .week: 0.3, .ytd: 0.4, .fiveYears: 0.6],
            "AMD": [.day: -0.3, .week: 0.1, .ytd: 0.6, .fiveYears: 1.0],
            "DOGE": [.day: 0.4, .week: -0.1, .ytd: 0.5, .fiveYears: 3.0],
            "JPM": [.day: 0.2, .week: 0.2, .ytd: 0.3, .fiveYears: 0.4],
            "V": [.day: 0.1, .week: 0.2, .ytd: 0.3, .fiveYears: 0.5],
        ]
        return biases[symbol]?[timeFrame] ?? 0.2
    }
}

// MARK: - Seeded RNG for consistent mock data

struct SeededRandomNumberGenerator: RandomNumberGenerator {
    private var state: UInt64

    init(seed: UInt64) {
        self.state = seed
    }

    mutating func next() -> UInt64 {
        state = state &* 6364136223846793005 &+ 1442695040888963407
        return state
    }
}
