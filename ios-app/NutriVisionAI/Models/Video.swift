//
//  Video.swift
//  NutriVision AI
//
//  Video recommendation models
//

import Foundation

// MARK: - Video

struct Video: Codable, Identifiable {
    let id: String
    let title: String
    let description: String?
    let thumbnailUrl: String
    let videoUrl: String
    let platform: VideoPlatform
    let duration: Int?
    let viewCount: Int?
    let creator: String?
    let createdAt: String?

    enum CodingKeys: String, CodingKey {
        case id, title, description
        case thumbnailUrl = "thumbnail_url"
        case videoUrl = "video_url"
        case platform, duration
        case viewCount = "view_count"
        case creator
        case createdAt = "created_at"
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

// MARK: - Video Search Response

struct VideoSearchResponse: Codable {
    let videos: [Video]
    let total: Int
    let page: Int
    let perPage: Int

    enum CodingKeys: String, CodingKey {
        case videos, total, page
        case perPage = "per_page"
    }
}
