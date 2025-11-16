//
//  RecipeService.swift
//  NutriVision AI
//
//  Recipe operations service
//

import Foundation

class RecipeService {
    private let apiClient = APIClient.shared

    // MARK: - Get Recipes

    func getRecipes(limit: Int = 20, offset: Int = 0) async throws -> [Recipe] {
        return try await apiClient.request(
            endpoint: "\(Config.Endpoints.recipes)?limit=\(limit)&offset=\(offset)",
            method: "GET"
        )
    }

    // MARK: - Search Recipes

    func searchRecipes(query: String, limit: Int = 20) async throws -> [Recipe] {
        let encodedQuery = query.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? query
        return try await apiClient.request(
            endpoint: "\(Config.Endpoints.searchRecipes)?query=\(encodedQuery)&limit=\(limit)",
            method: "GET"
        )
    }

    // MARK: - Get Recipe Details

    func getRecipeDetails(id: Int) async throws -> Recipe {
        return try await apiClient.request(
            endpoint: "\(Config.Endpoints.recipes)/\(id)",
            method: "GET"
        )
    }

    // MARK: - Find Similar Recipes

    func findSimilarRecipes(recipeId: Int, limit: Int = 10) async throws -> [Recipe] {
        return try await apiClient.request(
            endpoint: "\(Config.Endpoints.similarRecipes)/\(recipeId)?limit=\(limit)",
            method: "GET"
        )
    }

    // MARK: - Create Recipe

    func createRecipe(_ recipe: Recipe) async throws -> Recipe {
        return try await apiClient.request(
            endpoint: Config.Endpoints.recipes,
            method: "POST",
            body: recipe
        )
    }

    // MARK: - Update Recipe

    func updateRecipe(id: Int, recipe: Recipe) async throws -> Recipe {
        return try await apiClient.request(
            endpoint: "\(Config.Endpoints.recipes)/\(id)",
            method: "PUT",
            body: recipe
        )
    }

    // MARK: - Delete Recipe

    func deleteRecipe(id: Int) async throws {
        let _: EmptyResponse = try await apiClient.request(
            endpoint: "\(Config.Endpoints.recipes)/\(id)",
            method: "DELETE"
        )
    }

    // MARK: - Filter Recipes

    func filterRecipes(
        cuisine: String? = nil,
        difficulty: String? = nil,
        maxCalories: Int? = nil,
        dietaryRestrictions: [DietaryRestriction]? = nil
    ) async throws -> [Recipe] {
        var queryItems: [String] = []

        if let cuisine = cuisine {
            queryItems.append("cuisine=\(cuisine)")
        }
        if let difficulty = difficulty {
            queryItems.append("difficulty=\(difficulty)")
        }
        if let maxCalories = maxCalories {
            queryItems.append("max_calories=\(maxCalories)")
        }
        if let restrictions = dietaryRestrictions {
            let restrictionsStr = restrictions.map { $0.rawValue }.joined(separator: ",")
            queryItems.append("dietary_restrictions=\(restrictionsStr)")
        }

        let query = queryItems.isEmpty ? "" : "?\(queryItems.joined(separator: "&"))"

        return try await apiClient.request(
            endpoint: "\(Config.Endpoints.recipes)\(query)",
            method: "GET"
        )
    }
}

// MARK: - Empty Response

struct EmptyResponse: Codable {}
