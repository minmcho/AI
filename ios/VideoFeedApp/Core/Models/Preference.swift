import Foundation

// MARK: - User Preferences

struct UserPreference: Codable {
    var musicGenres:     [String] = []
    var musicMoods:      [String] = []
    var videoTypes:      [String] = []
    var countries:       [String] = []
    var platforms:       [SocialPlatform] = SocialPlatform.allCases
    var preferDubbed:    Bool = false
    var preferSubtitles: Bool = false
    var autoplayMuted:   Bool = false

    enum CodingKeys: String, CodingKey {
        case musicGenres = "music_genres"
        case musicMoods = "music_moods"
        case videoTypes = "video_types"
        case countries, platforms
        case preferDubbed = "prefer_dubbed"
        case preferSubtitles = "prefer_subtitles"
        case autoplayMuted = "autoplay_muted"
    }
}

// MARK: - Social Platforms

enum SocialPlatform: String, CaseIterable, Codable, Identifiable {
    case youtube, tiktok, instagram, spotify, soundcloud
    var id: String { rawValue }
    var label: String {
        switch self {
        case .youtube: return "YouTube"
        case .tiktok: return "TikTok"
        case .instagram: return "Instagram"
        case .spotify: return "Spotify"
        case .soundcloud: return "SoundCloud"
        }
    }
    var icon: String {
        switch self {
        case .youtube: return "play.rectangle.fill"
        case .tiktok: return "music.note.tv.fill"
        case .instagram: return "camera.fill"
        case .spotify: return "music.note.list"
        case .soundcloud: return "waveform"
        }
    }
    var color: String {
        switch self {
        case .youtube: return "FF0000"
        case .tiktok: return "010101"
        case .instagram: return "E1306C"
        case .spotify: return "1DB954"
        case .soundcloud: return "FF5500"
        }
    }
}

// MARK: - Search Result

struct SearchResultItem: Identifiable, Codable {
    let id: String
    let platform: String
    let itemType: String
    let externalID: String
    let title: String
    let authorName: String
    let thumbnailURL: URL?
    let mediaURL: URL?
    let duration: TimeInterval
    let viewCount: Int
    let likeCount: Int
    let country: String
    let tags: [String]

    var isMusicItem: Bool { itemType == "music" || itemType == "social_music" }

    enum CodingKeys: String, CodingKey {
        case platform
        case itemType = "item_type"
        case externalID = "external_id"
        case title
        case authorName = "author_name"
        case thumbnailURL = "thumbnail_url"
        case mediaURL = "media_url"
        case duration
        case viewCount = "view_count"
        case likeCount = "like_count"
        case country, tags
    }

    // Synthesise id from platform+externalID
    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        platform    = try c.decode(String.self, forKey: .platform)
        itemType    = try c.decode(String.self, forKey: .itemType)
        externalID  = try c.decode(String.self, forKey: .externalID)
        title       = try c.decode(String.self, forKey: .title)
        authorName  = try c.decode(String.self, forKey: .authorName)
        thumbnailURL = try? c.decode(URL.self, forKey: .thumbnailURL)
        mediaURL     = try? c.decode(URL.self, forKey: .mediaURL)
        duration    = (try? c.decode(Double.self, forKey: .duration)) ?? 0
        viewCount   = (try? c.decode(Int.self, forKey: .viewCount)) ?? 0
        likeCount   = (try? c.decode(Int.self, forKey: .likeCount)) ?? 0
        country     = (try? c.decode(String.self, forKey: .country)) ?? ""
        tags        = (try? c.decode([String].self, forKey: .tags)) ?? []
        id = "\(platform)_\(externalID)"
    }
}

// MARK: - Favorite

struct FavoriteItem: Identifiable, Codable {
    let id: String
    let itemType: String
    let platform: String?
    let externalID: String?
    let title: String?
    let thumbnailURL: URL?
    let mediaURL: URL?
    let authorName: String?
    let duration: TimeInterval?
    let createdAt: Date

    var isMusicItem: Bool { itemType == "music" || itemType == "social_music" }

    enum CodingKeys: String, CodingKey {
        case id
        case itemType = "item_type"
        case platform
        case externalID = "external_id"
        case title
        case thumbnailURL = "thumbnail_url"
        case mediaURL = "media_url"
        case authorName = "author_name"
        case duration
        case createdAt = "created_at"
    }
}

// MARK: - Preference Options (from API)

struct PreferenceOptions: Codable {
    let musicGenres: [String]
    let musicMoods:  [String]
    let videoTypes:  [String]
    let platforms:   [String]
    let countries:   [CountryOption]

    enum CodingKeys: String, CodingKey {
        case musicGenres = "music_genres"
        case musicMoods  = "music_moods"
        case videoTypes  = "video_types"
        case platforms, countries
    }
}

struct CountryOption: Codable, Identifiable {
    let code: String
    let name: String
    let flag: String
    var id: String { code }
}
