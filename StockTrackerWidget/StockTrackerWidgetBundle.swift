import WidgetKit
import SwiftUI

@main
struct StockTrackerWidgetBundle: WidgetBundle {
    var body: some Widget {
        WatchlistWidget()
        BenchmarkWidget()
    }
}
