import SwiftUI

// MARK: - ViewModel

@MainActor
final class InventoryViewModel: ObservableObject {
    @Published var items: [InventoryItem] = []
    @Published var isLoading = false
    @Published var showLowStockOnly = false
    @Published var searchQuery = ""

    private let api = CargoAPIClient.shared

    var filtered: [InventoryItem] {
        items.filter { item in
            (searchQuery.isEmpty ||
             item.sku.localizedCaseInsensitiveContains(searchQuery) ||
             item.description?.localizedCaseInsensitiveContains(searchQuery) == true)
            && (!showLowStockOnly || item.isLowStock)
        }
    }

    func load(locationId: String? = nil) {
        isLoading = true
        Task {
            do {
                items = try await api.fetchInventory(
                    locationId: locationId,
                    belowReorder: false
                )
            } catch {}
            isLoading = false
        }
    }
}

// MARK: - View

struct InventoryView: View {
    @StateObject private var vm = InventoryViewModel()

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Search
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundStyle(.secondary)
                    TextField("Search SKU or description…", text: $vm.searchQuery)
                }
                .padding(10)
                .background(Color(.secondarySystemBackground))
                .clipShape(RoundedRectangle(cornerRadius: 10))
                .padding([.horizontal, .top])

                // Filter toggle
                Toggle("Low Stock Only", isOn: $vm.showLowStockOnly)
                    .font(.subheadline)
                    .padding(.horizontal)
                    .padding(.top, 8)

                if vm.isLoading {
                    ProgressView().padding()
                } else {
                    List(vm.filtered) { item in
                        InventoryRowView(item: item)
                    }
                    .listStyle(.plain)
                    .overlay {
                        if vm.filtered.isEmpty {
                            ContentUnavailableView(
                                "No items found",
                                systemImage: "cube.box",
                                description: Text(vm.searchQuery.isEmpty
                                    ? "Inventory is empty"
                                    : "No match for "\(vm.searchQuery)"")
                            )
                        }
                    }
                }
            }
            .navigationTitle("Inventory")
            .onAppear { vm.load() }
        }
    }
}

struct InventoryRowView: View {
    let item: InventoryItem

    var stockFraction: Double {
        guard let max = item.maxStock, max > 0 else { return -1 }
        return Double(item.quantity) / Double(max)
    }

    var stockBarColor: Color {
        if item.isLowStock  { return .red }
        if stockFraction < 0.3 { return .orange }
        return .green
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(item.sku)
                        .font(.subheadline.bold())
                    if let desc = item.description {
                        Text(desc)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                    }
                }
                Spacer()
                VStack(alignment: .trailing, spacing: 2) {
                    Text("\(item.quantity)")
                        .font(.title3.bold())
                        .foregroundStyle(item.isLowStock ? .red : .primary)
                    Text("units")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }

            // Stock level bar
            if stockFraction >= 0 {
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 3)
                            .fill(Color(.systemFill))
                            .frame(height: 5)
                        RoundedRectangle(cornerRadius: 3)
                            .fill(stockBarColor)
                            .frame(width: geo.size.width * stockFraction.clamped(to: 0...1), height: 5)
                    }
                }
                .frame(height: 5)
            }

            HStack(spacing: 6) {
                if let cat = item.category {
                    Tag(text: cat, color: .blue)
                }
                if let bin = item.binLocation {
                    Tag(text: "Bin \(bin)", color: .purple)
                }
                if let cid = item.clusterId {
                    Tag(text: "C\(cid)", color: .orange)
                }
                if item.isLowStock {
                    Tag(text: "LOW STOCK", color: .red)
                }
            }
        }
        .padding(.vertical, 4)
    }
}

struct Tag: View {
    let text: String
    let color: Color

    var body: some View {
        Text(text)
            .font(.caption2.bold())
            .foregroundStyle(color)
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .background(color.opacity(0.12))
            .clipShape(Capsule())
    }
}

extension Comparable {
    func clamped(to range: ClosedRange<Self>) -> Self {
        min(max(self, range.lowerBound), range.upperBound)
    }
}

#Preview { InventoryView() }
