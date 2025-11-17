//
//  CulturalMealView.swift
//  NutriVision AI
//
//  Explore similar dishes across different cuisines
//

import SwiftUI

struct CulturalMealView: View {
    @StateObject private var viewModel = CulturalMealViewModel()
    @State private var mealDescription: String = ""
    @State private var selectedCuisines: Set<String> = []

    let availableCuisines = CulturalSimilarityService().getSuggestedCuisines()

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Header
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Discover Cross-Cultural Similarities")
                            .font(.title2)
                            .fontWeight(.bold)

                        Text("Explore how dishes from different cuisines share common elements")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    .padding(.horizontal)

                    // Meal Description Input
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Describe Your Meal")
                            .font(.headline)

                        TextField("e.g., Pasta with tomato sauce and cheese", text: $mealDescription)
                            .textFieldStyle(.roundedBorder)
                            .padding(.horizontal)
                    }
                    .padding(.horizontal)

                    // Cuisine Selection
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Select Cuisines to Compare")
                            .font(.headline)
                            .padding(.horizontal)

                        LazyVGrid(columns: [GridItem(.adaptive(minimum: 100))], spacing: 12) {
                            ForEach(availableCuisines, id: \.self) { cuisine in
                                CuisineChip(
                                    cuisine: cuisine,
                                    isSelected: selectedCuisines.contains(cuisine)
                                ) {
                                    if selectedCuisines.contains(cuisine) {
                                        selectedCuisines.remove(cuisine)
                                    } else {
                                        selectedCuisines.insert(cuisine)
                                    }
                                }
                            }
                        }
                        .padding(.horizontal)
                    }

                    // Analyze Button
                    Button(action: {
                        Task {
                            await viewModel.findSimilarMeals(
                                mealDescription: mealDescription,
                                targetCuisines: Array(selectedCuisines)
                            )
                        }
                    }) {
                        HStack {
                            if viewModel.isLoading {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            } else {
                                Image(systemName: "sparkles")
                                Text("Find Similar Dishes")
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(canAnalyze ? Color.blue : Color.gray)
                        .foregroundColor(.white)
                        .cornerRadius(12)
                    }
                    .disabled(!canAnalyze || viewModel.isLoading)
                    .padding(.horizontal)

                    // Error Message
                    if let error = viewModel.errorMessage {
                        Text(error)
                            .foregroundColor(.red)
                            .font(.caption)
                            .padding(.horizontal)
                    }

                    // Results
                    if let response = viewModel.similarityResponse {
                        VStack(alignment: .leading, spacing: 16) {
                            Divider()

                            // AI Analysis
                            VStack(alignment: .leading, spacing: 8) {
                                HStack {
                                    Image(systemName: "brain.head.profile")
                                        .foregroundColor(.purple)
                                    Text("AI Analysis")
                                        .font(.headline)
                                }

                                Text(response.analysis)
                                    .font(.body)
                                    .padding()
                                    .background(Color.purple.opacity(0.1))
                                    .cornerRadius(12)
                            }
                            .padding(.horizontal)

                            // Similar Meals
                            if let meals = response.similarMeals, !meals.isEmpty {
                                VStack(alignment: .leading, spacing: 12) {
                                    Text("Similar Dishes")
                                        .font(.headline)
                                        .padding(.horizontal)

                                    ForEach(meals) { meal in
                                        SimilarMealCard(meal: meal)
                                    }
                                }
                            }

                            // Recommendations
                            if let recommendations = response.recommendations, !recommendations.isEmpty {
                                VStack(alignment: .leading, spacing: 8) {
                                    Text("Recommendations")
                                        .font(.headline)
                                        .padding(.horizontal)

                                    ForEach(recommendations, id: \.self) { recommendation in
                                        HStack {
                                            Image(systemName: "checkmark.circle.fill")
                                                .foregroundColor(.green)
                                            Text(recommendation)
                                                .font(.subheadline)
                                        }
                                        .padding(.horizontal)
                                    }
                                }
                            }
                        }
                        .padding(.vertical)
                    }

                    Spacer()
                }
                .padding(.vertical)
            }
            .navigationTitle("Cultural Meals")
            .navigationBarTitleDisplayMode(.inline)
        }
    }

    private var canAnalyze: Bool {
        !mealDescription.isEmpty && !selectedCuisines.isEmpty
    }
}

// MARK: - Cuisine Chip

struct CuisineChip: View {
    let cuisine: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(cuisine)
                .font(.caption)
                .fontWeight(isSelected ? .semibold : .regular)
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(isSelected ? Color.blue : Color.gray.opacity(0.2))
                .foregroundColor(isSelected ? .white : .primary)
                .cornerRadius(20)
        }
    }
}

// MARK: - Similar Meal Card

struct SimilarMealCard: View {
    let meal: SimilarMeal

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(meal.dish)
                        .font(.headline)

                    Text(meal.cuisine)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }

                Spacer()

                VStack {
                    Text("\(Int(meal.similarity * 100))%")
                        .font(.title3)
                        .fontWeight(.bold)
                        .foregroundColor(.blue)

                    Text("Similar")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }

            if let description = meal.description {
                Text(description)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .background(Color.gray.opacity(0.1))
        .cornerRadius(12)
        .padding(.horizontal)
    }
}

// MARK: - ViewModel

@MainActor
class CulturalMealViewModel: ObservableObject {
    @Published var similarityResponse: CulturalSimilarityResponse?
    @Published var isLoading = false
    @Published var errorMessage: String?

    private let service = CulturalSimilarityService()

    func findSimilarMeals(mealDescription: String, targetCuisines: [String]) async {
        isLoading = true
        errorMessage = nil

        do {
            similarityResponse = try await service.findSimilarMeals(
                mealDescription: mealDescription,
                targetCuisines: targetCuisines
            )
        } catch {
            errorMessage = "Failed to analyze: \(error.localizedDescription)"
        }

        isLoading = false
    }
}

// MARK: - Preview

struct CulturalMealView_Previews: PreviewProvider {
    static var previews: some View {
        CulturalMealView()
    }
}
