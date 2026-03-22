import Foundation
import SwiftUI

// MARK: - Mood

struct Mood: Identifiable, Decodable {
    let id: String
    let emoji: String
    let label: String
    let color: String   // hex string e.g. "#FF4500"

    var swiftUIColor: Color {
        Color(hex: color) ?? .white
    }
}

// MARK: - Challenge

struct Challenge: Identifiable, Decodable {
    let id: String
    let title: String
    let description: String?
    let hashtag: String
    let category: String
    let thumbnailURL: URL?
    let participantCount: Int
    let viewCount: Int
    let isFeatured: Bool
    let endsAt: Date?
    let creatorUsername: String?
    let creatorAvatar: URL?

    enum CodingKeys: String, CodingKey {
        case id, title, description, hashtag, category
        case thumbnailURL     = "thumbnail_url"
        case participantCount = "participant_count"
        case viewCount        = "view_count"
        case isFeatured       = "is_featured"
        case endsAt           = "ends_at"
        case creatorUsername  = "creator_username"
        case creatorAvatar    = "creator_avatar"
    }
}

struct LeaderboardEntry: Identifiable, Decodable {
    let rank: Int
    let username: String
    let avatarURL: URL?
    let videoID: String?
    let likes: Int
    var id: String { "\(rank)_\(username)" }

    enum CodingKeys: String, CodingKey {
        case rank, username, likes
        case avatarURL = "avatar_url"
        case videoID   = "video_id"
    }
}

// MARK: - Streak & XP

struct StreakData: Decodable {
    let streakDays:    Int
    let longestStreak: Int
    let totalXP:       Int
    let level:         Int
    let levelTitle:    String
    let badges:        [String]
    let nextLevelXP:   Int
    let xpProgress:    Double
    let lastActive:    String

    enum CodingKeys: String, CodingKey {
        case streakDays    = "streak_days"
        case longestStreak = "longest_streak"
        case totalXP       = "total_xp"
        case level, badges
        case levelTitle    = "level_title"
        case nextLevelXP   = "next_level_xp"
        case xpProgress    = "xp_progress"
        case lastActive    = "last_active"
    }
}

struct BadgeDef: Decodable {
    let label: String
    let emoji: String
}

// MARK: - Vibe Match

struct VibeMatch: Identifiable, Decodable {
    let profileID:    String
    let username:     String
    let avatarURL:    URL?
    let similarity:   Double
    let similarityPct: Int
    let sharedGenres: [String]
    let totalXP:      Int
    let badges:       [String]
    var id: String { profileID }

    enum CodingKeys: String, CodingKey {
        case profileID      = "profile_id"
        case username
        case avatarURL      = "avatar_url"
        case similarity
        case similarityPct  = "similarity_pct"
        case sharedGenres   = "shared_genres"
        case totalXP        = "total_xp"
        case badges
    }
}

// MARK: - Study Session

struct StudyStats: Decodable {
    let totalSessions:         Int
    let totalMinutes:          Int
    let totalHours:            Double
    let totalPomodoros:        Int
    let bestSessionPomodoros:  Int
    let subjects:              [String]

    enum CodingKeys: String, CodingKey {
        case totalSessions        = "total_sessions"
        case totalMinutes         = "total_minutes"
        case totalHours           = "total_hours"
        case totalPomodoros       = "total_pomodoros"
        case bestSessionPomodoros = "best_session_pomodoros"
        case subjects
    }
}

// MARK: - Color hex helper

extension Color {
    init?(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        guard Scanner(string: hex).scanHexInt64(&int) else { return nil }
        let r = Double((int >> 16) & 0xFF) / 255
        let g = Double((int >> 8)  & 0xFF) / 255
        let b = Double(int         & 0xFF) / 255
        self.init(red: r, green: g, blue: b)
    }
}
