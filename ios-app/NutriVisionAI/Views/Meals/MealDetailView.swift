//
//  MealDetailView.swift
//  NutriVision AI
//
//  Detailed view of a logged meal
//

import SwiftUI

struct MealDetailView: View {
    let meal: Meal
    @StateObject private var viewModel = MealDetailViewModel()
    @Environment(\.presentationMode) var presentationMode
    @State private var showingDeleteAlert = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Meal Image
                if let imageUrl = meal.imageUrl {
                    AsyncImage(url: URL(string: imageUrl)) { phase in
                        switch phase {
                        case .empty:
                            Rectangle()
                                .fill(Color.gray.opacity(0.3))
                                .frame(height: 300)
                                .overlay(ProgressView())
                        case .success(let image):
                            image
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                                .frame(height: 300)
                                .clipped()
                        case .failure:
                            Rectangle()
                                .fill(Color.gray.opacity(0.3))
                                .frame(height: 300)
                                .overlay(
                                    Image(systemName: "photo")
                                        .foregroundColor(.gray)
                                        .font(.largeTitle)
                                )
                        @unknown default:
                            EmptyView()
                        }
                    }
                }

                VStack(alignment: .leading, spacing: 16) {
                    // Meal Name
                    Text(meal.name)
                        .font(.title)
                        .fontWeight(.bold)

                    // Meal Type and Time
                    HStack(spacing: 16) {
                        Label(meal.mealType.capitalized, systemImage: mealTypeIcon(meal.mealType))
                            .font(.subheadline)
                            .foregroundColor(.secondary)

                        if let timestamp = meal.timestamp {
                            Label(DateUtils.formatDateTime(timestamp), systemImage: "clock")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                    }

                    Divider()

                    // Nutrition Information
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Nutrition Facts")
                            .font(.headline)

                        NutritionCard(
                            calories: meal.calories,
                            protein: meal.protein,
                            carbs: meal.carbs,
                            fat: meal.fat,
                            showDetailed: true
                        )
                    }

                    // Analysis Results
                    if let analysis = meal.analysisResult {
                        Divider()

                        VStack(alignment: .leading, spacing: 12) {
                            Text("AI Analysis")
                                .font(.headline)

                            if let foodItems = analysis.foodItems, !foodItems.isEmpty {
                                VStack(alignment: .leading, spacing: 8) {
                                    Text("Detected Foods")
                                        .font(.subheadline)
                                        .fontWeight(.semibold)

                                    ForEach(foodItems, id: \.self) { item in
                                        HStack {
                                            Image(systemName: "checkmark.circle.fill")
                                                .foregroundColor(.green)
                                                .font(.caption)
                                            Text(item)
                                                .font(.subheadline)
                                        }
                                    }
                                }
                                .padding()
                                .background(Color.green.opacity(0.1))
                                .cornerRadius(12)
                            }

                            if let healthScore = analysis.healthScore {
                                HStack {
                                    Text("Health Score")
                                        .font(.subheadline)
                                        .fontWeight(.semibold)
                                    Spacer()
                                    Text("\(Int(healthScore))/100")
                                        .font(.title3)
                                        .fontWeight(.bold)
                                        .foregroundColor(healthScoreColor(healthScore))
                                }
                                .padding()
                                .background(Color.gray.opacity(0.1))
                                .cornerRadius(12)
                            }

                            if let suggestions = analysis.suggestions, !suggestions.isEmpty {
                                VStack(alignment: .leading, spacing: 8) {
                                    Text("Suggestions")
                                        .font(.subheadline)
                                        .fontWeight(.semibold)

                                    ForEach(suggestions, id: \.self) { suggestion in
                                        HStack(alignment: .top, spacing: 8) {
                                            Image(systemName: "lightbulb.fill")
                                                .foregroundColor(.yellow)
                                                .font(.caption)
                                            Text(suggestion)
                                                .font(.subheadline)
                                                .foregroundColor(.secondary)
                                        }
                                    }
                                }
                                .padding()
                                .background(Color.yellow.opacity(0.1))
                                .cornerRadius(12)
                            }
                        }
                    }

                    // Notes
                    if let notes = meal.notes, !notes.isEmpty {
                        Divider()

                        VStack(alignment: .leading, spacing: 8) {
                            Text("Notes")
                                .font(.headline)

                            Text(notes)
                                .font(.body)
                                .foregroundColor(.secondary)
                        }
                    }

                    // Location
                    if let location = meal.location, !location.isEmpty {
                        Divider()

                        HStack {
                            Image(systemName: "mappin.circle.fill")
                                .foregroundColor(.red)
                            Text(location)
                                .font(.subheadline)
                        }
                    }

                    // Tags
                    if let tags = meal.tags, !tags.isEmpty {
                        Divider()

                        VStack(alignment: .leading, spacing: 8) {
                            Text("Tags")
                                .font(.headline)

                            FlowLayout(spacing: 8) {
                                ForEach(tags, id: \.self) { tag in
                                    Text(tag)
                                        .font(.caption)
                                        .padding(.horizontal, 12)
                                        .padding(.vertical, 6)
                                        .background(Color.blue.opacity(0.2))
                                        .foregroundColor(.blue)
                                        .cornerRadius(16)
                                }
                            }
                        }
                    }

                    // Delete Button
                    Button(action: {
                        showingDeleteAlert = true
                    }) {
                        HStack {
                            Image(systemName: "trash")
                            Text("Delete Meal")
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.red.opacity(0.1))
                        .foregroundColor(.red)
                        .cornerRadius(12)
                    }
                    .padding(.top)
                }
                .padding()

                Spacer()
            }
        }
        .navigationTitle("Meal Details")
        .navigationBarTitleDisplayMode(.inline)
        .alert("Delete Meal", isPresented: $showingDeleteAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Delete", role: .destructive) {
                Task {
                    await viewModel.deleteMeal(meal.id)
                    presentationMode.wrappedValue.dismiss()
                }
            }
        } message: {
            Text("Are you sure you want to delete this meal? This action cannot be undone.")
        }
    }

    private func mealTypeIcon(_ type: String) -> String {
        switch type.lowercased() {
        case "breakfast": return "sunrise.fill"
        case "lunch": return "sun.max.fill"
        case "dinner": return "moon.stars.fill"
        case "snack": return "leaf.fill"
        default: return "fork.knife"
        }
    }

    private func healthScoreColor(_ score: Double) -> Color {
        if score >= 80 {
            return .green
        } else if score >= 60 {
            return .yellow
        } else {
            return .orange
        }
    }
}

// MARK: - Flow Layout for Tags

struct FlowLayout: Layout {
    var spacing: CGFloat = 8

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let result = FlowResult(
            in: proposal.replacingUnspecifiedDimensions().width,
            subviews: subviews,
            spacing: spacing
        )
        return result.size
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let result = FlowResult(
            in: bounds.width,
            subviews: subviews,
            spacing: spacing
        )
        for (index, subview) in subviews.enumerated() {
            subview.place(at: CGPoint(x: bounds.minX + result.positions[index].x, y: bounds.minY + result.positions[index].y), proposal: .unspecified)
        }
    }

    struct FlowResult {
        var size: CGSize
        var positions: [CGPoint]

        init(in maxWidth: CGFloat, subviews: Subviews, spacing: CGFloat) {
            var positions: [CGPoint] = []
            var size: CGSize = .zero
            var currentX: CGFloat = 0
            var currentY: CGFloat = 0
            var lineHeight: CGFloat = 0

            for subview in subviews {
                let subviewSize = subview.sizeThatFits(.unspecified)

                if currentX + subviewSize.width > maxWidth && currentX > 0 {
                    currentX = 0
                    currentY += lineHeight + spacing
                    lineHeight = 0
                }

                positions.append(CGPoint(x: currentX, y: currentY))
                lineHeight = max(lineHeight, subviewSize.height)
                currentX += subviewSize.width + spacing
                size.width = max(size.width, currentX - spacing)
            }

            size.height = currentY + lineHeight
            self.size = size
            self.positions = positions
        }
    }
}

// MARK: - ViewModel

@MainActor
class MealDetailViewModel: ObservableObject {
    private let mealService = MealService()

    func deleteMeal(_ id: String) async {
        do {
            try await mealService.deleteMeal(id: id)
        } catch {
            print("Failed to delete meal: \(error)")
        }
    }
}

// MARK: - Preview

struct MealDetailView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            MealDetailView(meal: Meal(
                id: "1",
                name: "Grilled Chicken Salad",
                mealType: "lunch",
                timestamp: Date(),
                imageUrl: nil,
                calories: 450.0,
                protein: 35.0,
                carbs: 25.0,
                fat: 20.0,
                notes: "Fresh and healthy lunch",
                location: "Home Kitchen",
                tags: ["Healthy", "High Protein", "Low Carb"],
                analysisResult: nil
            ))
        }
    }
}
