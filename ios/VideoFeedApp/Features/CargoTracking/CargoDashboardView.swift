import SwiftUI

// MARK: - ViewModel

@MainActor
final class CargoDashboardViewModel: ObservableObject {
    @Published var stats: DashboardStats?
    @Published var recentShipments: [Shipment] = []
    @Published var isLoading = false
    @Published var error: String?

    private let api = CargoAPIClient.shared

    func load() {
        isLoading = true
        error = nil
        Task {
            do {
                async let statsTask     = api.fetchStats()
                async let shipmentsTask = api.fetchShipments()
                let (s, sh) = try await (statsTask, shipmentsTask)
                stats           = s
                recentShipments = Array(sh.prefix(8))
            } catch {
                self.error = error.localizedDescription
            }
            isLoading = false
        }
    }
}

// MARK: - View

struct CargoDashboardView: View {
    @StateObject private var vm = CargoDashboardViewModel()
    @StateObject private var rtManager = RealtimeManager.shared

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    if vm.isLoading {
                        ProgressView("Loading…")
                            .padding()
                    }
                    if let err = vm.error {
                        Text(err)
                            .foregroundStyle(.red)
                            .padding()
                    }
                    if let stats = vm.stats {
                        StatsGridView(stats: stats)
                    }

                    if !vm.recentShipments.isEmpty {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Recent Shipments")
                                .font(.headline)
                                .padding(.horizontal)
                            ForEach(vm.recentShipments) { shipment in
                                NavigationLink(destination: ShipmentDetailView(shipmentId: shipment.id)) {
                                    ShipmentRowView(shipment: shipment)
                                        .padding(.horizontal)
                                }
                            }
                        }
                    }

                    // Real-time badge
                    HStack {
                        Circle()
                            .fill(rtManager.isConnected ? .green : .gray)
                            .frame(width: 8, height: 8)
                        Text(rtManager.isConnected ? "Live" : "Offline")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    .padding(.top, 4)
                }
                .padding(.vertical)
            }
            .navigationTitle("CargoTrack")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: vm.load) {
                        Image(systemName: "arrow.clockwise")
                    }
                }
            }
            .onAppear {
                vm.load()
                rtManager.connect()
            }
            .onDisappear { rtManager.disconnect() }
            .onChange(of: rtManager.latestEvent) { _, event in
                guard let event else { return }
                if ["shipment_updated", "new_alert", "inventory_changed"].contains(event.type) {
                    vm.load()
                }
            }
        }
    }
}

// MARK: - Subviews

struct StatsGridView: View {
    let stats: DashboardStats

    var body: some View {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
            StatCard(
                icon: "shippingbox.fill",
                label: "Active Shipments",
                value: "\(stats.activeShipments)",
                color: .blue
            )
            StatCard(
                icon: "checkmark.circle.fill",
                label: "Delivered Today",
                value: "\(stats.deliveredToday)",
                color: .green
            )
            StatCard(
                icon: "exclamationmark.triangle.fill",
                label: "Pending Alerts",
                value: "\(stats.pendingAlerts)",
                color: stats.pendingAlerts > 0 ? .orange : .gray
            )
            StatCard(
                icon: "ant.fill",
                label: "Defects",
                value: "\(stats.defectsDetected)",
                color: stats.defectsDetected > 0 ? .red : .gray
            )
        }
        .padding(.horizontal)
    }
}

struct StatCard: View {
    let icon: String
    let label: String
    let value: String
    let color: Color

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundStyle(color)
                .frame(width: 36)
            VStack(alignment: .leading, spacing: 2) {
                Text(value)
                    .font(.title2.bold())
                    .foregroundStyle(color)
                Text(label)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer()
        }
        .padding(12)
        .background(.regularMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

struct ShipmentRowView: View {
    let shipment: Shipment

    var statusColor: Color {
        Color(hex: shipment.statusColor) ?? .blue
    }

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(shipment.trackingNumber)
                    .font(.subheadline.bold())
                Text([shipment.carrier, shipment.priority.capitalized]
                    .compactMap { $0 }
                    .joined(separator: " · "))
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            StatusBadge(text: shipment.status.replacingOccurrences(of: "_", with: " ").capitalized,
                        color: statusColor)
        }
        .padding(12)
        .background(.regularMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }
}

struct StatusBadge: View {
    let text: String
    let color: Color

    var body: some View {
        Text(text)
            .font(.caption.bold())
            .foregroundStyle(color)
            .padding(.horizontal, 10)
            .padding(.vertical, 4)
            .background(color.opacity(0.15))
            .clipShape(Capsule())
    }
}

extension Color {
    init?(hex: String) {
        var s = hex.trimmingCharacters(in: .whitespaces)
        if s.hasPrefix("#") { s.removeFirst() }
        guard s.count == 6, let n = UInt64(s, radix: 16) else { return nil }
        self.init(
            red:   Double((n >> 16) & 0xFF) / 255,
            green: Double((n >>  8) & 0xFF) / 255,
            blue:  Double( n        & 0xFF) / 255
        )
    }
}

#Preview {
    CargoDashboardView()
}
