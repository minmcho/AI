import Foundation

// MARK: - Models

struct Shipment: Codable, Identifiable {
    let id: String
    let trackingNumber: String
    let status: String
    let priority: String
    let originId: String
    let destinationId: String
    let departmentId: String?
    let carrier: String?
    let serviceType: String?
    let estimatedArrival: String?
    let actualArrival: String?
    let totalWeightKg: Double?
    let totalVolumeM3: Double?
    let notes: String?
    let createdAt: String
    let updatedAt: String

    enum CodingKeys: String, CodingKey {
        case id
        case trackingNumber   = "tracking_number"
        case status, priority
        case originId         = "origin_id"
        case destinationId    = "destination_id"
        case departmentId     = "department_id"
        case carrier, serviceType = "service_type"
        case estimatedArrival = "estimated_arrival"
        case actualArrival    = "actual_arrival"
        case totalWeightKg    = "total_weight_kg"
        case totalVolumeM3    = "total_volume_m3"
        case notes, createdAt = "created_at", updatedAt = "updated_at"
    }

    var statusColor: String {
        switch status.lowercased() {
        case "in_transit":  return "#42A5F5"
        case "delivered":   return "#26A69A"
        case "at_customs":  return "#EF5350"
        case "arrived":     return "#66BB6A"
        case "exception":   return "#EF5350"
        case "cancelled":   return "#9E9E9E"
        default:            return "#FFA726"
        }
    }
}

struct TrackingEvent: Codable, Identifiable {
    let id: String
    let shipmentId: String
    let eventType: String
    let locationId: String?
    let locationName: String?
    let latitude: Double?
    let longitude: Double?
    let description: String?
    let occurredAt: String

    enum CodingKeys: String, CodingKey {
        case id
        case shipmentId   = "shipment_id"
        case eventType    = "event_type"
        case locationId   = "location_id"
        case locationName = "location_name"
        case latitude, longitude, description
        case occurredAt   = "occurred_at"
    }
}

struct CargoItem: Codable, Identifiable {
    let id: String
    let shipmentId: String
    let sku: String?
    let description: String
    let quantity: Int
    let weightKg: Double?
    let volumeM3: Double?
    let valueUsd: Double?
    let category: String?
    let subCategory: String?
    let clusterId: Int?
    let defectScore: Double?
    let createdAt: String

    enum CodingKeys: String, CodingKey {
        case id
        case shipmentId  = "shipment_id"
        case sku, description, quantity
        case weightKg    = "weight_kg"
        case volumeM3    = "volume_m3"
        case valueUsd    = "value_usd"
        case category
        case subCategory = "sub_category"
        case clusterId   = "cluster_id"
        case defectScore = "defect_score"
        case createdAt   = "created_at"
    }
}

struct InventoryItem: Codable, Identifiable {
    let id: String
    let locationId: String
    let departmentId: String?
    let sku: String
    let description: String?
    let quantity: Int
    let reorderPoint: Int?
    let maxStock: Int?
    let binLocation: String?
    let category: String?
    let subCategory: String?
    let clusterId: Int?
    let updatedAt: String

    enum CodingKeys: String, CodingKey {
        case id
        case locationId   = "location_id"
        case departmentId = "department_id"
        case sku, description, quantity
        case reorderPoint = "reorder_point"
        case maxStock     = "max_stock"
        case binLocation  = "bin_location"
        case category
        case subCategory  = "sub_category"
        case clusterId    = "cluster_id"
        case updatedAt    = "updated_at"
    }

    var isLowStock: Bool {
        guard let rp = reorderPoint else { return false }
        return quantity <= rp
    }
}

struct DashboardStats: Codable {
    let activeShipments: Int
    let deliveredToday: Int
    let pendingAlerts: Int
    let defectsDetected: Int
    let lowStockItems: Int

    enum CodingKeys: String, CodingKey {
        case activeShipments  = "active_shipments"
        case deliveredToday   = "delivered_today"
        case pendingAlerts    = "pending_alerts"
        case defectsDetected  = "defects_detected"
        case lowStockItems    = "low_stock_items"
    }
}

struct DefectResult: Codable {
    let defectFound: Bool
    let defectType: String
    let severity: String
    let confidence: Double
    let description: String
    let recommendedAction: String
    let reasoning: String?
    let modelVersion: String
    let latencyMs: Int
    let cacheReadTokens: Int

    enum CodingKeys: String, CodingKey {
        case defectFound      = "defect_found"
        case defectType       = "defect_type"
        case severity, confidence, description
        case recommendedAction = "recommended_action"
        case reasoning
        case modelVersion     = "model_version"
        case latencyMs        = "latency_ms"
        case cacheReadTokens  = "cache_read_tokens"
    }
}

// MARK: - Response wrappers

struct ShipmentsResponse: Codable {
    let shipments: [Shipment]
    let count: Int
}

struct InventoryResponse: Codable {
    let inventory: [InventoryItem]
    let count: Int
}

struct EventsResponse: Codable {
    let events: [TrackingEvent]
}

struct ItemsResponse: Codable {
    let items: [CargoItem]
}

// MARK: - API Client

@MainActor
final class CargoAPIClient: ObservableObject {
    static let shared = CargoAPIClient()

    private let baseURL: String
    private let decoder: JSONDecoder

    init() {
        baseURL = ProcessInfo.processInfo.environment["GO_API_URL"]
            ?? "http://localhost:8080"
        decoder = JSONDecoder()
    }

    // MARK: Dashboard

    func fetchStats(departmentId: String? = nil) async throws -> DashboardStats {
        var url = "\(baseURL)/api/v1/dashboard/stats"
        if let d = departmentId { url += "?department_id=\(d)" }
        return try await get(url: url)
    }

    // MARK: Shipments

    func fetchShipments(status: String? = nil, departmentId: String? = nil) async throws -> [Shipment] {
        var components = URLComponents(string: "\(baseURL)/api/v1/shipments")!
        var items: [URLQueryItem] = []
        if let s = status       { items.append(.init(name: "status",        value: s)) }
        if let d = departmentId { items.append(.init(name: "department_id", value: d)) }
        if !items.isEmpty { components.queryItems = items }
        let response: ShipmentsResponse = try await get(url: components.url!.absoluteString)
        return response.shipments
    }

    func fetchShipment(id: String) async throws -> Shipment {
        return try await get(url: "\(baseURL)/api/v1/shipments/\(id)")
    }

    func fetchShipmentByTracking(_ number: String) async throws -> Shipment {
        return try await get(url: "\(baseURL)/api/v1/shipments/track/\(number)")
    }

    func fetchEvents(shipmentId: String) async throws -> [TrackingEvent] {
        let r: EventsResponse = try await get(url: "\(baseURL)/api/v1/shipments/\(shipmentId)/events")
        return r.events
    }

    func fetchCargoItems(shipmentId: String) async throws -> [CargoItem] {
        let r: ItemsResponse = try await get(url: "\(baseURL)/api/v1/shipments/\(shipmentId)/items")
        return r.items
    }

    // MARK: Inventory

    func fetchInventory(locationId: String? = nil, belowReorder: Bool = false) async throws -> [InventoryItem] {
        var components = URLComponents(string: "\(baseURL)/api/v1/inventory")!
        var items: [URLQueryItem] = []
        if let l = locationId { items.append(.init(name: "location_id",   value: l)) }
        if belowReorder        { items.append(.init(name: "below_reorder", value: "true")) }
        if !items.isEmpty { components.queryItems = items }
        let r: InventoryResponse = try await get(url: components.url!.absoluteString)
        return r.inventory
    }

    // MARK: Defect detection

    func detectDefect(imageUrl: String, itemContext: [String: String] = [:]) async throws -> DefectResult {
        var body: [String: Any] = ["image_url": imageUrl, "persist": false]
        if !itemContext.isEmpty { body["item_context"] = itemContext }
        return try await post(url: "\(baseURL)/api/v1/ml/defect-detect", body: body)
    }

    // MARK: Internals

    private func get<T: Decodable>(url: String) async throws -> T {
        guard let u = URL(string: url) else { throw URLError(.badURL) }
        let (data, _) = try await URLSession.shared.data(from: u)
        return try decoder.decode(T.self, from: data)
    }

    private func post<T: Decodable>(url: String, body: [String: Any]) async throws -> T {
        guard let u = URL(string: url) else { throw URLError(.badURL) }
        var req = URLRequest(url: u)
        req.httpMethod = "POST"
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        req.httpBody = try JSONSerialization.data(withJSONObject: body)
        let (data, _) = try await URLSession.shared.data(for: req)
        return try decoder.decode(T.self, from: data)
    }
}
