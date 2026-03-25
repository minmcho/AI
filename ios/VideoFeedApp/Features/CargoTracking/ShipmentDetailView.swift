import SwiftUI

// MARK: - ViewModel

@MainActor
final class ShipmentDetailViewModel: ObservableObject {
    @Published var shipment: Shipment?
    @Published var events: [TrackingEvent] = []
    @Published var cargoItems: [CargoItem] = []
    @Published var isLoading = false

    private let api = CargoAPIClient.shared

    func load(shipmentId: String) {
        isLoading = true
        Task {
            do {
                async let sTask = api.fetchShipment(id: shipmentId)
                async let eTask = api.fetchEvents(shipmentId: shipmentId)
                async let iTask = api.fetchCargoItems(shipmentId: shipmentId)
                let (s, e, items) = try await (sTask, eTask, iTask)
                shipment   = s
                events     = e
                cargoItems = items
            } catch {}
            isLoading = false
        }
    }
}

// MARK: - View

struct ShipmentDetailView: View {
    let shipmentId: String
    @StateObject private var vm = ShipmentDetailViewModel()
    @State private var selectedTab = 0

    var body: some View {
        Group {
            if vm.isLoading {
                ProgressView()
            } else if let shipment = vm.shipment {
                VStack(spacing: 0) {
                    ShipmentHeaderCard(shipment: shipment)

                    Picker("Tab", selection: $selectedTab) {
                        Text("Timeline").tag(0)
                        Text("Cargo (\(vm.cargoItems.count))").tag(1)
                    }
                    .pickerStyle(.segmented)
                    .padding()

                    if selectedTab == 0 {
                        TrackingTimelineView(events: vm.events)
                    } else {
                        CargoItemListView(items: vm.cargoItems)
                    }
                }
            }
        }
        .navigationTitle(vm.shipment?.trackingNumber ?? "Loading…")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear { vm.load(shipmentId: shipmentId) }
    }
}

struct ShipmentHeaderCard: View {
    let shipment: Shipment

    var statusColor: Color {
        Color(hex: shipment.statusColor) ?? .blue
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("Status")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Spacer()
                StatusBadge(
                    text: shipment.status.replacingOccurrences(of: "_", with: " ").capitalized,
                    color: statusColor
                )
            }
            Divider()
            HStack(spacing: 24) {
                if let carrier = shipment.carrier {
                    LabeledValue(label: "Carrier", value: carrier)
                }
                LabeledValue(label: "Priority",
                             value: shipment.priority.capitalized)
                if let eta = shipment.estimatedArrival {
                    LabeledValue(label: "ETA", value: String(eta.prefix(10)))
                }
            }
        }
        .padding()
        .background(Color(.secondarySystemBackground))
    }
}

struct LabeledValue: View {
    let label: String
    let value: String

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(label)
                .font(.caption2)
                .foregroundStyle(.secondary)
            Text(value)
                .font(.subheadline.bold())
        }
    }
}

// MARK: - Tracking Timeline

struct TrackingTimelineView: View {
    let events: [TrackingEvent]

    var body: some View {
        if events.isEmpty {
            ContentUnavailableView("No Events", systemImage: "map.fill",
                description: Text("No tracking events recorded yet."))
        } else {
            List(events) { event in
                HStack(alignment: .top, spacing: 12) {
                    VStack {
                        Circle()
                            .fill(Color.blue)
                            .frame(width: 10, height: 10)
                        if event.id != events.last?.id {
                            Rectangle()
                                .fill(Color.blue.opacity(0.3))
                                .frame(width: 2)
                                .frame(maxHeight: .infinity)
                        }
                    }
                    VStack(alignment: .leading, spacing: 4) {
                        Text(event.eventType
                            .replacingOccurrences(of: "_", with: " ")
                            .capitalized)
                            .font(.subheadline.bold())
                        if let name = event.locationName {
                            Text(name)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        if let desc = event.description {
                            Text(desc)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        Text(String(event.occurredAt.prefix(16)).replacingOccurrences(of: "T", with: " "))
                            .font(.caption2)
                            .foregroundStyle(.tertiary)
                    }
                    .padding(.bottom, 12)
                }
                .listRowSeparator(.hidden)
            }
            .listStyle(.plain)
        }
    }
}

// MARK: - Cargo Items

struct CargoItemListView: View {
    let items: [CargoItem]

    var body: some View {
        if items.isEmpty {
            ContentUnavailableView("No Items", systemImage: "cube.box",
                description: Text("No cargo items added to this shipment."))
        } else {
            List(items) { item in
                CargoItemRow(item: item)
            }
        }
    }
}

struct CargoItemRow: View {
    let item: CargoItem

    var defectColor: Color {
        guard let score = item.defectScore else { return .clear }
        if score > 0.75 { return .red }
        if score > 0.5  { return .orange }
        return .clear
    }

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(item.description)
                    .font(.subheadline.bold())
                HStack(spacing: 8) {
                    if let sku = item.sku {
                        Text("SKU: \(sku)").font(.caption).foregroundStyle(.secondary)
                    }
                    Text("Qty: \(item.quantity)").font(.caption).foregroundStyle(.secondary)
                    if let cat = item.category {
                        Text(cat)
                            .font(.caption2.bold())
                            .foregroundStyle(.blue)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color.blue.opacity(0.1))
                            .clipShape(Capsule())
                    }
                }
                if let score = item.defectScore, score > 0 {
                    HStack(spacing: 4) {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .font(.caption2)
                            .foregroundStyle(.orange)
                        Text("Defect risk: \(Int(score * 100))%")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                }
            }
            Spacer()
            if item.defectScore ?? 0 > 0.5 {
                Image(systemName: "exclamationmark.circle.fill")
                    .foregroundStyle(defectColor)
            }
        }
    }
}

#Preview {
    NavigationStack {
        ShipmentDetailView(shipmentId: "demo-id")
    }
}
