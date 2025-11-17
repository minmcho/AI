//
//  RecipeNarrationView.swift
//  NutriVision AI
//
//  Voice-guided step-by-step recipe narration
//

import SwiftUI
import AVFoundation

struct RecipeNarrationView: View {
    let recipe: Recipe
    @StateObject private var viewModel = RecipeNarrationViewModel()
    @Environment(\.presentationMode) var presentationMode

    @State private var currentStepIndex: Int = 0
    @State private var isPlaying: Bool = false

    var body: some View {
        ZStack {
            // Background gradient
            LinearGradient(
                colors: [Color.blue.opacity(0.1), Color.purple.opacity(0.1)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            VStack(spacing: 0) {
                // Header
                VStack(spacing: 12) {
                    Text(recipe.name)
                        .font(.title2)
                        .fontWeight(.bold)
                        .multilineTextAlignment(.center)

                    // Progress
                    HStack {
                        Text("Step \(currentStepIndex + 1) of \(recipe.instructions.count)")
                            .font(.subheadline)
                            .foregroundColor(.secondary)

                        Spacer()

                        // Progress Bar
                        ProgressView(value: Double(currentStepIndex + 1), total: Double(recipe.instructions.count))
                            .frame(width: 100)
                            .tint(.blue)
                    }
                }
                .padding()
                .background(Color.white.opacity(0.9))

                Spacer()

                // Current Step
                if currentStepIndex < recipe.instructions.count {
                    VStack(spacing: 24) {
                        // Step Number Badge
                        ZStack {
                            Circle()
                                .fill(Color.blue.opacity(0.2))
                                .frame(width: 80, height: 80)

                            Text("\(currentStepIndex + 1)")
                                .font(.system(size: 40, weight: .bold))
                                .foregroundColor(.blue)
                        }

                        // Step Text
                        ScrollView {
                            Text(recipe.instructions[currentStepIndex])
                                .font(.title3)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal, 32)
                        }
                        .frame(maxHeight: 200)

                        // Timer (if step has duration)
                        if let duration = stepDuration(currentStepIndex) {
                            HStack(spacing: 8) {
                                Image(systemName: "timer")
                                    .foregroundColor(.orange)
                                Text(formatDuration(duration))
                                    .font(.headline)
                                    .foregroundColor(.orange)
                            }
                            .padding(.horizontal, 20)
                            .padding(.vertical, 10)
                            .background(Color.orange.opacity(0.1))
                            .cornerRadius(20)
                        }
                    }
                }

                Spacer()

                // Controls
                VStack(spacing: 20) {
                    // Navigation Buttons
                    HStack(spacing: 40) {
                        // Previous Button
                        Button(action: {
                            if currentStepIndex > 0 {
                                currentStepIndex -= 1
                                viewModel.speak(recipe.instructions[currentStepIndex])
                            }
                        }) {
                            Image(systemName: "backward.fill")
                                .font(.title)
                                .frame(width: 60, height: 60)
                                .background(Circle().fill(currentStepIndex > 0 ? Color.blue : Color.gray.opacity(0.3)))
                                .foregroundColor(.white)
                        }
                        .disabled(currentStepIndex == 0)

                        // Play/Pause Button
                        Button(action: {
                            if isPlaying {
                                viewModel.pauseSpeaking()
                                isPlaying = false
                            } else {
                                viewModel.speak(recipe.instructions[currentStepIndex])
                                isPlaying = true
                            }
                        }) {
                            Image(systemName: isPlaying ? "pause.fill" : "play.fill")
                                .font(.title)
                                .frame(width: 80, height: 80)
                                .background(Circle().fill(Color.blue))
                                .foregroundColor(.white)
                        }

                        // Next Button
                        Button(action: {
                            if currentStepIndex < recipe.instructions.count - 1 {
                                currentStepIndex += 1
                                viewModel.speak(recipe.instructions[currentStepIndex])
                            }
                        }) {
                            Image(systemName: "forward.fill")
                                .font(.title)
                                .frame(width: 60, height: 60)
                                .background(Circle().fill(currentStepIndex < recipe.instructions.count - 1 ? Color.blue : Color.gray.opacity(0.3)))
                                .foregroundColor(.white)
                        }
                        .disabled(currentStepIndex >= recipe.instructions.count - 1)
                    }

                    // Additional Controls
                    HStack(spacing: 20) {
                        // Repeat Button
                        Button(action: {
                            viewModel.speak(recipe.instructions[currentStepIndex])
                            isPlaying = true
                        }) {
                            HStack {
                                Image(systemName: "arrow.counterclockwise")
                                Text("Repeat")
                            }
                            .font(.subheadline)
                            .padding(.horizontal, 20)
                            .padding(.vertical, 10)
                            .background(Color.gray.opacity(0.2))
                            .foregroundColor(.primary)
                            .cornerRadius(20)
                        }

                        // Speed Control
                        Menu {
                            Button("0.75x") { viewModel.setSpeechRate(0.4) }
                            Button("1.0x (Normal)") { viewModel.setSpeechRate(0.5) }
                            Button("1.25x") { viewModel.setSpeechRate(0.6) }
                            Button("1.5x") { viewModel.setSpeechRate(0.7) }
                        } label: {
                            HStack {
                                Image(systemName: "speedometer")
                                Text("Speed")
                            }
                            .font(.subheadline)
                            .padding(.horizontal, 20)
                            .padding(.vertical, 10)
                            .background(Color.gray.opacity(0.2))
                            .foregroundColor(.primary)
                            .cornerRadius(20)
                        }
                    }
                }
                .padding()
                .background(Color.white.opacity(0.9))
            }
        }
        .navigationTitle("Cooking Mode")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("Done") {
                    viewModel.stopSpeaking()
                    presentationMode.wrappedValue.dismiss()
                }
            }
        }
        .onAppear {
            viewModel.speak(recipe.instructions[currentStepIndex])
            isPlaying = true
        }
        .onDisappear {
            viewModel.stopSpeaking()
        }
    }

    private func stepDuration(_ index: Int) -> Int? {
        // Extract duration from step text if it contains time markers
        // e.g., "Cook for 10 minutes" -> 10
        let step = recipe.instructions[index].lowercased()
        let patterns = [
            "\\d+\\s*minutes?",
            "\\d+\\s*mins?",
            "\\d+\\s*hours?",
            "\\d+\\s*hrs?"
        ]

        for pattern in patterns {
            if let range = step.range(of: pattern, options: .regularExpression) {
                let match = String(step[range])
                if let number = Int(match.components(separatedBy: CharacterSet.decimalDigits.inverted).joined()) {
                    if match.contains("hour") || match.contains("hr") {
                        return number * 60
                    }
                    return number
                }
            }
        }
        return nil
    }

    private func formatDuration(_ minutes: Int) -> String {
        if minutes >= 60 {
            let hours = minutes / 60
            let mins = minutes % 60
            if mins > 0 {
                return "\(hours)h \(mins)m"
            }
            return "\(hours)h"
        }
        return "\(minutes) min"
    }
}

// MARK: - ViewModel

@MainActor
class RecipeNarrationViewModel: ObservableObject {
    private var synthesizer = AVSpeechSynthesizer()
    private var speechRate: Float = 0.5

    func speak(_ text: String) {
        stopSpeaking()

        let utterance = AVSpeechUtterance(string: text)
        utterance.rate = speechRate
        utterance.voice = AVSpeechSynthesisVoice(language: "en-US")
        utterance.volume = 1.0

        synthesizer.speak(utterance)
    }

    func pauseSpeaking() {
        synthesizer.pauseSpeaking(at: .immediate)
    }

    func continueSpeaking() {
        synthesizer.continueSpeaking()
    }

    func stopSpeaking() {
        synthesizer.stopSpeaking(at: .immediate)
    }

    func setSpeechRate(_ rate: Float) {
        speechRate = rate
    }
}

// MARK: - Preview

struct RecipeNarrationView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            RecipeNarrationView(recipe: Recipe(
                id: "1",
                name: "Classic Spaghetti Carbonara",
                description: "Traditional Italian pasta dish",
                cuisine: "Italian",
                difficulty: "Medium",
                prepTime: 15,
                cookTime: 20,
                servings: 4,
                instructions: [
                    "Bring a large pot of salted water to a boil",
                    "Cook the spaghetti according to package directions for 10 minutes",
                    "While pasta cooks, fry the pancetta until crispy for 5 minutes",
                    "Beat eggs with Parmesan cheese in a bowl",
                    "Drain pasta, reserving 1 cup of pasta water",
                    "Toss hot pasta with pancetta and remove from heat",
                    "Quickly stir in egg mixture, adding pasta water to create a creamy sauce",
                    "Season with black pepper and serve immediately"
                ],
                ingredients: [],
                imageUrl: nil,
                videoUrl: nil,
                calories: 550,
                protein: 25,
                carbs: 60,
                fat: 22,
                tags: ["Italian", "Pasta", "Quick"],
                authorId: nil,
                createdAt: nil
            ))
        }
    }
}
