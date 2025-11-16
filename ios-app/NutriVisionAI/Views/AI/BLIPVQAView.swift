//
//  BLIPVQAView.swift
//  NutriVision AI
//
//  BLIP Visual Question Answering view
//

import SwiftUI
import UIKit

struct BLIPVQAView: View {
    @Environment(\.presentationMode) var presentationMode
    @StateObject private var viewModel = AIFeaturesViewModel()

    let image: UIImage
    @State private var question: String = ""
    @State private var questionHistory: [(question: String, answer: String)] = []

    // Suggested questions
    let suggestedQuestions = [
        "What food is this?",
        "How many calories does this have?",
        "Is this healthy?",
        "What are the main ingredients?",
        "How is this prepared?",
        "What cuisine is this from?"
    ]

    var body: some View {
        VStack(spacing: 0) {
            // Image preview
            Image(uiImage: image)
                .resizable()
                .scaledToFit()
                .frame(height: 200)
                .cornerRadius(12)
                .padding()

            // Q&A Section
            ScrollView {
                VStack(spacing: 16) {
                    // Question history
                    if !questionHistory.isEmpty {
                        VStack(spacing: 12) {
                            ForEach(questionHistory.indices, id: \.self) { index in
                                VStack(alignment: .leading, spacing: 8) {
                                    // Question
                                    HStack {
                                        Image(systemName: "person.circle.fill")
                                            .foregroundColor(.blue)
                                        Text(questionHistory[index].question)
                                            .font(.subheadline)
                                            .fontWeight(.medium)
                                    }
                                    .padding()
                                    .background(Color.blue.opacity(0.1))
                                    .cornerRadius(12)

                                    // Answer
                                    HStack {
                                        Image(systemName: "wand.and.stars")
                                            .foregroundColor(.green)
                                        Text(questionHistory[index].answer)
                                            .font(.subheadline)
                                    }
                                    .padding()
                                    .background(Color.green.opacity(0.1))
                                    .cornerRadius(12)
                                }
                            }
                        }
                        .padding(.horizontal)
                    }

                    // Suggested questions
                    if questionHistory.isEmpty {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Suggested Questions")
                                .font(.headline)
                                .padding(.horizontal)

                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 12) {
                                    ForEach(suggestedQuestions, id: \.self) { suggested in
                                        Button(action: {
                                            question = suggested
                                            askQuestion()
                                        }) {
                                            Text(suggested)
                                                .font(.subheadline)
                                                .padding(.horizontal, 16)
                                                .padding(.vertical, 8)
                                                .background(Color.green.opacity(0.1))
                                                .foregroundColor(.green)
                                                .cornerRadius(20)
                                        }
                                    }
                                }
                                .padding(.horizontal)
                            }
                        }
                    }

                    // Error message
                    if let error = viewModel.errorMessage {
                        Text(error)
                            .font(.caption)
                            .foregroundColor(.red)
                            .multilineTextAlignment(.center)
                            .padding()
                    }
                }
                .padding(.vertical)
            }

            // Input area
            VStack(spacing: 12) {
                Divider()

                HStack(spacing: 12) {
                    TextField("Ask a question about this image...", text: $question)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .submitLabel(.send)
                        .onSubmit(askQuestion)

                    Button(action: askQuestion) {
                        if viewModel.isLoading {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                .frame(width: 24, height: 24)
                        } else {
                            Image(systemName: "arrow.up.circle.fill")
                                .font(.title)
                                .foregroundColor(question.isEmpty ? .gray : .green)
                        }
                    }
                    .disabled(question.isEmpty || viewModel.isLoading)
                }
                .padding(.horizontal)
                .padding(.bottom)
            }
            .background(Color(.systemBackground))
        }
        .navigationTitle("Visual Q&A")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            viewModel.selectedImage = image
        }
    }

    // MARK: - Methods

    private func askQuestion() {
        guard !question.isEmpty else { return }

        let currentQuestion = question

        Task {
            await viewModel.answerVisualQuestion(image: image, question: currentQuestion)

            if let answer = viewModel.currentAnswer {
                questionHistory.append((question: currentQuestion, answer: answer))
                question = ""
            }
        }
    }
}

struct BLIPVQAView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            BLIPVQAView(image: UIImage(systemName: "photo")!)
        }
    }
}
