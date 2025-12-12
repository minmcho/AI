import Foundation
import AVFoundation

class SpeechSynthesizer {
    static let shared = SpeechSynthesizer()
    private let synthesizer = AVSpeechSynthesizer()
    private var currentCompletion: (() -> Void)?

    private init() {
        synthesizer.delegate = self
    }

    func speak(text: String, language: AppState.Language, completion: @escaping () -> Void) {
        currentCompletion = completion

        let utterance = AVSpeechUtterance(string: text)
        utterance.voice = AVSpeechSynthesisVoice(language: language == .spanish ? "es-ES" : "my-MM")
        utterance.rate = 0.5
        utterance.pitchMultiplier = 1.0
        utterance.volume = 1.0

        synthesizer.speak(utterance)
    }

    func stop() {
        synthesizer.stopSpeaking(at: .immediate)
        currentCompletion?()
        currentCompletion = nil
    }
}

extension SpeechSynthesizer: AVSpeechSynthesizerDelegate {
    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didFinish utterance: AVSpeechUtterance) {
        currentCompletion?()
        currentCompletion = nil
    }
}
