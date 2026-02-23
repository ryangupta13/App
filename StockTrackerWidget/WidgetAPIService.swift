import Foundation

// MARK: - Lightweight API Service for Widget

actor WidgetAPIService {
    static let shared = WidgetAPIService()

    private let session: URLSession
    private let chartBaseURL = "https://query1.finance.yahoo.com/v8/finance/chart/"

    init() {
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 10
        config.httpAdditionalHeaders = [
            "User-Agent": "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36"
        ]
        self.session = URLSession(configuration: config)
    }

    // MARK: - Quote Data

    struct WidgetQuote: Sendable {
        let symbol: String
        let currentPrice: Double
        let previousClose: Double
        let dayChangePercent: Double
    }

    func fetchQuote(symbol: String) async throws -> WidgetQuote {
        let encoded = symbol.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? symbol
        var components = URLComponents(string: chartBaseURL + encoded)!
        components.queryItems = [
            URLQueryItem(name: "range", value: "5d"),
            URLQueryItem(name: "interval", value: "1d"),
            URLQueryItem(name: "includePrePost", value: "false"),
        ]

        let (data, response) = try await session.data(from: components.url!)
        guard let http = response as? HTTPURLResponse, http.statusCode == 200 else {
            throw WidgetAPIError.invalidResponse
        }

        let chartResponse = try JSONDecoder().decode(ChartResponse.self, from: data)
        guard let result = chartResponse.chart.result?.first else {
            throw WidgetAPIError.noData
        }

        let meta = result.meta
        let currentPrice = meta.regularMarketPrice ?? 0
        let previousClose = meta.chartPreviousClose ?? meta.previousClose ?? 0
        let changePercent = previousClose > 0 ? ((currentPrice - previousClose) / previousClose) * 100 : 0

        return WidgetQuote(
            symbol: symbol,
            currentPrice: currentPrice,
            previousClose: previousClose,
            dayChangePercent: changePercent
        )
    }

    // MARK: - Period Change

    func fetchPeriodChange(symbol: String, timeFrame: WidgetTimeFrame) async throws -> Double {
        let encoded = symbol.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? symbol
        var components = URLComponents(string: chartBaseURL + encoded)!
        components.queryItems = [
            URLQueryItem(name: "range", value: timeFrame.apiRange),
            URLQueryItem(name: "interval", value: timeFrame.apiInterval),
            URLQueryItem(name: "includePrePost", value: "false"),
        ]

        let (data, response) = try await session.data(from: components.url!)
        guard let http = response as? HTTPURLResponse, http.statusCode == 200 else {
            throw WidgetAPIError.invalidResponse
        }

        let chartResponse = try JSONDecoder().decode(ChartResponse.self, from: data)
        guard let result = chartResponse.chart.result?.first else {
            throw WidgetAPIError.noData
        }

        let currentPrice = result.meta.regularMarketPrice ?? 0
        guard let closes = result.indicators.quote.first?.close else {
            throw WidgetAPIError.noData
        }

        // Find first valid close price
        let startPrice = closes.compactMap { $0 }.first ?? 0
        guard startPrice > 0 else { throw WidgetAPIError.noData }

        return ((currentPrice - startPrice) / startPrice) * 100
    }

    // MARK: - Batch Fetch

    struct TickerWidgetData: Sendable {
        let symbol: String
        let displaySymbol: String
        let name: String
        let assetType: String
        let currentPrice: Double
        let periodChange: Double
    }

    func fetchWatchlistData(tickers: [WidgetTickerData], timeFrame: WidgetTimeFrame) async -> [TickerWidgetData] {
        await withTaskGroup(of: TickerWidgetData?.self) { group in
            for ticker in tickers {
                group.addTask {
                    do {
                        async let quoteTask = self.fetchQuote(symbol: ticker.yahooSymbol)
                        async let changeTask = self.fetchPeriodChange(symbol: ticker.yahooSymbol, timeFrame: timeFrame)

                        let quote = try await quoteTask
                        let change = try await changeTask

                        return TickerWidgetData(
                            symbol: ticker.symbol,
                            displaySymbol: ticker.symbol,
                            name: ticker.name,
                            assetType: ticker.assetType,
                            currentPrice: quote.currentPrice,
                            periodChange: change
                        )
                    } catch {
                        return nil
                    }
                }
            }

            var results: [TickerWidgetData] = []
            for await result in group {
                if let result { results.append(result) }
            }

            // Maintain original ticker order
            let orderMap = Dictionary(uniqueKeysWithValues: tickers.enumerated().map { ($0.element.symbol, $0.offset) })
            results.sort { (orderMap[$0.symbol] ?? 0) < (orderMap[$1.symbol] ?? 0) }
            return results
        }
    }

    struct BenchmarkTickerData: Sendable {
        let symbol: String
        let displaySymbol: String
        let name: String
        let assetType: String
        let currentPrice: Double
        let tickerChange: Double
        let benchmarkChange: Double
        let relativeChange: Double
    }

    func fetchBenchmarkData(tickers: [WidgetTickerData], timeFrame: WidgetTimeFrame) async -> (benchmark: TickerWidgetData?, comparisons: [BenchmarkTickerData]) {
        guard let benchmarkTicker = tickers.first else { return (nil, []) }

        // Fetch benchmark change first
        let benchmarkChange: Double
        let benchmarkQuote: WidgetQuote?
        do {
            async let changeTask = fetchPeriodChange(symbol: benchmarkTicker.yahooSymbol, timeFrame: timeFrame)
            async let quoteTask = fetchQuote(symbol: benchmarkTicker.yahooSymbol)
            benchmarkChange = try await changeTask
            benchmarkQuote = try await quoteTask
        } catch {
            return (nil, [])
        }

        let benchmark = TickerWidgetData(
            symbol: benchmarkTicker.symbol,
            displaySymbol: benchmarkTicker.symbol,
            name: benchmarkTicker.name,
            assetType: benchmarkTicker.assetType,
            currentPrice: benchmarkQuote?.currentPrice ?? 0,
            periodChange: benchmarkChange
        )

        let others = Array(tickers.dropFirst())
        let comparisons = await withTaskGroup(of: BenchmarkTickerData?.self) { group in
            for ticker in others {
                group.addTask {
                    do {
                        async let quoteTask = self.fetchQuote(symbol: ticker.yahooSymbol)
                        async let changeTask = self.fetchPeriodChange(symbol: ticker.yahooSymbol, timeFrame: timeFrame)

                        let quote = try await quoteTask
                        let tickerPeriodChange = try await changeTask

                        return BenchmarkTickerData(
                            symbol: ticker.symbol,
                            displaySymbol: ticker.symbol,
                            name: ticker.name,
                            assetType: ticker.assetType,
                            currentPrice: quote.currentPrice,
                            tickerChange: tickerPeriodChange,
                            benchmarkChange: benchmarkChange,
                            relativeChange: tickerPeriodChange - benchmarkChange
                        )
                    } catch {
                        return nil
                    }
                }
            }

            var results: [BenchmarkTickerData] = []
            for await result in group {
                if let result { results.append(result) }
            }

            let orderMap = Dictionary(uniqueKeysWithValues: others.enumerated().map { ($0.element.symbol, $0.offset) })
            results.sort { (orderMap[$0.symbol] ?? 0) < (orderMap[$1.symbol] ?? 0) }
            return results
        }

        return (benchmark, comparisons)
    }
}

// MARK: - Widget TimeFrame

enum WidgetTimeFrame: String, CaseIterable, Sendable {
    case day = "1D"
    case week = "1W"
    case oneMonth = "1M"
    case threeMonths = "3M"
    case ytd = "YTD"
    case oneYear = "1Y"
    case fiveYears = "5Y"

    var apiRange: String {
        switch self {
        case .day: return "1d"
        case .week: return "5d"
        case .oneMonth: return "1mo"
        case .threeMonths: return "3mo"
        case .ytd: return "ytd"
        case .oneYear: return "1y"
        case .fiveYears: return "5y"
        }
    }

    var apiInterval: String {
        switch self {
        case .day: return "5m"
        case .week: return "1d"
        case .oneMonth: return "1d"
        case .threeMonths: return "1d"
        case .ytd: return "1d"
        case .oneYear: return "1wk"
        case .fiveYears: return "1mo"
        }
    }

    var displayLabel: String { rawValue }
}

// MARK: - Errors

enum WidgetAPIError: Error {
    case invalidResponse
    case noData
}

// MARK: - Yahoo Finance Response Models

private struct ChartResponse: Decodable {
    let chart: ChartData
}

private struct ChartData: Decodable {
    let result: [ChartResult]?
}

private struct ChartResult: Decodable {
    let meta: ChartMeta
    let timestamp: [Int]?
    let indicators: ChartIndicators
}

private struct ChartMeta: Decodable {
    let regularMarketPrice: Double?
    let previousClose: Double?
    let chartPreviousClose: Double?
}

private struct ChartIndicators: Decodable {
    let quote: [ChartQuote]
}

private struct ChartQuote: Decodable {
    let close: [Double?]?
}
