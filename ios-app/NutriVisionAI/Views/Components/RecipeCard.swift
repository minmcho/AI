//
//  RecipeCard.swift
//  NutriVision AI
//
//  Reusable recipe preview card component
//

import SwiftUI

struct RecipeCard: View {
    let recipe: Recipe
    var style: CardStyle = .standard

    enum CardStyle {
        case standard, compact, featured
    }

    var body: some View {
        switch style {
        case .standard:
            StandardRecipeCard(recipe: recipe)
        case .compact:
            CompactRecipeCard(recipe: recipe)
        case .featured:
            FeaturedRecipeCard(recipe: recipe)
        }
    }
}

// MARK: - Standard Card

struct StandardRecipeCard: View {
    let recipe: Recipe

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Image
            if let imageUrl = recipe.imageUrl {
                AsyncImage(url: URL(string: imageUrl)) { phase in
                    switch phase {
                    case .empty:
                        Rectangle()
                            .fill(Color.gray.opacity(0.3))
                            .frame(height: 180)
                            .overlay(ProgressView())
                    case .success(let image):
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(height: 180)
                            .clipped()
                    case .failure:
                        Rectangle()
                            .fill(Color.gray.opacity(0.3))
                            .frame(height: 180)
                            .overlay(
                                Image(systemName: "photo")
                                    .foregroundColor(.gray)
                            )
                    @unknown default:
                        EmptyView()
                    }
                }
            } else {
                Rectangle()
                    .fill(Color.gray.opacity(0.2))
                    .frame(height: 180)
                    .overlay(
                        Image(systemName: "fork.knife")
                            .font(.largeTitle)
                            .foregroundColor(.gray)
                    )
            }

            // Content
            VStack(alignment: .leading, spacing: 8) {
                // Title
                Text(recipe.name)
                    .font(.headline)
                    .lineLimit(2)

                // Cuisine & Difficulty
                HStack {
                    if let cuisine = recipe.cuisine {
                        Text(cuisine)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }

                    if let difficulty = recipe.difficulty {
                        Text("•")
                            .foregroundColor(.secondary)
                        Text(difficulty)
                            .font(.caption)
                            .foregroundColor(difficultyColor(difficulty))
                    }
                }

                // Time & Servings
                HStack(spacing: 12) {
                    if let prepTime = recipe.prepTime {
                        HStack(spacing: 4) {
                            Image(systemName: "clock")
                            Text("\(prepTime)m")
                        }
                        .font(.caption)
                        .foregroundColor(.secondary)
                    }

                    if let servings = recipe.servings {
                        HStack(spacing: 4) {
                            Image(systemName: "person.2")
                            Text("\(servings)")
                        }
                        .font(.caption)
                        .foregroundColor(.secondary)
                    }
                }

                // Calories
                if let calories = recipe.calories {
                    Text("\(Int(calories)) kcal")
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundColor(.blue)
                }
            }
            .padding()
        }
        .background(Color.white)
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
    }

    private func difficultyColor(_ difficulty: String) -> Color {
        switch difficulty.lowercased() {
        case "easy": return .green
        case "medium": return .orange
        case "hard": return .red
        default: return .secondary
        }
    }
}

// MARK: - Compact Card

struct CompactRecipeCard: View {
    let recipe: Recipe

    var body: some View {
        HStack(spacing: 12) {
            // Thumbnail
            if let imageUrl = recipe.imageUrl {
                AsyncImage(url: URL(string: imageUrl)) { phase in
                    switch phase {
                    case .success(let image):
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                    default:
                        Color.gray.opacity(0.3)
                            .overlay(
                                Image(systemName: "fork.knife")
                                    .foregroundColor(.gray)
                            )
                    }
                }
                .frame(width: 80, height: 80)
                .cornerRadius(8)
            }

            // Info
            VStack(alignment: .leading, spacing: 4) {
                Text(recipe.name)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .lineLimit(2)

                if let cuisine = recipe.cuisine {
                    Text(cuisine)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                HStack(spacing: 8) {
                    if let prepTime = recipe.prepTime {
                        HStack(spacing: 2) {
                            Image(systemName: "clock")
                            Text("\(prepTime)m")
                        }
                        .font(.caption2)
                        .foregroundColor(.secondary)
                    }

                    if let calories = recipe.calories {
                        Text("\(Int(calories)) kcal")
                            .font(.caption2)
                            .foregroundColor(.blue)
                    }
                }
            }

            Spacer()
        }
        .padding()
        .background(Color.gray.opacity(0.05))
        .cornerRadius(12)
    }
}

// MARK: - Featured Card

struct FeaturedRecipeCard: View {
    let recipe: Recipe

    var body: some View {
        ZStack(alignment: .bottomLeading) {
            // Background Image
            if let imageUrl = recipe.imageUrl {
                AsyncImage(url: URL(string: imageUrl)) { phase in
                    switch phase {
                    case .success(let image):
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                    default:
                        Color.gray.opacity(0.3)
                    }
                }
                .frame(height: 250)
                .clipped()
            } else {
                Rectangle()
                    .fill(LinearGradient(
                        colors: [.blue, .purple],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ))
                    .frame(height: 250)
            }

            // Gradient Overlay
            LinearGradient(
                colors: [Color.black.opacity(0.7), Color.clear],
                startPoint: .bottom,
                endPoint: .center
            )

            // Content Overlay
            VStack(alignment: .leading, spacing: 8) {
                if let cuisine = recipe.cuisine {
                    Text(cuisine.uppercased())
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundColor(.white.opacity(0.9))
                }

                Text(recipe.name)
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                    .lineLimit(2)

                HStack(spacing: 12) {
                    if let prepTime = recipe.prepTime {
                        Label("\(prepTime)m", systemImage: "clock")
                    }

                    if let calories = recipe.calories {
                        Label("\(Int(calories)) kcal", systemImage: "flame")
                    }
                }
                .font(.caption)
                .foregroundColor(.white.opacity(0.9))
            }
            .padding()
        }
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.2), radius: 8, x: 0, y: 4)
    }
}

struct RecipeCard_Previews: PreviewProvider {
    static var previews: some View {
        let sampleRecipe = Recipe(
            id: 1,
            name: "Spaghetti Carbonara",
            description: "Classic Italian pasta dish",
            instructions: nil,
            prepTime: 15,
            cookTime: 20,
            totalTime: 35,
            servings: 4,
            difficulty: "Easy",
            cuisine: "Italian",
            imageUrl: nil,
            calories: 450,
            protein: 25,
            carbs: 50,
            fat: 15,
            ingredients: nil,
            tags: nil,
            dietaryTags: nil,
            ratingAvg: nil,
            createdBy: nil,
            isPublic: true
        )

        VStack(spacing: 20) {
            RecipeCard(recipe: sampleRecipe, style: .standard)
            RecipeCard(recipe: sampleRecipe, style: .compact)
            RecipeCard(recipe: sampleRecipe, style: .featured)
        }
        .padding()
    }
}
