//
//  RecipeDetailView.swift
//  NutriVision AI
//
//  Detailed recipe view with ingredients and instructions
//

import SwiftUI

struct RecipeDetailView: View {
    @Environment(\.presentationMode) var presentationMode
    @StateObject private var viewModel = RecipeViewModel()

    let recipe: Recipe
    @State private var selectedTab = 0
    @State private var showSimilar = false

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 0) {
                    // Header image
                    if let imageUrl = recipe.imageUrl {
                        AsyncImage(url: URL(string: imageUrl)) { phase in
                            switch phase {
                            case .success(let image):
                                image
                                    .resizable()
                                    .scaledToFill()
                                    .frame(height: 250)
                                    .clipped()

                            default:
                                Rectangle()
                                    .fill(Color.gray.opacity(0.2))
                                    .frame(height: 250)
                                    .overlay(
                                        Image(systemName: "photo")
                                            .font(.largeTitle)
                                            .foregroundColor(.gray)
                                    )
                            }
                        }
                    }

                    VStack(alignment: .leading, spacing: 20) {
                        // Title and meta info
                        VStack(alignment: .leading, spacing: 12) {
                            Text(recipe.name)
                                .font(.title)
                                .fontWeight(.bold)

                            if let description = recipe.description {
                                Text(description)
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                            }

                            // Meta information
                            HStack(spacing: 16) {
                                if let cuisine = recipe.cuisine {
                                    MetaInfo(icon: "globe", text: cuisine)
                                }

                                if let difficulty = recipe.difficulty {
                                    MetaInfo(icon: "chart.bar.fill", text: difficulty.capitalized)
                                }

                                if let servings = recipe.servings {
                                    MetaInfo(icon: "person.2.fill", text: "\(servings) servings")
                                }
                            }
                            .font(.caption)
                        }
                        .padding()

                        // Dietary restrictions
                        if let restrictions = recipe.dietaryRestrictions, !restrictions.isEmpty {
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 8) {
                                    ForEach(restrictions, id: \.self) { restriction in
                                        DietaryBadge(restriction: restriction)
                                    }
                                }
                                .padding(.horizontal)
                            }
                        }

                        Divider()

                        // Tabs
                        Picker("", selection: $selectedTab) {
                            Text("Ingredients").tag(0)
                            Text("Instructions").tag(1)
                            Text("Nutrition").tag(2)
                        }
                        .pickerStyle(SegmentedPickerStyle())
                        .padding(.horizontal)

                        // Tab content
                        Group {
                            switch selectedTab {
                            case 0:
                                IngredientsView(ingredients: recipe.ingredients)
                            case 1:
                                InstructionsView(instructions: recipe.instructions ?? [])
                            case 2:
                                NutritionView(nutrition: recipe.nutrition)
                            default:
                                EmptyView()
                            }
                        }
                        .padding()

                        // Similar recipes button
                        if let recipeId = recipe.id {
                            Button(action: {
                                Task {
                                    await viewModel.findSimilarRecipes(to: recipeId)
                                    showSimilar = true
                                }
                            }) {
                                HStack {
                                    Image(systemName: "sparkles")
                                    Text("Find Similar Recipes")
                                        .fontWeight(.semibold)
                                }
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.green)
                                .cornerRadius(12)
                            }
                            .padding(.horizontal)
                        }
                    }
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        presentationMode.wrappedValue.dismiss()
                    }
                }
            }
            .sheet(isPresented: $showSimilar) {
                SimilarRecipesView(recipes: viewModel.similarRecipes)
            }
        }
    }
}

// MARK: - Meta Info

struct MetaInfo: View {
    let icon: String
    let text: String

    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: icon)
                .foregroundColor(.green)
            Text(text)
                .foregroundColor(.secondary)
        }
    }
}

// MARK: - Ingredients View

struct IngredientsView: View {
    let ingredients: [Ingredient]

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Ingredients")
                .font(.headline)

            if ingredients.isEmpty {
                Text("No ingredients listed")
                    .foregroundColor(.secondary)
            } else {
                ForEach(ingredients) { ingredient in
                    HStack(alignment: .top, spacing: 12) {
                        Image(systemName: "circle.fill")
                            .font(.system(size: 6))
                            .foregroundColor(.green)
                            .padding(.top, 6)

                        VStack(alignment: .leading, spacing: 4) {
                            Text(ingredient.name)
                                .font(.body)

                            if let amount = ingredient.amount, let unit = ingredient.unit {
                                Text("\(String(format: "%.1f", amount)) \(unit)")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }

                        Spacer()
                    }
                    .padding(.vertical, 4)
                }
            }
        }
    }
}

// MARK: - Instructions View

struct InstructionsView: View {
    let instructions: [String]

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Instructions")
                .font(.headline)

            if instructions.isEmpty {
                Text("No instructions available")
                    .foregroundColor(.secondary)
            } else {
                ForEach(Array(instructions.enumerated()), id: \.offset) { index, instruction in
                    HStack(alignment: .top, spacing: 12) {
                        ZStack {
                            Circle()
                                .fill(Color.green)
                                .frame(width: 24, height: 24)

                            Text("\(index + 1)")
                                .font(.caption)
                                .fontWeight(.bold)
                                .foregroundColor(.white)
                        }

                        Text(instruction)
                            .font(.body)
                            .fixedSize(horizontal: false, vertical: true)

                        Spacer()
                    }
                }
            }
        }
    }
}

// MARK: - Nutrition View

struct NutritionView: View {
    let nutrition: Nutrition?

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Nutrition Information")
                .font(.headline)

            if let nutrition = nutrition {
                VStack(spacing: 12) {
                    // Major macros
                    HStack(spacing: 16) {
                        MacroCard(
                            label: "Calories",
                            value: "\(nutrition.calories)",
                            unit: "kcal",
                            color: .orange
                        )

                        MacroCard(
                            label: "Protein",
                            value: String(format: "%.1f", nutrition.protein),
                            unit: "g",
                            color: .red
                        )
                    }

                    HStack(spacing: 16) {
                        MacroCard(
                            label: "Carbs",
                            value: String(format: "%.1f", nutrition.carbs),
                            unit: "g",
                            color: .blue
                        )

                        MacroCard(
                            label: "Fat",
                            value: String(format: "%.1f", nutrition.fat),
                            unit: "g",
                            color: .yellow
                        )
                    }

                    // Optional nutrients
                    if let fiber = nutrition.fiber {
                        NutritionRow(label: "Fiber", value: String(format: "%.1f", fiber), unit: "g")
                    }

                    if let sugar = nutrition.sugar {
                        NutritionRow(label: "Sugar", value: String(format: "%.1f", sugar), unit: "g")
                    }

                    if let sodium = nutrition.sodium {
                        NutritionRow(label: "Sodium", value: String(format: "%.0f", sodium), unit: "mg")
                    }

                    if let cholesterol = nutrition.cholesterol {
                        NutritionRow(label: "Cholesterol", value: String(format: "%.0f", cholesterol), unit: "mg")
                    }
                }
            } else {
                Text("Nutrition information not available")
                    .foregroundColor(.secondary)
            }
        }
    }
}

// MARK: - Macro Card

struct MacroCard: View {
    let label: String
    let value: String
    let unit: String
    let color: Color

    var body: some View {
        VStack(spacing: 8) {
            Text(value)
                .font(.title)
                .fontWeight(.bold)
                .foregroundColor(color)

            Text(unit)
                .font(.caption)
                .foregroundColor(.secondary)

            Text(label)
                .font(.subheadline)
                .fontWeight(.medium)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(color.opacity(0.1))
        .cornerRadius(12)
    }
}

// MARK: - Nutrition Row

struct NutritionRow: View {
    let label: String
    let value: String
    let unit: String

    var body: some View {
        HStack {
            Text(label)
                .font(.body)

            Spacer()

            Text("\(value) \(unit)")
                .font(.body)
                .fontWeight(.medium)
                .foregroundColor(.green)
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(8)
    }
}

// MARK: - Similar Recipes View

struct SimilarRecipesView: View {
    @Environment(\.presentationMode) var presentationMode
    let recipes: [Recipe]

    var body: some View {
        NavigationView {
            ScrollView {
                LazyVStack(spacing: 16) {
                    ForEach(recipes) { recipe in
                        RecipeCard(recipe: recipe)
                    }
                }
                .padding()
            }
            .navigationTitle("Similar Recipes")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        presentationMode.wrappedValue.dismiss()
                    }
                }
            }
        }
    }
}

struct RecipeDetailView_Previews: PreviewProvider {
    static var previews: some View {
        RecipeDetailView(recipe: Recipe(
            id: 1,
            name: "Sample Recipe",
            description: "A delicious sample recipe",
            ingredients: [],
            instructions: ["Step 1", "Step 2"],
            cuisine: "Italian",
            difficulty: "easy",
            servings: 4,
            nutrition: nil,
            dietaryRestrictions: nil,
            imageUrl: nil
        ))
    }
}
