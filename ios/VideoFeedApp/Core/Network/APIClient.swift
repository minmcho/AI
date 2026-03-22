import Foundation

enum APIError: LocalizedError {
    case invalidURL, badResponse(Int), decodingFailed(Error), serverError(String)
    var errorDescription: String? {
        switch self {
        case .invalidURL: return "Invalid URL"
        case .badResponse(let code): return "HTTP \(code)"
        case .decodingFailed(let e): return "Decode error: \(e)"
        case .serverError(let msg): return msg
        }
    }
}

actor APIClient {
    static let shared = APIClient()
    private let goBase = URL(string: ProcessInfo.processInfo.environment["GO_API_URL"] ?? "http://localhost:8080")!
    private let pyBase = URL(string: ProcessInfo.processInfo.environment["PY_API_URL"] ?? "http://localhost:8000")!

    private let session: URLSession = {
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 30
        config.waitsForConnectivity = true
        return URLSession(configuration: config)
    }()

    // MARK: - Generic Request

    func get<T: Decodable>(_ path: String, base: URL) async throws -> T {
        let url = base.appending(path: path)
        let (data, resp) = try await session.data(from: url)
        guard let http = resp as? HTTPURLResponse else { throw APIError.badResponse(0) }
        guard (200..<300).contains(http.statusCode) else { throw APIError.badResponse(http.statusCode) }
        return try JSONDecoder.iso8601.decode(T.self, from: data)
    }

    func post<B: Encodable, T: Decodable>(_ path: String, body: B, base: URL) async throws -> T {
        let url = base.appending(path: path)
        var req = URLRequest(url: url)
        req.httpMethod = "POST"
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        req.httpBody = try JSONEncoder.iso8601.encode(body)
        let (data, resp) = try await session.data(for: req)
        guard let http = resp as? HTTPURLResponse else { throw APIError.badResponse(0) }
        guard (200..<300).contains(http.statusCode) else { throw APIError.badResponse(http.statusCode) }
        return try JSONDecoder.iso8601.decode(T.self, from: data)
    }

    // MARK: - Go API (video feed, webhooks)

    func fetchFeedPage(_ page: Int, limit: Int = 5) async throws -> [Video] {
        try await get("/api/v1/videos?page=\(page)&limit=\(limit)", base: goBase)
    }

    func likeVideo(id: String) async throws {
        let _: EmptyResponse = try await post("/api/v1/videos/\(id)/like", body: EmptyBody(), base: goBase)
    }

    // MARK: - Python AI API (OpenClaw agents)

    func transcribeVideo(videoID: String) async throws -> AgentJob {
        try await post("/ai/transcribe", body: ["video_id": videoID], base: pyBase)
    }

    func dubVideo(videoID: String, language: String, persona: String) async throws -> AgentJob {
        let body = DubRequest(videoID: videoID, targetLanguage: language, voicePersona: persona)
        return try await post("/ai/dub", body: body, base: pyBase)
    }

    func generateMixTrack(videoID: String, style: String) async throws -> AgentJob {
        let body = MixRequest(videoID: videoID, style: style)
        return try await post("/ai/music", body: body, base: pyBase)
    }

    func pollJob(jobID: String) async throws -> AgentJob {
        try await get("/ai/jobs/\(jobID)", base: pyBase)
    }
}

// MARK: - Helpers

private struct EmptyBody: Encodable {}
private struct EmptyResponse: Decodable {}

private struct DubRequest: Encodable {
    let videoID: String
    let targetLanguage: String
    let voicePersona: String
    enum CodingKeys: String, CodingKey {
        case videoID = "video_id"
        case targetLanguage = "target_language"
        case voicePersona = "voice_persona"
    }
}

private struct MixRequest: Encodable {
    let videoID: String
    let style: String
    enum CodingKeys: String, CodingKey {
        case videoID = "video_id"
        case style
    }
}

extension JSONDecoder {
    static let iso8601: JSONDecoder = {
        let d = JSONDecoder()
        d.dateDecodingStrategy = .iso8601
        return d
    }()
}

extension JSONEncoder {
    static let iso8601: JSONEncoder = {
        let e = JSONEncoder()
        e.dateEncodingStrategy = .iso8601
        return e
    }()
}
