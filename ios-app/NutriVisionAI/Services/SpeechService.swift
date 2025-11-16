//
//  SpeechService.swift
//  NutriVision AI
//
//  Speech recognition and synthesis service
//

import Foundation
import AVFoundation
import Speech

class SpeechService: NSObject, ObservableObject {
    private let apiClient = APIClient.shared
    private var audioEngine: AVAudioEngine?
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?
    private let speechRecognizer = SFSpeechRecognizer()

    @Published var isRecording = false
    @Published var transcribedText: String = ""

    // MARK: - Speech-to-Text (Server-side with Whisper)

    func transcribeAudio(
        audioData: Data,
        language: String? = nil,
        translateToEnglish: Bool = false
    ) async throws -> TranscriptionResponse {
        let base64Audio = audioData.base64EncodedString()
        let request = TranscriptionRequest(
            audioBase64: base64Audio,
            language: language,
            translateToEnglish: translateToEnglish
        )

        return try await apiClient.request(
            endpoint: Config.Endpoints.transcribe,
            method: "POST",
            body: request
        )
    }

    // MARK: - Text-to-Speech

    func synthesizeSpeech(
        text: String,
        language: String = "en",
        slow: Bool = false
    ) async throws -> Data {
        let request = SynthesisRequest(text: text, language: language, slow: slow)

        let response: SynthesisResponse = try await apiClient.request(
            endpoint: Config.Endpoints.synthesize,
            method: "POST",
            body: request
        )

        // Decode base64 audio
        guard let audioData = Data(base64Encoded: response.audioBase64) else {
            throw APIError.decodingFailed(NSError(domain: "", code: -1, userInfo: nil))
        }

        return audioData
    }

    // MARK: - Voice Command Processing

    func processVoiceCommand(
        audioData: Data,
        language: String = "en"
    ) async throws -> VoiceCommandResponse {
        let base64Audio = audioData.base64EncodedString()
        let request = VoiceCommandRequest(audioBase64: base64Audio, userLanguage: language)

        return try await apiClient.request(
            endpoint: Config.Endpoints.voiceCommand,
            method: "POST",
            body: request
        )
    }

    // MARK: - Translation

    func translateText(
        text: String,
        from sourceLang: String,
        to targetLang: String
    ) async throws -> TranslationResponse {
        let request = TranslationRequest(
            text: text,
            sourceLang: sourceLang,
            targetLang: targetLang
        )

        return try await apiClient.request(
            endpoint: Config.Endpoints.translate,
            method: "POST",
            body: request
        )
    }

    // MARK: - Get Supported Languages

    func getSupportedLanguages() async throws -> [LanguageInfo] {
        return try await apiClient.request(
            endpoint: Config.Endpoints.languages,
            method: "GET"
        )
    }

    // MARK: - Play Audio

    func playAudio(data: Data) throws {
        let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent("tts.mp3")
        try data.write(to: tempURL)

        let player = try AVAudioPlayer(contentsOf: tempURL)
        player.prepareToPlay()
        player.play()
    }

    // MARK: - Local Speech Recognition (iOS)

    func requestSpeechAuthorization() async -> Bool {
        await withCheckedContinuation { continuation in
            SFSpeechRecognizer.requestAuthorization { status in
                continuation.resume(returning: status == .authorized)
            }
        }
    }

    func startLocalRecording(language: String = "en") throws {
        guard !isRecording else { return }

        // Request microphone permission
        AVAudioSession.sharedInstance().requestRecordPermission { [weak self] allowed in
            guard allowed else { return }

            DispatchQueue.main.async {
                self?.isRecording = true
                self?.transcribedText = ""
            }
        }

        // Configure audio session
        let audioSession = AVAudioSession.sharedInstance()
        try audioSession.setCategory(.record, mode: .measurement, options: .duckOthers)
        try audioSession.setActive(true, options: .notifyOthersOnDeactivation)

        // Create recognition request
        recognitionRequest = SFSpeechAudioBufferRecognitionRequest()
        guard let recognitionRequest = recognitionRequest else {
            throw NSError(domain: "SpeechService", code: -1, userInfo: [NSLocalizedDescriptionKey: "Unable to create recognition request"])
        }

        recognitionRequest.shouldReportPartialResults = true

        // Start recognition task
        recognitionTask = speechRecognizer?.recognitionTask(with: recognitionRequest) { [weak self] result, error in
            if let result = result {
                DispatchQueue.main.async {
                    self?.transcribedText = result.bestTranscription.formattedString
                }
            }

            if error != nil || result?.isFinal == true {
                self?.stopLocalRecording()
            }
        }

        // Configure audio engine
        audioEngine = AVAudioEngine()
        let inputNode = audioEngine!.inputNode
        let recordingFormat = inputNode.outputFormat(forBus: 0)
        inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { buffer, _ in
            recognitionRequest.append(buffer)
        }

        audioEngine?.prepare()
        try audioEngine?.start()
    }

    func stopLocalRecording() {
        audioEngine?.stop()
        audioEngine?.inputNode.removeTap(onBus: 0)
        recognitionRequest?.endAudio()
        recognitionTask?.cancel()

        audioEngine = nil
        recognitionRequest = nil
        recognitionTask = nil

        DispatchQueue.main.async {
            self.isRecording = false
        }
    }
}
