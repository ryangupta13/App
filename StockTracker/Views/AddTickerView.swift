import SwiftUI

struct AddTickerView: View {
    @Environment(StockViewModel.self) var viewModel
    @Environment(\.dismiss) var dismiss
    @State private var searchText = ""
    @State private var addedSymbols: Set<String> = []
    @State private var searchTask: Task<Void, Never>?

    var body: some View {
        NavigationStack {
            ZStack {
                Theme.background.ignoresSafeArea()

                VStack(spacing: 0) {
                    // Search bar
                    HStack(spacing: 10) {
                        Image(systemName: "magnifyingglass")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundStyle(Theme.textTertiary)

                        TextField("Search stocks, crypto, ETFs, commodities...", text: $searchText)
                            .font(.system(size: 16))
                            .foregroundStyle(Theme.textPrimary)
                            .autocorrectionDisabled()
                            .textInputAutocapitalization(.characters)

                        if viewModel.isSearching {
                            ProgressView()
                                .tint(Theme.textTertiary)
                                .scaleEffect(0.8)
                        } else if !searchText.isEmpty {
                            Button {
                                searchText = ""
                                viewModel.searchResults = []
                            } label: {
                                Image(systemName: "xmark.circle.fill")
                                    .font(.system(size: 16))
                                    .foregroundStyle(Theme.textTertiary)
                            }
                        }
                    }
                    .padding(12)
                    .background(Theme.surfaceElevated)
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .stroke(Theme.cardBorder, lineWidth: 0.5)
                    )
                    .padding(.horizontal, 16)
                    .padding(.top, 8)
                    .padding(.bottom, 12)

                    // Results
                    if searchText.isEmpty {
                        searchPrompt
                    } else if viewModel.searchResults.isEmpty && !viewModel.isSearching {
                        noResults
                    } else {
                        ScrollView {
                            LazyVStack(spacing: 6) {
                                ForEach(viewModel.searchResults) { item in
                                    let alreadyTracked = viewModel.isTickerInWatchlist(item.yahooSymbol) || addedSymbols.contains(item.yahooSymbol)
                                    AddTickerSearchRow(
                                        item: item,
                                        isAdding: viewModel.addingSymbol == item.yahooSymbol,
                                        alreadyTracked: alreadyTracked
                                    ) {
                                        addedSymbols.insert(item.yahooSymbol)
                                        Task {
                                            await viewModel.addTicker(from: item)
                                        }
                                    }
                                }
                            }
                            .padding(.horizontal, 16)
                            .padding(.bottom, 20)
                        }
                    }
                }
            }
            .navigationTitle("Add Asset")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(Theme.accent)
                }
            }
            .toolbarBackground(Theme.background, for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .onChange(of: searchText) { _, newValue in
                searchTask?.cancel()
                searchTask = Task {
                    try? await Task.sleep(nanoseconds: 300_000_000)
                    guard !Task.isCancelled else { return }
                    await viewModel.performSearch(query: newValue)
                }
            }
        }
    }

    private var searchPrompt: some View {
        VStack(spacing: 12) {
            Spacer()
            Image(systemName: "magnifyingglass")
                .font(.system(size: 36))
                .foregroundStyle(Theme.textTertiary)
            Text("Search for any asset")
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(Theme.textSecondary)
            Text("Stocks, ETFs, crypto, commodities & more")
                .font(.system(size: 13))
                .foregroundStyle(Theme.textTertiary)
            Spacer()
        }
    }

    private var noResults: some View {
        VStack(spacing: 12) {
            Spacer()
            Image(systemName: "magnifyingglass")
                .font(.system(size: 36))
                .foregroundStyle(Theme.textTertiary)
            Text("No results found")
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(Theme.textSecondary)
            Text("Try a different search term")
                .font(.system(size: 13))
                .foregroundStyle(Theme.textTertiary)
            Spacer()
        }
    }
}

// MARK: - Search Row

struct AddTickerSearchRow: View {
    let item: TickerSearchItem
    let isAdding: Bool
    var alreadyTracked: Bool = false
    let onAdd: () -> Void
    @State private var isPressed = false

    var body: some View {
        HStack(spacing: 14) {
            ZStack {
                Circle()
                    .fill(typeColor.opacity(0.15))
                    .frame(width: 40, height: 40)
                Image(systemName: item.assetType.icon)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundStyle(typeColor)
            }

            VStack(alignment: .leading, spacing: 3) {
                Text(item.displaySymbol)
                    .font(.system(size: 16, weight: .bold, design: .rounded))
                    .foregroundStyle(alreadyTracked ? Theme.textSecondary : Theme.textPrimary)
                Text(item.name)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(alreadyTracked ? Theme.textTertiary : Theme.textSecondary)
                    .lineLimit(1)
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 3) {
                Text(item.exchange)
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(Theme.textTertiary)
                Text(item.assetType.rawValue)
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(Theme.textTertiary)
            }

            if alreadyTracked {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 28))
                    .foregroundStyle(Theme.positive)
            } else if isAdding {
                ProgressView()
                    .tint(Theme.accent)
                    .frame(width: 28, height: 28)
            } else {
                Button(action: onAdd) {
                    Image(systemName: "plus.circle.fill")
                        .font(.system(size: 28))
                        .foregroundStyle(Theme.accent)
                        .scaleEffect(isPressed ? 0.85 : 1.0)
                }
                .buttonStyle(.plain)
                .simultaneousGesture(
                    DragGesture(minimumDistance: 0)
                        .onChanged { _ in isPressed = true }
                        .onEnded { _ in isPressed = false }
                )
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .cardStyle()
    }

    private var typeColor: Color {
        switch item.assetType {
        case .stock: return Theme.benchmark
        case .crypto: return Color.orange
        case .etf: return Theme.accentSecondary
        case .commodity: return Color.yellow
        }
    }
}

#Preview {
    AddTickerView()
        .environment(StockViewModel())
        .preferredColorScheme(.dark)
}
