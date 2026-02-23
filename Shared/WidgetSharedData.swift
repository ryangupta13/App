import Foundation
import WidgetKit

// MARK: - App Group Constants

enum AppGroupConfig {
    static let suiteName = "group.com.stocktracker.app"

    static var sharedDefaults: UserDefaults? {
        UserDefaults(suiteName: suiteName)
    }
}

// MARK: - Shared Ticker Data

struct WidgetTickerData: Codable {
    let symbol: String
    let yahooSymbol: String
    let name: String
    let assetType: String
}

enum WidgetDataStore {
    private static let tickersKey = "widget_tickers"

    static func saveTickers(_ tickers: [WidgetTickerData]) {
        guard let data = try? JSONEncoder().encode(tickers) else { return }
        AppGroupConfig.sharedDefaults?.set(data, forKey: tickersKey)
    }

    static func loadTickers() -> [WidgetTickerData] {
        guard let data = AppGroupConfig.sharedDefaults?.data(forKey: tickersKey),
              let tickers = try? JSONDecoder().decode([WidgetTickerData].self, from: data) else {
            return []
        }
        return tickers
    }

    static func reloadWidgets() {
        WidgetCenter.shared.reloadAllTimelines()
    }
}
