import Foundation

/// Interfaces with the Python FastAPI layer that hosts OpenClaw agents
/// for video editing (eachlabs-video-edit) and music generation (ace-music).
actor OpenClawService {
    static let shared = OpenClawService()
    private let client = APIClient.shared

    // MARK: - Video Agent (eachlabs-video-edit skill)

    /// Triggers the OpenClaw video agent to apply lip-sync dubbing and subtitles.
    func editVideoWithDub(videoID: String, dubAudioURL: URL, language: String) async throws -> AgentJob {
        struct Payload: Encodable {
            let videoID: String
            let dubAudioURL: String
            let language: String
            enum CodingKeys: String, CodingKey {
                case videoID = "video_id"
                case dubAudioURL = "dub_audio_url"
                case language
            }
        }
        return try await client.post(
            "/ai/openclaw/video-edit",
            body: Payload(videoID: videoID, dubAudioURL: dubAudioURL.absoluteString, language: language),
            base: client.pyBase
        )
    }

    // MARK: - Music Agent (ace-music skill via claw.fm)

    /// Generates a background mix track using OpenClaw's ace-music skill.
    func generateMixTrack(videoID: String, genre: MusicGenre, mood: MusicMood) async throws -> AgentJob {
        struct Payload: Encodable {
            let videoID: String
            let genre: String
            let mood: String
            let skill: String
            enum CodingKeys: String, CodingKey {
                case videoID = "video_id"
                case genre, mood, skill
            }
        }
        return try await client.post(
            "/ai/openclaw/music",
            body: Payload(videoID: videoID, genre: genre.rawValue, mood: mood.rawValue, skill: "ace-music"),
            base: client.pyBase
        )
    }

    // MARK: - Job Polling

    func pollUntilDone(jobID: String, interval: Duration = .seconds(2)) async throws -> AgentJob {
        var job = try await client.pollJob(jobID: jobID)
        while job.status == .pending || job.status == .running {
            try await Task.sleep(for: interval)
            job = try await client.pollJob(jobID: jobID)
        }
        return job
    }
}

enum MusicGenre: String, CaseIterable {
    case electronic, hiphop, lofi, pop, ambient, edm
}

enum MusicMood: String, CaseIterable {
    case energetic, chill, dramatic, uplifting, dark
}

// APIClient.pyBase is nonisolated let — accessible directly without await.
