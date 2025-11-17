//
//  UserService.swift
//  NutriVision AI
//
//  Service for user profile and settings
//

import Foundation

class UserService {
    private let apiClient = APIClient.shared

    // MARK: - Get Current User

    func getCurrentUser() throws -> User {
        // Try to load user from UserDefaults or Keychain
        // This is a simplified version - in production, you'd want secure storage

        guard let userId = UserDefaults.standard.value(forKey: Config.UserDefaultsKeys.userId) as? Int,
              let email = UserDefaults.standard.string(forKey: Config.UserDefaultsKeys.userEmail) else {
            throw UserServiceError.notAuthenticated
        }

        // Create a minimal user object from stored data
        // In a real app, you might want to fetch fresh data from /auth/me
        return User(
            id: userId,
            email: email,
            name: UserDefaults.standard.string(forKey: "user_name") ?? "User",
            dietaryPreferences: []
        )
    }

    // MARK: - Get User Profile

    func getUserProfile() async throws -> User {
        return try await apiClient.request(
            endpoint: Config.Endpoints.me,
            method: "GET"
        )
    }

    // MARK: - Update Profile

    struct UpdateProfileRequest: Codable {
        let name: String?
        let age: Int?
        let weight: Double?
        let height: Double?
        let activityLevel: String?
        let dietaryPreferences: [String]?
        let healthGoals: [String]?

        enum CodingKeys: String, CodingKey {
            case name, age, weight, height
            case activityLevel = "activity_level"
            case dietaryPreferences = "dietary_preferences"
            case healthGoals = "health_goals"
        }
    }

    func updateProfile(request: UpdateProfileRequest) async throws -> User {
        return try await apiClient.request(
            endpoint: Config.Endpoints.profile,
            method: "PUT",
            body: request
        )
    }

    // MARK: - Get Health Summary

    struct HealthSummary: Codable {
        let dailyCaloriesConsumed: Double
        let weeklyAverage: Double
        let streak: Int
        let recommendations: [String]

        enum CodingKeys: String, CodingKey {
            case dailyCaloriesConsumed = "daily_calories_consumed"
            case weeklyAverage = "weekly_average"
            case streak
            case recommendations
        }
    }

    func getHealthSummary() async throws -> HealthSummary {
        return try await apiClient.request(
            endpoint: Config.Endpoints.healthSummary,
            method: "GET"
        )
    }

    // MARK: - Get Nutrition Recommendations

    struct NutritionRecommendations: Codable {
        let targetCalories: Int
        let targetProtein: Double
        let targetCarbs: Double
        let targetFat: Double
        let recommendations: [String]

        enum CodingKeys: String, CodingKey {
            case targetCalories = "target_calories"
            case targetProtein = "target_protein"
            case targetCarbs = "target_carbs"
            case targetFat = "target_fat"
            case recommendations
        }
    }

    func getNutritionRecommendations() async throws -> NutritionRecommendations {
        return try await apiClient.request(
            endpoint: Config.Endpoints.nutritionRecommendations,
            method: "GET"
        )
    }
}

// MARK: - Errors

enum UserServiceError: Error, LocalizedError {
    case notAuthenticated
    case invalidData

    var errorDescription: String? {
        switch self {
        case .notAuthenticated:
            return "User is not authenticated"
        case .invalidData:
            return "Invalid user data"
        }
    }
}
