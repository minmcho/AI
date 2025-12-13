import Foundation
import AVFoundation
import Speech
import Combine

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

        let locale = language == .spanish ? Locale(identifier: "es-ES") : Locale(identifier: "my-MM")
        speechRecognizer = SFSpeechRecognizer(locale: locale)

        guard let speechRecognizer = speechRecognizer, speechRecognizer.isAvailable else {
            isRecording = false
            return
        }

        let audioSession = AVAudioSession.sharedInstance()
        try? audioSession.setCategory(.record, mode: .measurement, options: .duckOthers)
        try? audioSession.setActive(true, options: .notifyOthersOnDeactivation)

        recognitionRequest = SFSpeechAudioBufferRecognitionRequest()
        guard let recognitionRequest = recognitionRequest else { return }
        recognitionRequest.shouldReportPartialResults = true

        audioEngine = AVAudioEngine()
        guard let audioEngine = audioEngine else { return }

        let inputNode = audioEngine.inputNode
        let recordingFormat = inputNode.outputFormat(forBus: 0)

        inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { buffer, _ in
            recognitionRequest.append(buffer)
        }

        audioEngine.prepare()
        try? audioEngine.start()

        recognitionTask = speechRecognizer.recognitionTask(with: recognitionRequest) { [weak self] result, error in
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

        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) { [weak self] in
            let transcript = self?.getMockTranscription() ?? "Sample question"
            self?.isProcessing = false
            completion(transcript)
        }
    }

    private func getMockTranscription() -> String {
        let questions = [
            "¿Es esto peligroso?",
            "ဒါက အန္တရာယ်ရှိပါသလား။"
        ]
        return questions.randomElement()!
    }
}
