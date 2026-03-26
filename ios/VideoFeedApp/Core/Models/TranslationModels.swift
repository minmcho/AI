import Foundation

// MARK: - Language

struct MyanmarLanguage: Identifiable, Hashable, Codable {
    let code: String      // NLLB-200 code, e.g. "mya_Mymr"
    let name: String      // Display name, e.g. "Myanmar"

    var id: String { code }

    var flag: String {
        switch code {
        case "mya_Mymr": return "🇲🇲"
        case "eng_Latn": return "🇬🇧"
        case "zho_Hans": return "🇨🇳"
        case "zho_Hant": return "🇹🇼"
        case "tha_Thai": return "🇹🇭"
        case "jpn_Jpan": return "🇯🇵"
        case "kor_Hang": return "🇰🇷"
        case "fra_Latn": return "🇫🇷"
        case "spa_Latn": return "🇪🇸"
        case "deu_Latn": return "🇩🇪"
        case "por_Latn": return "🇧🇷"
        case "arb_Arab": return "🇸🇦"
        case "hin_Deva": return "🇮🇳"
        case "vie_Latn": return "🇻🇳"
        case "ind_Latn": return "🇮🇩"
        case "rus_Cyrl": return "🇷🇺"
        case "zsm_Latn": return "🇲🇾"
        default:         return "🌐"
        }
    }

    // Default bundle - fetched once from /ai/translate/languages
    static let builtIn: [MyanmarLanguage] = [
        .init(code: "mya_Mymr", name: "Myanmar"),
        .init(code: "eng_Latn", name: "English"),
        .init(code: "zho_Hans", name: "Chinese (Simplified)"),
        .init(code: "zho_Hant", name: "Chinese (Traditional)"),
        .init(code: "tha_Thai", name: "Thai"),
        .init(code: "jpn_Jpan", name: "Japanese"),
        .init(code: "kor_Hang", name: "Korean"),
        .init(code: "fra_Latn", name: "French"),
        .init(code: "spa_Latn", name: "Spanish"),
        .init(code: "deu_Latn", name: "German"),
        .init(code: "por_Latn", name: "Portuguese"),
        .init(code: "arb_Arab", name: "Arabic"),
        .init(code: "hin_Deva", name: "Hindi"),
        .init(code: "vie_Latn", name: "Vietnamese"),
        .init(code: "ind_Latn", name: "Indonesian"),
        .init(code: "rus_Cyrl", name: "Russian"),
        .init(code: "zsm_Latn", name: "Malay"),
    ]

    static let myanmar  = MyanmarLanguage(code: "mya_Mymr", name: "Myanmar")
    static let english  = MyanmarLanguage(code: "eng_Latn", name: "English")
}

// MARK: - API Request / Response

struct TranslateRequest: Encodable {
    let text: String
    let sourceLang: String
    let targetLang: String
    enum CodingKeys: String, CodingKey {
        case text
        case sourceLang = "source_lang"
        case targetLang = "target_lang"
    }
}

struct TranslateResponse: Decodable {
    let sourceText: String
    let translatedText: String
    let sourceLang: String
    let sourceLangName: String
    let targetLang: String
    let targetLangName: String
    enum CodingKeys: String, CodingKey {
        case sourceText      = "source_text"
        case translatedText  = "translated_text"
        case sourceLang      = "source_lang"
        case sourceLangName  = "source_lang_name"
        case targetLang      = "target_lang"
        case targetLangName  = "target_lang_name"
    }
}

struct MultiTranslateRequest: Encodable {
    let text: String
    let sourceLang: String
    let targetLangs: [String]
    enum CodingKeys: String, CodingKey {
        case text
        case sourceLang  = "source_lang"
        case targetLangs = "target_langs"
    }
}

struct MultiTranslateResponse: Decodable {
    let sourceText: String
    let sourceLang: String
    let translations: [String: String]       // code -> translated text
    let translationNames: [String: String]   // code -> display name
    enum CodingKeys: String, CodingKey {
        case sourceText       = "source_text"
        case sourceLang       = "source_lang"
        case translations
        case translationNames = "translation_names"
    }
}

struct LanguagesResponse: Decodable {
    struct LanguageItem: Decodable {
        let name: String
        let code: String
    }
    let languages: [LanguageItem]
}

// MARK: - History

struct TranslationHistoryItem: Identifiable, Codable {
    let id: UUID
    let sourceText: String
    let translatedText: String
    let sourceLang: MyanmarLanguage
    let targetLang: MyanmarLanguage
    let createdAt: Date

    init(sourceText: String, translatedText: String,
         sourceLang: MyanmarLanguage, targetLang: MyanmarLanguage) {
        self.id             = UUID()
        self.sourceText     = sourceText
        self.translatedText = translatedText
        self.sourceLang     = sourceLang
        self.targetLang     = targetLang
        self.createdAt      = Date()
    }
}

// MARK: - Multi-result display

struct MultiTranslationResult: Identifiable {
    let id = UUID()
    let language: MyanmarLanguage
    let translatedText: String
}
