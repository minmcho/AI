//
//  AIAnalysisResultView.swift
//  NutriVision AI
//
//  Display results from AI analysis
//

import SwiftUI

struct AIAnalysisResultView: View {
    @Environment(\.presentationMode) var presentationMode
    @ObservedObject var viewModel: AIFeaturesViewModel
    let analysisType: FoodScannerView.AnalysisType

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // Image preview
                    if let image = viewModel.selectedImage {
                        Image(uiImage: image)
                            .resizable()
                            .scaledToFit()
                            .frame(height: 200)
                            .cornerRadius(12)
                            .shadow(radius: 5)
                    }

                    // Results based on analysis type
                    switch analysisType {
                    case .blip:
                        if let analysis = viewModel.foodAnalysis {
                            BLIPAnalysisResultView(analysis: analysis)
                        }

                    case .vision:
                        if let analysis = viewModel.visionAnalysis {
                            VisionAnalysisResultView(analysis: analysis)
                        }

                    case .caption:
                        if let caption = viewModel.captionResult {
                            CaptionResultView(caption: caption)
                        }

                    case .vqa:
                        EmptyView()
                    }

                    // Close button
                    Button(action: {
                        presentationMode.wrappedValue.dismiss()
                    }) {
                        Text("Done")
                            .fontWeight(.semibold)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.green)
                            .cornerRadius(12)
                    }
                    .padding(.horizontal, 32)
                    .padding(.bottom, 20)
                }
                .padding()
            }
            .navigationTitle("Analysis Results")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

// MARK: - BLIP Analysis Result View

struct BLIPAnalysisResultView: View {
    let analysis: BlipFoodAnalysisResponse

    var body: some View {
        VStack(spacing: 20) {
            // Header
            HStack {
                Image(systemName: "wand.and.stars")
                    .font(.title2)
                    .foregroundColor(.green)

                Text("BLIP Comprehensive Analysis")
                    .font(.headline)

                Spacer()
            }

            // Caption
            ResultCard(
                icon: "text.bubble.fill",
                title: "Description",
                value: analysis.caption,
                color: .blue
            )

            // Food Type
            ResultCard(
                icon: "fork.knife",
                title: "Food Type",
                value: analysis.foodType,
                color: .green
            )

            // Ingredients
            if let ingredients = analysis.ingredients {
                ResultCard(
                    icon: "list.bullet",
                    title: "Main Ingredients",
                    value: ingredients,
                    color: .orange
                )
            }

            // Cooking Method
            if let cookingMethod = analysis.cookingMethod {
                ResultCard(
                    icon: "flame.fill",
                    title: "Cooking Method",
                    value: cookingMethod,
                    color: .red
                )
            }

            // Cuisine
            if let cuisine = analysis.cuisine {
                ResultCard(
                    icon: "globe",
                    title: "Cuisine Type",
                    value: cuisine,
                    color: .purple
                )
            }

            // Servings
            if let servings = analysis.servings {
                ResultCard(
                    icon: "person.2.fill",
                    title: "Estimated Servings",
                    value: servings,
                    color: .teal
                )
            }

            // Confidence
            ConfidenceBar(confidence: analysis.confidence)
        }
    }
}

// MARK: - Vision Analysis Result View

struct VisionAnalysisResultView: View {
    let analysis: FoodAnalysisResponse

    var body: some View {
        VStack(spacing: 20) {
            // Header
            HStack {
                Image(systemName: "eye.fill")
                    .font(.title2)
                    .foregroundColor(.blue)

                Text("Vision AI Analysis")
                    .font(.headline)

                Spacer()
            }

            // Food name
            ResultCard(
                icon: "fork.knife",
                title: "Food Item",
                value: analysis.foodName,
                color: .green
            )

            // Nutrition
            if let nutrition = analysis.nutrition {
                VStack(alignment: .leading, spacing: 16) {
                    HStack {
                        Image(systemName: "chart.bar.fill")
                            .foregroundColor(.orange)
                        Text("Nutrition Information")
                            .font(.headline)
                    }

                    NutritionGrid(nutrition: nutrition)
                }
                .padding()
                .background(Color.orange.opacity(0.1))
                .cornerRadius(12)
            }

            // Confidence
            ConfidenceBar(confidence: analysis.confidence)
        }
    }
}

// MARK: - Caption Result View

struct CaptionResultView: View {
    let caption: BlipCaptionResponse

    var body: some View {
        VStack(spacing: 20) {
            // Header
            HStack {
                Image(systemName: "text.bubble.fill")
                    .font(.title2)
                    .foregroundColor(.purple)

                Text("Image Caption")
                    .font(.headline)

                Spacer()
            }

            // Caption
            VStack(alignment: .leading, spacing: 12) {
                Text(caption.caption)
                    .font(.title3)
                    .fontWeight(.medium)
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color.purple.opacity(0.1))
                    .cornerRadius(12)
            }

            // Model info
            HStack {
                Image(systemName: "cpu")
                    .foregroundColor(.secondary)
                Text("Model: \(caption.model)")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            // Confidence
            ConfidenceBar(confidence: caption.confidence)
        }
    }
}

// MARK: - Result Card Component

struct ResultCard: View {
    let icon: String
    let title: String
    let value: String
    let color: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(color)
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(.secondary)
            }

            Text(value)
                .font(.body)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding()
        .background(color.opacity(0.1))
        .cornerRadius(12)
    }
}

// MARK: - Confidence Bar

struct ConfidenceBar: View {
    let confidence: Double

    var confidencePercentage: Int {
        Int(confidence * 100)
    }

    var confidenceColor: Color {
        switch confidence {
        case 0.8...1.0:
            return .green
        case 0.6..<0.8:
            return .yellow
        default:
            return .orange
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: "checkmark.seal.fill")
                    .foregroundColor(confidenceColor)

                Text("Confidence: \(confidencePercentage)%")
                    .font(.subheadline)
                    .fontWeight(.semibold)

                Spacer()
            }

            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    Rectangle()
                        .fill(Color.gray.opacity(0.2))
                        .frame(height: 8)
                        .cornerRadius(4)

                    Rectangle()
                        .fill(confidenceColor)
                        .frame(width: geometry.size.width * CGFloat(confidence), height: 8)
                        .cornerRadius(4)
                }
            }
            .frame(height: 8)
        }
        .padding()
        .background(confidenceColor.opacity(0.1))
        .cornerRadius(12)
    }
}

// MARK: - Nutrition Grid

struct NutritionGrid: View {
    let nutrition: Nutrition

    var body: some View {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
            NutritionCell(label: "Calories", value: "\(nutrition.calories)", unit: "kcal")
            NutritionCell(label: "Protein", value: String(format: "%.1f", nutrition.protein), unit: "g")
            NutritionCell(label: "Carbs", value: String(format: "%.1f", nutrition.carbs), unit: "g")
            NutritionCell(label: "Fat", value: String(format: "%.1f", nutrition.fat), unit: "g")

            if let fiber = nutrition.fiber {
                NutritionCell(label: "Fiber", value: String(format: "%.1f", fiber), unit: "g")
            }

            if let sugar = nutrition.sugar {
                NutritionCell(label: "Sugar", value: String(format: "%.1f", sugar), unit: "g")
            }
        }
    }
}

struct NutritionCell: View {
    let label: String
    let value: String
    let unit: String

    var body: some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.title3)
                .fontWeight(.bold)
                .foregroundColor(.green)

            Text(unit)
                .font(.caption2)
                .foregroundColor(.secondary)

            Text(label)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(8)
    }
}

struct AIAnalysisResultView_Previews: PreviewProvider {
    static var previews: some View {
        let viewModel = AIFeaturesViewModel()
        AIAnalysisResultView(viewModel: viewModel, analysisType: .blip)
    }
}
