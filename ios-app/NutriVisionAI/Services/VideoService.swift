//
//  VideoService.swift
//  NutriVision AI
//
//  Video recommendation service
//

import Foundation

class VideoService {
    private let apiClient = APIClient.shared

    // MARK: - Get Recipe Videos

    func getRecipeVideos(recipeId: Int, limit: Int = 5) async throws -> [Video] {
        return try await apiClient.request(
            endpoint: "\(Config.Endpoints.recipeVideos)/\(recipeId)?limit=\(limit)",
            method: "GET"
        )
    }

    // MARK: - Search Videos

    func searchVideos(query: String, limit: Int = 10) async throws -> VideoSearchResponse {
        let encodedQuery = query.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? query
        return try await apiClient.request(
            endpoint: "\(Config.Endpoints.searchVideos)?query=\(encodedQuery)&limit=\(limit)",
            method: "GET"
        )
    }

    // MARK: - Get Trending Videos

    func getTrendingVideos(limit: Int = 20) async throws -> [Video] {
        return try await apiClient.request(
            endpoint: "\(Config.Endpoints.trendingVideos)?limit=\(limit)",
            method: "GET"
        )
    }
}
