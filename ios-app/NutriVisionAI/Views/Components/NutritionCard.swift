//
//  NutritionCard.swift
//  NutriVision AI
//
//  Reusable nutrition information card component
//

import SwiftUI

struct NutritionCard: View {
    let calories: Double?
    let protein: Double?
    let carbs: Double?
    let fat: Double?
    var showDetailed: Bool = false

    var body: some View {
        VStack(spacing: 12) {
            // Header
            HStack {
                Image(systemName: "chart.bar.fill")
                    .foregroundColor(.blue)
                Text("Nutrition Facts")
                    .font(.headline)
                Spacer()
            }

            Divider()

            // Calories
            if let calories = calories {
                HStack {
                    Text("Calories")
                        .font(.subheadline)
                    Spacer()
                    Text("\(Int(calories))")
                        .font(.title3)
                        .fontWeight(.bold)
                    Text("kcal")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }

            if showDetailed {
                Divider()

                // Macros
                VStack(spacing: 8) {
                    if let protein = protein {
                        MacroRow(name: "Protein", amount: protein, unit: "g", color: .red)
                    }

                    if let carbs = carbs {
                        MacroRow(name: "Carbs", amount: carbs, unit: "g", color: .orange)
                    }

                    if let fat = fat {
                        MacroRow(name: "Fat", amount: fat, unit: "g", color: .purple)
                    }
                }
            } else {
                // Compact macro display
                HStack(spacing: 16) {
                    if let protein = protein {
                        MacroPill(name: "Protein", amount: protein, unit: "g", color: .red)
                    }

                    if let carbs = carbs {
                        MacroPill(name: "Carbs", amount: carbs, unit: "g", color: .orange)
                    }

                    if let fat = fat {
                        MacroPill(name: "Fat", amount: fat, unit: "g", color: .purple)
                    }
                }
            }
        }
        .padding()
        .background(Color.gray.opacity(0.05))
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.gray.opacity(0.2), lineWidth: 1)
        )
    }
}

// MARK: - Macro Row (Detailed)

struct MacroRow: View {
    let name: String
    let amount: Double
    let unit: String
    let color: Color

    var body: some View {
        HStack {
            Circle()
                .fill(color)
                .frame(width: 8, height: 8)

            Text(name)
                .font(.subheadline)

            Spacer()

            Text("\(Int(amount))\(unit)")
                .font(.subheadline)
                .fontWeight(.semibold)
        }
    }
}

// MARK: - Macro Pill (Compact)

struct MacroPill: View {
    let name: String
    let amount: Double
    let unit: String
    let color: Color

    var body: some View {
        VStack(spacing: 4) {
            Text("\(Int(amount))\(unit)")
                .font(.caption)
                .fontWeight(.bold)

            Text(name)
                .font(.caption2)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
        .background(color.opacity(0.1))
        .cornerRadius(8)
    }
}

struct NutritionCard_Previews: PreviewProvider {
    static var previews: some View {
        VStack(spacing: 16) {
            NutritionCard(
                calories: 450,
                protein: 25,
                carbs: 50,
                fat: 15,
                showDetailed: false
            )

            NutritionCard(
                calories: 450,
                protein: 25,
                carbs: 50,
                fat: 15,
                showDetailed: true
            )
        }
        .padding()
    }
}
