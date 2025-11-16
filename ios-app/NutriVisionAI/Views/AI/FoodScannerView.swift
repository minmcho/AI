//
//  FoodScannerView.swift
//  NutriVision AI
//
//  Food scanner with camera and BLIP analysis
//

import SwiftUI

struct FoodScannerView: View {
    @StateObject private var viewModel = AIFeaturesViewModel()
    @State private var showCamera = false
    @State private var showPhotoPicker = false
    @State private var showAnalysisResult = false
    @State private var analysisType: AnalysisType = .blip

    enum AnalysisType {
        case blip, vision, caption, vqa
    }

    var body: some View {
        NavigationView {
            ZStack {
                if viewModel.selectedImage == nil {
                    // Empty state
                    VStack(spacing: 24) {
                        Image(systemName: "camera.viewfinder")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 100, height: 100)
                            .foregroundColor(.green)

                        Text("Scan Your Food")
                            .font(.title)
                            .fontWeight(.bold)

                        Text("Use the camera to capture food images and get instant AI-powered nutritional analysis")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 40)

                        VStack(spacing: 16) {
                            Button(action: { showCamera = true }) {
                                Label("Take Photo", systemImage: "camera.fill")
                                    .font(.headline)
                                    .foregroundColor(.white)
                                    .frame(maxWidth: .infinity)
                                    .padding()
                                    .background(Color.green)
                                    .cornerRadius(12)
                            }

                            Button(action: { showPhotoPicker = true }) {
                                Label("Choose from Library", systemImage: "photo.fill")
                                    .font(.headline)
                                    .foregroundColor(.green)
                                    .frame(maxWidth: .infinity)
                                    .padding()
                                    .background(Color.green.opacity(0.1))
                                    .cornerRadius(12)
                            }
                        }
                        .padding(.horizontal, 32)
                    }
                } else {
                    // Image selected
                    ScrollView {
                        VStack(spacing: 20) {
                            // Image preview
                            Image(uiImage: viewModel.selectedImage!)
                                .resizable()
                                .scaledToFit()
                                .frame(maxHeight: 300)
                                .cornerRadius(12)
                                .shadow(radius: 5)
                                .padding()

                            // Analysis options
                            VStack(spacing: 12) {
                                Text("Choose Analysis Type")
                                    .font(.headline)

                                // BLIP Comprehensive Analysis
                                AnalysisOptionCard(
                                    icon: "wand.and.stars",
                                    title: "Comprehensive Analysis",
                                    description: "Get detailed food info using BLIP AI",
                                    color: .green,
                                    isLoading: viewModel.isLoading && analysisType == .blip
                                ) {
                                    analysisType = .blip
                                    analyzeWithBLIP()
                                }

                                // Vision AI Analysis
                                AnalysisOptionCard(
                                    icon: "eye.fill",
                                    title: "Vision Analysis",
                                    description: "Nutritional analysis with Vision AI",
                                    color: .blue,
                                    isLoading: viewModel.isLoading && analysisType == .vision
                                ) {
                                    analysisType = .vision
                                    analyzeWithVision()
                                }

                                // BLIP Caption
                                AnalysisOptionCard(
                                    icon: "text.bubble.fill",
                                    title: "Generate Caption",
                                    description: "Get a natural language description",
                                    color: .purple,
                                    isLoading: viewModel.isLoading && analysisType == .caption
                                ) {
                                    analysisType = .caption
                                    generateCaption()
                                }

                                // Visual Q&A
                                NavigationLink(destination: BLIPVQAView(image: viewModel.selectedImage!)) {
                                    HStack {
                                        Image(systemName: "questionmark.circle.fill")
                                            .foregroundColor(.orange)
                                            .font(.title2)

                                        VStack(alignment: .leading) {
                                            Text("Ask Questions")
                                                .font(.headline)
                                            Text("Ask specific questions about the image")
                                                .font(.caption)
                                                .foregroundColor(.secondary)
                                        }

                                        Spacer()

                                        Image(systemName: "chevron.right")
                                            .foregroundColor(.gray)
                                    }
                                    .padding()
                                    .background(Color(.systemGray6))
                                    .cornerRadius(12)
                                }
                            }
                            .padding(.horizontal)

                            // Error message
                            if let error = viewModel.errorMessage {
                                Text(error)
                                    .font(.caption)
                                    .foregroundColor(.red)
                                    .multilineTextAlignment(.center)
                                    .padding()
                            }

                            // Retake button
                            Button(action: { viewModel.selectedImage = nil }) {
                                Text("Choose Different Image")
                                    .foregroundColor(.green)
                            }
                            .padding(.bottom, 20)
                        }
                    }
                }
            }
            .navigationTitle("Food Scanner")
            .sheet(isPresented: $showCamera) {
                CameraView(selectedImage: $viewModel.selectedImage)
            }
            .sheet(isPresented: $showPhotoPicker) {
                PhotoLibraryView(selectedImage: $viewModel.selectedImage)
            }
            .sheet(isPresented: $showAnalysisResult) {
                AIAnalysisResultView(viewModel: viewModel, analysisType: analysisType)
            }
        }
    }

    // MARK: - Analysis Methods

    private func analyzeWithBLIP() {
        guard let image = viewModel.selectedImage else { return }

        Task {
            await viewModel.analyzeFoodWithBLIP(image: image)

            if viewModel.foodAnalysis != nil {
                showAnalysisResult = true
            }
        }
    }

    private func analyzeWithVision() {
        guard let image = viewModel.selectedImage else { return }

        Task {
            await viewModel.analyzeFood(image: image)

            if viewModel.visionAnalysis != nil {
                showAnalysisResult = true
            }
        }
    }

    private func generateCaption() {
        guard let image = viewModel.selectedImage else { return }

        Task {
            await viewModel.generateCaption(from: image)

            if viewModel.captionResult != nil {
                showAnalysisResult = true
            }
        }
    }
}

// MARK: - Analysis Option Card

struct AnalysisOptionCard: View {
    let icon: String
    let title: String
    let description: String
    let color: Color
    let isLoading: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(color)
                    .font(.title2)

                VStack(alignment: .leading) {
                    Text(title)
                        .font(.headline)
                        .foregroundColor(.primary)
                    Text(description)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                Spacer()

                if isLoading {
                    ProgressView()
                } else {
                    Image(systemName: "arrow.right.circle.fill")
                        .foregroundColor(color)
                        .font(.title2)
                }
            }
            .padding()
            .background(Color(.systemGray6))
            .cornerRadius(12)
        }
        .disabled(isLoading)
    }
}

struct FoodScannerView_Previews: PreviewProvider {
    static var previews: some View {
        FoodScannerView()
    }
}
