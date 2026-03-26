import Foundation
import Observation
import Speech
import AVFoundation

@Observable
final class TranslationViewModel {

    // MARK: - Inputs

    var sourceText: String = "" {
        didSet { scheduleAutoTranslate() }
    }
    var sourceLang: MyanmarLanguage = .myanmar
    var targetLang: MyanmarLanguage = .english

    // MARK: - Outputs

    var translatedText: String = ""
    var multiResults: [MultiTranslationResult] = []
    var languages: [MyanmarLanguage] = MyanmarLanguage.builtIn
    var history: [TranslationHistoryItem] = []

    // MARK: - State

    var isTranslating: Bool = false
    var isRecording: Bool = false
    var errorMessage: String? = nil
    var isMultiMode: Bool = false
    var selectedMultiTargets: Set<String> = ["eng_Latn", "zho_Hans", "tha_Thai", "jpn_Jpan"]

    // MARK: - Private

    private var autoTranslateTask: Task<Void, Never>?
    private var speechRecognizer: SFSpeechRecognizer?
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?
    private let audioEngine = AVAudioEngine()
    private let api = APIClient.shared

    init() {
        loadHistory()
        Task { await loadLanguages() }
    }

    // MARK: - Language management

    @MainActor
    func loadLanguages() async {
        do {
            let fetched = try await api.fetchLanguages()
            if !fetched.isEmpty { languages = fetched }
        } catch {
            // silently fall back to built-in list
        }
    }

    func swapLanguages() {
        let tmp = sourceLang
        sourceLang = targetLang
        targetLang = tmp
        let tmpText = sourceText
        sourceText = translatedText
        translatedText = tmpText
    }

    // MARK: - Translation

    @MainActor
    func translate() async {
        guard !sourceText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            translatedText = ""
            return
        }
        isTranslating = true
        errorMessage = nil
        defer { isTranslating = false }

        do {
            let result = try await api.translate(text: sourceText, from: sourceLang, to: targetLang)
            translatedText = result.translatedText
            appendHistory(translated: result.translatedText)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    @MainActor
    func translateToAll() async {
        guard !sourceText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
        let targets = languages.filter { selectedMultiTargets.contains($0.code) && $0.code != sourceLang.code }
        guard !targets.isEmpty else { return }

        isTranslating = true
        errorMessage = nil
        defer { isTranslating = false }

        do {
            let result = try await api.translateToMultiple(text: sourceText, from: sourceLang, to: targets)
            multiResults = targets.compactMap { lang in
                guard let text = result.translations[lang.code], !text.isEmpty else { return nil }
                return MultiTranslationResult(language: lang, translatedText: text)
            }
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func scheduleAutoTranslate() {
        autoTranslateTask?.cancel()
        let text = sourceText
        guard !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            translatedText = ""
            multiResults = []
            return
        }
        autoTranslateTask = Task { [weak self] in
            try? await Task.sleep(for: .milliseconds(600))
            guard !Task.isCancelled, let self else { return }
            await self.isMultiMode ? self.translateToAll() : self.translate()
        }
    }

    // MARK: - History

    private func appendHistory(translated: String) {
        let item = TranslationHistoryItem(
            sourceText: sourceText,
            translatedText: translated,
            sourceLang: sourceLang,
            targetLang: targetLang
        )
        history.insert(item, at: 0)
        if history.count > 100 { history = Array(history.prefix(100)) }
        saveHistory()
    }

    func deleteHistoryItems(at offsets: IndexSet) {
        history.remove(atOffsets: offsets)
        saveHistory()
    }

    func clearHistory() {
        history.removeAll()
        saveHistory()
    }

    func restoreFromHistory(_ item: TranslationHistoryItem) {
        sourceLang = item.sourceLang
        targetLang = item.targetLang
        sourceText = item.sourceText
        translatedText = item.translatedText
    }

    private func saveHistory() {
        if let data = try? JSONEncoder().encode(history) {
            UserDefaults.standard.set(data, forKey: "translation_history")
        }
    }

    private func loadHistory() {
        if let data = UserDefaults.standard.data(forKey: "translation_history"),
           let items = try? JSONDecoder().decode([TranslationHistoryItem].self, from: data) {
            history = items
        }
    }

    // MARK: - Speech recognition (Myanmar STT via on-device API)

    func requestSpeechPermission() async -> Bool {
        await withCheckedContinuation { cont in
            SFSpeechRecognizer.requestAuthorization { status in
                cont.resume(returning: status == .authorized)
            }
        }
    }

    @MainActor
    func startRecording() async {
        guard await requestSpeechPermission() else {
            errorMessage = "Speech recognition permission denied"
            return
        }

        // Use locale matching source language where possible
        let locale = localeForLang(sourceLang)
        speechRecognizer = SFSpeechRecognizer(locale: locale)

        guard let recognizer = speechRecognizer, recognizer.isAvailable else {
            errorMessage = "Speech recognition unavailable for \(sourceLang.name)"
            return
        }

        let audioSession = AVAudioSession.sharedInstance()
        do {
            try audioSession.setCategory(.record, mode: .measurement, options: .duckOthers)
            try audioSession.setActive(true, options: .notifyOthersOnDeactivation)
        } catch {
            errorMessage = "Audio session error: \(error.localizedDescription)"
            return
        }

        recognitionRequest = SFSpeechAudioBufferRecognitionRequest()
        guard let recognitionRequest else { return }
        recognitionRequest.shouldReportPartialResults = true

        let inputNode = audioEngine.inputNode
        recognitionTask = recognizer.recognitionTask(with: recognitionRequest) { [weak self] result, error in
            guard let self else { return }
            if let result {
                Task { @MainActor in self.sourceText = result.bestTranscription.formattedString }
            }
            if error != nil || result?.isFinal == true {
                Task { @MainActor in self.stopRecording() }
            }
        }

        let format = inputNode.outputFormat(forBus: 0)
        inputNode.installTap(onBus: 0, bufferSize: 1024, format: format) { buffer, _ in
            recognitionRequest.append(buffer)
        }

        audioEngine.prepare()
        do {
            try audioEngine.start()
            isRecording = true
        } catch {
            errorMessage = "Audio engine error: \(error.localizedDescription)"
            stopRecording()
        }
    }

    @MainActor
    func stopRecording() {
        audioEngine.stop()
        audioEngine.inputNode.removeTap(onBus: 0)
        recognitionRequest?.endAudio()
        recognitionTask?.cancel()
        recognitionRequest = nil
        recognitionTask = nil
        isRecording = false
        try? AVAudioSession.sharedInstance().setActive(false)
    }

    private func localeForLang(_ lang: MyanmarLanguage) -> Locale {
        switch lang.code {
        case "mya_Mymr": return Locale(identifier: "my-MM")
        case "eng_Latn": return Locale(identifier: "en-US")
        case "zho_Hans": return Locale(identifier: "zh-CN")
        case "zho_Hant": return Locale(identifier: "zh-TW")
        case "tha_Thai": return Locale(identifier: "th-TH")
        case "jpn_Jpan": return Locale(identifier: "ja-JP")
        case "kor_Hang": return Locale(identifier: "ko-KR")
        case "fra_Latn": return Locale(identifier: "fr-FR")
        case "spa_Latn": return Locale(identifier: "es-ES")
        case "deu_Latn": return Locale(identifier: "de-DE")
        case "arb_Arab": return Locale(identifier: "ar-SA")
        case "hin_Deva": return Locale(identifier: "hi-IN")
        case "vie_Latn": return Locale(identifier: "vi-VN")
        case "ind_Latn": return Locale(identifier: "id-ID")
        case "rus_Cyrl": return Locale(identifier: "ru-RU")
        case "kor_Hang": return Locale(identifier: "ko-KR")
        default:          return Locale.current
        }
    }
}
