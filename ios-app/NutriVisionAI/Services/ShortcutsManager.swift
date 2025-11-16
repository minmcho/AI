//
//  ShortcutsManager.swift
//  NutriVision AI
//
//  Siri Shortcuts donation and management
//

import Foundation
import Intents

class ShortcutsManager {
    static let shared = ShortcutsManager()

    // MARK: - Donate Shortcuts

    func donateLogMealShortcut(mealType: String, calories: Int, protein: Double?, carbs: Double?, fat: Double?) {
        let intent = LogMealIntent()
        intent.mealType = mealType
        intent.calories = NSNumber(value: calories)
        intent.protein = protein.map { NSNumber(value: $0) }
        intent.carbs = carbs.map { NSNumber(value: $0) }
        intent.fat = fat.map { NSNumber(value: $0) }

        intent.suggestedInvocationPhrase = "Log my \(mealType)"

        let interaction = INInteraction(intent: intent, response: nil)
        interaction.donate { error in
            if let error = error {
                print("Failed to donate log meal shortcut: \(error)")
            }
        }
    }

    func donateGetNutritionShortcut() {
        let intent = GetNutritionIntent()
        intent.suggestedInvocationPhrase = "Show my nutrition"

        let interaction = INInteraction(intent: intent, response: nil)
        interaction.donate { error in
            if let error = error {
                print("Failed to donate get nutrition shortcut: \(error)")
            }
        }
    }

    func donateLogWaterShortcut(amount: Double = 250) {
        let intent = LogWaterIntent()
        intent.amount = NSNumber(value: amount)
        intent.suggestedInvocationPhrase = "Log water"

        let interaction = INInteraction(intent: intent, response: nil)
        interaction.donate { error in
            if let error = error {
                print("Failed to donate log water shortcut: \(error)")
            }
        }
    }

    func donateFindRecipeShortcut(query: String) {
        let intent = FindRecipeIntent()
        intent.query = query
        intent.suggestedInvocationPhrase = "Find \(query) recipe"

        let interaction = INInteraction(intent: intent, response: nil)
        interaction.donate { error in
            if let error = error {
                print("Failed to donate find recipe shortcut: \(error)")
            }
        }
    }

    // MARK: - Delete Shortcuts

    func deleteAllShortcuts() {
        INInteraction.deleteAll { error in
            if let error = error {
                print("Failed to delete shortcuts: \(error)")
            }
        }
    }

    func deleteShortcuts(withIdentifiers identifiers: [String]) {
        INInteraction.delete(with: identifiers) { error in
            if let error = error {
                print("Failed to delete shortcuts: \(error)")
            }
        }
    }

    // MARK: - Voice Shortcuts

    func addVoiceShortcut(for intent: INIntent, completion: @escaping (INVoiceShortcut?, Error?) -> Void) {
        let interaction = INInteraction(intent: intent, response: nil)

        INVoiceShortcutCenter.shared.getAllVoiceShortcuts { shortcuts, error in
            if let error = error {
                completion(nil, error)
                return
            }

            // Check if shortcut already exists
            if let existingShortcut = shortcuts?.first(where: { $0.shortcut.intent?.intentDescription == intent.intentDescription }) {
                completion(existingShortcut, nil)
            } else {
                // Create new shortcut
                let shortcut = INShortcut(intent: intent)
                completion(INVoiceShortcut(shortcut: shortcut), nil)
            }
        }
    }
}

// MARK: - Intent Definitions (Would normally be in .intentdefinition file)

// These are placeholder protocols - actual implementations would come from Xcode's Intent Definition file

protocol LogMealIntent: INIntent {
    var mealType: String? { get set }
    var calories: NSNumber? { get set }
    var protein: NSNumber? { get set }
    var carbs: NSNumber? { get set }
    var fat: NSNumber? { get set }
}

protocol GetNutritionIntent: INIntent {}

protocol LogWaterIntent: INIntent {
    var amount: NSNumber? { get set }
}

protocol FindRecipeIntent: INIntent {
    var query: String? { get set }
}

// Response protocols

protocol LogMealIntentResponse: INIntentResponse {
    var code: LogMealIntentResponseCode { get }
    var calories: NSNumber? { get set }
    var mealType: String? { get set }
}

enum LogMealIntentResponseCode: Int {
    case success
    case failure
}

protocol GetNutritionIntentResponse: INIntentResponse {
    var code: GetNutritionIntentResponseCode { get }
    var calories: NSNumber? { get set }
    var protein: NSNumber? { get set }
    var carbs: NSNumber? { get set }
    var fat: NSNumber? { get set }
    var summary: String? { get set }
}

enum GetNutritionIntentResponseCode: Int {
    case success
    case failure
}

protocol LogWaterIntentResponse: INIntentResponse {
    var code: LogWaterIntentResponseCode { get }
    var amount: NSNumber? { get set }
}

enum LogWaterIntentResponseCode: Int {
    case success
    case failure
}

protocol FindRecipeIntentResponse: INIntentResponse {
    var code: FindRecipeIntentResponseCode { get }
    var recipeName: String? { get set }
    var recipeCount: NSNumber? { get set }
}

enum FindRecipeIntentResponseCode: Int {
    case success
    case failure
    case notFound
}

// Resolution results

class LogMealCaloriesResolutionResult: INIntentResolutionResult {
    static func success(with value: Int) -> Self {
        return self.init()
    }

    static func needsValue() -> Self {
        return self.init()
    }
}

class LogWaterAmountResolutionResult: INIntentResolutionResult {
    static func success(with value: Double) -> Self {
        return self.init()
    }

    static func needsValue() -> Self {
        return self.init()
    }
}

// Handling protocols

protocol LogMealIntentHandling {
    func handle(intent: LogMealIntent, completion: @escaping (LogMealIntentResponse) -> Void)
    func resolveMealType(for intent: LogMealIntent, with completion: @escaping (INStringResolutionResult) -> Void)
    func resolveCalories(for intent: LogMealIntent, with completion: @escaping (LogMealCaloriesResolutionResult) -> Void)
}

protocol GetNutritionIntentHandling {
    func handle(intent: GetNutritionIntent, completion: @escaping (GetNutritionIntentResponse) -> Void)
}

protocol LogWaterIntentHandling {
    func handle(intent: LogWaterIntent, completion: @escaping (LogWaterIntentResponse) -> Void)
    func resolveAmount(for intent: LogWaterIntent, with completion: @escaping (LogWaterAmountResolutionResult) -> Void)
}

protocol FindRecipeIntentHandling {
    func handle(intent: FindRecipeIntent, completion: @escaping (FindRecipeIntentResponse) -> Void)
    func resolveQuery(for intent: FindRecipeIntent, with completion: @escaping (INStringResolutionResult) -> Void)
}
