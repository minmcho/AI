import Foundation

struct Video: Identifiable, Codable, Hashable {
    let id: String
    let url: URL
    let thumbnailURL: URL
    let author: Author
    let caption: String
    var likes: Int
    var comments: Int
    var shares: Int
    let duration: TimeInterval
    let tags: [String]
    let mixTrackURL: URL?
    let createdAt: Date

    struct Author: Codable, Hashable {
        let id: String
        let username: String
        let avatarURL: URL?
    }

    enum CodingKeys: String, CodingKey {
        case id, url, caption, likes, comments, shares, duration, tags
        case thumbnailURL = "thumbnail"
        case author = "profiles"
        case mixTrackURL = "mix_track_url"
        case createdAt = "created_at"
    }
}

struct AgentJob: Identifiable, Codable {
    let id: String
    var status: JobStatus
    var result: String?
    var error: String?
    let jobType: JobType
    let createdAt: Date

    enum JobStatus: String, Codable { case pending, running, completed, failed }
    enum JobType: String, Codable { case transcription, translation, tts, music, videoEdit = "video_edit" }
}

struct DJSettings {
    var playbackSpeed: Float = 1.0
    var preservePitch: Bool = true
    var autoMixEnabled: Bool = false
    var autoMixVolume: Float = 0.5
    var originalVolume: Float = 1.0
}

struct DubSettings {
    var targetLanguage: Language = .spanish
    var voicePersona: VoicePersona = .energetic
    var isActive: Bool = false
    var dubAudioURL: URL?
}

enum VoicePersona: String, CaseIterable, Identifiable {
    case energetic, calm, deepBass = "deep_bass", highPitch = "high_pitch", synthesizer, cloned
    var id: String { rawValue }
    var label: String {
        switch self {
        case .energetic: return "Energetic"
        case .calm: return "Calm"
        case .deepBass: return "Deep Bass"
        case .highPitch: return "High Pitch"
        case .synthesizer: return "Synthesizer"
        case .cloned: return "Cloned Voice"
        }
    }
    var icon: String {
        switch self {
        case .energetic: return "bolt.fill"
        case .calm: return "leaf.fill"
        case .deepBass: return "waveform.path"
        case .highPitch: return "waveform"
        case .synthesizer: return "cpu.fill"
        case .cloned: return "person.wave.2.fill"
        }
    }
}

enum Language: String, CaseIterable, Identifiable {
    case spanish = "es", japanese = "ja", thai = "th", french = "fr"
    case german = "de", portuguese = "pt", korean = "ko", chinese = "zh"
    case arabic = "ar", hindi = "hi"
    var id: String { rawValue }
    var label: String {
        Locale.current.localizedString(forLanguageCode: rawValue) ?? rawValue.uppercased()
    }
    var flag: String {
        switch self {
        case .spanish: return "🇪🇸"
        case .japanese: return "🇯🇵"
        case .thai: return "🇹🇭"
        case .french: return "🇫🇷"
        case .german: return "🇩🇪"
        case .portuguese: return "🇧🇷"
        case .korean: return "🇰🇷"
        case .chinese: return "🇨🇳"
        case .arabic: return "🇸🇦"
        case .hindi: return "🇮🇳"
        }
    }
}
