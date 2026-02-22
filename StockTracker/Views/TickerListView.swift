import SwiftUI

struct TickerListView: View {
    @Environment(StockViewModel.self) var viewModel
    @State private var editMode: EditMode = .inactive

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack(alignment: .center) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Watchlist")
                        .font(.system(size: 28, weight: .bold, design: .rounded))
                        .foregroundStyle(Theme.textPrimary)
                    Text("\(viewModel.tickers.count) assets")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundStyle(Theme.textTertiary)
                }

                Spacer()

                HStack(spacing: 12) {
                    Button {
                        withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                            editMode = editMode == .active ? .inactive : .active
                        }
                    } label: {
                        Image(systemName: editMode == .active ? "checkmark.circle.fill" : "arrow.up.arrow.down.circle")
                            .font(.system(size: 22))
                            .foregroundStyle(editMode == .active ? Theme.positive : Theme.textSecondary)
                    }

                    Button {
                        viewModel.showingAddTicker = true
                    } label: {
                        Image(systemName: "plus.circle.fill")
                            .font(.system(size: 22))
                            .foregroundStyle(Theme.accent)
                    }
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 4)
            .padding(.bottom, 12)

            // Metric labels
            HStack {
                Text("ASSET")
                    .frame(maxWidth: .infinity, alignment: .leading)
                Spacer()
                Text("CHART")
                    .frame(width: 60)
                Text("PRICE")
                    .frame(width: 80, alignment: .trailing)
            }
            .font(.system(size: 10, weight: .semibold))
            .foregroundStyle(Theme.textTertiary)
            .padding(.horizontal, 20)
            .padding(.bottom, 8)

            // Ticker list
            if viewModel.tickers.isEmpty {
                emptyState
            } else {
                List {
                    ForEach(viewModel.tickers) { ticker in
                        TickerRowView(ticker: ticker)
                            .listRowBackground(Color.clear)
                            .listRowSeparator(.hidden)
                            .listRowInsets(EdgeInsets(top: 4, leading: 16, bottom: 4, trailing: 16))
                    }
                    .onMove { from, to in
                        viewModel.moveTicker(from: from, to: to)
                    }
                    .onDelete { offsets in
                        viewModel.removeTicker(at: offsets)
                    }
                }
                .listStyle(.plain)
                .scrollContentBackground(.hidden)
                .environment(\.editMode, $editMode)
            }
        }
    }

    private var emptyState: some View {
        VStack(spacing: 16) {
            Spacer()
            Image(systemName: "chart.line.uptrend.xyaxis")
                .font(.system(size: 48))
                .foregroundStyle(Theme.textTertiary)
            Text("No assets tracked")
                .font(.system(size: 18, weight: .semibold))
                .foregroundStyle(Theme.textSecondary)
            Text("Tap + to add stocks and crypto")
                .font(.system(size: 14))
                .foregroundStyle(Theme.textTertiary)
            Button {
                viewModel.showingAddTicker = true
            } label: {
                Text("Add Asset")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 24)
                    .padding(.vertical, 12)
                    .background(Theme.accent)
                    .clipShape(Capsule())
            }
            .padding(.top, 8)
            Spacer()
        }
    }
}

#Preview {
    ZStack {
        Theme.background.ignoresSafeArea()
        TickerListView()
            .environment(StockViewModel())
    }
    .preferredColorScheme(.dark)
}
