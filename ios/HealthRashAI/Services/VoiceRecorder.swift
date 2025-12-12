import Foundation
import AVFoundation
import Speech

class VoiceRecorder: NSObject, ObservableObject {
    @Published var isRecording = false
    @Published var isProcessing = false

    private var audioEngine: AVAudioEngine?
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?
    private var speechRecognizer: SFSpeechRecognizer?
    private var transcriptionCompletion: ((String) -> Void)?

    override init() {
        super.init()
        requestPermissions()
    }

    private func requestPermissions() {
        SFSpeechRecognizer.requestAuthorization { _ in }
        AVAudioSession.sharedInstance().requestRecordPermission { _ in }
    }

    func startRecording(language: AppState.Language) {
        isRecording = true

        // Initialize speech recognizer for the selected language
        let locale = language == .spanish ? Locale(identifier: "es-ES") : Locale(identifier: "my-MM")
        speechRecognizer = SFSpeechRecognizer(locale: locale)

        guard let speechRecognizer = speechRecognizer, speechRecognizer.isAvailable else {
            print("Speech recognizer not available for locale")
            isRecording = false
            return
        }

        // Setup audio session
        let audioSession = AVAudioSession.sharedInstance()
        try? audioSession.setCategory(.record, mode: .measurement, options: .duckOthers)
        try? audioSession.setActive(true, options: .notifyOthersOnDeactivation)

        // Create recognition request
        recognitionRequest = SFSpeechAudioBufferRecognitionRequest()
        guard let recognitionRequest = recognitionRequest else { return }
        recognitionRequest.shouldReportPartialResults = true

        // Setup audio engine
        audioEngine = AVAudioEngine()
        guard let audioEngine = audioEngine else { return }

        let inputNode = audioEngine.inputNode
        let recordingFormat = inputNode.outputFormat(forBus: 0)

        inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { buffer, _ in
            recognitionRequest.append(buffer)
        }

        audioEngine.prepare()
        try? audioEngine.start()

        // Start recognition
        recognitionTask = speechRecognizer.recognitionTask(with: recognitionRequest) { [weak self] result, error in
            if let result = result {
                // Store partial result
                print("Transcription: \(result.bestTranscription.formattedString)")
            }

            if error != nil || result?.isFinal == true {
                self?.audioEngine?.stop()
                inputNode.removeTap(onBus: 0)
                self?.recognitionRequest = nil
                self?.recognitionTask = nil
            }
        }
    }

    func stopRecording(completion: @escaping (String) -> Void) {
        transcriptionCompletion = completion
        isRecording = false
        isProcessing = true

        audioEngine?.stop()
        recognitionRequest?.endAudio()

        // Simulate processing delay and get mock transcription
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) { [weak self] in
            guard let self = self else { return }

            // In production, use the actual transcription from recognitionTask
            // For now, return mock transcription
            let transcript = self.getMockTranscription()

            self.isProcessing = false
            completion(transcript)
        }
    }

    private func getMockTranscription() -> String {
        // Mock transcription - in production this would come from Speech framework
        let spanishQuestions = [
            "¿Es esto peligroso?",
            "¿Qué debo hacer para tratarlo?",
            "¿Necesita atención médica inmediata?"
        ]

        let burmeseQuestions = [
            "ဒါက အန္တရာယ်ရှိပါသလား။",
            "ကုသရန် ဘာလုပ်သင့်ပါသလဲ။",
            "ချက်ခြင်း ဆေးကုသမှု လိုအပ်ပါသလား။"
        ]

        // Return random question for demo
        return Bool.random() ? spanishQuestions.randomElement()! : burmeseQuestions.randomElement()!
    }
}
