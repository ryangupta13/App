import SwiftUI

struct ContentView: View {
    @Environment(StockViewModel.self) var viewModel

    var body: some View {
        @Bindable var vm = viewModel

        ZStack {
            Theme.background.ignoresSafeArea()

            VStack(spacing: 0) {
                // Top page selector
                PageSelectorView(currentPage: $vm.currentPage, pages: viewModel.pages)
                    .padding(.top, 8)

                // Horizontal paging content
                TabView(selection: $vm.currentPage) {
                    TickerListView()
                        .tag(0)

                    ForEach(1...4, id: \.self) { pageIdx in
                        ComparisonPageView(pageIndex: pageIdx)
                            .tag(pageIdx)
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                .animation(.easeInOut(duration: 0.3), value: vm.currentPage)
            }

            // Loading overlay on first launch
            if viewModel.isLoading && viewModel.tickers.isEmpty {
                ZStack {
                    Theme.background.ignoresSafeArea()
                    VStack(spacing: 16) {
                        ProgressView()
                            .tint(Theme.accent)
                            .scaleEffect(1.2)
                        Text("Loading market data...")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundStyle(Theme.textSecondary)
                    }
                }
            }
        }
        .sheet(isPresented: $vm.showingAddTicker) {
            AddTickerView()
                .environment(viewModel)
        }
        .task {
            await viewModel.loadInitialData()
        }
    }
}

// MARK: - Page Selector

struct PageSelectorView: View {
    @Binding var currentPage: Int
    let pages: [StockViewModel.PageType]

    var body: some View {
        ScrollViewReader { proxy in
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 6) {
                    ForEach(Array(pages.enumerated()), id: \.offset) { index, page in
                        PageTab(title: page.title, isSelected: currentPage == index)
                            .id(index)
                            .onTapGesture {
                                withAnimation(.spring(response: 0.35, dampingFraction: 0.85)) {
                                    currentPage = index
                                }
                            }
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
            }
            .onChange(of: currentPage) { _, newValue in
                withAnimation(.spring(response: 0.35)) {
                    proxy.scrollTo(newValue, anchor: .center)
                }
            }
        }
    }
}

struct PageTab: View {
    let title: String
    let isSelected: Bool

    var body: some View {
        Text(title)
            .font(.system(size: 14, weight: isSelected ? .semibold : .medium))
            .foregroundStyle(isSelected ? Theme.textPrimary : Theme.textTertiary)
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(
                Capsule()
                    .fill(isSelected ? Theme.surfaceElevated : Color.clear)
            )
            .overlay(
                Capsule()
                    .stroke(isSelected ? Theme.cardBorder : Color.clear, lineWidth: 0.5)
            )
            .contentShape(Capsule())
    }
}

#Preview {
    ContentView()
        .environment(StockViewModel())
}
