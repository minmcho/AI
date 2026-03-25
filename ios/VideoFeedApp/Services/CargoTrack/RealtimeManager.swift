import Foundation
import Combine

// MARK: - Realtime event

struct RealtimeEvent: Decodable {
    let type: String
    let payload: [String: AnyCodable]
    let timestamp: String
}

// AnyCodable shim for heterogeneous JSON payloads
struct AnyCodable: Codable {
    let value: Any
    init(_ value: Any) { self.value = value }
    init(from decoder: Decoder) throws {
        let c = try decoder.singleValueContainer()
        if let v = try? c.decode(Bool.self)   { value = v; return }
        if let v = try? c.decode(Int.self)    { value = v; return }
        if let v = try? c.decode(Double.self) { value = v; return }
        if let v = try? c.decode(String.self) { value = v; return }
        value = NSNull()
    }
    func encode(to encoder: Encoder) throws {
        var c = encoder.singleValueContainer()
        switch value {
        case let v as Bool:   try c.encode(v)
        case let v as Int:    try c.encode(v)
        case let v as Double: try c.encode(v)
        case let v as String: try c.encode(v)
        default:              try c.encodeNil()
        }
    }
}

// MARK: - WebSocket real-time manager

@MainActor
final class RealtimeManager: ObservableObject {
    static let shared = RealtimeManager()

    @Published var latestEvent: RealtimeEvent?
    @Published var isConnected = false

    private var task: URLSessionWebSocketTask?
    private let baseURL: String

    init() {
        baseURL = ProcessInfo.processInfo.environment["GO_API_URL"]
            ?? "http://localhost:8080"
    }

    func connect(departmentId: String? = nil, locationId: String? = nil) {
        disconnect()
        var wsURL = baseURL
            .replacingOccurrences(of: "http://", with: "ws://")
            .replacingOccurrences(of: "https://", with: "wss://")
        wsURL += "/ws"
        var params: [String] = []
        if let d = departmentId { params.append("department_id=\(d)") }
        if let l = locationId   { params.append("location_id=\(l)") }
        if !params.isEmpty { wsURL += "?" + params.joined(separator: "&") }

        guard let url = URL(string: wsURL) else { return }
        task = URLSession.shared.webSocketTask(with: url)
        task?.resume()
        isConnected = true
        receive()
    }

    func disconnect() {
        task?.cancel(with: .normalClosure, reason: nil)
        task = nil
        isConnected = false
    }

    private func receive() {
        task?.receive { [weak self] result in
            Task { @MainActor in
                switch result {
                case .success(let msg):
                    switch msg {
                    case .string(let text):
                        if let data = text.data(using: .utf8),
                           let event = try? JSONDecoder().decode(RealtimeEvent.self, from: data) {
                            self?.latestEvent = event
                        }
                    default: break
                    }
                    self?.receive()  // keep listening
                case .failure:
                    self?.isConnected = false
                }
            }
        }
    }

    // Periodic ping to keep connection alive
    func sendPing() {
        task?.sendPing { _ in }
    }
}
