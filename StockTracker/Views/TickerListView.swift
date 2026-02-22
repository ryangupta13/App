import SwiftUI

struct TickerListView: View {
    @Environment(StockViewModel.self) var viewModel
    @State private var editMode: EditMode = .inactive
    @State private var showMetricPicker = false

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
                    // Refresh button
                    if viewModel.isLoading {
                        ProgressView()
                            .tint(Theme.textTertiary)
                            .scaleEffect(0.8)
                    } else {
                        Button {
                            Task { await viewModel.refreshPrices() }
                        } label: {
                            Image(systemName: "arrow.clockwise")
                                .font(.system(size: 18))
                                .foregroundStyle(Theme.textSecondary)
                        }
                    }

                    // Metrics customization
                    Button {
                        showMetricPicker = true
                    } label: {
                        Image(systemName: "slider.horizontal.3")
                            .font(.system(size: 18))
                            .foregroundStyle(Theme.textSecondary)
                    }

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

            // Ticker list
            if viewModel.tickers.isEmpty && !viewModel.isLoading {
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
        .sheet(isPresented: $showMetricPicker) {
            MetricPickerView(selectedMetrics: viewModel.homeMetrics) { metrics in
                viewModel.setHomeMetrics(metrics)
            }
            .presentationDetents([.medium, .large])
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
            Text("Tap + to add stocks, crypto & more")
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

// MARK: - Metric Picker

struct MetricPickerView: View {
    @Environment(\.dismiss) var dismiss
    @State var selectedMetrics: [TickerMetric]
    let onSave: ([TickerMetric]) -> Void

    private let allSwappable: [TickerMetric] = TickerMetric.defaultHomeMetrics + TickerMetric.additionalMetrics

    var body: some View {
        NavigationStack {
            ZStack {
                Theme.background.ignoresSafeArea()
                ScrollView {
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Choose which metrics appear on the watchlist cards. Tap to toggle.")
                            .font(.system(size: 13))
                            .foregroundStyle(Theme.textTertiary)
                            .padding(.horizontal, 16)

                        LazyVStack(spacing: 6) {
                            ForEach(allSwappable) { metric in
                                let isSelected = selectedMetrics.contains(metric)
                                Button {
                                    if isSelected {
                                        selectedMetrics.removeAll { $0 == metric }
                                    } else {
                                        selectedMetrics.append(metric)
                                    }
                                } label: {
                                    HStack {
                                        Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                                            .foregroundStyle(isSelected ? Theme.accent : Theme.textTertiary)
                                        Text(metric.rawValue)
                                            .font(.system(size: 14, weight: .medium))
                                            .foregroundStyle(Theme.textPrimary)
                                        Spacer()
                                    }
                                    .padding(12)
                                    .background(isSelected ? Theme.accent.opacity(0.08) : Theme.surfaceElevated)
                                    .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                                }
                            }
                        }
                        .padding(.horizontal, 16)
                    }
                    .padding(.vertical, 12)
                }
            }
            .navigationTitle("Customize Metrics")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Save") {
                        onSave(selectedMetrics)
                        dismiss()
                    }
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(Theme.accent)
                }
            }
            .toolbarBackground(Theme.background, for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
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
