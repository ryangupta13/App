import Foundation

enum TimeFrame: Int, CaseIterable, Identifiable, Codable {
    case day = 0
    case week = 1
    case twoWeeks = 2
    case oneMonth = 3
    case threeMonths = 4
    case qtd = 5
    case ytd = 6
    case oneYear = 7
    case twoYears = 8
    case threeYears = 9
    case fiveYears = 10
    case allTime = 11

    var id: Int { rawValue }

    var label: String {
        switch self {
        case .day: return "1D"
        case .week: return "1W"
        case .twoWeeks: return "2W"
        case .oneMonth: return "1M"
        case .threeMonths: return "3M"
        case .qtd: return "QTD"
        case .ytd: return "YTD"
        case .oneYear: return "1Y"
        case .twoYears: return "2Y"
        case .threeYears: return "3Y"
        case .fiveYears: return "5Y"
        case .allTime: return "ALL"
        }
    }

    var fullTitle: String {
        switch self {
        case .day: return "Last Day"
        case .week: return "Last Week"
        case .twoWeeks: return "Last 2 Weeks"
        case .oneMonth: return "Last Month"
        case .threeMonths: return "Last 3 Months"
        case .qtd: return "Quarter to Date"
        case .ytd: return "Year to Date"
        case .oneYear: return "Last Year"
        case .twoYears: return "Last 2 Years"
        case .threeYears: return "Last 3 Years"
        case .fiveYears: return "Last 5 Years"
        case .allTime: return "All Time"
        }
    }

    /// Yahoo Finance chart API parameters: (range, interval)
    var apiParams: (range: String, interval: String) {
        switch self {
        case .day:         return ("1d", "5m")
        case .week:        return ("5d", "30m")
        case .twoWeeks:    return ("1mo", "1h")
        case .oneMonth:    return ("1mo", "1d")
        case .threeMonths: return ("3mo", "1d")
        case .qtd:         return ("3mo", "1d")   // filtered to QTD in code
        case .ytd:         return ("ytd", "1d")
        case .oneYear:     return ("1y", "1d")
        case .twoYears:    return ("2y", "1wk")
        case .threeYears:  return ("3y", "1wk")
        case .fiveYears:   return ("5y", "1wk")
        case .allTime:     return ("max", "1mo")
        }
    }

    /// Default 4 timeframes for the comparison pages
    static let defaultComparisonFrames: [TimeFrame] = [.week, .oneMonth, .ytd, .fiveYears]
}
