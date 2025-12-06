//
//  Config.swift
//  NutriVision AI
//
//  Configuration and constants for the app
//

import Foundation

struct Config {
    // MARK: - API Configuration

    /// Base URL for the API
    /// Change this to your deployed backend URL in production
    static let baseURL = "http://localhost:8000"

    /// API Endpoints
    struct Endpoints {
        // Authentication
        static let login = "/auth/login"
        static let register = "/auth/register"
        static let me = "/auth/me"
        static let refreshToken = "/auth/refresh"

        // Profile
        static let profile = "/profile/update"
        static let healthSummary = "/profile/health-summary"
        static let nutritionRecommendations = "/profile/nutrition-recommendations"
        static let generateMealPlan = "/profile/generate-meal-plan"

        // Recipes
        static let recipes = "/recipes"
        static let similarRecipes = "/recipes/similar"
        static let searchRecipes = "/recipes/search"

        // AI Features
        static let chat = "/ai/chat/cooking-assistant"
        static let analyzeFood = "/ai/analyze-food-image"
        static let analyzeFoodUpload = "/ai/analyze-food-image/upload"
        static let blipCaption = "/ai/blip/caption"
        static let blipVQA = "/ai/blip/vqa"
        static let blipAnalyze = "/ai/blip/analyze-food"
        static let culturalSimilarity = "/ai/cultural-similarity"
        static let beveragePairing = "/ai/beverage-pairing"

        // Speech
        static let transcribe = "/speech/transcribe"
        static let synthesize = "/speech/synthesize"
        static let voiceCommand = "/speech/voice-command"
        static let translate = "/speech/translate"
        static let languages = "/speech/languages"

        // Videos
        static let recipeVideos = "/videos/recipe"
        static let searchVideos = "/videos/search"
        static let trendingVideos = "/videos/trending"

        // Shopping
        static let shoppingLists = "/shopping/lists"
        static let generateShoppingList = "/shopping/generate"

        // Meals & Journal
        static let mealPlans = "/meals/plans"
        static let journal = "/meals/journal"
        static let socialFeed = "/meals/social/feed"

        // Clinical Nutrition
        static let clinicalConditions = "/clinical/conditions"
        static let labResults = "/clinical/lab-results"
        static let nutrientDeficiencies = "/clinical/deficiencies"
        static let therapeuticDiets = "/clinical/therapeutic-diets"
        static let clinicalAssessments = "/clinical/assessments"
        static let medicationInteractions = "/clinical/medication-interactions"
        static let complianceReport = "/clinical/reports/compliance"
        static let nutritionStatusReport = "/clinical/reports/nutrition-status"
    }

    // MARK: - App Configuration

    struct App {
        static let name = "NutriVision AI"
        static let version = "1.0.0"
        static let bundleId = "com.nutrivision.ai"
    }

    // MARK: - User Defaults Keys

    struct UserDefaultsKeys {
        static let accessToken = "access_token"
        static let refreshToken = "refresh_token"
        static let userEmail = "user_email"
        static let userId = "user_id"
        static let preferredLanguage = "preferred_language"
        static let isOnboardingComplete = "is_onboarding_complete"
    }

    // MARK: - Feature Flags

    struct Features {
        static let enableVoiceCommands = true
        static let enableSocialSharing = true
        static let enableOfflineMode = false
        static let enablePremiumFeatures = true
    }

    // MARK: - UI Constants

    struct UI {
        static let cornerRadius: CGFloat = 12
        static let padding: CGFloat = 16
        static let iconSize: CGFloat = 24
        static let imageMaxSize: CGFloat = 1024
    }

    // MARK: - Languages

    struct Languages {
        static let supported = ["en", "zh", "ja", "ko", "th", "my"]
        static let names = [
            "en": "English",
            "zh": "中文",
            "ja": "日本語",
            "ko": "한국어",
            "th": "ไทย",
            "my": "မြန်မာ"
        ]
    }
}
