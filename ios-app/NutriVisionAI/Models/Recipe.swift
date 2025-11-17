//
//  Recipe.swift
//  NutriVision AI
//
//  Recipe and meal-related models
//

import Foundation

// MARK: - Recipe

struct Recipe: Codable, Identifiable, Hashable {
    let id: String  // Support both String and Int IDs
    let name: String
    let description: String?
    let instructions: [String]
    let prepTime: Int?
    let cookTime: Int?
    let totalTime: Int?
    let servings: Int?
    let difficulty: String?
    let cuisine: String?
    let imageUrl: String?
    let videoUrl: String?
    let calories: Double?
    let protein: Double?
    let carbs: Double?
    let fat: Double?
    let ingredients: [Ingredient]
    let tags: [String]?
    let dietaryTags: [String]?
    let ratingAvg: Double?
    let authorId: Int?
    let createdAt: Date?
    let isPublic: Bool?

    enum CodingKeys: String, CodingKey {
        case id, name, description, instructions
        case prepTime = "prep_time_minutes"
        case cookTime = "cook_time_minutes"
        case totalTime = "total_time_minutes"
        case servings, difficulty, cuisine
        case imageUrl = "image_url"
        case videoUrl = "video_url"
        case calories, protein, carbs, fat, ingredients, tags
        case dietaryTags = "dietary_tags"
        case ratingAvg = "rating_avg"
        case authorId = "created_by"
        case createdAt = "created_at"
        case isPublic = "is_public"
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        // Handle id as either String or Int
        if let intId = try? container.decode(Int.self, forKey: .id) {
            id = String(intId)
        } else {
            id = try container.decode(String.self, forKey: .id)
        }
        name = try container.decode(String.self, forKey: .name)
        description = try? container.decode(String.self, forKey: .description)
        instructions = (try? container.decode([String].self, forKey: .instructions)) ?? []
        prepTime = try? container.decode(Int.self, forKey: .prepTime)
        cookTime = try? container.decode(Int.self, forKey: .cookTime)
        totalTime = try? container.decode(Int.self, forKey: .totalTime)
        servings = try? container.decode(Int.self, forKey: .servings)
        difficulty = try? container.decode(String.self, forKey: .difficulty)
        cuisine = try? container.decode(String.self, forKey: .cuisine)
        imageUrl = try? container.decode(String.self, forKey: .imageUrl)
        videoUrl = try? container.decode(String.self, forKey: .videoUrl)
        calories = try? container.decode(Double.self, forKey: .calories)
        protein = try? container.decode(Double.self, forKey: .protein)
        carbs = try? container.decode(Double.self, forKey: .carbs)
        fat = try? container.decode(Double.self, forKey: .fat)
        ingredients = (try? container.decode([Ingredient].self, forKey: .ingredients)) ?? []
        tags = try? container.decode([String].self, forKey: .tags)
        dietaryTags = try? container.decode([String].self, forKey: .dietaryTags)
        ratingAvg = try? container.decode(Double.self, forKey: .ratingAvg)
        authorId = try? container.decode(Int.self, forKey: .authorId)
        createdAt = try? container.decode(Date.self, forKey: .createdAt)
        isPublic = try? container.decode(Bool.self, forKey: .isPublic)
    }

    // For Hashable conformance
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }

    static func == (lhs: Recipe, rhs: Recipe) -> Bool {
        lhs.id == rhs.id
    }

    // Convenience initializer for mocks
    init(id: String, name: String, description: String?, cuisine: String?, difficulty: String?, prepTime: Int?, cookTime: Int?, servings: Int?, instructions: [String], ingredients: [Ingredient], imageUrl: String?, videoUrl: String?, calories: Double?, protein: Double?, carbs: Double?, fat: Double?, tags: [String]?, authorId: Int?, createdAt: Date?) {
        self.id = id
        self.name = name
        self.description = description
        self.cuisine = cuisine
        self.difficulty = difficulty
        self.prepTime = prepTime
        self.cookTime = cookTime
        self.totalTime = (prepTime ?? 0) + (cookTime ?? 0)
        self.servings = servings
        self.instructions = instructions
        self.ingredients = ingredients
        self.imageUrl = imageUrl
        self.videoUrl = videoUrl
        self.calories = calories
        self.protein = protein
        self.carbs = carbs
        self.fat = fat
        self.tags = tags
        self.dietaryTags = nil
        self.ratingAvg = nil
        self.authorId = authorId
        self.createdAt = createdAt
        self.isPublic = true
    }
}

// MARK: - Ingredient

struct Ingredient: Codable, Identifiable, Hashable {
    let id: String
    let recipeId: Int?
    let name: String
    let amount: Double?  // Mapped to "quantity" in API
    let unit: String?
    let notes: String?

    enum CodingKeys: String, CodingKey {
        case id
        case recipeId = "recipe_id"
        case name
        case amount = "quantity"  // API uses "quantity"
        case unit, notes
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        if let intId = try? container.decode(Int.self, forKey: .id) {
            id = String(intId)
        } else {
            id = (try? container.decode(String.self, forKey: .id)) ?? UUID().uuidString
        }
        recipeId = try? container.decode(Int.self, forKey: .recipeId)
        name = try container.decode(String.self, forKey: .name)
        amount = try? container.decode(Double.self, forKey: .amount)
        unit = try? container.decode(String.self, forKey: .unit)
        notes = try? container.decode(String.self, forKey: .notes)
    }
}

// MARK: - Meal Plan

struct MealPlan: Codable, Identifiable {
    let id: String
    let userId: Int
    let name: String
    let startDate: Date?
    let endDate: Date?
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

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        if let intId = try? container.decode(Int.self, forKey: .id) {
            id = String(intId)
        } else {
            id = try container.decode(String.self, forKey: .id)
        }
        userId = try container.decode(Int.self, forKey: .userId)
        name = try container.decode(String.self, forKey: .name)

        // Parse dates from strings
        if let startDateStr = try? container.decode(String.self, forKey: .startDate) {
            startDate = DateUtils.iso8601ToDate(startDateStr)
        } else {
            startDate = nil
        }

        if let endDateStr = try? container.decode(String.self, forKey: .endDate) {
            endDate = DateUtils.iso8601ToDate(endDateStr)
        } else {
            endDate = nil
        }

        meals = try? container.decode([Meal].self, forKey: .meals)
        totalCalories = try? container.decode(Double.self, forKey: .totalCalories)
        notes = try? container.decode(String.self, forKey: .notes)
    }
}

// MARK: - Meal

struct Meal: Codable, Identifiable {
    let id: String
    let name: String
    let mealType: String  // breakfast, lunch, dinner, snack
    let timestamp: Date?
    let imageUrl: String?
    let calories: Double?
    let protein: Double?
    let carbs: Double?
    let fat: Double?
    let notes: String?
    let location: String?
    let tags: [String]?
    let analysisResult: FoodAnalysisResult?

    enum CodingKeys: String, CodingKey {
        case id
        case name
        case mealType = "meal_type"
        case timestamp
        case imageUrl = "image_url"
        case calories, protein, carbs, fat
        case notes, location, tags
        case analysisResult = "analysis_result"
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        if let intId = try? container.decode(Int.self, forKey: .id) {
            id = String(intId)
        } else {
            id = try container.decode(String.self, forKey: .id)
        }
        name = (try? container.decode(String.self, forKey: .name)) ?? "Meal"
        mealType = (try? container.decode(String.self, forKey: .mealType)) ?? "snack"

        if let timestampStr = try? container.decode(String.self, forKey: .timestamp) {
            timestamp = DateUtils.iso8601ToDate(timestampStr)
        } else {
            timestamp = nil
        }

        imageUrl = try? container.decode(String.self, forKey: .imageUrl)
        calories = try? container.decode(Double.self, forKey: .calories)
        protein = try? container.decode(Double.self, forKey: .protein)
        carbs = try? container.decode(Double.self, forKey: .carbs)
        fat = try? container.decode(Double.self, forKey: .fat)
        notes = try? container.decode(String.self, forKey: .notes)
        location = try? container.decode(String.self, forKey: .location)
        tags = try? container.decode([String].self, forKey: .tags)
        analysisResult = try? container.decode(FoodAnalysisResult.self, forKey: .analysisResult)
    }

    // Convenience initializer
    init(id: String, name: String, mealType: String, timestamp: Date?, imageUrl: String?, calories: Double?, protein: Double?, carbs: Double?, fat: Double?, notes: String?, location: String?, tags: [String]?, analysisResult: FoodAnalysisResult?) {
        self.id = id
        self.name = name
        self.mealType = mealType
        self.timestamp = timestamp
        self.imageUrl = imageUrl
        self.calories = calories
        self.protein = protein
        self.carbs = carbs
        self.fat = fat
        self.notes = notes
        self.location = location
        self.tags = tags
        self.analysisResult = analysisResult
    }
}

// MARK: - Food Analysis

struct FoodAnalysisResult: Codable {
    let foodItems: [String]?
    let estimatedCalories: Double?
    let healthScore: Double?
    let suggestions: [String]?

    enum CodingKeys: String, CodingKey {
        case foodItems = "food_items"
        case estimatedCalories = "estimated_calories"
        case healthScore = "health_score"
        case suggestions
    }
}

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
    let title: String?
    let content: String
    let mealDate: String
    let mealType: String?
    let mood: String?
    let satisfaction: Int?
    let tags: [String]?
    let photoUrls: [String]?
    let createdAt: String

    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case title, content
        case mealDate = "meal_date"
        case mealType = "meal_type"
        case mood, satisfaction, tags
        case photoUrls = "photo_urls"
        case createdAt = "created_at"
    }
}

// MARK: - Shopping List

struct ShoppingList: Codable, Identifiable {
    let id: Int
    let userId: Int
    let name: String
    let items: [ShoppingListItem]?
    let totalEstimatedCost: Double?
    let isCompleted: Bool?
    let createdAt: String

    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case name, items
        case totalEstimatedCost = "total_estimated_cost"
        case isCompleted = "is_completed"
        case createdAt = "created_at"
    }
}

struct ShoppingListItem: Codable, Identifiable {
    let id: String
    let listId: Int?
    let name: String
    let quantity: String?
    let unit: String?
    let category: String?
    let estimatedPrice: Double?
    let actualPrice: Double?
    var checked: Bool

    enum CodingKeys: String, CodingKey {
        case id
        case listId = "list_id"
        case name, quantity, unit, category
        case estimatedPrice = "estimated_price"
        case actualPrice = "actual_price"
        case checked = "is_purchased"
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        if let intId = try? container.decode(Int.self, forKey: .id) {
            id = String(intId)
        } else {
            id = try container.decode(String.self, forKey: .id)
        }
        listId = try? container.decode(Int.self, forKey: .listId)
        name = try container.decode(String.self, forKey: .name)

        // Handle quantity as either String or Double
        if let doubleQty = try? container.decode(Double.self, forKey: .quantity) {
            quantity = String(doubleQty)
        } else {
            quantity = try? container.decode(String.self, forKey: .quantity)
        }

        unit = try? container.decode(String.self, forKey: .unit)
        category = try? container.decode(String.self, forKey: .category)
        estimatedPrice = try? container.decode(Double.self, forKey: .estimatedPrice)
        actualPrice = try? container.decode(Double.self, forKey: .actualPrice)
        checked = (try? container.decode(Bool.self, forKey: .checked)) ?? false
    }

    init(id: String, name: String, quantity: String?, unit: String?, checked: Bool) {
        self.id = id
        self.listId = nil
        self.name = name
        self.quantity = quantity
        self.unit = unit
        self.category = nil
        self.estimatedPrice = nil
        self.actualPrice = nil
        self.checked = checked
    }
}
