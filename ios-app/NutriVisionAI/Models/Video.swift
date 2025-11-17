//
//  Video.swift
//  NutriVision AI
//
//  Video recommendation models
//

import Foundation

// MARK: - Video

struct Video: Codable, Identifiable {
    let id: String  // Mapped from video_id
    let title: String
    let description: String?
    let thumbnailUrl: String
    let videoUrl: String
    let platform: VideoPlatform
    let duration: String?  // Changed from Int to String to match API
    let viewCount: Int?
    let likeCount: Int?
    let channelName: String?
    let channelUrl: String?
    let relevanceScore: Double?

    enum CodingKeys: String, CodingKey {
        case id = "video_id"  // API uses video_id
        case title, description
        case thumbnailUrl = "thumbnail_url"
        case videoUrl = "url"  // API uses url, not video_url
        case platform, duration
        case viewCount = "view_count"
        case likeCount = "like_count"
        case channelName = "channel_name"  // API uses channel_name
        case channelUrl = "channel_url"
        case relevanceScore = "relevance_score"
    }
}

enum VideoPlatform: String, Codable {
    case youtube = "youtube"
    case tiktok = "tiktok"
    case instagram = "instagram"
    case other = "other"

    var displayName: String {
        switch self {
        case .youtube: return "YouTube"
        case .tiktok: return "TikTok"
        case .instagram: return "Instagram"
        case .other: return "Other"
        }
    }

    var icon: String {
        switch self {
        case .youtube: return "play.rectangle.fill"
        case .tiktok: return "music.note"
        case .instagram: return "camera.fill"
        case .other: return "video.fill"
        }
    }

    var color: String {
        switch self {
        case .youtube: return "red"
        case .tiktok: return "pink"
        case .instagram: return "purple"
        case .other: return "blue"
        }
    }
}

// MARK: - Trending Videos Response

struct TrendingVideosResponse: Codable {
    let videos: [Video]
    let cuisine: String?
    let totalCount: Int

    enum CodingKeys: String, CodingKey {
        case videos, cuisine
        case totalCount = "total_count"
    }
}
