//
//  IntentHandler.swift
//  NutriVision AI
//
//  Siri Shortcuts integration
//

import Intents
import Foundation

class IntentHandler: INExtension {
    override func handler(for intent: INIntent) -> Any {
        switch intent {
        case is LogMealIntent:
            return LogMealIntentHandler()
        case is GetNutritionIntent:
            return GetNutritionIntentHandler()
        case is LogWaterIntent:
            return LogWaterIntentHandler()
        case is FindRecipeIntent:
            return FindRecipeIntentHandler()
        default:
            fatalError("Unhandled intent type: \(intent)")
        }
    }
}

// MARK: - Log Meal Intent Handler

class LogMealIntentHandler: NSObject, LogMealIntentHandling {
    func handle(intent: LogMealIntent, completion: @escaping (LogMealIntentResponse) -> Void) {
        guard let mealType = intent.mealType,
              let calories = intent.calories as? Int else {
            completion(LogMealIntentResponse(code: .failure, userActivity: nil))
            return
        }

        // Save to HealthKit
        Task {
            do {
                let protein = intent.protein?.doubleValue ?? 0
                let carbs = intent.carbs?.doubleValue ?? 0
                let fat = intent.fat?.doubleValue ?? 0

                try await HealthKitManager.shared.saveMealToHealth(
                    calories: Double(calories),
                    protein: protein,
                    carbs: carbs,
                    fat: fat
                )

                let response = LogMealIntentResponse(code: .success, userActivity: nil)
                response.calories = NSNumber(value: calories)
                response.mealType = mealType
                completion(response)
            } catch {
                completion(LogMealIntentResponse(code: .failure, userActivity: nil))
            }
        }
    }

    func resolveMealType(for intent: LogMealIntent, with completion: @escaping (INStringResolutionResult) -> Void) {
        if let mealType = intent.mealType {
            completion(INStringResolutionResult.success(with: mealType))
        } else {
            completion(INStringResolutionResult.needsValue())
        }
    }

    func resolveCalories(for intent: LogMealIntent, with completion: @escaping (LogMealCaloriesResolutionResult) -> Void) {
        if let calories = intent.calories {
            completion(LogMealCaloriesResolutionResult.success(with: calories.intValue))
        } else {
            completion(LogMealCaloriesResolutionResult.needsValue())
        }
    }
}

// MARK: - Get Nutrition Intent Handler

class GetNutritionIntentHandler: NSObject, GetNutritionIntentHandling {
    func handle(intent: GetNutritionIntent, completion: @escaping (GetNutritionIntentResponse) -> Void) {
        Task {
            do {
                try await HealthKitManager.shared.fetchTodayNutrition()

                let healthKit = HealthKitManager.shared
                let response = GetNutritionIntentResponse(code: .success, userActivity: nil)

                response.calories = NSNumber(value: Int(healthKit.todayCalories))
                response.protein = NSNumber(value: healthKit.todayProtein)
                response.carbs = NSNumber(value: healthKit.todayCarbs)
                response.fat = NSNumber(value: healthKit.todayFat)

                let summary = "Today you've consumed \(Int(healthKit.todayCalories)) calories, \(Int(healthKit.todayProtein))g protein, \(Int(healthKit.todayCarbs))g carbs, and \(Int(healthKit.todayFat))g fat."
                response.summary = summary

                completion(response)
            } catch {
                completion(GetNutritionIntentResponse(code: .failure, userActivity: nil))
            }
        }
    }
}

// MARK: - Log Water Intent Handler

class LogWaterIntentHandler: NSObject, LogWaterIntentHandling {
    func handle(intent: LogWaterIntent, completion: @escaping (LogWaterIntentResponse) -> Void) {
        guard let amount = intent.amount as? Double else {
            completion(LogWaterIntentResponse(code: .failure, userActivity: nil))
            return
        }

        Task {
            do {
                try await HealthKitManager.shared.saveWater(milliliters: amount)

                let response = LogWaterIntentResponse(code: .success, userActivity: nil)
                response.amount = NSNumber(value: amount)
                completion(response)
            } catch {
                completion(LogWaterIntentResponse(code: .failure, userActivity: nil))
            }
        }
    }

    func resolveAmount(for intent: LogWaterIntent, with completion: @escaping (LogWaterAmountResolutionResult) -> Void) {
        if let amount = intent.amount {
            completion(LogWaterAmountResolutionResult.success(with: amount.doubleValue))
        } else {
            // Default to 250ml (1 glass)
            completion(LogWaterAmountResolutionResult.success(with: 250))
        }
    }
}

// MARK: - Find Recipe Intent Handler

class FindRecipeIntentHandler: NSObject, FindRecipeIntentHandling {
    func handle(intent: FindRecipeIntent, completion: @escaping (FindRecipeIntentResponse) -> Void) {
        guard let query = intent.query else {
            completion(FindRecipeIntentResponse(code: .failure, userActivity: nil))
            return
        }

        Task {
            do {
                let apiClient = APIClient.shared

                struct RecipeSearchRequest: Codable {
                    let query: String
                }

                struct RecipeSearchResponse: Codable {
                    let recipes: [SimpleRecipe]
                }

                struct SimpleRecipe: Codable {
                    let id: Int
                    let name: String
                    let calories: Int?
                }

                let searchResponse: RecipeSearchResponse = try await apiClient.request(
                    endpoint: "\(Config.Endpoints.recipes)/search",
                    method: "POST",
                    body: RecipeSearchRequest(query: query)
                )

                if let firstRecipe = searchResponse.recipes.first {
                    let response = FindRecipeIntentResponse(code: .success, userActivity: nil)
                    response.recipeName = firstRecipe.name
                    response.recipeCount = NSNumber(value: searchResponse.recipes.count)

                    completion(response)
                } else {
                    let response = FindRecipeIntentResponse(code: .notFound, userActivity: nil)
                    completion(response)
                }
            } catch {
                completion(FindRecipeIntentResponse(code: .failure, userActivity: nil))
            }
        }
    }

    func resolveQuery(for intent: FindRecipeIntent, with completion: @escaping (INStringResolutionResult) -> Void) {
        if let query = intent.query {
            completion(INStringResolutionResult.success(with: query))
        } else {
            completion(INStringResolutionResult.needsValue())
        }
    }
}
