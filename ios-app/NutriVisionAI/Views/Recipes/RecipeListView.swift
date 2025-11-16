//
//  RecipeListView.swift
//  NutriVision AI
//
//  Recipe browsing and list view
//

import SwiftUI

struct RecipeListView: View {
    @StateObject private var viewModel = RecipeViewModel()
    @State private var showSearch = false
    @State private var showFilter = false
    @State private var selectedRecipe: Recipe?

    var body: some View {
        NavigationView {
            ZStack {
                if viewModel.isLoading && viewModel.recipes.isEmpty {
                    LoadingView(message: "Loading recipes...")
                } else if viewModel.recipes.isEmpty {
                    EmptyRecipesView()
                } else {
                    ScrollView {
                        LazyVStack(spacing: 16) {
                            ForEach(viewModel.recipes) { recipe in
                                RecipeCard(recipe: recipe)
                                    .onTapGesture {
                                        selectedRecipe = recipe
                                    }
                            }
                        }
                        .padding()
                    }
                    .refreshable {
                        await viewModel.loadRecipes()
                    }
                }
            }
            .navigationTitle("Recipes")
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: { showFilter = true }) {
                        Image(systemName: "line.3.horizontal.decrease.circle")
                            .foregroundColor(.green)
                    }
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { showSearch = true }) {
                        Image(systemName: "magnifyingglass")
                            .foregroundColor(.green)
                    }
                }
            }
            .sheet(isPresented: $showSearch) {
                RecipeSearchView()
            }
            .sheet(isPresented: $showFilter) {
                RecipeFilterView(viewModel: viewModel)
            }
            .sheet(item: $selectedRecipe) { recipe in
                RecipeDetailView(recipe: recipe)
            }
            .task {
                if viewModel.recipes.isEmpty {
                    await viewModel.loadRecipes()
                }
            }
        }
    }
}

// MARK: - Recipe Card

struct RecipeCard: View {
    let recipe: Recipe

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Image
            if let imageUrl = recipe.imageUrl {
                AsyncImage(url: URL(string: imageUrl)) { phase in
                    switch phase {
                    case .empty:
                        Rectangle()
                            .fill(Color.gray.opacity(0.2))
                            .frame(height: 180)
                            .overlay(ProgressView())

                    case .success(let image):
                        image
                            .resizable()
                            .scaledToFill()
                            .frame(height: 180)
                            .clipped()

                    case .failure:
                        Rectangle()
                            .fill(Color.gray.opacity(0.2))
                            .frame(height: 180)
                            .overlay(
                                Image(systemName: "photo")
                                    .foregroundColor(.gray)
                            )

                    @unknown default:
                        EmptyView()
                    }
                }
                .cornerRadius(12)
            }

            // Title
            Text(recipe.name)
                .font(.headline)
                .lineLimit(2)

            // Cuisine and difficulty
            HStack {
                if let cuisine = recipe.cuisine {
                    Label(cuisine, systemImage: "globe")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                Spacer()

                if let difficulty = recipe.difficulty {
                    DifficultyBadge(difficulty: difficulty)
                }
            }

            // Nutrition summary
            if let nutrition = recipe.nutrition {
                HStack(spacing: 16) {
                    NutritionBadge(icon: "flame.fill", value: "\(nutrition.calories)", label: "cal")
                    NutritionBadge(icon: "p.circle.fill", value: String(format: "%.0f", nutrition.protein), label: "g")
                    NutritionBadge(icon: "c.circle.fill", value: String(format: "%.0f", nutrition.carbs), label: "g")
                    NutritionBadge(icon: "f.circle.fill", value: String(format: "%.0f", nutrition.fat), label: "g")
                }
                .font(.caption)
            }

            // Dietary restrictions
            if let restrictions = recipe.dietaryRestrictions, !restrictions.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(restrictions, id: \.self) { restriction in
                            DietaryBadge(restriction: restriction)
                        }
                    }
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: .gray.opacity(0.2), radius: 5, x: 0, y: 2)
    }
}

// MARK: - Empty State

struct EmptyRecipesView: View {
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "book.closed")
                .resizable()
                .scaledToFit()
                .frame(width: 80, height: 80)
                .foregroundColor(.gray)

            Text("No Recipes Yet")
                .font(.title2)
                .fontWeight(.semibold)

            Text("Start by searching or filtering recipes to find what you're looking for")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
        }
    }
}

// MARK: - Difficulty Badge

struct DifficultyBadge: View {
    let difficulty: String

    var color: Color {
        switch difficulty.lowercased() {
        case "easy":
            return .green
        case "medium":
            return .orange
        case "hard":
            return .red
        default:
            return .gray
        }
    }

    var body: some View {
        Text(difficulty.capitalized)
            .font(.caption)
            .fontWeight(.medium)
            .foregroundColor(.white)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(color)
            .cornerRadius(6)
    }
}

// MARK: - Nutrition Badge

struct NutritionBadge: View {
    let icon: String
    let value: String
    let label: String

    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: icon)
                .foregroundColor(.green)
            Text(value)
                .fontWeight(.semibold)
            Text(label)
                .foregroundColor(.secondary)
        }
    }
}

// MARK: - Dietary Badge

struct DietaryBadge: View {
    let restriction: DietaryRestriction

    var body: some View {
        Text(restriction.rawValue.replacingOccurrences(of: "_", with: " ").capitalized)
            .font(.caption)
            .padding(.horizontal, 10)
            .padding(.vertical, 5)
            .background(Color.green.opacity(0.2))
            .foregroundColor(.green)
            .cornerRadius(12)
    }
}

// MARK: - Recipe Filter View

struct RecipeFilterView: View {
    @Environment(\.presentationMode) var presentationMode
    @ObservedObject var viewModel: RecipeViewModel

    @State private var tempCuisine: String?
    @State private var tempDifficulty: String?
    @State private var tempMaxCalories: Int?
    @State private var tempRestrictions: Set<DietaryRestriction> = []

    let cuisines = ["Italian", "Chinese", "Japanese", "Mexican", "Indian", "Thai", "American", "French"]
    let difficulties = ["Easy", "Medium", "Hard"]

    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Cuisine")) {
                    Picker("Cuisine", selection: $tempCuisine) {
                        Text("Any").tag(nil as String?)
                        ForEach(cuisines, id: \.self) { cuisine in
                            Text(cuisine).tag(cuisine as String?)
                        }
                    }
                }

                Section(header: Text("Difficulty")) {
                    Picker("Difficulty", selection: $tempDifficulty) {
                        Text("Any").tag(nil as String?)
                        ForEach(difficulties, id: \.self) { difficulty in
                            Text(difficulty).tag(difficulty as String?)
                        }
                    }
                }

                Section(header: Text("Max Calories")) {
                    HStack {
                        TextField("No limit", value: $tempMaxCalories, format: .number)
                            .keyboardType(.numberPad)

                        if tempMaxCalories != nil {
                            Button(action: { tempMaxCalories = nil }) {
                                Image(systemName: "xmark.circle.fill")
                                    .foregroundColor(.gray)
                            }
                        }
                    }
                }

                Section(header: Text("Dietary Restrictions")) {
                    ForEach([DietaryRestriction.vegetarian, .vegan, .glutenFree, .dairyFree], id: \.self) { restriction in
                        Button(action: {
                            if tempRestrictions.contains(restriction) {
                                tempRestrictions.remove(restriction)
                            } else {
                                tempRestrictions.insert(restriction)
                            }
                        }) {
                            HStack {
                                Text(restriction.rawValue.replacingOccurrences(of: "_", with: " ").capitalized)
                                    .foregroundColor(.primary)

                                Spacer()

                                if tempRestrictions.contains(restriction) {
                                    Image(systemName: "checkmark")
                                        .foregroundColor(.green)
                                }
                            }
                        }
                    }
                }
            }
            .navigationTitle("Filter Recipes")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Clear") {
                        tempCuisine = nil
                        tempDifficulty = nil
                        tempMaxCalories = nil
                        tempRestrictions = []
                    }
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Apply") {
                        applyFilters()
                    }
                }
            }
        }
        .onAppear {
            tempCuisine = viewModel.selectedCuisine
            tempDifficulty = viewModel.selectedDifficulty
            tempMaxCalories = viewModel.maxCalories
            tempRestrictions = Set(viewModel.selectedDietaryRestrictions)
        }
    }

    private func applyFilters() {
        viewModel.selectedCuisine = tempCuisine
        viewModel.selectedDifficulty = tempDifficulty
        viewModel.maxCalories = tempMaxCalories
        viewModel.selectedDietaryRestrictions = Array(tempRestrictions)

        Task {
            await viewModel.filterRecipes()
        }

        presentationMode.wrappedValue.dismiss()
    }
}

struct RecipeListView_Previews: PreviewProvider {
    static var previews: some View {
        RecipeListView()
    }
}
