//
//  AIFeaturesViewModel.swift
//  NutriVision AI
//
//  AI features view model for BLIP, Vision AI, and Chat
//

import Foundation
import SwiftUI
import UIKit

@MainActor
class AIFeaturesViewModel: ObservableObject {
    // BLIP Caption
    @Published var captionResult: BlipCaptionResponse?
    @Published var currentCaption: String = ""

    // BLIP VQA
    @Published var vqaResult: BlipVQAResponse?
    @Published var currentQuestion: String = ""
    @Published var currentAnswer: String = ""

    // BLIP Food Analysis
    @Published var foodAnalysis: BlipFoodAnalysisResponse?

    // Vision AI
    @Published var visionAnalysis: FoodAnalysisResponse?

    // Chat
    @Published var chatMessages: [ChatMessage] = []
    @Published var currentMessage: String = ""

    // Cultural Similarity
    @Published var culturalSimilarity: CulturalSimilarityResponse?

    // General
    @Published var selectedImage: UIImage?
    @Published var isLoading = false
    @Published var errorMessage: String?

    private let aiService = AIService()

    // MARK: - BLIP Image Captioning

    func generateCaption(from image: UIImage, maxLength: Int = 50, numBeams: Int = 3) async {
        guard let imageData = image.jpegData(compressionQuality: 0.8) else {
            errorMessage = "Failed to process image"
            return
        }

        isLoading = true
        errorMessage = nil

        do {
            captionResult = try await aiService.generateCaption(
                imageData: imageData,
                maxLength: maxLength,
                numBeams: numBeams
            )
            currentCaption = captionResult?.caption ?? ""
            isLoading = false
        } catch {
            errorMessage = "Caption generation failed: \(error.localizedDescription)"
            isLoading = false
        }
    }

    // MARK: - BLIP Visual Question Answering

    func answerVisualQuestion(image: UIImage, question: String) async {
        guard let imageData = image.jpegData(compressionQuality: 0.8) else {
            errorMessage = "Failed to process image"
            return
        }

        isLoading = true
        errorMessage = nil
        currentQuestion = question

        do {
            vqaResult = try await aiService.answerVisualQuestion(
                imageData: imageData,
                question: question
            )
            currentAnswer = vqaResult?.answer ?? ""
            isLoading = false
        } catch {
            errorMessage = "VQA failed: \(error.localizedDescription)"
            isLoading = false
        }
    }

    // MARK: - BLIP Comprehensive Food Analysis

    func analyzeFoodWithBLIP(image: UIImage) async {
        guard let imageData = image.jpegData(compressionQuality: 0.8) else {
            errorMessage = "Failed to process image"
            return
        }

        isLoading = true
        errorMessage = nil

        do {
            foodAnalysis = try await aiService.analyzeFoodWithBLIP(imageData: imageData)
            isLoading = false
        } catch {
            errorMessage = "Food analysis failed: \(error.localizedDescription)"
            isLoading = false
        }
    }

    // MARK: - Vision AI Food Analysis

    func analyzeFood(image: UIImage) async {
        guard let imageData = image.jpegData(compressionQuality: 0.8) else {
            errorMessage = "Failed to process image"
            return
        }

        isLoading = true
        errorMessage = nil

        do {
            visionAnalysis = try await aiService.analyzeFoodImage(imageData: imageData)
            isLoading = false
        } catch {
            errorMessage = "Vision analysis failed: \(error.localizedDescription)"
            isLoading = false
        }
    }

    // MARK: - Chat with AI Assistant

    func sendMessage(_ message: String) async {
        guard !message.isEmpty else { return }

        // Add user message
        let userMessage = ChatMessage(role: "user", content: message)
        chatMessages.append(userMessage)
        currentMessage = ""

        isLoading = true
        errorMessage = nil

        do {
            let response = try await aiService.chatWithAssistant(message: message)

            // Add assistant response
            let assistantMessage = ChatMessage(role: "assistant", content: response.response)
            chatMessages.append(assistantMessage)
            isLoading = false
        } catch {
            errorMessage = "Chat failed: \(error.localizedDescription)"
            isLoading = false
        }
    }

    // MARK: - Cultural Similarity

    func findCulturalSimilarity(recipeId: Int, targetCuisine: String) async {
        isLoading = true
        errorMessage = nil

        do {
            culturalSimilarity = try await aiService.findCulturalSimilarity(
                recipeId: recipeId,
                targetCuisine: targetCuisine
            )
            isLoading = false
        } catch {
            errorMessage = "Cultural similarity search failed: \(error.localizedDescription)"
            isLoading = false
        }
    }

    // MARK: - Beverage Pairing

    func findBeveragePairing(recipeId: Int) async -> BeveragePairingResponse? {
        isLoading = true
        errorMessage = nil

        do {
            let pairing = try await aiService.findBeveragePairing(recipeId: recipeId)
            isLoading = false
            return pairing
        } catch {
            errorMessage = "Beverage pairing search failed: \(error.localizedDescription)"
            isLoading = false
            return nil
        }
    }

    // MARK: - Helper Methods

    func clearCaption() {
        captionResult = nil
        currentCaption = ""
    }

    func clearVQA() {
        vqaResult = nil
        currentQuestion = ""
        currentAnswer = ""
    }

    func clearAnalysis() {
        foodAnalysis = nil
        visionAnalysis = nil
    }

    func clearChat() {
        chatMessages = []
        currentMessage = ""
    }

    func resetAll() {
        clearCaption()
        clearVQA()
        clearAnalysis()
        clearChat()
        selectedImage = nil
        errorMessage = nil
    }
}

// MARK: - Supporting Models

struct ChatMessage: Identifiable {
    let id = UUID()
    let role: String
    let content: String
    let timestamp: Date = Date()
}
