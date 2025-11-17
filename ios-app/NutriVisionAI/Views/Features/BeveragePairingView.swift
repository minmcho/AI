//
//  BeveragePairingView.swift
//  NutriVision AI
//
//  AI-powered beverage pairing recommendations
//

import SwiftUI

struct BeveragePairingView: View {
    @StateObject private var viewModel = BeveragePairingViewModel()
    @State private var mealDescription: String = ""
    @State private var selectedPreferences: Set<String> = []

    let preferenceOptions = BeveragePairingService().getPreferenceOptions()

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Header
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Image(systemName: "wineglass")
                                .font(.title)
                                .foregroundColor(.purple)
                            Text("Beverage Pairing")
                                .font(.title2)
                                .fontWeight(.bold)
                        }

                        Text("Get sommelier-level recommendations for your meal")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    .padding(.horizontal)

                    // Meal Description
                    VStack(alignment: .leading, spacing: 8) {
                        Text("What are you eating?")
                            .font(.headline)

                        TextField("e.g., Grilled salmon with lemon butter", text: $mealDescription)
                            .textFieldStyle(.roundedBorder)
                            .padding(.horizontal)
                    }
                    .padding(.horizontal)

                    // Preferences
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Your Preferences")
                            .font(.headline)
                            .padding(.horizontal)

                        LazyVGrid(columns: [GridItem(.adaptive(minimum: 120))], spacing: 12) {
                            ForEach(preferenceOptions, id: \.self) { preference in
                                PreferenceChip(
                                    preference: preference,
                                    isSelected: selectedPreferences.contains(preference)
                                ) {
                                    if selectedPreferences.contains(preference) {
                                        selectedPreferences.remove(preference)
                                    } else {
                                        selectedPreferences.insert(preference)
                                    }
                                }
                            }
                        }
                        .padding(.horizontal)
                    }

                    // Get Recommendations Button
                    Button(action: {
                        Task {
                            await viewModel.getPairings(
                                meal: mealDescription,
                                preferences: Array(selectedPreferences)
                            )
                        }
                    }) {
                        HStack {
                            if viewModel.isLoading {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            } else {
                                Image(systemName: "sparkles")
                                Text("Get Recommendations")
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(canGetRecommendations ? Color.purple : Color.gray)
                        .foregroundColor(.white)
                        .cornerRadius(12)
                    }
                    .disabled(!canGetRecommendations || viewModel.isLoading)
                    .padding(.horizontal)

                    // Error Message
                    if let error = viewModel.errorMessage {
                        Text(error)
                            .foregroundColor(.red)
                            .font(.caption)
                            .padding(.horizontal)
                    }

                    // Results
                    if let response = viewModel.pairingResponse {
                        VStack(alignment: .leading, spacing: 16) {
                            Divider()

                            // AI Analysis
                            VStack(alignment: .leading, spacing: 8) {
                                HStack {
                                    Image(systemName: "person.fill.checkmark")
                                        .foregroundColor(.green)
                                    Text("Sommelier's Insight")
                                        .font(.headline)
                                }

                                Text(response.analysis)
                                    .font(.body)
                                    .padding()
                                    .background(Color.green.opacity(0.1))
                                    .cornerRadius(12)
                            }
                            .padding(.horizontal)

                            // Pairings
                            if !response.pairings.isEmpty {
                                VStack(alignment: .leading, spacing: 12) {
                                    Text("Recommended Pairings")
                                        .font(.headline)
                                        .padding(.horizontal)

                                    ForEach(response.pairings) { pairing in
                                        BeveragePairingCard(pairing: pairing)
                                    }
                                }
                            }

                            // Explanation
                            if let explanation = response.explanation {
                                VStack(alignment: .leading, spacing: 8) {
                                    Text("Why These Pairings?")
                                        .font(.headline)
                                        .padding(.horizontal)

                                    Text(explanation)
                                        .font(.subheadline)
                                        .foregroundColor(.secondary)
                                        .padding()
                                        .background(Color.purple.opacity(0.05))
                                        .cornerRadius(8)
                                        .padding(.horizontal)
                                }
                            }
                        }
                        .padding(.vertical)
                    }

                    Spacer()
                }
                .padding(.vertical)
            }
            .navigationTitle("Beverage Pairing")
            .navigationBarTitleDisplayMode(.inline)
        }
    }

    private var canGetRecommendations: Bool {
        !mealDescription.isEmpty
    }
}

// MARK: - Preference Chip

struct PreferenceChip: View {
    let preference: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(preference)
                .font(.caption)
                .fontWeight(isSelected ? .semibold : .regular)
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(isSelected ? Color.purple : Color.gray.opacity(0.2))
                .foregroundColor(isSelected ? .white : .primary)
                .cornerRadius(20)
        }
    }
}

// MARK: - Beverage Pairing Card

struct BeveragePairingCard: View {
    let pairing: BeveragePairing

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top) {
                // Icon based on type
                Image(systemName: beverageIcon(for: pairing.type))
                    .font(.title2)
                    .foregroundColor(beverageColor(for: pairing.type))
                    .frame(width: 40)

                VStack(alignment: .leading, spacing: 4) {
                    Text(pairing.beverage)
                        .font(.headline)

                    Text(pairing.type)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 2)
                        .background(beverageColor(for: pairing.type).opacity(0.2))
                        .cornerRadius(4)
                }

                Spacer()

                if let confidence = pairing.confidence {
                    VStack(spacing: 2) {
                        Text("\(Int(confidence * 100))%")
                            .font(.caption)
                            .fontWeight(.bold)
                        Text("Match")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                }
            }

            Text(pairing.reason)
                .font(.subheadline)
                .foregroundColor(.primary)

            if let temp = pairing.servingTemp {
                HStack {
                    Image(systemName: "thermometer")
                        .font(.caption)
                    Text("Serve: \(temp)")
                        .font(.caption)
                }
                .foregroundColor(.secondary)
            }
        }
        .padding()
        .background(Color.gray.opacity(0.05))
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(beverageColor(for: pairing.type).opacity(0.3), lineWidth: 1)
        )
        .padding(.horizontal)
    }

    private func beverageIcon(for type: String) -> String {
        switch type.lowercased() {
        case _ where type.contains("wine"):
            return "wineglass"
        case _ where type.contains("beer"):
            return "cup.and.saucer"
        case _ where type.contains("cocktail"):
            return "wineglass.fill"
        case _ where type.contains("tea"):
            return "cup.and.saucer.fill"
        case _ where type.contains("coffee"):
            return "cup.and.saucer"
        default:
            return "drop.fill"
        }
    }

    private func beverageColor(for type: String) -> Color {
        switch type.lowercased() {
        case _ where type.contains("wine"):
            return .purple
        case _ where type.contains("beer"):
            return .orange
        case _ where type.contains("cocktail"):
            return .pink
        case _ where type.contains("tea"):
            return .green
        case _ where type.contains("coffee"):
            return .brown
        default:
            return .blue
        }
    }
}

// MARK: - ViewModel

@MainActor
class BeveragePairingViewModel: ObservableObject {
    @Published var pairingResponse: BeveragePairingResponse?
    @Published var isLoading = false
    @Published var errorMessage: String?

    private let service = BeveragePairingService()

    func getPairings(meal: String, preferences: [String]) async {
        isLoading = true
        errorMessage = nil

        do {
            pairingResponse = try await service.getBeveragePairings(
                meal: meal,
                preferences: preferences
            )
        } catch {
            errorMessage = "Failed to get pairings: \(error.localizedDescription)"
        }

        isLoading = false
    }
}

// MARK: - Preview

struct BeveragePairingView_Previews: PreviewProvider {
    static var previews: some View {
        BeveragePairingView()
    }
}
