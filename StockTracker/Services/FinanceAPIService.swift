import Foundation

// MARK: - Finance API Service (Yahoo Finance)

actor FinanceAPIService {
    static let shared = FinanceAPIService()

    private let session: URLSession
    private let chartBaseURL = "https://query1.finance.yahoo.com/v8/finance/chart/"
    private let searchBaseURL = "https://query1.finance.yahoo.com/v1/finance/search"
    private let quoteBaseURL = "https://query2.finance.yahoo.com/v10/finance/quoteSummary/"
    private let crumbURL = "https://query2.finance.yahoo.com/v1/test/getcrumb"

    private var crumb: String?

    init() {
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 15
        config.httpAdditionalHeaders = [
            "User-Agent": "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36"
        ]
        config.httpCookieAcceptPolicy = .always
        config.httpShouldSetCookies = true
        config.httpCookieStorage = .shared
        self.session = URLSession(configuration: config)
    }

    // MARK: - Crumb Authentication

    private func ensureCrumb() async throws -> String {
        if let crumb = crumb { return crumb }

        // Step 1: Hit consent page to get cookies
        let consentURL = URL(string: "https://fc.yahoo.com/")!
        _ = try? await session.data(from: consentURL)

        // Step 2: Fetch crumb using the cookies
        let (data, response) = try await session.data(from: URL(string: crumbURL)!)
        guard let http = response as? HTTPURLResponse, http.statusCode == 200,
              let crumbValue = String(data: data, encoding: .utf8)?.trimmingCharacters(in: .whitespacesAndNewlines),
              !crumbValue.isEmpty else {
            throw FinanceAPIError.invalidResponse
        }

        self.crumb = crumbValue
        return crumbValue
    }

    private func fetchWithCrumb(path: String, modules: String) async throws -> (Data, URLResponse) {
        var crumb = try await ensureCrumb()
        var components = URLComponents(string: path)!
        components.queryItems = [
            URLQueryItem(name: "modules", value: modules),
            URLQueryItem(name: "crumb", value: crumb),
        ]

        let (data, response) = try await session.data(from: components.url!)
        if let http = response as? HTTPURLResponse, http.statusCode == 401 {
            // Crumb expired — clear and retry once
            self.crumb = nil
            crumb = try await ensureCrumb()
            components.queryItems = [
                URLQueryItem(name: "modules", value: modules),
                URLQueryItem(name: "crumb", value: crumb),
            ]
            let (retryData, retryResponse) = try await session.data(from: components.url!)
            guard let retryHttp = retryResponse as? HTTPURLResponse, retryHttp.statusCode == 200 else {
                throw FinanceAPIError.invalidResponse
            }
            return (retryData, retryResponse)
        }

        guard let http = response as? HTTPURLResponse, http.statusCode == 200 else {
            throw FinanceAPIError.invalidResponse
        }
        return (data, response)
    }

    // MARK: - Search Symbols

    struct SearchResult: Sendable {
        let symbol: String
        let displaySymbol: String
        let name: String
        let assetType: Ticker.AssetType
        let exchange: String
    }

    func searchSymbols(query: String) async throws -> [SearchResult] {
        guard !query.isEmpty else { return [] }

        var components = URLComponents(string: searchBaseURL)!
        components.queryItems = [
            URLQueryItem(name: "q", value: query),
            URLQueryItem(name: "quotesCount", value: "25"),
            URLQueryItem(name: "newsCount", value: "0"),
            URLQueryItem(name: "listsCount", value: "0"),
        ]

        let (data, response) = try await session.data(from: components.url!)
        guard let http = response as? HTTPURLResponse, http.statusCode == 200 else {
            throw FinanceAPIError.invalidResponse
        }

        let searchResponse = try JSONDecoder().decode(YFSearchResponse.self, from: data)

        return searchResponse.quotes.compactMap { quote in
            guard quote.isYahooFinance != false else { return nil }

            let assetType: Ticker.AssetType
            switch quote.quoteType?.uppercased() {
            case "EQUITY": assetType = .stock
            case "CRYPTOCURRENCY": assetType = .crypto
            case "ETF": assetType = .etf
            case "FUTURE": assetType = .commodity
            default: assetType = .stock
            }

            let displaySymbol: String
            if assetType == .crypto {
                displaySymbol = quote.symbol.replacingOccurrences(of: "-USD", with: "")
            } else {
                displaySymbol = quote.symbol
            }

            return SearchResult(
                symbol: quote.symbol,
                displaySymbol: displaySymbol,
                name: quote.longname ?? quote.shortname ?? displaySymbol,
                assetType: assetType,
                exchange: quote.exchDisp ?? quote.exchange ?? ""
            )
        }
    }

    // MARK: - Fetch Quote (current price + day data)

    struct QuoteData: Sendable {
        let currentPrice: Double
        let previousClose: Double
        let dayChangePercent: Double
        let movingAverage50: Double
        let volume: Double
        let marketCap: Double
        let fiftyTwoWeekHigh: Double
        let fiftyTwoWeekLow: Double
        let averageVolume: Double
        let name: String
    }

    func fetchQuote(symbol: String) async throws -> QuoteData {
        // Fetch chart data and price summary in parallel for complete data
        async let chartTask = fetchChartData(symbol: symbol)
        async let priceTask = fetchPriceData(symbol: symbol)

        let chart = try await chartTask
        let priceData = try? await priceTask

        let currentPrice = chart.currentPrice
        let previousClose = chart.previousClose
        let changePercent = previousClose > 0 ? ((currentPrice - previousClose) / previousClose) * 100 : 0

        return QuoteData(
            currentPrice: currentPrice,
            previousClose: previousClose,
            dayChangePercent: changePercent,
            movingAverage50: chart.fiftyDayAverage,
            volume: chart.volume,
            marketCap: priceData?.marketCap ?? 0,
            fiftyTwoWeekHigh: priceData?.fiftyTwoWeekHigh ?? chart.fiftyTwoWeekHigh,
            fiftyTwoWeekLow: priceData?.fiftyTwoWeekLow ?? chart.fiftyTwoWeekLow,
            averageVolume: priceData?.averageVolume ?? chart.averageVolume,
            name: chart.name
        )
    }

    // Chart API for price + name
    private struct ChartQuote: Sendable {
        let currentPrice: Double
        let previousClose: Double
        let fiftyDayAverage: Double
        let volume: Double
        let fiftyTwoWeekHigh: Double
        let fiftyTwoWeekLow: Double
        let averageVolume: Double
        let name: String
    }

    private func fetchChartData(symbol: String) async throws -> ChartQuote {
        let encoded = symbol.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? symbol
        var components = URLComponents(string: chartBaseURL + encoded)!
        components.queryItems = [
            URLQueryItem(name: "range", value: "5d"),
            URLQueryItem(name: "interval", value: "1d"),
            URLQueryItem(name: "includePrePost", value: "false"),
        ]

        let (data, response) = try await session.data(from: components.url!)
        guard let http = response as? HTTPURLResponse, http.statusCode == 200 else {
            throw FinanceAPIError.invalidResponse
        }

        let chartResponse = try JSONDecoder().decode(YFChartResponse.self, from: data)
        guard let result = chartResponse.chart.result?.first else {
            throw FinanceAPIError.noData
        }

        let meta = result.meta
        return ChartQuote(
            currentPrice: meta.regularMarketPrice ?? 0,
            previousClose: meta.chartPreviousClose ?? meta.previousClose ?? 0,
            fiftyDayAverage: meta.fiftyDayAverage ?? 0,
            volume: Double(meta.regularMarketVolume ?? 0),
            fiftyTwoWeekHigh: meta.fiftyTwoWeekHigh ?? 0,
            fiftyTwoWeekLow: meta.fiftyTwoWeekLow ?? 0,
            averageVolume: Double(meta.averageDailyVolume3Month ?? 0),
            name: meta.longName ?? meta.shortName ?? symbol
        )
    }

    // QuoteSummary price module for marketCap + enriched data
    private struct PriceModuleData: Sendable {
        let marketCap: Double
        let fiftyTwoWeekHigh: Double
        let fiftyTwoWeekLow: Double
        let averageVolume: Double
    }

    private func fetchPriceData(symbol: String) async throws -> PriceModuleData {
        let encoded = symbol.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? symbol

        let (data, _) = try await fetchWithCrumb(path: quoteBaseURL + encoded, modules: "price,summaryDetail")

        let summaryResponse = try JSONDecoder().decode(YFQuoteSummaryResponse.self, from: data)
        guard let resultItem = summaryResponse.quoteSummary.result?.first else {
            throw FinanceAPIError.noData
        }

        return PriceModuleData(
            marketCap: resultItem.price?.marketCap?.raw ?? 0,
            fiftyTwoWeekHigh: resultItem.summaryDetail?.fiftyTwoWeekHigh?.raw ?? 0,
            fiftyTwoWeekLow: resultItem.summaryDetail?.fiftyTwoWeekLow?.raw ?? 0,
            averageVolume: resultItem.summaryDetail?.averageVolume?.raw ?? 0
        )
    }

    // MARK: - Fetch Price History

    func fetchPriceHistory(symbol: String, timeFrame: TimeFrame) async throws -> [PricePoint] {
        let params = timeFrame.apiParams
        let encoded = symbol.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? symbol
        var components = URLComponents(string: chartBaseURL + encoded)!
        components.queryItems = [
            URLQueryItem(name: "range", value: params.range),
            URLQueryItem(name: "interval", value: params.interval),
            URLQueryItem(name: "includePrePost", value: "false"),
        ]

        let (data, response) = try await session.data(from: components.url!)
        guard let http = response as? HTTPURLResponse, http.statusCode == 200 else {
            throw FinanceAPIError.invalidResponse
        }

        let chartResponse = try JSONDecoder().decode(YFChartResponse.self, from: data)
        guard let result = chartResponse.chart.result?.first else {
            throw FinanceAPIError.noData
        }

        var points: [PricePoint] = []
        if let timestamps = result.timestamp,
           let closes = result.indicators.quote.first?.close {
            for (i, timestamp) in timestamps.enumerated() {
                if i < closes.count, let close = closes[i] {
                    let date = Date(timeIntervalSince1970: TimeInterval(timestamp))
                    points.append(PricePoint(date: date, price: close))
                }
            }
        }
        return points
    }

    // MARK: - Fetch Fundamental Metrics

    struct FundamentalData: Sendable {
        let trailingPE: Double?
        let forwardPE: Double?
        let trailingEPS: Double?
        let revenueTTM: Double?
        let revenueGrowthYoY: Double?
        let netMargin: Double?
        let freeCashFlow: Double?
        let debtToEquity: Double?
        let dividendYield: Double?
        let beta: Double?
        let shortPercentFloat: Double?
        let analystRating: String?
        let averagePriceTarget: Double?
        let fiftyTwoWeekChange: Double?
        let evToEBITDA: Double?
        let marketCap: Double?
        let fiftyTwoWeekHigh: Double?
        let fiftyTwoWeekLow: Double?
        let averageVolume: Double?
    }

    func fetchFundamentals(symbol: String) async throws -> FundamentalData {
        let encoded = symbol.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? symbol
        let modules = "defaultKeyStatistics,financialData,summaryDetail,earnings,price"

        let (data, _) = try await fetchWithCrumb(path: quoteBaseURL + encoded, modules: modules)

        let summaryResponse = try JSONDecoder().decode(YFQuoteSummaryResponse.self, from: data)
        guard let resultItem = summaryResponse.quoteSummary.result?.first else {
            throw FinanceAPIError.noData
        }

        let stats = resultItem.defaultKeyStatistics
        let financial = resultItem.financialData
        let summary = resultItem.summaryDetail
        let price = resultItem.price

        return FundamentalData(
            trailingPE: summary?.trailingPE?.raw,
            forwardPE: summary?.forwardPE?.raw,
            trailingEPS: stats?.trailingEps?.raw,
            revenueTTM: financial?.totalRevenue?.raw,
            revenueGrowthYoY: financial?.revenueGrowth?.raw.map { $0 * 100 },
            netMargin: financial?.profitMargins?.raw.map { $0 * 100 },
            freeCashFlow: financial?.freeCashflow?.raw,
            debtToEquity: financial?.debtToEquity?.raw,
            dividendYield: summary?.dividendYield?.raw.map { $0 * 100 },
            beta: summary?.beta?.raw,
            shortPercentFloat: stats?.shortPercentOfFloat?.raw.map { $0 * 100 },
            analystRating: financial?.recommendationKey,
            averagePriceTarget: financial?.targetMeanPrice?.raw,
            fiftyTwoWeekChange: stats?.fiftyTwoWeekChange?.raw.map { $0 * 100 },
            evToEBITDA: stats?.enterpriseToEbitda?.raw,
            marketCap: price?.marketCap?.raw,
            fiftyTwoWeekHigh: summary?.fiftyTwoWeekHigh?.raw,
            fiftyTwoWeekLow: summary?.fiftyTwoWeekLow?.raw,
            averageVolume: summary?.averageVolume?.raw
        )
    }

    // MARK: - Batch Quotes

    func fetchQuotes(symbols: [String]) async -> [String: QuoteData] {
        await withTaskGroup(of: (String, QuoteData?).self) { group in
            for symbol in symbols {
                group.addTask {
                    do {
                        let quote = try await self.fetchQuote(symbol: symbol)
                        return (symbol, quote)
                    } catch {
                        return (symbol, nil)
                    }
                }
            }

            var results: [String: QuoteData] = [:]
            for await (symbol, quote) in group {
                if let quote = quote {
                    results[symbol] = quote
                }
            }
            return results
        }
    }
}

// MARK: - Errors

enum FinanceAPIError: LocalizedError {
    case noData
    case invalidResponse

    var errorDescription: String? {
        switch self {
        case .noData: return "No market data available"
        case .invalidResponse: return "Invalid response from server"
        }
    }
}

// MARK: - Yahoo Finance API Response Models

// Search
private struct YFSearchResponse: Decodable {
    let quotes: [YFSearchQuote]
}

private struct YFSearchQuote: Decodable {
    let symbol: String
    let shortname: String?
    let longname: String?
    let quoteType: String?
    let exchange: String?
    let exchDisp: String?
    let isYahooFinance: Bool?
}

// Chart
private struct YFChartResponse: Decodable {
    let chart: YFChartData
}

private struct YFChartData: Decodable {
    let result: [YFChartResult]?
}

private struct YFChartResult: Decodable {
    let meta: YFChartMeta
    let timestamp: [Int]?
    let indicators: YFIndicators
}

private struct YFChartMeta: Decodable {
    let regularMarketPrice: Double?
    let previousClose: Double?
    let chartPreviousClose: Double?
    let fiftyDayAverage: Double?
    let regularMarketVolume: Int?
    let fiftyTwoWeekHigh: Double?
    let fiftyTwoWeekLow: Double?
    let averageDailyVolume3Month: Int?
    let longName: String?
    let shortName: String?
}

private struct YFIndicators: Decodable {
    let quote: [YFQuoteIndicator]
}

private struct YFQuoteIndicator: Decodable {
    let close: [Double?]
}

// Quote Summary (Fundamentals)
private struct YFQuoteSummaryResponse: Decodable {
    let quoteSummary: YFQuoteSummaryData
}

private struct YFQuoteSummaryData: Decodable {
    let result: [YFQuoteSummaryResult]?
}

private struct YFQuoteSummaryResult: Decodable {
    let defaultKeyStatistics: YFKeyStatistics?
    let financialData: YFFinancialData?
    let summaryDetail: YFSummaryDetail?
    let price: YFPrice?
}

private struct YFRawValue: Decodable {
    let raw: Double?
    let fmt: String?
}

private struct YFKeyStatistics: Decodable {
    let trailingEps: YFRawValue?
    let shortPercentOfFloat: YFRawValue?
    let fiftyTwoWeekChange: YFRawValue?
    let enterpriseToEbitda: YFRawValue?
}

private struct YFFinancialData: Decodable {
    let totalRevenue: YFRawValue?
    let revenueGrowth: YFRawValue?
    let profitMargins: YFRawValue?
    let freeCashflow: YFRawValue?
    let debtToEquity: YFRawValue?
    let recommendationKey: String?
    let targetMeanPrice: YFRawValue?
}

private struct YFSummaryDetail: Decodable {
    let trailingPE: YFRawValue?
    let forwardPE: YFRawValue?
    let dividendYield: YFRawValue?
    let beta: YFRawValue?
    let fiftyTwoWeekHigh: YFRawValue?
    let fiftyTwoWeekLow: YFRawValue?
    let averageVolume: YFRawValue?
}

private struct YFPrice: Decodable {
    let marketCap: YFRawValue?
}
