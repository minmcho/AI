//
//  CulturalSimilarityService.swift
//  NutriVision AI
//
//  Service for cross-cultural meal similarity analysis
//

import Foundation

class CulturalSimilarityService {
    private let apiClient = APIClient.shared

    // MARK: - Find Similar Meals Across Cultures

    func findSimilarMeals(
        mealDescription: String,
        targetCuisines: [String]
    ) async throws -> CulturalSimilarityResponse {
        let request = CulturalSimilarityRequest(
            mealDescription: mealDescription,
            targetCuisines: targetCuisines
        )

        return try await apiClient.request(
            endpoint: Config.Endpoints.culturalSimilarity,
            method: "POST",
            body: request
        )
    }

    // MARK: - Get Suggested Cuisines

    func getSuggestedCuisines() -> [String] {
        return [
            "Italian",
            "Chinese",
            "Japanese",
            "Korean",
            "Thai",
            "Indian",
            "Mexican",
            "French",
            "Greek",
            "Vietnamese",
            "Spanish",
            "Middle Eastern",
            "American",
            "Mediterranean"
        ]
    }
}

// MARK: - Request/Response Models

struct CulturalSimilarityRequest: Codable {
    let mealDescription: String
    let targetCuisines: [String]

    enum CodingKeys: String, CodingKey {
        case mealDescription = "meal_description"
        case targetCuisines = "target_cuisines"
    }
}

struct CulturalSimilarityResponse: Codable {
    let analysis: String
    let agent: String
    let similarMeals: [SimilarMeal]?
    let recommendations: [String]?

    enum CodingKeys: String, CodingKey {
        case analysis, agent
        case similarMeals = "similar_meals"
        case recommendations
    }
}

struct SimilarMeal: Codable, Identifiable {
    let id = UUID()
    let cuisine: String
    let dish: String
    let similarity: Double
    let description: String?

    enum CodingKeys: String, CodingKey {
        case cuisine, dish, similarity, description
    }
}
