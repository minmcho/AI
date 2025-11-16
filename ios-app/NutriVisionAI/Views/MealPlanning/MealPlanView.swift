//
//  MealPlanView.swift
//  NutriVision AI
//
//  Meal planning main view
//

import SwiftUI

struct MealPlanView: View {
    @StateObject private var viewModel = MealPlanViewModel()
    @State private var showGenerator = false
    @State private var showCalendar = false

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    if viewModel.isLoading && viewModel.mealPlans.isEmpty {
                        LoadingView(message: "Loading meal plans...")
                    } else if let currentPlan = viewModel.currentWeekPlan {
                        // Current week plan
                        VStack(spacing: 16) {
                            HStack {
                                Text("This Week's Plan")
                                    .font(.title2)
                                    .fontWeight(.bold)

                                Spacer()

                                Button(action: { showCalendar = true }) {
                                    Image(systemName: "calendar")
                                        .foregroundColor(.green)
                                }
                            }
                            .padding(.horizontal)

                            CurrentMealPlanCard(mealPlan: currentPlan)
                                .padding(.horizontal)
                        }

                        Divider()
                            .padding(.vertical)

                        // All meal plans
                        if !viewModel.mealPlans.isEmpty {
                            VStack(alignment: .leading, spacing: 16) {
                                Text("All Meal Plans")
                                    .font(.headline)
                                    .padding(.horizontal)

                                ForEach(viewModel.mealPlans) { plan in
                                    MealPlanRow(mealPlan: plan)
                                        .padding(.horizontal)
                                        .onTapGesture {
                                            viewModel.selectedMealPlan = plan
                                        }
                                }
                            }
                        }
                    } else {
                        // Empty state
                        VStack(spacing: 24) {
                            Image(systemName: "calendar.badge.plus")
                                .resizable()
                                .scaledToFit()
                                .frame(width: 80, height: 80)
                                .foregroundColor(.green)
                                .padding(.top, 60)

                            Text("No Meal Plan Yet")
                                .font(.title2)
                                .fontWeight(.bold)

                            Text("Create a personalized meal plan based on your preferences and health goals")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal, 40)

                            CustomButton(
                                title: "Generate Meal Plan",
                                icon: "wand.and.stars",
                                style: .primary
                            ) {
                                showGenerator = true
                            }
                            .padding(.horizontal, 32)
                        }
                    }
                }
                .padding(.vertical)
            }
            .navigationTitle("Meal Plans")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { showGenerator = true }) {
                        Image(systemName: "plus.circle.fill")
                            .foregroundColor(.green)
                    }
                }
            }
            .refreshable {
                await viewModel.loadMealPlans()
            }
            .sheet(isPresented: $showGenerator) {
                MealPlanGeneratorView()
            }
            .sheet(isPresented: $showCalendar) {
                if let plan = viewModel.currentWeekPlan {
                    MealCalendarView(mealPlan: plan)
                }
            }
            .task {
                if viewModel.mealPlans.isEmpty {
                    await viewModel.loadMealPlans()
                }
            }
        }
    }
}

// MARK: - Current Meal Plan Card

struct CurrentMealPlanCard: View {
    let mealPlan: MealPlan

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(mealPlan.name)
                        .font(.headline)

                    Text("\(mealPlan.startDate) - \(mealPlan.endDate)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                Spacer()

                Text("\(mealPlan.meals.count) meals")
                    .font(.subheadline)
                    .foregroundColor(.green)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Color.green.opacity(0.1))
                    .cornerRadius(12)
            }

            // Today's meals
            if !todayMeals.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Today")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(.secondary)

                    ForEach(todayMeals) { meal in
                        MealTimeRow(meal: meal)
                    }
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: .gray.opacity(0.2), radius: 5, x: 0, y: 2)
    }

    var todayMeals: [Meal] {
        let today = ISO8601DateFormatter().string(from: Date()).prefix(10)
        return mealPlan.meals.filter { $0.date.hasPrefix(String(today)) }
    }
}

// MARK: - Meal Time Row

struct MealTimeRow: View {
    let meal: Meal

    var body: some View {
        HStack {
            Image(systemName: mealTypeIcon)
                .foregroundColor(.green)

            Text(meal.mealType.capitalized)
                .font(.subheadline)

            Spacer()

            if let recipe = meal.recipe {
                Text(recipe.name)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(1)
            }
        }
        .padding(12)
        .background(Color(.systemGray6))
        .cornerRadius(8)
    }

    var mealTypeIcon: String {
        switch meal.mealType.lowercased() {
        case "breakfast":
            return "sunrise.fill"
        case "lunch":
            return "sun.max.fill"
        case "dinner":
            return "moon.stars.fill"
        case "snack":
            return "leaf.fill"
        default:
            return "fork.knife"
        }
    }
}

// MARK: - Meal Plan Row

struct MealPlanRow: View {
    let mealPlan: MealPlan

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 8) {
                Text(mealPlan.name)
                    .font(.headline)

                Text("\(mealPlan.startDate) - \(mealPlan.endDate)")
                    .font(.caption)
                    .foregroundColor(.secondary)

                HStack {
                    Label("\(mealPlan.meals.count) meals", systemImage: "fork.knife")
                        .font(.caption)
                        .foregroundColor(.green)
                }
            }

            Spacer()

            Image(systemName: "chevron.right")
                .foregroundColor(.gray)
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .gray.opacity(0.1), radius: 3, x: 0, y: 1)
    }
}

struct MealPlanView_Previews: PreviewProvider {
    static var previews: some View {
        MealPlanView()
    }
}
