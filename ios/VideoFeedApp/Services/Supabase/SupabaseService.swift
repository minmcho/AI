import Foundation

/// Thin wrapper around Supabase REST + Realtime APIs.
/// Uses URLSession directly to avoid adding the full Supabase Swift SDK as a package dependency
/// in this design document; swap for the official SDK in Xcode by adding:
///   .package(url: "https://github.com/supabase/supabase-swift", from: "2.0.0")
actor SupabaseService {
    private let url: URL
    private let anonKey: String
    private var realtimeTasks: [String: Task<Void, Never>] = [:]

    init() {
        let rawURL = ProcessInfo.processInfo.environment["SUPABASE_URL"] ?? "https://placeholder.supabase.co"
        self.url = URL(string: rawURL) ?? URL(string: "https://placeholder.supabase.co")!
        self.anonKey = ProcessInfo.processInfo.environment["SUPABASE_ANON_KEY"] ?? ""
    }

    private var headers: [String: String] {
        ["apikey": anonKey, "Authorization": "Bearer \(anonKey)", "Content-Type": "application/json"]
    }

    // MARK: - Video Feed

    func fetchFeed(page: Int, limit: Int = 5) async throws -> [Video] {
        let offset = page * limit
        var components = URLComponents(url: url.appending(path: "/rest/v1/videos"), resolvingAgainstBaseURL: false)!
        components.queryItems = [
            URLQueryItem(name: "select", value: "id,url,thumbnail,caption,likes,comments,shares,duration,tags,mix_track_url,created_at,profiles(id,username,avatar_url)"),
            URLQueryItem(name: "order", value: "created_at.desc"),
            URLQueryItem(name: "offset", value: "\(offset)"),
            URLQueryItem(name: "limit", value: "\(limit)"),
        ]
        var req = URLRequest(url: components.url!)
        headers.forEach { req.setValue($1, forHTTPHeaderField: $0) }
        let (data, _) = try await URLSession.shared.data(for: req)
        return try JSONDecoder.iso8601.decode([Video].self, from: data)
    }

    func likeVideo(id: String) async throws {
        let rpcURL = url.appending(path: "/rest/v1/rpc/increment_likes")
        var req = URLRequest(url: rpcURL)
        req.httpMethod = "POST"
        headers.forEach { req.setValue($1, forHTTPHeaderField: $0) }
        req.httpBody = try JSONEncoder.iso8601.encode(["video_id": id])
        _ = try await URLSession.shared.data(for: req)
    }

    // MARK: - Realtime Job Polling

    /// Polls agent_jobs table every 2s via Supabase REST until job completes or fails.
    func watchJob(id: String, onUpdate: @escaping (AgentJob) -> Void) {
        realtimeTasks[id] = Task {
            while !Task.isCancelled {
                if let job = try? await fetchJob(id: id) {
                    onUpdate(job)
                    if job.status == .completed || job.status == .failed { break }
                }
                try? await Task.sleep(for: .seconds(2))
            }
        }
    }

    func cancelWatch(id: String) {
        realtimeTasks[id]?.cancel()
        realtimeTasks.removeValue(forKey: id)
    }

    private func fetchJob(id: String) async throws -> AgentJob {
        var components = URLComponents(url: url.appending(path: "/rest/v1/agent_jobs"), resolvingAgainstBaseURL: false)!
        components.queryItems = [URLQueryItem(name: "id", value: "eq.\(id)"), URLQueryItem(name: "limit", value: "1")]
        var req = URLRequest(url: components.url!)
        headers.forEach { req.setValue($1, forHTTPHeaderField: $0) }
        let (data, _) = try await URLSession.shared.data(for: req)
        let jobs = try JSONDecoder.iso8601.decode([AgentJob].self, from: data)
        guard let job = jobs.first else { throw APIError.badResponse(404) }
        return job
    }
}
