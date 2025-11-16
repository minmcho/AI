//
//  ProfileViewModel.swift
//  NutriVision AI
//
//  User profile view model
//

import Foundation
import SwiftUI

@MainActor
class ProfileViewModel: ObservableObject {
    @Published var user: User?
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var successMessage: String?

    // Edit mode
    @Published var isEditing = false
    @Published var editedUser: User?

    // Health metrics
    @Published var bmi: Double?
    @Published var bmr: Double?
    @Published var dailyCalorieGoal: Double?

    // Statistics
    @Published var totalRecipes: Int = 0
    @Published var totalMealPlans: Int = 0
    @Published var journalStreak: Int = 0

    private let apiClient = APIClient.shared

    // MARK: - Load Profile

    func loadProfile() async {
        isLoading = true
        errorMessage = nil

        do {
            user = try await apiClient.request(
                endpoint: Config.Endpoints.profile,
                method: "GET"
            )

            // Calculate health metrics
            calculateHealthMetrics()

            isLoading = false
        } catch {
            errorMessage = "Failed to load profile: \(error.localizedDescription)"
            isLoading = false
        }
    }

    // MARK: - Update Profile

    func updateProfile(user updatedUser: User) async -> Bool {
        isLoading = true
        errorMessage = nil
        successMessage = nil

        do {
            let updated: User = try await apiClient.request(
                endpoint: Config.Endpoints.profile,
                method: "PUT",
                body: updatedUser
            )

            user = updated
            editedUser = nil
            isEditing = false
            successMessage = "Profile updated successfully"

            calculateHealthMetrics()

            isLoading = false
            return true
        } catch {
            errorMessage = "Failed to update profile: \(error.localizedDescription)"
            isLoading = false
            return false
        }
    }

    // MARK: - Update Health Profile

    func updateHealthProfile(
        age: Int?,
        weightKg: Double?,
        heightCm: Int?,
        sex: Sex?,
        healthGoals: [HealthGoal]?,
        dietaryRestrictions: [DietaryRestriction]?,
        allergies: [String]?
    ) async -> Bool {
        guard var currentUser = user else { return false }

        // Update fields
        currentUser.age = age
        currentUser.weightKg = weightKg
        currentUser.heightCm = heightCm
        currentUser.sex = sex
        currentUser.healthGoals = healthGoals
        currentUser.dietaryRestrictions = dietaryRestrictions
        currentUser.allergies = allergies

        return await updateProfile(user: currentUser)
    }

    // MARK: - Update Language Preference

    func updateLanguage(_ language: Language) async -> Bool {
        guard var currentUser = user else { return false }

        currentUser.language = language

        return await updateProfile(user: currentUser)
    }

    // MARK: - Load Statistics

    func loadStatistics() async {
        // Load user statistics
        do {
            struct StatsResponse: Codable {
                let totalRecipes: Int
                let totalMealPlans: Int
                let journalStreak: Int

                enum CodingKeys: String, CodingKey {
                    case totalRecipes = "total_recipes"
                    case totalMealPlans = "total_meal_plans"
                    case journalStreak = "journal_streak"
                }
            }

            let stats: StatsResponse = try await apiClient.request(
                endpoint: "\(Config.Endpoints.profile)/stats",
                method: "GET"
            )

            totalRecipes = stats.totalRecipes
            totalMealPlans = stats.totalMealPlans
            journalStreak = stats.journalStreak
        } catch {
            // Stats are optional, don't show error
            print("Failed to load statistics: \(error)")
        }
    }

    // MARK: - Health Calculations

    private func calculateHealthMetrics() {
        guard let user = user,
              let weight = user.weightKg,
              let height = user.heightCm else {
            bmi = nil
            bmr = nil
            dailyCalorieGoal = nil
            return
        }

        // Calculate BMI
        let heightInMeters = Double(height) / 100.0
        bmi = weight / (heightInMeters * heightInMeters)

        // Calculate BMR (Basal Metabolic Rate) using Mifflin-St Jeor Equation
        if let age = user.age, let sex = user.sex {
            let bmrBase = (10 * weight) + (6.25 * Double(height)) - (5 * Double(age))

            bmr = sex == .male ? bmrBase + 5 : bmrBase - 161

            // Calculate daily calorie goal based on health goals
            if let goals = user.healthGoals, !goals.isEmpty {
                let activityMultiplier = 1.55 // Moderate activity assumption

                if goals.contains(.weightLoss) {
                    dailyCalorieGoal = bmr! * activityMultiplier * 0.85 // 15% deficit
                } else if goals.contains(.muscleGain) {
                    dailyCalorieGoal = bmr! * activityMultiplier * 1.10 // 10% surplus
                } else {
                    dailyCalorieGoal = bmr! * activityMultiplier // Maintenance
                }
            }
        }
    }

    // MARK: - BMI Category

    func getBMICategory() -> String {
        guard let bmi = bmi else { return "Unknown" }

        switch bmi {
        case ..<18.5:
            return "Underweight"
        case 18.5..<25:
            return "Normal"
        case 25..<30:
            return "Overweight"
        default:
            return "Obese"
        }
    }

    func getBMIColor() -> Color {
        guard let bmi = bmi else { return .gray }

        switch bmi {
        case ..<18.5:
            return .blue
        case 18.5..<25:
            return .green
        case 25..<30:
            return .orange
        default:
            return .red
        }
    }

    // MARK: - Edit Mode

    func startEditing() {
        editedUser = user
        isEditing = true
    }

    func cancelEditing() {
        editedUser = nil
        isEditing = false
    }

    func saveEdits() async -> Bool {
        guard let edited = editedUser else { return false }
        return await updateProfile(user: edited)
    }

    // MARK: - Validation

    func validateProfile(_ user: User) -> String? {
        if let email = user.email, email.isEmpty {
            return "Email is required"
        }

        if let age = user.age, age < 13 || age > 120 {
            return "Age must be between 13 and 120"
        }

        if let weight = user.weightKg, weight < 20 || weight > 500 {
            return "Weight must be between 20 and 500 kg"
        }

        if let height = user.heightCm, height < 50 || height > 300 {
            return "Height must be between 50 and 300 cm"
        }

        return nil
    }

    // MARK: - Helper Methods

    func clearMessages() {
        errorMessage = nil
        successMessage = nil
    }
}
