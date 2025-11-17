//
//  HomeViewModel.swift
//  NutriVision AI
//
//  ViewModel for home screen dashboard
//

import Foundation
import Combine

@MainActor
class HomeViewModel: ObservableObject {
    // MARK: - Published Properties

    @Published var userName: String = ""
    @Published var todayStats: DailyStats?
    @Published var recentMeals: [Meal] = []
    @Published var recommendedRecipes: [Recipe] = []
    @Published var trendingVideos: [Video] = []
    @Published var healthGoals: [HealthGoal] = []
    @Published var motivationalQuote: String = ""

    @Published var isLoadingStats = false
    @Published var isLoadingMeals = false
    @Published var isLoadingRecipes = false
    @Published var isLoadingVideos = false

    @Published var errorMessage: String?

    // MARK: - Services

    private let userService = UserService()
    private let mealService = MealService()
    private let recipeService = RecipeService()
    private let videoService = VideoService()

    // MARK: - Initialization

    init() {
        loadUserName()
        loadMotivationalQuote()
    }

    // MARK: - Public Methods

    func loadDashboard() async {
        await withTaskGroup(of: Void.self) { group in
            group.addTask { await self.loadTodayStats() }
            group.addTask { await self.loadRecentMeals() }
            group.addTask { await self.loadRecommendedRecipes() }
            group.addTask { await self.loadTrendingVideos() }
            group.addTask { await self.loadHealthGoals() }
        }
    }

    func refreshDashboard() async {
        errorMessage = nil
        await loadDashboard()
    }

    // MARK: - Private Methods

    private func loadUserName() {
        // Load from UserDefaults or Keychain
        if let user = try? userService.getCurrentUser() {
            userName = user.name
        }
    }

    private func loadTodayStats() async {
        isLoadingStats = true

        do {
            let startOfDay = DateUtils.startOfDay()
            let endOfDay = DateUtils.endOfDay()

            let meals = try await mealService.getMeals(
                startDate: startOfDay,
                endDate: endOfDay
            )

            var totalCalories = 0.0
            var totalProtein = 0.0
            var totalCarbs = 0.0
            var totalFat = 0.0

            for meal in meals {
                if let calories = meal.calories {
                    totalCalories += calories
                }
                if let protein = meal.protein {
                    totalProtein += protein
                }
                if let carbs = meal.carbs {
                    totalCarbs += carbs
                }
                if let fat = meal.fat {
                    totalFat += fat
                }
            }

            todayStats = DailyStats(
                date: Date(),
                caloriesConsumed: totalCalories,
                proteinConsumed: totalProtein,
                carbsConsumed: totalCarbs,
                fatConsumed: totalFat,
                mealsLogged: meals.count,
                caloriesGoal: 2000.0,
                proteinGoal: 150.0,
                carbsGoal: 200.0,
                fatGoal: 65.0
            )
        } catch {
            errorMessage = "Failed to load today's stats"
        }

        isLoadingStats = false
    }

    private func loadRecentMeals() async {
        isLoadingMeals = true

        do {
            let meals = try await mealService.getMeals(
                limit: 5,
                offset: 0
            )
            recentMeals = meals
        } catch {
            errorMessage = "Failed to load recent meals"
        }

        isLoadingMeals = false
    }

    private func loadRecommendedRecipes() async {
        isLoadingRecipes = true

        do {
            let recipes = try await recipeService.getRecipes(
                limit: 10,
                offset: 0
            )
            // TODO: Filter based on user preferences
            recommendedRecipes = Array(recipes.prefix(5))
        } catch {
            errorMessage = "Failed to load recipes"
        }

        isLoadingRecipes = false
    }

    private func loadTrendingVideos() async {
        isLoadingVideos = true

        do {
            let response = try await videoService.getTrendingVideos(
                cuisine: nil
            )
            trendingVideos = Array(response.videos.prefix(3))
        } catch {
            errorMessage = "Failed to load videos"
        }

        isLoadingVideos = false
    }

    private func loadHealthGoals() async {
        // Mock health goals
        healthGoals = [
            HealthGoal(
                id: "1",
                title: "Daily Calories",
                current: todayStats?.caloriesConsumed ?? 0,
                target: todayStats?.caloriesGoal ?? 2000,
                unit: "kcal",
                icon: "flame.fill",
                color: "orange"
            ),
            HealthGoal(
                id: "2",
                title: "Protein",
                current: todayStats?.proteinConsumed ?? 0,
                target: todayStats?.proteinGoal ?? 150,
                unit: "g",
                icon: "leaf.fill",
                color: "red"
            ),
            HealthGoal(
                id: "3",
                title: "Water Intake",
                current: 1.5,
                target: 2.5,
                unit: "L",
                icon: "drop.fill",
                color: "blue"
            )
        ]
    }

    private func loadMotivationalQuote() {
        let quotes = [
            "Every meal is a new opportunity to nourish your body.",
            "You are what you eat, so eat something amazing!",
            "Small changes in what you eat can lead to big results.",
            "Eating well is a form of self-respect.",
            "Your body deserves the best fuel possible.",
            "Good nutrition is the foundation of good health.",
            "Make every meal count towards your goals.",
            "Healthy eating is a journey, not a destination."
        ]
        motivationalQuote = quotes.randomElement() ?? quotes[0]
    }

    // MARK: - Computed Properties

    var caloriesProgress: Double {
        guard let stats = todayStats, stats.caloriesGoal > 0 else { return 0 }
        return min(stats.caloriesConsumed / stats.caloriesGoal, 1.0)
    }

    var proteinProgress: Double {
        guard let stats = todayStats, stats.proteinGoal > 0 else { return 0 }
        return min(stats.proteinConsumed / stats.proteinGoal, 1.0)
    }

    var carbsProgress: Double {
        guard let stats = todayStats, stats.carbsGoal > 0 else { return 0 }
        return min(stats.carbsConsumed / stats.carbsGoal, 1.0)
    }

    var fatProgress: Double {
        guard let stats = todayStats, stats.fatGoal > 0 else { return 0 }
        return min(stats.fatConsumed / stats.fatGoal, 1.0)
    }

    var greetingMessage: String {
        let hour = Calendar.current.component(.hour, from: Date())
        switch hour {
        case 5..<12:
            return "Good morning"
        case 12..<17:
            return "Good afternoon"
        case 17..<22:
            return "Good evening"
        default:
            return "Hello"
        }
    }
}

// MARK: - Models

struct DailyStats {
    let date: Date
    let caloriesConsumed: Double
    let proteinConsumed: Double
    let carbsConsumed: Double
    let fatConsumed: Double
    let mealsLogged: Int
    let caloriesGoal: Double
    let proteinGoal: Double
    let carbsGoal: Double
    let fatGoal: Double
}

struct HealthGoal: Identifiable {
    let id: String
    let title: String
    let current: Double
    let target: Double
    let unit: String
    let icon: String
    let color: String

    var progress: Double {
        guard target > 0 else { return 0 }
        return min(current / target, 1.0)
    }

    var percentage: Int {
        Int(progress * 100)
    }
}
