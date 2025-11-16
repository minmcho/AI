//
//  HomeView.swift
//  NutriVision AI
//
//  Main home dashboard view
//

import SwiftUI

struct HomeView: View {
    @EnvironmentObject var authViewModel: AuthenticationViewModel
    @StateObject private var viewModel = HomeViewModel()
    @State private var showScanner = false

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // Welcome Header
                    welcomeHeader

                    // Quick Actions
                    quickActionsGrid

                    // Today's Stats
                    todayStatsSection

                    // Recommended Recipes
                    recommendedRecipesSection

                    // Recent Activities
                    recentActivitiesSection
                }
                .padding()
            }
            .navigationTitle("Home")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { showScanner = true }) {
                        Image(systemName: "camera.fill")
                    }
                }
            }
            .sheet(isPresented: $showScanner) {
                FoodScannerView()
            }
            .onAppear {
                Task {
                    await viewModel.loadDashboardData()
                }
            }
        }
    }

    // MARK: - Welcome Header

    private var welcomeHeader: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Welcome back,")
                .font(.title3)
                .foregroundColor(.secondary)

            Text(authViewModel.currentUser?.username ?? "User")
                .font(.largeTitle)
                .fontWeight(.bold)

            if let targetCalories = authViewModel.currentUser?.targetCalories {
                Text("Daily Goal: \(targetCalories) cal")
                    .font(.subheadline)
                    .foregroundColor(.blue)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(
            LinearGradient(
                colors: [Color.blue.opacity(0.1), Color.purple.opacity(0.1)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .cornerRadius(16)
    }

    // MARK: - Quick Actions

    private var quickActionsGrid: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Quick Actions")
                .font(.headline)

            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 12) {
                QuickActionCard(
                    icon: "camera.fill",
                    title: "Scan Food",
                    color: .blue
                ) {
                    showScanner = true
                }

                QuickActionCard(
                    icon: "magnifyingglass",
                    title: "Search Recipes",
                    color: .green
                ) {
                    // Navigate to recipe search
                }

                QuickActionCard(
                    icon: "calendar",
                    title: "Meal Plan",
                    color: .orange
                ) {
                    // Navigate to meal planner
                }

                QuickActionCard(
                    icon: "mic.fill",
                    title: "Voice Command",
                    color: .purple
                ) {
                    // Navigate to voice commands
                }
            }
        }
    }

    // MARK: - Today's Stats

    private var todayStatsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Today's Nutrition")
                .font(.headline)

            HStack(spacing: 12) {
                StatsCard(
                    title: "Calories",
                    value: viewModel.todayCalories,
                    goal: authViewModel.currentUser?.targetCalories ?? 2000,
                    color: .blue,
                    unit: "kcal"
                )

                StatsCard(
                    title: "Protein",
                    value: Int(viewModel.todayProtein),
                    goal: Int(authViewModel.currentUser?.targetProteinG ?? 150),
                    color: .red,
                    unit: "g"
                )
            }

            HStack(spacing: 12) {
                StatsCard(
                    title: "Carbs",
                    value: Int(viewModel.todayCarbs),
                    goal: Int(authViewModel.currentUser?.targetCarbsG ?? 200),
                    color: .orange,
                    unit: "g"
                )

                StatsCard(
                    title: "Fats",
                    value: Int(viewModel.todayFats),
                    goal: Int(authViewModel.currentUser?.targetFatG ?? 65),
                    color: .yellow,
                    unit: "g"
                )
            }
        }
    }

    // MARK: - Recommended Recipes

    private var recommendedRecipesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Recommended for You")
                    .font(.headline)

                Spacer()

                NavigationLink("See All") {
                    RecipeListView()
                }
                .font(.subheadline)
            }

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 16) {
                    ForEach(viewModel.recommendedRecipes) { recipe in
                        RecipeCard(recipe: recipe)
                            .frame(width: 200)
                    }
                }
            }
        }
    }

    // MARK: - Recent Activities

    private var recentActivitiesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Recent Activities")
                .font(.headline)

            ForEach(viewModel.recentActivities) { activity in
                ActivityRow(activity: activity)
            }
        }
    }
}

// MARK: - Quick Action Card

struct QuickActionCard: View {
    let icon: String
    let title: String
    let color: Color
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.system(size: 32))
                    .foregroundColor(color)

                Text(title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.primary)
                    .multilineTextAlignment(.center)
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(color.opacity(0.1))
            .cornerRadius(12)
        }
    }
}

// MARK: - Stats Card

struct StatsCard: View {
    let title: String
    let value: Int
    let goal: Int
    let color: Color
    let unit: String

    private var progress: Double {
        Double(value) / Double(goal)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)

            HStack(alignment: .firstTextBaseline) {
                Text("\(value)")
                    .font(.title2)
                    .fontWeight(.bold)

                Text("/\(goal) \(unit)")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            ProgressView(value: min(progress, 1.0))
                .tint(color)
                .background(Color.gray.opacity(0.2))
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.white)
        .cornerRadius(12)
        .shadow(radius: 2)
    }
}

// MARK: - Recipe Card

struct RecipeCard: View {
    let recipe: Recipe

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Recipe image
            if let imageUrl = recipe.imageUrl {
                AsyncImage(url: URL(string: imageUrl)) { image in
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                } placeholder: {
                    Color.gray.opacity(0.2)
                }
                .frame(height: 120)
                .clipped()
                .cornerRadius(8)
            }

            // Recipe info
            VStack(alignment: .leading, spacing: 4) {
                Text(recipe.name)
                    .font(.headline)
                    .lineLimit(2)

                HStack {
                    if let calories = recipe.calories {
                        Label("\(Int(calories)) cal", systemImage: "flame.fill")
                            .font(.caption)
                            .foregroundColor(.orange)
                    }

                    if let cookTime = recipe.cookTime {
                        Label("\(cookTime) min", systemImage: "clock")
                            .font(.caption)
                            .foregroundColor(.gray)
                    }
                }
            }
            .padding(.horizontal, 8)
        }
        .background(Color.white)
        .cornerRadius(12)
        .shadow(radius: 2)
    }
}

// MARK: - Activity Row

struct ActivityRow: View {
    let activity: Activity

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: activity.icon)
                .font(.title3)
                .foregroundColor(activity.color)
                .frame(width: 40, height: 40)
                .background(activity.color.opacity(0.1))
                .cornerRadius(8)

            VStack(alignment: .leading, spacing: 4) {
                Text(activity.title)
                    .font(.subheadline)
                    .fontWeight(.medium)

                Text(activity.time)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Spacer()

            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding()
        .background(Color.white)
        .cornerRadius(8)
    }
}

// MARK: - Home ViewModel

@MainActor
class HomeViewModel: ObservableObject {
    @Published var todayCalories: Int = 0
    @Published var todayProtein: Double = 0
    @Published var todayCarbs: Double = 0
    @Published var todayFats: Double = 0
    @Published var recommendedRecipes: [Recipe] = []
    @Published var recentActivities: [Activity] = []

    func loadDashboardData() async {
        // Load today's nutrition stats
        // Load recommended recipes
        // Load recent activities
        // This would make API calls to fetch actual data
    }
}

// MARK: - Activity Model

struct Activity: Identifiable {
    let id = UUID()
    let title: String
    let time: String
    let icon: String
    let color: Color
}

// MARK: - Preview

struct HomeView_Previews: PreviewProvider {
    static var previews: some View {
        HomeView()
            .environmentObject(AuthenticationViewModel())
            .environmentObject(AppState())
    }
}
