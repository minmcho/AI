//
//  MealService.swift
//  NutriVision AI
//
//  Service for meal logging and tracking
//

import Foundation

class MealService {
    private let apiClient = APIClient.shared

    // MARK: - Get Meals

    func getMeals(limit: Int = 20, offset: Int = 0, startDate: Date? = nil, endDate: Date? = nil) async throws -> [Meal] {
        var endpoint = "/meals?limit=\(limit)&offset=\(offset)"

        if let startDate = startDate {
            let startStr = DateUtils.dateToString(startDate, format: "yyyy-MM-dd")
            endpoint += "&start_date=\(startStr)"
        }

        if let endDate = endDate {
            let endStr = DateUtils.dateToString(endDate, format: "yyyy-MM-dd")
            endpoint += "&end_date=\(endStr)"
        }

        return try await apiClient.request(
            endpoint: endpoint,
            method: "GET"
        )
    }

    // MARK: - Get Meal Details

    func getMealDetails(id: String) async throws -> Meal {
        return try await apiClient.request(
            endpoint: "/meals/\(id)",
            method: "GET"
        )
    }

    // MARK: - Delete Meal

    func deleteMeal(id: String) async throws {
        let _: EmptyResponse = try await apiClient.request(
            endpoint: "/meals/\(id)",
            method: "DELETE"
        )
    }

    // MARK: - Log Meal

    struct LogMealRequest: Codable {
        let name: String
        let mealType: String
        let timestamp: String?
        let imageUrl: String?
        let calories: Double?
        let protein: Double?
        let carbs: Double?
        let fat: Double?
        let notes: String?
        let location: String?
        let tags: [String]?

        enum CodingKeys: String, CodingKey {
            case name
            case mealType = "meal_type"
            case timestamp
            case imageUrl = "image_url"
            case calories, protein, carbs, fat
            case notes, location, tags
        }
    }

    func logMeal(
        name: String,
        mealType: String,
        timestamp: Date? = nil,
        imageUrl: String? = nil,
        calories: Double? = nil,
        protein: Double? = nil,
        carbs: Double? = nil,
        fat: Double? = nil,
        notes: String? = nil,
        location: String? = nil,
        tags: [String]? = nil
    ) async throws -> Meal {
        let timestampStr = timestamp.map { DateUtils.dateToString($0, format: "yyyy-MM-dd'T'HH:mm:ssZ") }

        let request = LogMealRequest(
            name: name,
            mealType: mealType,
            timestamp: timestampStr,
            imageUrl: imageUrl,
            calories: calories,
            protein: protein,
            carbs: carbs,
            fat: fat,
            notes: notes,
            location: location,
            tags: tags
        )

        return try await apiClient.request(
            endpoint: "/meals",
            method: "POST",
            body: request
        )
    }
}

// Empty response for DELETE requests
struct EmptyResponse: Codable {}
