import SwiftUI

struct AddTickerView: View {
    @Environment(StockViewModel.self) var viewModel
    @Environment(\.dismiss) var dismiss
    @State private var searchText = ""
    @State private var addedSymbols: Set<String> = []

    var filteredTickers: [Ticker] {
        let service = StockDataService.shared
        let all = service.searchTickers(query: searchText)
        let existing = Set(viewModel.tickers.map { $0.symbol })
        return all.filter { !existing.contains($0.symbol) && !addedSymbols.contains($0.symbol) }
    }

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

                        TextField("Search stocks, crypto, ETFs...", text: $searchText)
                            .font(.system(size: 16))
                            .foregroundStyle(Theme.textPrimary)
                            .autocorrectionDisabled()
                            .textInputAutocapitalization(.characters)

                        if !searchText.isEmpty {
                            Button {
                                searchText = ""
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
                    if filteredTickers.isEmpty {
                        noResults
                    } else {
                        ScrollView {
                            LazyVStack(spacing: 6) {
                                ForEach(filteredTickers) { ticker in
                                    AddTickerRowView(ticker: ticker) {
                                        withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                                            addedSymbols.insert(ticker.symbol)
                                            viewModel.addTicker(ticker)
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
        }
    }

    private var noResults: some View {
        VStack(spacing: 12) {
            Spacer()
            Image(systemName: "magnifyingglass")
                .font(.system(size: 36))
                .foregroundStyle(Theme.textTertiary)
            Text(searchText.isEmpty ? "All assets added" : "No results found")
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(Theme.textSecondary)
            Text(searchText.isEmpty ? "You've added all available assets" : "Try a different search term")
                .font(.system(size: 13))
                .foregroundStyle(Theme.textTertiary)
            Spacer()
        }
    }
}

// MARK: - Add Ticker Row

struct AddTickerRowView: View {
    let ticker: Ticker
    let onAdd: () -> Void
    @State private var isPressed = false

    var body: some View {
        HStack(spacing: 14) {
            // Type icon
            ZStack {
                Circle()
                    .fill(typeColor.opacity(0.15))
                    .frame(width: 40, height: 40)
                Image(systemName: ticker.assetType.icon)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundStyle(typeColor)
            }

            // Info
            VStack(alignment: .leading, spacing: 3) {
                Text(ticker.symbol)
                    .font(.system(size: 16, weight: .bold, design: .rounded))
                    .foregroundStyle(Theme.textPrimary)
                Text(ticker.name)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(Theme.textSecondary)
                    .lineLimit(1)
            }

            Spacer()

            // Price
            VStack(alignment: .trailing, spacing: 3) {
                Text(Theme.formatPrice(ticker.currentPrice))
                    .font(.system(size: 14, weight: .semibold, design: .rounded))
                    .foregroundStyle(Theme.textPrimary)
                Text(ticker.assetType.rawValue)
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(Theme.textTertiary)
            }

            // Add button
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
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .cardStyle()
    }

    private var typeColor: Color {
        switch ticker.assetType {
        case .stock: return Theme.benchmark
        case .crypto: return Color.orange
        case .etf: return Theme.accentSecondary
        }
    }
}

#Preview {
    AddTickerView()
        .environment(StockViewModel())
        .preferredColorScheme(.dark)
}
