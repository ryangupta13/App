import Foundation

struct Ticker: Identifiable, Codable, Equatable, Hashable {
    let id: UUID
    var symbol: String
    var name: String
    var assetType: AssetType
    var currentPrice: Double
    var previousClose: Double
    var dayChangePercent: Double
    var movingAverage50: Double
    var volume: Double
    var marketCap: Double

    var dayChange: Double {
        currentPrice - previousClose
    }

    var isPositive: Bool {
        dayChangePercent >= 0
    }

    enum AssetType: String, Codable, Hashable {
        case stock = "Stock"
        case crypto = "Crypto"
        case etf = "ETF"

        var icon: String {
            switch self {
            case .stock: return "building.columns.fill"
            case .crypto: return "bitcoinsign.circle.fill"
            case .etf: return "chart.pie.fill"
            }
        }
    }

    static func == (lhs: Ticker, rhs: Ticker) -> Bool {
        lhs.id == rhs.id
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}

struct PricePoint: Identifiable, Codable {
    let id: UUID
    let date: Date
    let price: Double

    init(date: Date, price: Double) {
        self.id = UUID()
        self.date = date
        self.price = price
    }
}

struct TickerComparison: Identifiable {
    let id: UUID
    let ticker: Ticker
    let benchmarkTicker: Ticker
    let tickerReturn: Double
    let benchmarkReturn: Double
    let relativePerformance: Double
    let tickerNormalized: [NormalizedPoint]
    let benchmarkNormalized: [NormalizedPoint]

    init(ticker: Ticker, benchmarkTicker: Ticker, tickerReturn: Double, benchmarkReturn: Double, tickerNormalized: [NormalizedPoint], benchmarkNormalized: [NormalizedPoint]) {
        self.id = UUID()
        self.ticker = ticker
        self.benchmarkTicker = benchmarkTicker
        self.tickerReturn = tickerReturn
        self.benchmarkReturn = benchmarkReturn
        self.relativePerformance = tickerReturn - benchmarkReturn
        self.tickerNormalized = tickerNormalized
        self.benchmarkNormalized = benchmarkNormalized
    }
}

struct NormalizedPoint: Identifiable {
    let id = UUID()
    let index: Int
    let value: Double
    let date: Date
}
