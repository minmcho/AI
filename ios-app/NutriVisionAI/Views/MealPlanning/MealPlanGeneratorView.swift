//
//  MealPlanGeneratorView.swift
//  NutriVision AI
//
//  AI-powered meal plan generation
//

import SwiftUI

struct MealPlanGeneratorView: View {
    @Environment(\.presentationMode) var presentationMode
    @StateObject private var viewModel = MealPlanViewModel()

    @State private var numberOfDays: Int = 7
    @State private var targetCalories: String = ""
    @State private var mealsPerDay: Int = 3
    @State private var includedCuisines: Set<String> = []
    @State private var avoidIngredients: String = ""

    let cuisineOptions = ["Italian", "Chinese", "Japanese", "Mexican", "Indian", "Thai", "Mediterranean"]
    let dayOptions = [3, 5, 7, 14, 30]

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // Header
                    VStack(spacing: 8) {
                        Image(systemName: "wand.and.stars")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 60, height: 60)
                            .foregroundColor(.green)

                        Text("Generate Meal Plan")
                            .font(.title2)
                            .fontWeight(.bold)

                        Text("Create a personalized meal plan with AI")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    .padding(.top, 20)

                    VStack(spacing: 20) {
                        // Duration
                        VStack(alignment: .leading, spacing: 12) {
                            Label("Plan Duration", systemImage: "calendar")
                                .font(.headline)

                            Picker("Days", selection: $numberOfDays) {
                                ForEach(dayOptions, id: \.self) { days in
                                    Text("\(days) days").tag(days)
                                }
                            }
                            .pickerStyle(SegmentedPickerStyle())
                        }

                        // Meals per day
                        VStack(alignment: .leading, spacing: 12) {
                            Label("Meals Per Day", systemImage: "fork.knife")
                                .font(.headline)

                            Stepper(value: $mealsPerDay, in: 2...5) {
                                Text("\(mealsPerDay) meals")
                                    .foregroundColor(.secondary)
                            }
                        }

                        // Target calories
                        VStack(alignment: .leading, spacing: 12) {
                            Label("Daily Calorie Target (optional)", systemImage: "flame.fill")
                                .font(.headline)

                            TextField("e.g., 2000", text: $targetCalories)
                                .keyboardType(.numberPad)
                                .padding()
                                .background(Color(.systemGray6))
                                .cornerRadius(12)
                        }

                        // Cuisine preferences
                        VStack(alignment: .leading, spacing: 12) {
                            Label("Preferred Cuisines", systemImage: "globe")
                                .font(.headline)

                            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                                ForEach(cuisineOptions, id: \.self) { cuisine in
                                    CuisineToggle(
                                        cuisine: cuisine,
                                        isSelected: includedCuisines.contains(cuisine)
                                    ) {
                                        if includedCuisines.contains(cuisine) {
                                            includedCuisines.remove(cuisine)
                                        } else {
                                            includedCuisines.insert(cuisine)
                                        }
                                    }
                                }
                            }
                        }

                        // Avoid ingredients
                        VStack(alignment: .leading, spacing: 12) {
                            Label("Avoid Ingredients (optional)", systemImage: "exclamationmark.triangle.fill")
                                .font(.headline)

                            TextField("e.g., peanuts, dairy", text: $avoidIngredients)
                                .padding()
                                .background(Color(.systemGray6))
                                .cornerRadius(12)
                        }
                    }
                    .padding(.horizontal, 24)

                    // Error message
                    if let error = viewModel.errorMessage {
                        Text(error)
                            .font(.caption)
                            .foregroundColor(.red)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                    }

                    // Generate button
                    CustomButton(
                        title: "Generate Plan",
                        icon: "sparkles",
                        style: .primary,
                        isLoading: viewModel.isLoading
                    ) {
                        generatePlan()
                    }
                    .padding(.horizontal, 24)
                    .padding(.bottom, 32)
                }
            }
            .navigationTitle("New Meal Plan")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        presentationMode.wrappedValue.dismiss()
                    }
                }
            }
        }
    }

    // MARK: - Methods

    private func generatePlan() {
        var preferences: [String: String] = [:]

        preferences["meals_per_day"] = String(mealsPerDay)

        if !targetCalories.isEmpty {
            preferences["target_calories"] = targetCalories
        }

        if !includedCuisines.isEmpty {
            preferences["cuisines"] = includedCuisines.joined(separator: ",")
        }

        if !avoidIngredients.isEmpty {
            preferences["avoid_ingredients"] = avoidIngredients
        }

        Task {
            let success = await viewModel.generateMealPlan(
                days: numberOfDays,
                preferences: preferences.isEmpty ? nil : preferences
            )

            if success {
                presentationMode.wrappedValue.dismiss()
            }
        }
    }
}

// MARK: - Cuisine Toggle

struct CuisineToggle: View {
    let cuisine: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(cuisine)
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundColor(isSelected ? .white : .primary)
                .padding(.vertical, 12)
                .frame(maxWidth: .infinity)
                .background(isSelected ? Color.green : Color(.systemGray6))
                .cornerRadius(10)
        }
    }
}

struct MealPlanGeneratorView_Previews: PreviewProvider {
    static var previews: some View {
        MealPlanGeneratorView()
    }
}
