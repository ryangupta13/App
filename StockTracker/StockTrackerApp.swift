import SwiftUI

@main
struct StockTrackerApp: App {
    @State private var viewModel = StockViewModel()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(viewModel)
                .preferredColorScheme(.dark)
        }
    }
}
