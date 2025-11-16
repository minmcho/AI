//
//  TranslationView.swift
//  NutriVision AI
//
//  Text translation view
//

import SwiftUI

struct TranslationView: View {
    @StateObject private var viewModel = SpeechViewModel()
    @FocusState private var isInputFocused: Bool

    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Language selector
                HStack(spacing: 16) {
                    // Source language
                    LanguageSelector(
                        title: "From",
                        selectedLanguage: viewModel.sourceLanguage,
                        languages: [.en, .zh, .ja, .ko, .th, .my]
                    ) { language in
                        viewModel.sourceLanguage = language
                    }

                    // Swap button
                    Button(action: swapLanguages) {
                        Image(systemName: "arrow.left.arrow.right")
                            .foregroundColor(.green)
                            .padding()
                            .background(Color(.systemGray6))
                            .clipShape(Circle())
                    }

                    // Target language
                    LanguageSelector(
                        title: "To",
                        selectedLanguage: viewModel.targetLanguage,
                        languages: [.en, .zh, .ja, .ko, .th, .my]
                    ) { language in
                        viewModel.targetLanguage = language
                    }
                }
                .padding()

                Divider()

                // Input section
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Text("Enter text")
                            .font(.subheadline)
                            .foregroundColor(.secondary)

                        Spacer()

                        if !viewModel.sourceText.isEmpty {
                            Button(action: { viewModel.sourceText = "" }) {
                                Image(systemName: "xmark.circle.fill")
                                    .foregroundColor(.gray)
                            }
                        }
                    }

                    TextEditor(text: $viewModel.sourceText)
                        .frame(height: 120)
                        .padding(8)
                        .background(Color(.systemGray6))
                        .cornerRadius(12)
                        .focused($isInputFocused)

                    // Character count
                    Text("\(viewModel.sourceText.count) characters")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding()

                // Translate button
                CustomButton(
                    title: "Translate",
                    icon: "arrow.right.arrow.left.circle.fill",
                    style: .primary,
                    isLoading: viewModel.isLoading
                ) {
                    isInputFocused = false
                    translate()
                }
                .padding(.horizontal)
                .disabled(viewModel.sourceText.isEmpty)

                Divider()
                    .padding(.vertical)

                // Translation result
                if let result = viewModel.translationResult {
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Text("Translation")
                                .font(.subheadline)
                                .foregroundColor(.secondary)

                            Spacer()

                            // Copy button
                            Button(action: {
                                UIPasteboard.general.string = result.translatedText
                            }) {
                                Image(systemName: "doc.on.doc")
                                    .foregroundColor(.green)
                            }

                            // Listen button
                            Button(action: {
                                speakTranslation()
                            }) {
                                Image(systemName: viewModel.isPlaying ? "speaker.wave.2.fill" : "speaker.wave.2")
                                    .foregroundColor(.green)
                            }
                        }

                        ScrollView {
                            Text(result.translatedText)
                                .font(.body)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding()
                                .background(Color.green.opacity(0.1))
                                .cornerRadius(12)
                        }

                        // Confidence
                        if let confidence = result.confidence {
                            HStack {
                                Image(systemName: "checkmark.seal.fill")
                                    .foregroundColor(.green)
                                    .font(.caption)

                                Text("Confidence: \(String(format: "%.0f%%", confidence * 100))")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                    .padding()
                } else if !viewModel.sourceText.isEmpty && !viewModel.isLoading {
                    VStack(spacing: 12) {
                        Image(systemName: "text.bubble")
                            .font(.largeTitle)
                            .foregroundColor(.gray)

                        Text("Translation will appear here")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    .frame(maxHeight: .infinity)
                }

                // Error message
                if let error = viewModel.errorMessage {
                    Text(error)
                        .font(.caption)
                        .foregroundColor(.red)
                        .multilineTextAlignment(.center)
                        .padding()
                }

                Spacer()
            }
            .navigationTitle("Translation")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { viewModel.clearTranslation() }) {
                        Image(systemName: "trash")
                            .foregroundColor(.red)
                    }
                    .disabled(viewModel.sourceText.isEmpty && viewModel.translationResult == nil)
                }
            }
        }
    }

    // MARK: - Methods

    private func translate() {
        Task {
            await viewModel.translateText(
                text: viewModel.sourceText,
                from: viewModel.sourceLanguage,
                to: viewModel.targetLanguage
            )
        }
    }

    private func swapLanguages() {
        let temp = viewModel.sourceLanguage
        viewModel.sourceLanguage = viewModel.targetLanguage
        viewModel.targetLanguage = temp

        if let result = viewModel.translationResult {
            viewModel.sourceText = result.translatedText
            viewModel.translationResult = nil
        }
    }

    private func speakTranslation() {
        guard let result = viewModel.translationResult else { return }

        Task {
            await viewModel.synthesizeSpeech(
                text: result.translatedText,
                language: viewModel.targetLanguage
            )

            if let audioData = viewModel.synthesizedAudioData {
                viewModel.playAudio(data: audioData)
            }
        }
    }
}

// MARK: - Language Selector

struct LanguageSelector: View {
    let title: String
    let selectedLanguage: Language
    let languages: [Language]
    let onSelect: (Language) -> Void

    @State private var showPicker = false

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)

            Button(action: { showPicker = true }) {
                HStack {
                    Text(selectedLanguage.flag)
                    Text(selectedLanguage.displayName)
                        .font(.subheadline)
                        .foregroundColor(.primary)
                    Image(systemName: "chevron.down")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(Color(.systemGray6))
                .cornerRadius(8)
            }
        }
        .frame(maxWidth: .infinity)
        .sheet(isPresented: $showPicker) {
            NavigationView {
                List {
                    ForEach(languages, id: \.self) { language in
                        Button(action: {
                            onSelect(language)
                            showPicker = false
                        }) {
                            HStack {
                                Text(language.flag)
                                Text(language.displayName)
                                    .foregroundColor(.primary)

                                Spacer()

                                if language == selectedLanguage {
                                    Image(systemName: "checkmark")
                                        .foregroundColor(.green)
                                }
                            }
                        }
                    }
                }
                .navigationTitle(title)
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button("Done") {
                            showPicker = false
                        }
                    }
                }
            }
        }
    }
}

struct TranslationView_Previews: PreviewProvider {
    static var previews: some View {
        TranslationView()
    }
}
