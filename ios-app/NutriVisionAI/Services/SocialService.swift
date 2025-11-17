//
//  SocialService.swift
//  NutriVision AI
//
//  Service for social feed and posting
//

import Foundation
import UIKit

class SocialService {
    private let apiClient = APIClient.shared

    // MARK: - Models

    struct SocialPost: Codable, Identifiable {
        let id: Int
        let userId: Int
        let caption: String
        let photoUrls: [String]
        let hashtags: [String]
        let recipeId: Int?
        let likesCount: Int
        let commentsCount: Int
        let isPublic: Bool
        let createdAt: String

        enum CodingKeys: String, CodingKey {
            case id
            case userId = "user_id"
            case caption
            case photoUrls = "photo_urls"
            case hashtags
            case recipeId = "recipe_id"
            case likesCount = "likes_count"
            case commentsCount = "comments_count"
            case isPublic = "is_public"
            case createdAt = "created_at"
        }
    }

    struct CreatePostRequest: Codable {
        let caption: String
        let photoUrls: [String]
        let hashtags: [String]
        let recipeId: Int?
        let isPublic: Bool

        enum CodingKeys: String, CodingKey {
            case caption
            case photoUrls = "photo_urls"
            case hashtags
            case recipeId = "recipe_id"
            case isPublic = "is_public"
        }
    }

    // MARK: - Get Social Feed

    func getSocialFeed(limit: Int = 20, offset: Int = 0) async throws -> [SocialPost] {
        return try await apiClient.request(
            endpoint: "\(Config.Endpoints.socialFeed)?limit=\(limit)&offset=\(offset)",
            method: "GET"
        )
    }

    // MARK: - Get My Posts

    func getMyPosts(limit: Int = 20) async throws -> [SocialPost] {
        return try await apiClient.request(
            endpoint: "/meals/social/my-posts?limit=\(limit)",
            method: "GET"
        )
    }

    // MARK: - Create Post

    func createPost(
        caption: String,
        imageData: Data,
        mealId: String? = nil,
        recipeId: String? = nil
    ) async throws -> SocialPost {
        // TODO: Upload image first and get URL
        // For now, use a placeholder
        let photoUrl = "https://example.com/photo.jpg"

        let request = CreatePostRequest(
            caption: caption,
            photoUrls: [photoUrl],
            hashtags: extractHashtags(from: caption),
            recipeId: recipeId.flatMap { Int($0) },
            isPublic: true
        )

        return try await apiClient.request(
            endpoint: "/meals/social",
            method: "POST",
            body: request
        )
    }

    // MARK: - Like Post

    func likePost(postId: Int) async throws {
        let _: EmptyResponse = try await apiClient.request(
            endpoint: "/meals/social/\(postId)/like",
            method: "POST"
        )
    }

    // MARK: - Delete Post

    func deletePost(postId: Int) async throws {
        let _: EmptyResponse = try await apiClient.request(
            endpoint: "/meals/social/\(postId)",
            method: "DELETE"
        )
    }

    // MARK: - Helper Methods

    private func extractHashtags(from text: String) -> [String] {
        let pattern = "#([a-zA-Z0-9_]+)"
        guard let regex = try? NSRegularExpression(pattern: pattern) else { return [] }

        let matches = regex.matches(in: text, range: NSRange(text.startIndex..., in: text))

        return matches.compactMap { match in
            guard let range = Range(match.range(at: 1), in: text) else { return nil }
            return String(text[range])
        }
    }
}
