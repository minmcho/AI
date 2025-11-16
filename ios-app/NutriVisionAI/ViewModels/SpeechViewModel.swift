//
//  SpeechViewModel.swift
//  NutriVision AI
//
//  Speech and voice command view model
//

import Foundation
import SwiftUI
import AVFoundation

@MainActor
class SpeechViewModel: ObservableObject {
    // Transcription
    @Published var transcribedText: String = ""
    @Published var isRecording = false
    @Published var recordingDuration: TimeInterval = 0

    // Synthesis
    @Published var synthesizedAudioData: Data?
    @Published var isPlaying = false

    // Voice Commands
    @Published var lastCommand: VoiceCommandResponse?
    @Published var commandHistory: [VoiceCommandResponse] = []

    // Translation
    @Published var translationResult: TranslationResponse?
    @Published var sourceText: String = ""
    @Published var translatedText: String = ""

    // Language
    @Published var selectedLanguage: Language = .en
    @Published var sourceLanguage: Language = .en
    @Published var targetLanguage: Language = .en

    // Audio recording
    @Published var audioData: Data?
    @Published var recordingLevel: Float = 0.0

    // General
    @Published var isLoading = false
    @Published var errorMessage: String?

    private let speechService = SpeechService()
    private var recordingTimer: Timer?

    // MARK: - Speech-to-Text (Server)

    func transcribeAudio(data: Data, language: Language? = nil) async {
        isLoading = true
        errorMessage = nil

        do {
            let response = try await speechService.transcribeAudio(
                audioData: data,
                language: language?.rawValue
            )
            transcribedText = response.text
            isLoading = false
        } catch {
            errorMessage = "Transcription failed: \(error.localizedDescription)"
            isLoading = false
        }
    }

    // MARK: - Local iOS Speech Recognition

    func startLocalRecording(language: Language) {
        do {
            try speechService.startLocalRecording(language: language.rawValue)
            isRecording = true
            startRecordingTimer()

            // Observe transcribed text from service
            speechService.$transcribedText
                .assign(to: &$transcribedText)
        } catch {
            errorMessage = "Failed to start recording: \(error.localizedDescription)"
        }
    }

    func stopLocalRecording() {
        speechService.stopLocalRecording()
        isRecording = false
        stopRecordingTimer()

        // Get the recorded audio data
        audioData = speechService.getRecordedAudioData()
    }

    // MARK: - Text-to-Speech

    func synthesizeSpeech(text: String, language: Language) async {
        guard !text.isEmpty else {
            errorMessage = "Please enter text to synthesize"
            return
        }

        isLoading = true
        errorMessage = nil

        do {
            let audioData = try await speechService.synthesizeSpeech(
                text: text,
                language: language.rawValue
            )
            synthesizedAudioData = audioData
            isLoading = false
        } catch {
            errorMessage = "Speech synthesis failed: \(error.localizedDescription)"
            isLoading = false
        }
    }

    func playAudio(data: Data) {
        do {
            try speechService.playAudio(data: data)
            isPlaying = true

            // Stop playing after duration
            DispatchQueue.main.asyncAfter(deadline: .now() + 3) { [weak self] in
                self?.isPlaying = false
            }
        } catch {
            errorMessage = "Audio playback failed: \(error.localizedDescription)"
        }
    }

    func stopAudio() {
        speechService.stopAudio()
        isPlaying = false
    }

    // MARK: - Voice Commands

    func processVoiceCommand(audioData: Data, language: Language) async {
        isLoading = true
        errorMessage = nil

        do {
            let response = try await speechService.processVoiceCommand(
                audioData: audioData,
                language: language.rawValue
            )
            lastCommand = response
            commandHistory.insert(response, at: 0)
            isLoading = false

            // Execute command
            await executeCommand(response)
        } catch {
            errorMessage = "Voice command processing failed: \(error.localizedDescription)"
            isLoading = false
        }
    }

    // MARK: - Translation

    func translateText(text: String, from sourceLang: Language, to targetLang: Language) async {
        guard !text.isEmpty else {
            errorMessage = "Please enter text to translate"
            return
        }

        isLoading = true
        errorMessage = nil
        sourceText = text

        do {
            let response = try await speechService.translateText(
                text: text,
                from: sourceLang.rawValue,
                to: targetLang.rawValue
            )
            translationResult = response
            translatedText = response.translatedText
            isLoading = false
        } catch {
            errorMessage = "Translation failed: \(error.localizedDescription)"
            isLoading = false
        }
    }

    // MARK: - Command Execution

    private func executeCommand(_ command: VoiceCommandResponse) async {
        // Handle different intents
        switch command.intent {
        case "search_recipe":
            if let query = command.parameters["query"]?.value as? String {
                // Notify other view models to perform search
                NotificationCenter.default.post(
                    name: NSNotification.Name("SearchRecipe"),
                    object: query
                )
            }

        case "create_meal_plan":
            if let days = command.parameters["days"]?.value as? Int {
                NotificationCenter.default.post(
                    name: NSNotification.Name("CreateMealPlan"),
                    object: days
                )
            }

        case "add_to_shopping_list":
            if let item = command.parameters["item"]?.value as? String {
                NotificationCenter.default.post(
                    name: NSNotification.Name("AddToShoppingList"),
                    object: item
                )
            }

        case "scan_food":
            NotificationCenter.default.post(
                name: NSNotification.Name("OpenFoodScanner"),
                object: nil
            )

        case "open_journal":
            NotificationCenter.default.post(
                name: NSNotification.Name("OpenJournal"),
                object: nil
            )

        default:
            break
        }
    }

    // MARK: - Recording Timer

    private func startRecordingTimer() {
        recordingDuration = 0
        recordingTimer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] _ in
            self?.recordingDuration += 0.1
        }
    }

    private func stopRecordingTimer() {
        recordingTimer?.invalidate()
        recordingTimer = nil
    }

    // MARK: - Helper Methods

    func clearTranscription() {
        transcribedText = ""
        audioData = nil
    }

    func clearTranslation() {
        translationResult = nil
        sourceText = ""
        translatedText = ""
    }

    func clearCommands() {
        lastCommand = nil
        commandHistory = []
    }

    func formatDuration(_ duration: TimeInterval) -> String {
        let minutes = Int(duration) / 60
        let seconds = Int(duration) % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
}
