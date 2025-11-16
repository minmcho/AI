//
//  User.swift
//  NutriVision AI
//
//  User model and related types
//

import Foundation

// MARK: - User Model

struct User: Codable, Identifiable {
    let id: Int
    let email: String
    let username: String
    var fullName: String?
    var avatarUrl: String?
    var bio: String?

    // Health Profile
    var age: Int?
    var weightKg: Double?
    var heightCm: Int?
    var sex: Sex?
    var targetCalories: Int?
    var targetProteinG: Double?
    var targetCarbsG: Double?
    var targetFatG: Double?
    var activityLevel: ActivityLevel?
    var healthGoals: [HealthGoal]?

    // Preferences
    var dietaryRestrictions: [DietaryRestriction]?
    var allergies: [String]?
    var cuisinePreferences: [String]?
    var dislikedIngredients: [String]?

    // Medical
    var medicalConditions: [String]?
    var medications: [String]?

    // Settings
    var language: Language?
    var timezone: String?
    var isPremium: Bool?

    enum CodingKeys: String, CodingKey {
        case id, email, username
        case fullName = "full_name"
        case avatarUrl = "avatar_url"
        case bio, age
        case weightKg = "weight_kg"
        case heightCm = "height_cm"
        case sex
        case targetCalories = "target_calories"
        case targetProteinG = "target_protein_g"
        case targetCarbsG = "target_carbs_g"
        case targetFatG = "target_fat_g"
        case activityLevel = "activity_level"
        case healthGoals = "health_goals"
        case dietaryRestrictions = "dietary_restrictions"
        case allergies
        case cuisinePreferences = "cuisine_preferences"
        case dislikedIngredients = "disliked_ingredients"
        case medicalConditions = "medical_conditions"
        case medications, language, timezone
        case isPremium = "is_premium"
    }
}

// MARK: - Enums

enum Sex: String, Codable, CaseIterable {
    case male, female, other

    var displayName: String {
        switch self {
        case .male: return "Male"
        case .female: return "Female"
        case .other: return "Other"
        }
    }
}

enum ActivityLevel: String, Codable, CaseIterable {
    case sedentary, light, moderate, active
    case veryActive = "very_active"

    var displayName: String {
        switch self {
        case .sedentary: return "Sedentary"
        case .light: return "Lightly Active"
        case .moderate: return "Moderately Active"
        case .active: return "Very Active"
        case .veryActive: return "Extremely Active"
        }
    }

    var description: String {
        switch self {
        case .sedentary: return "Little or no exercise"
        case .light: return "Exercise 1-3 times/week"
        case .moderate: return "Exercise 4-5 times/week"
        case .active: return "Daily exercise"
        case .veryActive: return "Intense daily exercise"
        }
    }
}

enum HealthGoal: String, Codable, CaseIterable {
    case weightLoss = "weight_loss"
    case weightGain = "weight_gain"
    case muscleGain = "muscle_gain"
    case maintainWeight = "maintain_weight"
    case improveFitness = "improve_fitness"
    case manageDiabetes = "manage_diabetes"
    case lowerCholesterol = "lower_cholesterol"
    case heartHealth = "heart_health"
    case digestiveHealth = "digestive_health"
    case generalWellness = "general_wellness"

    var displayName: String {
        switch self {
        case .weightLoss: return "Weight Loss"
        case .weightGain: return "Weight Gain"
        case .muscleGain: return "Muscle Gain"
        case .maintainWeight: return "Maintain Weight"
        case .improveFitness: return "Improve Fitness"
        case .manageDiabetes: return "Manage Diabetes"
        case .lowerCholesterol: return "Lower Cholesterol"
        case .heartHealth: return "Heart Health"
        case .digestiveHealth: return "Digestive Health"
        case .generalWellness: return "General Wellness"
        }
    }

    var icon: String {
        switch self {
        case .weightLoss: return "chart.line.downtrend.xyaxis"
        case .weightGain: return "chart.line.uptrend.xyaxis"
        case .muscleGain: return "figure.strengthtraining.traditional"
        case .maintainWeight: return "equal.circle"
        case .improveFitness: return "figure.run"
        case .manageDiabetes: return "heart.text.square"
        case .lowerCholesterol: return "waveform.path.ecg"
        case .heartHealth: return "heart.fill"
        case .digestiveHealth: return "leaf.fill"
        case .generalWellness: return "star.fill"
        }
    }
}

enum DietaryRestriction: String, Codable, CaseIterable {
    case vegetarian, vegan
    case glutenFree = "gluten_free"
    case dairyFree = "dairy_free"
    case keto, paleo, halal, kosher
    case lowCarb = "low_carb"
    case lowFat = "low_fat"

    var displayName: String {
        switch self {
        case .vegetarian: return "Vegetarian"
        case .vegan: return "Vegan"
        case .glutenFree: return "Gluten-Free"
        case .dairyFree: return "Dairy-Free"
        case .keto: return "Keto"
        case .paleo: return "Paleo"
        case .halal: return "Halal"
        case .kosher: return "Kosher"
        case .lowCarb: return "Low Carb"
        case .lowFat: return "Low Fat"
        }
    }

    var icon: String {
        switch self {
        case .vegetarian: return "leaf.circle.fill"
        case .vegan: return "leaf.fill"
        case .glutenFree: return "g.circle.fill"
        case .dairyFree: return "drop.fill"
        case .keto: return "k.circle.fill"
        case .paleo: return "p.circle.fill"
        case .halal: return "h.circle.fill"
        case .kosher: return "star.circle.fill"
        case .lowCarb: return "c.circle.fill"
        case .lowFat: return "f.circle.fill"
        }
    }
}

enum Language: String, Codable, CaseIterable {
    case en, zh, ja, ko, th, my

    var displayName: String {
        Config.Languages.names[self.rawValue] ?? self.rawValue.uppercased()
    }

    var flag: String {
        switch self {
        case .en: return "🇺🇸"
        case .zh: return "🇨🇳"
        case .ja: return "🇯🇵"
        case .ko: return "🇰🇷"
        case .th: return "🇹🇭"
        case .my: return "🇲🇲"
        }
    }
}

// MARK: - Authentication Models

struct LoginRequest: Codable {
    let username: String
    let password: String
}

struct LoginResponse: Codable {
    let accessToken: String
    let refreshToken: String
    let tokenType: String
    let user: User

    enum CodingKeys: String, CodingKey {
        case accessToken = "access_token"
        case refreshToken = "refresh_token"
        case tokenType = "token_type"
        case user
    }
}

struct RegisterRequest: Codable {
    let email: String
    let username: String
    let password: String
    let age: Int?
    let weightKg: Double?
    let heightCm: Int?
    let sex: Sex?
    let allergies: [String]?
    let dietaryRestrictions: [DietaryRestriction]?
    let healthGoals: [HealthGoal]?
    let activityLevel: ActivityLevel?

    enum CodingKeys: String, CodingKey {
        case email, username, password, age
        case weightKg = "weight_kg"
        case heightCm = "height_cm"
        case sex, allergies
        case dietaryRestrictions = "dietary_restrictions"
        case healthGoals = "health_goals"
        case activityLevel = "activity_level"
    }
}
