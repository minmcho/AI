//
//  Recipe.swift
//  NutriVision AI
//
//  Recipe and meal-related models
//

import Foundation

// MARK: - Recipe

struct Recipe: Codable, Identifiable {
    let id: Int
    let name: String
    let description: String?
    let instructions: [String]?
    let prepTime: Int?
    let cookTime: Int?
    let servings: Int?
    let difficulty: String?
    let cuisine: String?
    let imageUrl: String?
    let calories: Double?
    let protein: Double?
    let carbs: Double?
    let fat: Double?
    let ingredients: [Ingredient]?
    let tags: [String]?
    let createdBy: Int?
    let isPublic: Bool?

    enum CodingKeys: String, CodingKey {
        case id, name, description, instructions
        case prepTime = "prep_time"
        case cookTime = "cook_time"
        case servings, difficulty, cuisine
        case imageUrl = "image_url"
        case calories, protein, carbs, fat, ingredients, tags
        case createdBy = "created_by"
        case isPublic = "is_public"
    }
}

// MARK: - Ingredient

struct Ingredient: Codable, Identifiable {
    let id: Int?
    let recipeId: Int?
    let name: String
    let amount: Double?
    let unit: String?
    let notes: String?

    enum CodingKeys: String, CodingKey {
        case id
        case recipeId = "recipe_id"
        case name, amount, unit, notes
    }
}

// MARK: - Meal Plan

struct MealPlan: Codable, Identifiable {
    let id: Int
    let userId: Int
    let name: String
    let startDate: String
    let endDate: String
    let meals: [Meal]?
    let totalCalories: Double?
    let notes: String?

    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case name
        case startDate = "start_date"
        case endDate = "end_date"
        case meals
        case totalCalories = "total_calories"
        case notes
    }
}

// MARK: - Meal

struct Meal: Codable, Identifiable {
    let id: Int
    let mealPlanId: Int?
    let recipeId: Int?
    let mealType: MealType
    let scheduledDate: String?
    let recipe: Recipe?
    let notes: String?

    enum CodingKeys: String, CodingKey {
        case id
        case mealPlanId = "meal_plan_id"
        case recipeId = "recipe_id"
        case mealType = "meal_type"
        case scheduledDate = "scheduled_date"
        case recipe, notes
    }
}

enum MealType: String, Codable {
    case breakfast, lunch, dinner, snack

    var displayName: String {
        self.rawValue.capitalized
    }

    var icon: String {
        switch self {
        case .breakfast: return "sunrise.fill"
        case .lunch: return "sun.max.fill"
        case .dinner: return "moon.stars.fill"
        case .snack: return "leaf.fill"
        }
    }
}

// MARK: - Food Analysis

struct FoodAnalysisResponse: Codable {
    let foodItems: [String]
    let estimatedCalories: Double
    let detectedIngredients: [String]
    let cuisineType: String
    let confidence: Double

    enum CodingKeys: String, CodingKey {
        case foodItems = "food_items"
        case estimatedCalories = "estimated_calories"
        case detectedIngredients = "detected_ingredients"
        case cuisineType = "cuisine_type"
        case confidence
    }
}

// MARK: - BLIP Models

struct BlipCaptionResponse: Codable {
    let caption: String
    let confidence: Double
    let model: String
}

struct BlipVQAResponse: Codable {
    let question: String
    let answer: String
    let confidence: Double
    let model: String
}

struct BlipFoodAnalysisResponse: Codable {
    let caption: String
    let foodType: String
    let ingredients: String
    let cookingMethod: String
    let cuisine: String
    let servings: String
    let confidence: Double

    enum CodingKeys: String, CodingKey {
        case caption
        case foodType = "food_type"
        case ingredients
        case cookingMethod = "cooking_method"
        case cuisine, servings, confidence
    }
}

// MARK: - Journal Entry

struct JournalEntry: Codable, Identifiable {
    let id: Int
    let userId: Int
    let mealType: MealType
    let description: String
    let imageUrl: String?
    let calories: Double?
    let mood: String?
    let notes: String?
    let createdAt: String

    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case mealType = "meal_type"
        case description
        case imageUrl = "image_url"
        case calories, mood, notes
        case createdAt = "created_at"
    }
}

// MARK: - Shopping List

struct ShoppingList: Codable, Identifiable {
    let id: Int
    let userId: Int
    let name: String
    let items: [ShoppingListItem]?
    let createdAt: String

    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case name, items
        case createdAt = "created_at"
    }
}

struct ShoppingListItem: Codable, Identifiable {
    let id: Int
    let listId: Int
    let name: String
    let quantity: String?
    let unit: String?
    let category: String?
    var isPurchased: Bool

    enum CodingKeys: String, CodingKey {
        case id
        case listId = "list_id"
        case name, quantity, unit, category
        case isPurchased = "is_purchased"
    }
}
