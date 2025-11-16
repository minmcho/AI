//
//  AIService.swift
//  NutriVision AI
//
//  AI features service (BLIP, Vision, Chat)
//

import Foundation
import UIKit

class AIService {
    private let apiClient = APIClient.shared

    // MARK: - Chat Assistant

    struct ChatRequest: Codable {
        let message: String
        let context: [String: String]?
    }

    struct ChatResponse: Codable {
        let message: String
        let agentName: String
        let suggestions: [String]
        let confidence: Double

        enum CodingKeys: String, CodingKey {
            case message
            case agentName = "agent_name"
            case suggestions, confidence
        }
    }

    func chatWithAssistant(message: String, context: [String: String]? = nil) async throws -> ChatResponse {
        let request = ChatRequest(message: message, context: context)
        return try await apiClient.request(
            endpoint: Config.Endpoints.chat,
            method: "POST",
            body: request
        )
    }

    // MARK: - Food Image Analysis (Vision AI)

    func analyzeFoodImage(imageData: Data) async throws -> FoodAnalysisResponse {
        let base64Image = imageData.base64EncodedString()
        let request = ["image_data": "data:image/jpeg;base64,\(base64Image)"]

        return try await apiClient.request(
            endpoint: Config.Endpoints.analyzeFood,
            method: "POST",
            body: request
        )
    }

    func analyzeFoodImageUpload(image: UIImage) async throws -> FoodAnalysisResponse {
        guard let imageData = image.jpegData(compressionQuality: 0.8) else {
            throw APIError.invalidResponse
        }

        return try await apiClient.uploadImage(
            endpoint: Config.Endpoints.analyzeFoodUpload,
            image: imageData
        )
    }

    // MARK: - BLIP Image Captioning

    struct BlipCaptionRequest: Codable {
        let imageData: String
        let maxLength: Int
        let numBeams: Int
        let conditionalText: String?

        enum CodingKeys: String, CodingKey {
            case imageData = "image_data"
            case maxLength = "max_length"
            case numBeams = "num_beams"
            case conditionalText = "conditional_text"
        }
    }

    func generateCaption(
        imageData: Data,
        maxLength: Int = 50,
        numBeams: Int = 3,
        conditionalText: String? = nil
    ) async throws -> BlipCaptionResponse {
        let base64Image = imageData.base64EncodedString()
        let request = BlipCaptionRequest(
            imageData: "data:image/jpeg;base64,\(base64Image)",
            maxLength: maxLength,
            numBeams: numBeams,
            conditionalText: conditionalText
        )

        return try await apiClient.request(
            endpoint: Config.Endpoints.blipCaption,
            method: "POST",
            body: request
        )
    }

    func generateCaptionUpload(
        image: UIImage,
        maxLength: Int = 50,
        numBeams: Int = 3
    ) async throws -> BlipCaptionResponse {
        guard let imageData = image.jpegData(compressionQuality: 0.8) else {
            throw APIError.invalidResponse
        }

        return try await apiClient.uploadImage(
            endpoint: "\(Config.Endpoints.blipCaption)/upload",
            image: imageData,
            additionalParams: [
                "max_length": "\(maxLength)",
                "num_beams": "\(numBeams)"
            ]
        )
    }

    // MARK: - BLIP Visual Question Answering

    struct BlipVQARequest: Codable {
        let imageData: String
        let question: String
        let maxLength: Int

        enum CodingKeys: String, CodingKey {
            case imageData = "image_data"
            case question
            case maxLength = "max_length"
        }
    }

    func answerVisualQuestion(
        imageData: Data,
        question: String,
        maxLength: Int = 50
    ) async throws -> BlipVQAResponse {
        let base64Image = imageData.base64EncodedString()
        let request = BlipVQARequest(
            imageData: "data:image/jpeg;base64,\(base64Image)",
            question: question,
            maxLength: maxLength
        )

        return try await apiClient.request(
            endpoint: Config.Endpoints.blipVQA,
            method: "POST",
            body: request
        )
    }

    func answerVisualQuestionUpload(
        image: UIImage,
        question: String,
        maxLength: Int = 50
    ) async throws -> BlipVQAResponse {
        guard let imageData = image.jpegData(compressionQuality: 0.8) else {
            throw APIError.invalidResponse
        }

        return try await apiClient.uploadImage(
            endpoint: "\(Config.Endpoints.blipVQA)/upload",
            image: imageData,
            additionalParams: [
                "question": question,
                "max_length": "\(maxLength)"
            ]
        )
    }

    // MARK: - BLIP Comprehensive Food Analysis

    func analyzeFoodWithBLIP(imageData: Data) async throws -> BlipFoodAnalysisResponse {
        let base64Image = imageData.base64EncodedString()
        let request = ["image_data": "data:image/jpeg;base64,\(base64Image)"]

        return try await apiClient.request(
            endpoint: Config.Endpoints.blipAnalyze,
            method: "POST",
            body: request
        )
    }

    func analyzeFoodWithBLIPUpload(image: UIImage) async throws -> BlipFoodAnalysisResponse {
        guard let imageData = image.jpegData(compressionQuality: 0.8) else {
            throw APIError.invalidResponse
        }

        return try await apiClient.uploadImage(
            endpoint: "\(Config.Endpoints.blipAnalyze)/upload",
            image: imageData
        )
    }

    // MARK: - Cultural Similarity

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
    }

    func findCulturalSimilarity(
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

    // MARK: - Beverage Pairing

    struct BeveragePairingRequest: Codable {
        let mealDescription: String
        let preferences: [String: String]

        enum CodingKeys: String, CodingKey {
            case mealDescription = "meal_description"
            case preferences
        }
    }

    struct BeveragePairingResponse: Codable {
        let pairings: String
        let agent: String
    }

    func getBeveragePairing(
        mealDescription: String,
        preferences: [String: String] = [:]
    ) async throws -> BeveragePairingResponse {
        let request = BeveragePairingRequest(
            mealDescription: mealDescription,
            preferences: preferences
        )

        return try await apiClient.request(
            endpoint: Config.Endpoints.beveragePairing,
            method: "POST",
            body: request
        )
    }
}
