import Foundation

struct Ticker: Identifiable, Codable, Equatable, Hashable {
    let id: UUID
    var symbol: String        // Display symbol: "BTC", "AAPL", "GC=F"
    var yahooSymbol: String   // Yahoo Finance symbol: "BTC-USD", "AAPL", "GC=F"
    var name: String
    var assetType: AssetType
    var currentPrice: Double
    var previousClose: Double
    var dayChangePercent: Double
    var movingAverage50: Double
    var volume: Double
    var marketCap: Double
    var fiftyTwoWeekHigh: Double
    var fiftyTwoWeekLow: Double
    var averageVolume: Double

    var dayChange: Double {
        currentPrice - previousClose
    }

    var isPositive: Bool {
        dayChangePercent >= 0
    }

    enum AssetType: String, Codable, Hashable, CaseIterable {
        case stock = "Stock"
        case crypto = "Crypto"
        case etf = "ETF"
        case commodity = "Commodity"

        var icon: String {
            switch self {
            case .stock: return "building.columns.fill"
            case .crypto: return "bitcoinsign.circle.fill"
            case .etf: return "chart.pie.fill"
            case .commodity: return "shippingbox.fill"
            }
        }
    }

    // Codable backwards compat: provide defaults for new fields
    init(id: UUID = UUID(), symbol: String, yahooSymbol: String? = nil, name: String,
         assetType: AssetType, currentPrice: Double, previousClose: Double,
         dayChangePercent: Double, movingAverage50: Double, volume: Double,
         marketCap: Double, fiftyTwoWeekHigh: Double = 0, fiftyTwoWeekLow: Double = 0,
         averageVolume: Double = 0) {
        self.id = id
        self.symbol = symbol
        self.yahooSymbol = yahooSymbol ?? symbol
        self.name = name
        self.assetType = assetType
        self.currentPrice = currentPrice
        self.previousClose = previousClose
        self.dayChangePercent = dayChangePercent
        self.movingAverage50 = movingAverage50
        self.volume = volume
        self.marketCap = marketCap
        self.fiftyTwoWeekHigh = fiftyTwoWeekHigh
        self.fiftyTwoWeekLow = fiftyTwoWeekLow
        self.averageVolume = averageVolume
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = try c.decode(UUID.self, forKey: .id)
        symbol = try c.decode(String.self, forKey: .symbol)
        yahooSymbol = try c.decodeIfPresent(String.self, forKey: .yahooSymbol) ?? symbol
        name = try c.decode(String.self, forKey: .name)
        assetType = try c.decode(AssetType.self, forKey: .assetType)
        currentPrice = try c.decode(Double.self, forKey: .currentPrice)
        previousClose = try c.decode(Double.self, forKey: .previousClose)
        dayChangePercent = try c.decode(Double.self, forKey: .dayChangePercent)
        movingAverage50 = try c.decode(Double.self, forKey: .movingAverage50)
        volume = try c.decode(Double.self, forKey: .volume)
        marketCap = try c.decode(Double.self, forKey: .marketCap)
        fiftyTwoWeekHigh = try c.decodeIfPresent(Double.self, forKey: .fiftyTwoWeekHigh) ?? 0
        fiftyTwoWeekLow = try c.decodeIfPresent(Double.self, forKey: .fiftyTwoWeekLow) ?? 0
        averageVolume = try c.decodeIfPresent(Double.self, forKey: .averageVolume) ?? 0
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
    let ratioPoints: [RatioPoint]

    init(ticker: Ticker, benchmarkTicker: Ticker, tickerReturn: Double, benchmarkReturn: Double, ratioPoints: [RatioPoint]) {
        self.id = UUID()
        self.ticker = ticker
        self.benchmarkTicker = benchmarkTicker
        self.tickerReturn = tickerReturn
        self.benchmarkReturn = benchmarkReturn
        self.relativePerformance = tickerReturn - benchmarkReturn
        self.ratioPoints = ratioPoints
    }
}

struct RatioPoint: Identifiable {
    let id = UUID()
    let index: Int
    let date: Date
    let ratio: Double
}

struct NormalizedPoint: Identifiable {
    let id = UUID()
    let index: Int
    let value: Double
    let date: Date
}

// MARK: - Displayable Metrics

enum TickerMetric: String, Codable, CaseIterable, Identifiable {
    // Default home screen metrics
    case currentPrice = "Current Price"
    case dayChange = "Day Change"
    case marketCap = "Market Cap"
    case fiftyTwoWeekRange = "52-Week High/Low"
    case volumeVsAverage = "Volume vs Average"

    // Optional / detail metrics
    case trailingPE = "P/E Ratio (Trailing)"
    case forwardPE = "Forward P/E"
    case trailingEPS = "EPS (Trailing)"
    case revenueTTM = "Revenue (TTM)"
    case revenueGrowthYoY = "Revenue Growth (YoY)"
    case netMargin = "Net Margin"
    case freeCashFlow = "Free Cash Flow"
    case debtToEquity = "Debt-to-Equity"
    case dividendYield = "Dividend Yield"
    case beta = "Beta"
    case shortInterest = "Short Interest (% Float)"
    case analystRating = "Analyst Rating"
    case avgPriceTarget = "Avg Price Target"
    case fiftyTwoWeekChange = "52-Week Change %"
    case evToEBITDA = "EV/EBITDA"
    case movingAvg50 = "50-Day MA"

    var id: String { rawValue }

    static let defaultHomeMetrics: [TickerMetric] = [
        .currentPrice, .dayChange, .marketCap, .fiftyTwoWeekRange, .volumeVsAverage
    ]

    static let additionalMetrics: [TickerMetric] = [
        .trailingPE, .forwardPE, .trailingEPS, .revenueTTM, .revenueGrowthYoY,
        .netMargin, .freeCashFlow, .debtToEquity, .dividendYield, .beta,
        .shortInterest, .analystRating, .avgPriceTarget, .fiftyTwoWeekChange,
        .evToEBITDA, .movingAvg50
    ]
}
