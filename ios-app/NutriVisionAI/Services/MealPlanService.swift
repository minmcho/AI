//
//  MealPlanService.swift
//  NutriVision AI
//
//  Meal planning and journal service
//

import Foundation

class MealPlanService {
    private let apiClient = APIClient.shared

    // MARK: - Get Meal Plans

    func getMealPlans() async throws -> [MealPlan] {
        return try await apiClient.request(
            endpoint: Config.Endpoints.mealPlans,
            method: "GET"
        )
    }

    // MARK: - Generate Meal Plan

    struct GenerateMealPlanRequest: Codable {
        let days: Int
        let preferences: [String: String]?
    }

    func generateMealPlan(days: Int = 7, preferences: [String: String]? = nil) async throws -> MealPlan {
        let request = GenerateMealPlanRequest(days: days, preferences: preferences)

        return try await apiClient.request(
            endpoint: Config.Endpoints.generateMealPlan,
            method: "POST",
            body: request
        )
    }

    // MARK: - Get Meal Plan Details

    func getMealPlanDetails(id: Int) async throws -> MealPlan {
        return try await apiClient.request(
            endpoint: "\(Config.Endpoints.mealPlans)/\(id)",
            method: "GET"
        )
    }

    // MARK: - Update Meal Plan

    func updateMealPlan(id: Int, mealPlan: MealPlan) async throws -> MealPlan {
        return try await apiClient.request(
            endpoint: "\(Config.Endpoints.mealPlans)/\(id)",
            method: "PUT",
            body: mealPlan
        )
    }

    // MARK: - Delete Meal Plan

    func deleteMealPlan(id: Int) async throws {
        let _: EmptyResponse = try await apiClient.request(
            endpoint: "\(Config.Endpoints.mealPlans)/\(id)",
            method: "DELETE"
        )
    }

    // MARK: - Journal Entries

    func getJournalEntries(date: String? = nil) async throws -> [JournalEntry] {
        var endpoint = Config.Endpoints.journal
        if let date = date {
            endpoint += "?date=\(date)"
        }

        return try await apiClient.request(
            endpoint: endpoint,
            method: "GET"
        )
    }

    func createJournalEntry(_ entry: JournalEntry) async throws -> JournalEntry {
        return try await apiClient.request(
            endpoint: Config.Endpoints.journal,
            method: "POST",
            body: entry
        )
    }

    func updateJournalEntry(id: Int, entry: JournalEntry) async throws -> JournalEntry {
        return try await apiClient.request(
            endpoint: "\(Config.Endpoints.journal)/\(id)",
            method: "PUT",
            body: entry
        )
    }

    func deleteJournalEntry(id: Int) async throws {
        let _: EmptyResponse = try await apiClient.request(
            endpoint: "\(Config.Endpoints.journal)/\(id)",
            method: "DELETE"
        )
    }

    // MARK: - Social Feed

    struct SocialPost: Codable, Identifiable {
        let id: Int
        let userId: Int
        let username: String
        let content: String
        let imageUrl: String?
        let likes: Int
        let comments: Int
        let createdAt: String

        enum CodingKeys: String, CodingKey {
            case id
            case userId = "user_id"
            case username, content
            case imageUrl = "image_url"
            case likes, comments
            case createdAt = "created_at"
        }
    }

    func getSocialFeed(limit: Int = 20, offset: Int = 0) async throws -> [SocialPost] {
        return try await apiClient.request(
            endpoint: "\(Config.Endpoints.socialFeed)?limit=\(limit)&offset=\(offset)",
            method: "GET"
        )
    }

    func createPost(content: String, imageUrl: String? = nil) async throws -> SocialPost {
        let request: [String: Any?] = [
            "content": content,
            "image_url": imageUrl
        ]

        struct CreatePostRequest: Codable {
            let content: String
            let imageUrl: String?

            enum CodingKeys: String, CodingKey {
                case content
                case imageUrl = "image_url"
            }
        }

        let postRequest = CreatePostRequest(content: content, imageUrl: imageUrl)

        return try await apiClient.request(
            endpoint: "\(Config.Endpoints.mealPlans)/social",
            method: "POST",
            body: postRequest
        )
    }
}
