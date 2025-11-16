//
//  RecipeViewModel.swift
//  NutriVision AI
//
//  Recipe management view model
//

import Foundation
import SwiftUI

@MainActor
class RecipeViewModel: ObservableObject {
    @Published var recipes: [Recipe] = []
    @Published var searchResults: [Recipe] = []
    @Published var similarRecipes: [Recipe] = []
    @Published var selectedRecipe: Recipe?
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var searchQuery: String = ""

    // Filter options
    @Published var selectedCuisine: String?
    @Published var selectedDifficulty: String?
    @Published var maxCalories: Int?
    @Published var selectedDietaryRestrictions: [DietaryRestriction] = []

    private let recipeService = RecipeService()

    // MARK: - Load Recipes

    func loadRecipes() async {
        isLoading = true
        errorMessage = nil

        do {
            recipes = try await recipeService.getRecipes()
            isLoading = false
        } catch {
            errorMessage = "Failed to load recipes: \(error.localizedDescription)"
            isLoading = false
        }
    }

    // MARK: - Search Recipes

    func searchRecipes() async {
        guard !searchQuery.isEmpty else {
            searchResults = []
            return
        }

        isLoading = true
        errorMessage = nil

        do {
            searchResults = try await recipeService.searchRecipes(query: searchQuery)
            isLoading = false
        } catch {
            errorMessage = "Search failed: \(error.localizedDescription)"
            isLoading = false
        }
    }

    // MARK: - Get Recipe Details

    func loadRecipeDetails(id: Int) async {
        isLoading = true
        errorMessage = nil

        do {
            selectedRecipe = try await recipeService.getRecipeDetails(id: id)
            isLoading = false
        } catch {
            errorMessage = "Failed to load recipe details: \(error.localizedDescription)"
            isLoading = false
        }
    }

    // MARK: - Find Similar Recipes

    func findSimilarRecipes(to recipeId: Int, limit: Int = 5) async {
        isLoading = true
        errorMessage = nil

        do {
            similarRecipes = try await recipeService.findSimilarRecipes(recipeId: recipeId, limit: limit)
            isLoading = false
        } catch {
            errorMessage = "Failed to find similar recipes: \(error.localizedDescription)"
            isLoading = false
        }
    }

    // MARK: - Filter Recipes

    func filterRecipes() async {
        isLoading = true
        errorMessage = nil

        do {
            recipes = try await recipeService.filterRecipes(
                cuisine: selectedCuisine,
                difficulty: selectedDifficulty,
                maxCalories: maxCalories,
                dietaryRestrictions: selectedDietaryRestrictions.isEmpty ? nil : selectedDietaryRestrictions
            )
            isLoading = false
        } catch {
            errorMessage = "Filter failed: \(error.localizedDescription)"
            isLoading = false
        }
    }

    // MARK: - Create Recipe

    func createRecipe(_ recipe: Recipe) async -> Bool {
        isLoading = true
        errorMessage = nil

        do {
            let newRecipe = try await recipeService.createRecipe(recipe)
            recipes.insert(newRecipe, at: 0)
            isLoading = false
            return true
        } catch {
            errorMessage = "Failed to create recipe: \(error.localizedDescription)"
            isLoading = false
            return false
        }
    }

    // MARK: - Update Recipe

    func updateRecipe(id: Int, recipe: Recipe) async -> Bool {
        isLoading = true
        errorMessage = nil

        do {
            let updatedRecipe = try await recipeService.updateRecipe(id: id, recipe: recipe)
            if let index = recipes.firstIndex(where: { $0.id == id }) {
                recipes[index] = updatedRecipe
            }
            selectedRecipe = updatedRecipe
            isLoading = false
            return true
        } catch {
            errorMessage = "Failed to update recipe: \(error.localizedDescription)"
            isLoading = false
            return false
        }
    }

    // MARK: - Delete Recipe

    func deleteRecipe(id: Int) async -> Bool {
        isLoading = true
        errorMessage = nil

        do {
            try await recipeService.deleteRecipe(id: id)
            recipes.removeAll { $0.id == id }
            if selectedRecipe?.id == id {
                selectedRecipe = nil
            }
            isLoading = false
            return true
        } catch {
            errorMessage = "Failed to delete recipe: \(error.localizedDescription)"
            isLoading = false
            return false
        }
    }

    // MARK: - Helper Methods

    func clearFilters() {
        selectedCuisine = nil
        selectedDifficulty = nil
        maxCalories = nil
        selectedDietaryRestrictions = []
    }

    func clearSearch() {
        searchQuery = ""
        searchResults = []
    }
}
