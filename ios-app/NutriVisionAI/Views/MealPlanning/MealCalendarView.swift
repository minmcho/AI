//
//  MealCalendarView.swift
//  NutriVision AI
//
//  Calendar view for meal plans
//

import SwiftUI

struct MealCalendarView: View {
    @Environment(\.presentationMode) var presentationMode
    @StateObject private var viewModel = MealPlanViewModel()

    let mealPlan: MealPlan
    @State private var selectedDate: Date = Date()

    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Calendar
                CalendarWeekView(
                    selectedDate: $selectedDate,
                    mealPlan: mealPlan
                )
                .padding()

                Divider()

                // Meals for selected date
                ScrollView {
                    VStack(spacing: 16) {
                        // Date header
                        HStack {
                            Text(selectedDate, style: .date)
                                .font(.title3)
                                .fontWeight(.bold)

                            Spacer()

                            Text("\(mealsForSelectedDate.count) meals")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                        .padding()

                        // Meals
                        if mealsForSelectedDate.isEmpty {
                            VStack(spacing: 16) {
                                Image(systemName: "fork.knife")
                                    .resizable()
                                    .scaledToFit()
                                    .frame(width: 60, height: 60)
                                    .foregroundColor(.gray)
                                    .padding(.top, 40)

                                Text("No meals planned")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                            }
                        } else {
                            ForEach(mealsForSelectedDate) { meal in
                                MealCard(meal: meal)
                            }
                            .padding(.horizontal)
                        }
                    }
                    .padding(.vertical)
                }
            }
            .navigationTitle(mealPlan.name)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        presentationMode.wrappedValue.dismiss()
                    }
                }
            }
            .onAppear {
                viewModel.loadCalendarMeals(for: mealPlan)
            }
        }
    }

    var mealsForSelectedDate: [Meal] {
        viewModel.getMealsForDate(selectedDate)
    }
}

// MARK: - Calendar Week View

struct CalendarWeekView: View {
    @Binding var selectedDate: Date
    let mealPlan: MealPlan

    @State private var weekDates: [Date] = []

    var body: some View {
        VStack(spacing: 12) {
            // Week navigation
            HStack {
                Button(action: previousWeek) {
                    Image(systemName: "chevron.left")
                        .foregroundColor(.green)
                }

                Spacer()

                Text(weekTitle)
                    .font(.headline)

                Spacer()

                Button(action: nextWeek) {
                    Image(systemName: "chevron.right")
                        .foregroundColor(.green)
                }
            }

            // Week days
            HStack(spacing: 8) {
                ForEach(weekDates, id: \.self) { date in
                    DayCell(
                        date: date,
                        isSelected: Calendar.current.isDate(date, inSameDayAs: selectedDate),
                        hasMeals: hasMealsOnDate(date)
                    ) {
                        selectedDate = date
                    }
                }
            }
        }
        .onAppear {
            setupWeekDates()
        }
    }

    private var weekTitle: String {
        guard let firstDate = weekDates.first,
              let lastDate = weekDates.last else {
            return ""
        }

        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d"

        if Calendar.current.isDate(firstDate, equalTo: lastDate, toGranularity: .month) {
            return formatter.string(from: firstDate) + " - " + String(Calendar.current.component(.day, from: lastDate))
        } else {
            return formatter.string(from: firstDate) + " - " + formatter.string(from: lastDate)
        }
    }

    private func setupWeekDates() {
        let calendar = Calendar.current
        var dates: [Date] = []

        let weekday = calendar.component(.weekday, from: selectedDate)
        let daysToSubtract = (weekday + 5) % 7 // Monday as start
        guard let weekStart = calendar.date(byAdding: .day, value: -daysToSubtract, to: selectedDate) else {
            return
        }

        for i in 0..<7 {
            if let date = calendar.date(byAdding: .day, value: i, to: weekStart) {
                dates.append(date)
            }
        }

        weekDates = dates
    }

    private func previousWeek() {
        guard let newDate = Calendar.current.date(byAdding: .day, value: -7, to: selectedDate) else {
            return
        }
        selectedDate = newDate
        setupWeekDates()
    }

    private func nextWeek() {
        guard let newDate = Calendar.current.date(byAdding: .day, value: 7, to: selectedDate) else {
            return
        }
        selectedDate = newDate
        setupWeekDates()
    }

    private func hasMealsOnDate(_ date: Date) -> Bool {
        let dateString = ISO8601DateFormatter().string(from: date).prefix(10)
        return mealPlan.meals.contains { $0.date.hasPrefix(String(dateString)) }
    }
}

// MARK: - Day Cell

struct DayCell: View {
    let date: Date
    let isSelected: Bool
    let hasMeals: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Text(dayOfWeek)
                    .font(.caption)
                    .foregroundColor(isSelected ? .white : .secondary)

                Text("\(dayOfMonth)")
                    .font(.subheadline)
                    .fontWeight(isSelected ? .bold : .regular)
                    .foregroundColor(isSelected ? .white : .primary)

                if hasMeals {
                    Circle()
                        .fill(isSelected ? Color.white : Color.green)
                        .frame(width: 4, height: 4)
                } else {
                    Circle()
                        .fill(Color.clear)
                        .frame(width: 4, height: 4)
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(isSelected ? Color.green : Color(.systemGray6))
            .cornerRadius(12)
        }
    }

    private var dayOfWeek: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEE"
        return formatter.string(from: date).uppercased()
    }

    private var dayOfMonth: Int {
        Calendar.current.component(.day, from: date)
    }
}

// MARK: - Meal Card

struct MealCard: View {
    let meal: Meal

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Meal type header
            HStack {
                Image(systemName: mealTypeIcon)
                    .foregroundColor(.green)

                Text(meal.mealType.capitalized)
                    .font(.headline)

                Spacer()

                if let time = meal.time {
                    Text(time)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }

            if let recipe = meal.recipe {
                VStack(alignment: .leading, spacing: 8) {
                    Text(recipe.name)
                        .font(.body)
                        .fontWeight(.medium)

                    if let nutrition = recipe.nutrition {
                        HStack(spacing: 16) {
                            NutritionBadge(
                                icon: "flame.fill",
                                value: "\(nutrition.calories)",
                                label: "cal"
                            )
                            NutritionBadge(
                                icon: "p.circle.fill",
                                value: String(format: "%.0f", nutrition.protein),
                                label: "g"
                            )
                            NutritionBadge(
                                icon: "c.circle.fill",
                                value: String(format: "%.0f", nutrition.carbs),
                                label: "g"
                            )
                        }
                        .font(.caption)
                    }
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .gray.opacity(0.1), radius: 3, x: 0, y: 1)
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

struct MealCalendarView_Previews: PreviewProvider {
    static var previews: some View {
        MealCalendarView(mealPlan: MealPlan(
            id: 1,
            name: "Weekly Plan",
            startDate: "2024-01-01",
            endDate: "2024-01-07",
            meals: []
        ))
    }
}
