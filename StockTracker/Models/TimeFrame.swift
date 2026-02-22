import Foundation

enum TimeFrame: Int, CaseIterable, Identifiable {
    case day = 0
    case week = 1
    case ytd = 2
    case fiveYears = 3

    var id: Int { rawValue }

    var label: String {
        switch self {
        case .day: return "1D"
        case .week: return "1W"
        case .ytd: return "YTD"
        case .fiveYears: return "5Y"
        }
    }

    var fullTitle: String {
        switch self {
        case .day: return "Last Day"
        case .week: return "Last Week"
        case .ytd: return "Year to Date"
        case .fiveYears: return "Last 5 Years"
        }
    }

    var dataPointCount: Int {
        switch self {
        case .day: return 24
        case .week: return 7
        case .ytd: return 52
        case .fiveYears: return 60
        }
    }

    var volatilityFactor: Double {
        switch self {
        case .day: return 0.005
        case .week: return 0.012
        case .ytd: return 0.04
        case .fiveYears: return 0.08
        }
    }
}
