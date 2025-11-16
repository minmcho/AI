//
//  Speech.swift
//  NutriVision AI
//
//  Speech and language models
//

import Foundation

// MARK: - Transcription

struct TranscriptionRequest: Codable {
    let audioBase64: String
    let language: String?
    let translateToEnglish: Bool

    enum CodingKeys: String, CodingKey {
        case audioBase64 = "audio_base64"
        case language
        case translateToEnglish = "translate_to_english"
    }
}

struct TranscriptionResponse: Codable {
    let text: String
    let language: String
    let confidence: Double
}

// MARK: - Synthesis

struct SynthesisRequest: Codable {
    let text: String
    let language: String
    let slow: Bool
}

struct SynthesisResponse: Codable {
    let audioBase64: String
    let language: String

    enum CodingKeys: String, CodingKey {
        case audioBase64 = "audio_base64"
        case language
    }
}

// MARK: - Voice Command

struct VoiceCommandRequest: Codable {
    let audioBase64: String
    let userLanguage: String

    enum CodingKeys: String, CodingKey {
        case audioBase64 = "audio_base64"
        case userLanguage = "user_language"
    }
}

struct VoiceCommandResponse: Codable {
    let command: String
    let language: String
    let intent: String
    let parameters: [String: AnyCodable]
    let confidence: Double
}

// MARK: - Translation

struct TranslationRequest: Codable {
    let text: String
    let sourceLang: String
    let targetLang: String

    enum CodingKeys: String, CodingKey {
        case text
        case sourceLang = "source_lang"
        case targetLang = "target_lang"
    }
}

struct TranslationResponse: Codable {
    let translatedText: String
    let sourceLang: String
    let targetLang: String

    enum CodingKeys: String, CodingKey {
        case translatedText = "translated_text"
        case sourceLang = "source_lang"
        case targetLang = "target_lang"
    }
}

// MARK: - Language Info

struct LanguageInfo: Codable {
    let code: String
    let name: String
    let sttSupported: Bool
    let ttsSupported: Bool

    enum CodingKeys: String, CodingKey {
        case code, name
        case sttSupported = "stt_supported"
        case ttsSupported = "tts_supported"
    }
}

// MARK: - Helper for Dynamic JSON

struct AnyCodable: Codable {
    let value: Any

    init(_ value: Any) {
        self.value = value
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()

        if let intValue = try? container.decode(Int.self) {
            value = intValue
        } else if let doubleValue = try? container.decode(Double.self) {
            value = doubleValue
        } else if let stringValue = try? container.decode(String.self) {
            value = stringValue
        } else if let boolValue = try? container.decode(Bool.self) {
            value = boolValue
        } else if let arrayValue = try? container.decode([AnyCodable].self) {
            value = arrayValue.map { $0.value }
        } else if let dictValue = try? container.decode([String: AnyCodable].self) {
            value = dictValue.mapValues { $0.value }
        } else {
            value = NSNull()
        }
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()

        switch value {
        case let intValue as Int:
            try container.encode(intValue)
        case let doubleValue as Double:
            try container.encode(doubleValue)
        case let stringValue as String:
            try container.encode(stringValue)
        case let boolValue as Bool:
            try container.encode(boolValue)
        case let arrayValue as [Any]:
            try container.encode(arrayValue.map { AnyCodable($0) })
        case let dictValue as [String: Any]:
            try container.encode(dictValue.mapValues { AnyCodable($0) })
        default:
            try container.encodeNil()
        }
    }
}
