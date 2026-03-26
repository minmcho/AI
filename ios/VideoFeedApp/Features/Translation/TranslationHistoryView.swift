import SwiftUI

struct TranslationHistoryView: View {
    @Bindable var vm: TranslationViewModel

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            if vm.history.isEmpty {
                emptyState
            } else {
                historyList
            }
        }
        .navigationTitle("History")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .toolbar {
            if !vm.history.isEmpty {
                ToolbarItem(placement: .destructiveAction) {
                    Button("Clear All", role: .destructive) { vm.clearHistory() }
                        .foregroundStyle(.red)
                }
            }
        }
    }

    private var historyList: some View {
        List {
            ForEach(vm.history) { item in
                Button { vm.restoreFromHistory(item) } label: {
                    HistoryRowView(item: item)
                }
                .listRowBackground(Color(.systemGray6).opacity(0.12))
                .listRowSeparatorTint(.white.opacity(0.08))
            }
            .onDelete { offsets in vm.deleteHistoryItems(at: offsets) }
        }
        .listStyle(.plain)
        .scrollContentBackground(.hidden)
    }

    private var emptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "clock.arrow.circlepath")
                .font(.system(size: 56))
                .foregroundStyle(.white.opacity(0.2))
            Text("No translations yet")
                .foregroundStyle(.white.opacity(0.4))
                .font(.subheadline)
        }
    }
}

private struct HistoryRowView: View {
    let item: TranslationHistoryItem

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 6) {
                Text(item.sourceLang.flag + " " + item.sourceLang.name)
                Image(systemName: "arrow.right")
                Text(item.targetLang.flag + " " + item.targetLang.name)
                Spacer()
                Text(item.createdAt, style: .relative)
            }
            .font(.caption)
            .foregroundStyle(.white.opacity(0.5))

            Text(item.sourceText)
                .font(.subheadline)
                .foregroundStyle(.white)
                .lineLimit(2)

            Text(item.translatedText)
                .font(.subheadline)
                .foregroundStyle(.cyan)
                .lineLimit(2)
        }
        .padding(.vertical, 4)
    }
}
