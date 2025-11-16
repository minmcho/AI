//
//  NutriVisionWidget.swift
//  NutriVision AI Widget
//
//  Home screen widgets for quick stats
//

import WidgetKit
import SwiftUI

// MARK: - Widget Entry

struct NutritionEntry: TimelineEntry {
    let date: Date
    let todayCalories: Int
    let calorieGoal: Int
    let protein: Double
    let carbs: Double
    let fat: Double
    let water: Double
}

// MARK: - Timeline Provider

struct NutritionProvider: TimelineProvider {
    func placeholder(in context: Context) -> NutritionEntry {
        NutritionEntry(
            date: Date(),
            todayCalories: 1200,
            calorieGoal: 2000,
            protein: 45,
            carbs: 150,
            fat: 40,
            water: 1500
        )
    }

    func getSnapshot(in context: Context, completion: @escaping (NutritionEntry) -> Void) {
        let entry = placeholder(in: context)
        completion(entry)
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<NutritionEntry>) -> Void) {
        Task {
            // Fetch data from HealthKit
            let healthKit = HealthKitManager.shared

            do {
                try await healthKit.fetchTodayNutrition()

                let entry = NutritionEntry(
                    date: Date(),
                    todayCalories: Int(healthKit.todayCalories),
                    calorieGoal: 2000, // TODO: Fetch from user profile
                    protein: healthKit.todayProtein,
                    carbs: healthKit.todayCarbs,
                    fat: healthKit.todayFat,
                    water: healthKit.todayWater
                )

                // Update every 30 minutes
                let nextUpdate = Calendar.current.date(byAdding: .minute, value: 30, to: Date())!
                let timeline = Timeline(entries: [entry], policy: .after(nextUpdate))

                completion(timeline)
            } catch {
                // Return placeholder on error
                let entry = placeholder(in: context)
                let timeline = Timeline(entries: [entry], policy: .atEnd)
                completion(timeline)
            }
        }
    }
}

// MARK: - Widget Views

struct NutritionWidgetView: View {
    @Environment(\.widgetFamily) var family
    var entry: NutritionEntry

    var body: some View {
        switch family {
        case .systemSmall:
            SmallWidgetView(entry: entry)
        case .systemMedium:
            MediumWidgetView(entry: entry)
        case .systemLarge:
            LargeWidgetView(entry: entry)
        default:
            SmallWidgetView(entry: entry)
        }
    }
}

// MARK: - Small Widget

struct SmallWidgetView: View {
    let entry: NutritionEntry

    var progress: Double {
        Double(entry.todayCalories) / Double(entry.calorieGoal)
    }

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [Color.green.opacity(0.7), Color.blue.opacity(0.5)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            VStack(spacing: 8) {
                Image(systemName: "flame.fill")
                    .font(.title)
                    .foregroundColor(.white)

                Text("\(entry.todayCalories)")
                    .font(.system(size: 32, weight: .bold))
                    .foregroundColor(.white)

                Text("/ \(entry.calorieGoal) cal")
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.9))

                // Progress ring
                ZStack {
                    Circle()
                        .stroke(Color.white.opacity(0.3), lineWidth: 4)

                    Circle()
                        .trim(from: 0, to: min(progress, 1.0))
                        .stroke(Color.white, style: StrokeStyle(lineWidth: 4, lineCap: .round))
                        .rotationEffect(.degrees(-90))
                }
                .frame(width: 50, height: 50)
            }
        }
    }
}

// MARK: - Medium Widget

struct MediumWidgetView: View {
    let entry: NutritionEntry

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [Color.green.opacity(0.7), Color.blue.opacity(0.5)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            HStack(spacing: 16) {
                // Calories
                VStack(spacing: 4) {
                    Image(systemName: "flame.fill")
                        .font(.title2)
                        .foregroundColor(.white)

                    Text("\(entry.todayCalories)")
                        .font(.title)
                        .fontWeight(.bold)
                        .foregroundColor(.white)

                    Text("/ \(entry.calorieGoal)")
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.9))

                    Text("Calories")
                        .font(.caption2)
                        .foregroundColor(.white.opacity(0.8))
                }
                .frame(maxWidth: .infinity)

                Divider()
                    .background(Color.white.opacity(0.3))

                // Macros
                VStack(alignment: .leading, spacing: 8) {
                    MacroRow(
                        icon: "p.circle.fill",
                        label: "Protein",
                        value: String(format: "%.0fg", entry.protein),
                        color: .red
                    )

                    MacroRow(
                        icon: "c.circle.fill",
                        label: "Carbs",
                        value: String(format: "%.0fg", entry.carbs),
                        color: .blue
                    )

                    MacroRow(
                        icon: "f.circle.fill",
                        label: "Fat",
                        value: String(format: "%.0fg", entry.fat),
                        color: .yellow
                    )
                }
                .frame(maxWidth: .infinity)
            }
            .padding()
        }
    }
}

struct MacroRow: View {
    let icon: String
    let label: String
    let value: String
    let color: Color

    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: icon)
                .foregroundColor(color)
                .font(.caption)

            Text(label)
                .font(.caption)
                .foregroundColor(.white.opacity(0.9))

            Spacer()

            Text(value)
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundColor(.white)
        }
    }
}

// MARK: - Large Widget

struct LargeWidgetView: View {
    let entry: NutritionEntry

    var calorieProgress: Double {
        Double(entry.todayCalories) / Double(entry.calorieGoal)
    }

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [Color.green.opacity(0.7), Color.blue.opacity(0.5)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            VStack(spacing: 16) {
                // Header
                HStack {
                    Image(systemName: "leaf.circle.fill")
                        .font(.title2)
                        .foregroundColor(.white)

                    Text("Today's Nutrition")
                        .font(.headline)
                        .foregroundColor(.white)

                    Spacer()

                    Text(entry.date, style: .time)
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.8))
                }

                // Calories with ring
                ZStack {
                    Circle()
                        .stroke(Color.white.opacity(0.3), lineWidth: 8)
                        .frame(width: 120, height: 120)

                    Circle()
                        .trim(from: 0, to: min(calorieProgress, 1.0))
                        .stroke(Color.white, style: StrokeStyle(lineWidth: 8, lineCap: .round))
                        .frame(width: 120, height: 120)
                        .rotationEffect(.degrees(-90))

                    VStack(spacing: 4) {
                        Text("\(entry.todayCalories)")
                            .font(.system(size: 28, weight: .bold))
                            .foregroundColor(.white)

                        Text("/ \(entry.calorieGoal)")
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.9))

                        Text("calories")
                            .font(.caption2)
                            .foregroundColor(.white.opacity(0.8))
                    }
                }

                // Macros grid
                HStack(spacing: 12) {
                    MacroCard(
                        icon: "p.circle.fill",
                        label: "Protein",
                        value: String(format: "%.0fg", entry.protein),
                        color: .red
                    )

                    MacroCard(
                        icon: "c.circle.fill",
                        label: "Carbs",
                        value: String(format: "%.0fg", entry.carbs),
                        color: .blue
                    )

                    MacroCard(
                        icon: "f.circle.fill",
                        label: "Fat",
                        value: String(format: "%.0fg", entry.fat),
                        color: .yellow
                    )
                }

                // Water
                HStack {
                    Image(systemName: "drop.fill")
                        .foregroundColor(.cyan)

                    Text("Water: \(Int(entry.water))ml")
                        .font(.subheadline)
                        .foregroundColor(.white)

                    Spacer()
                }
                .padding(.horizontal, 8)
            }
            .padding()
        }
    }
}

struct MacroCard: View {
    let icon: String
    let label: String
    let value: String
    let color: Color

    var body: some View {
        VStack(spacing: 6) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(color)

            Text(value)
                .font(.headline)
                .fontWeight(.bold)
                .foregroundColor(.white)

            Text(label)
                .font(.caption2)
                .foregroundColor(.white.opacity(0.8))
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
        .background(Color.white.opacity(0.2))
        .cornerRadius(8)
    }
}

// MARK: - Widget Configuration

@main
struct NutriVisionWidget: Widget {
    let kind: String = "NutriVisionWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: NutritionProvider()) { entry in
            NutritionWidgetView(entry: entry)
        }
        .configurationDisplayName("Nutrition Stats")
        .description("Track your daily nutrition at a glance")
        .supportedFamilies([.systemSmall, .systemMedium, .systemLarge])
    }
}

// MARK: - Preview

struct NutriVisionWidget_Previews: PreviewProvider {
    static var previews: some View {
        let entry = NutritionEntry(
            date: Date(),
            todayCalories: 1200,
            calorieGoal: 2000,
            protein: 45,
            carbs: 150,
            fat: 40,
            water: 1500
        )

        Group {
            NutritionWidgetView(entry: entry)
                .previewContext(WidgetPreviewContext(family: .systemSmall))

            NutritionWidgetView(entry: entry)
                .previewContext(WidgetPreviewContext(family: .systemMedium))

            NutritionWidgetView(entry: entry)
                .previewContext(WidgetPreviewContext(family: .systemLarge))
        }
    }
}
