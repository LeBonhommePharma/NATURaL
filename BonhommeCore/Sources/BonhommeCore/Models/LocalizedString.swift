import Foundation

/// A string with multilingual translations.
/// Supports: English, French, Spanish, Japanese, Chinese, Korean, Russian, German, Arabic, Italian, Portuguese.
/// Resolves automatically based on the current locale.
public struct LocalizedString: Codable, Sendable, Hashable {
    public let en: String
    public let fr: String
    public let es: String
    public let ja: String
    public let zh: String
    public let ko: String
    public let ru: String
    public let de: String
    public let ar: String
    public let it: String
    public let pt: String

    public init(en: String, fr: String, es: String = "", ja: String = "",
                zh: String = "", ko: String = "", ru: String = "",
                de: String = "", ar: String = "", it: String = "", pt: String = "") {
        self.en = en
        self.fr = fr
        self.es = es
        self.ja = ja
        self.zh = zh
        self.ko = ko
        self.ru = ru
        self.de = de
        self.ar = ar
        self.it = it
        self.pt = pt
    }

    /// All supported language codes.
    public static let supportedLanguages = ["en", "fr", "es", "ja", "zh", "ko", "ru", "de", "ar", "it", "pt"]

    /// Match the ordered OS language list, including regional and script variants.
    public static func preferredLanguage(in identifiers: [String]) -> String {
        identifiers.lazy.map(normalizedLanguage).first(where: supportedLanguages.contains) ?? "en"
    }

    public static func normalizedLanguage(_ identifier: String) -> String {
        identifier.replacingOccurrences(of: "_", with: "-")
            .split(separator: "-").first.map { String($0).lowercased() } ?? "en"
    }

    /// Returns the appropriate translation for the current locale.
    /// Falls back to English if the locale's language is not supported or translation is empty.
    public var localized: String {
        let lang = LocalizedString.preferredLanguage(in: Locale.preferredLanguages)
        return value(for: lang)
    }

    /// Explicitly resolve for a given language code.
    /// Falls back to English if the translation for the requested language is empty.
    public func value(for languageCode: String) -> String {
        let languageCode = Self.normalizedLanguage(languageCode)
        let resolved: String
        switch true {
        case languageCode == "fr": resolved = fr
        case languageCode == "es": resolved = es
        case languageCode == "ja": resolved = ja
        case languageCode == "zh": resolved = zh
        case languageCode == "ko": resolved = ko
        case languageCode == "ru": resolved = ru
        case languageCode == "de": resolved = de
        case languageCode == "ar": resolved = ar
        case languageCode == "it": resolved = it
        case languageCode == "pt": resolved = pt
        default: resolved = en
        }
        return resolved.isEmpty ? en : resolved
    }
}

/// A localized array of strings (e.g., modifications).
public struct LocalizedStringArray: Codable, Sendable, Hashable {
    public let en: [String]
    public let fr: [String]
    public let es: [String]
    public let ja: [String]
    public let zh: [String]
    public let ko: [String]
    public let ru: [String]
    public let de: [String]
    public let ar: [String]
    public let it: [String]
    public let pt: [String]

    public init(en: [String], fr: [String], es: [String] = [], ja: [String] = [],
                zh: [String] = [], ko: [String] = [], ru: [String] = [],
                de: [String] = [], ar: [String] = [], it: [String] = [], pt: [String] = []) {
        self.en = en
        self.fr = fr
        self.es = es
        self.ja = ja
        self.zh = zh
        self.ko = ko
        self.ru = ru
        self.de = de
        self.ar = ar
        self.it = it
        self.pt = pt
    }

    public var localized: [String] {
        let lang = LocalizedString.preferredLanguage(in: Locale.preferredLanguages)
        return value(for: lang)
    }

    public func value(for languageCode: String) -> [String] {
        let languageCode = LocalizedString.normalizedLanguage(languageCode)
        let resolved: [String]
        switch true {
        case languageCode == "fr": resolved = fr
        case languageCode == "es": resolved = es
        case languageCode == "ja": resolved = ja
        case languageCode == "zh": resolved = zh
        case languageCode == "ko": resolved = ko
        case languageCode == "ru": resolved = ru
        case languageCode == "de": resolved = de
        case languageCode == "ar": resolved = ar
        case languageCode == "it": resolved = it
        case languageCode == "pt": resolved = pt
        default: resolved = en
        }
        return resolved.isEmpty ? en : resolved
    }
}
