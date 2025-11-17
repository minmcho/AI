//
//  BeveragePairingService.swift
//  NutriVision AI
//
//  Service for AI-powered beverage pairing recommendations
//

import Foundation

class BeveragePairingService {
    private let apiClient = APIClient.shared

    // MARK: - Get Beverage Pairings

    func getBeveragePairings(
        meal: String,
        preferences: [String] = []
    ) async throws -> BeveragePairingResponse {
        let request = BeveragePairingRequest(
            meal: meal,
            preferences: preferences
        )

        return try await apiClient.request(
            endpoint: Config.Endpoints.beveragePairing,
            method: "POST",
            body: request
        )
    }

    // MARK: - Get Preference Options

    func getPreferenceOptions() -> [String] {
        return [
            "Wine",
            "Beer",
            "Cocktails",
            "Non-Alcoholic",
            "Tea",
            "Coffee",
            "Juice",
            "Sparkling Water"
        ]
    }

    // MARK: - Get Wine Types

    func getWineTypes() -> [String] {
        return [
            "Red Wine",
            "White Wine",
            "Rosé",
            "Sparkling Wine",
            "Dessert Wine"
        ]
    }
}

// MARK: - Request/Response Models

struct BeveragePairingRequest: Codable {
    let meal: String
    let preferences: [String]
}

struct BeveragePairingResponse: Codable {
    let analysis: String
    let agent: String
    let pairings: [BeveragePairing]
    let explanation: String?

    enum CodingKeys: String, CodingKey {
        case analysis, agent, pairings, explanation
    }
}

struct BeveragePairing: Codable, Identifiable {
    let id = UUID()
    let beverage: String
    let type: String
    let reason: String
    let servingTemp: String?
    let confidence: Double?

    enum CodingKeys: String, CodingKey {
        case beverage, type, reason
        case servingTemp = "serving_temp"
        case confidence
    }
}
