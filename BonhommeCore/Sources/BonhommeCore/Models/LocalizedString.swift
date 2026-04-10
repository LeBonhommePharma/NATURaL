import Foundation

/// A string with multilingual translations.
/// Supports: English, French, Spanish, Japanese, Chinese, Korean, Russian, German, Arabic, Italian, Portuguese.
/// Also supports common regional variants (en-GB, en-CA, pt-BR, zh-Hans).
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

    // Regional variants (empty string = fall back to base language)
    public let en_GB: String
    public let en_CA: String
    public let pt_BR: String
    public let zh_Hans: String

    public init(
        en: String,
        fr: String,
        es: String = "",
        ja: String = "",
        zh: String = "",
        ko: String = "",
        ru: String = "",
        de: String = "",
        ar: String = "",
        it: String = "",
        pt: String = "",
        en_GB: String = "",
        en_CA: String = "",
        pt_BR: String = "",
        zh_Hans: String = ""
    ) {
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
        self.en_GB = en_GB
        self.en_CA = en_CA
        self.pt_BR = pt_BR
        self.zh_Hans = zh_Hans
    }

    /// All supported base language codes.
    public static let supportedLanguages = ["en", "fr", "es", "ja", "zh", "ko", "ru", "de", "ar", "it", "pt"]

    /// Returns the appropriate translation for the current locale.
    /// Falls back to English if the locale's language is not supported or translation is empty.
    public var localized: String {
        let lang = Locale.current.language.languageCode?.identifier ?? "en"
        return value(for: lang)
    }

    /// Explicitly resolve for a given language code.
    /// Checks specific regional variants first, then falls back to the base language, then English.
    public func value(for languageCode: String) -> String {
        // Check specific regional variants first
        let regional: String?
        switch languageCode {
        case "en-GB":   regional = en_GB.isEmpty ? nil : en_GB
        case "en-CA":   regional = en_CA.isEmpty ? nil : en_CA
        case "pt-BR":   regional = pt_BR.isEmpty ? nil : pt_BR
        case "zh-Hans": regional = zh_Hans.isEmpty ? nil : zh_Hans
        default:        regional = nil
        }
        if let r = regional { return r }

        // Base language match
        let resolved: String
        switch true {
        case languageCode.hasPrefix("fr"): resolved = fr
        case languageCode.hasPrefix("es"): resolved = es
        case languageCode.hasPrefix("ja"): resolved = ja
        case languageCode.hasPrefix("zh"): resolved = zh
        case languageCode.hasPrefix("ko"): resolved = ko
        case languageCode.hasPrefix("ru"): resolved = ru
        case languageCode.hasPrefix("de"): resolved = de
        case languageCode.hasPrefix("ar"): resolved = ar
        case languageCode.hasPrefix("it"): resolved = it
        case languageCode.hasPrefix("pt"): resolved = pt
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

    // Regional variants
    public let en_GB: [String]
    public let en_CA: [String]
    public let pt_BR: [String]
    public let zh_Hans: [String]

    public init(
        en: [String],
        fr: [String],
        es: [String] = [],
        ja: [String] = [],
        zh: [String] = [],
        ko: [String] = [],
        ru: [String] = [],
        de: [String] = [],
        ar: [String] = [],
        it: [String] = [],
        pt: [String] = [],
        en_GB: [String] = [],
        en_CA: [String] = [],
        pt_BR: [String] = [],
        zh_Hans: [String] = []
    ) {
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
        self.en_GB = en_GB
        self.en_CA = en_CA
        self.pt_BR = pt_BR
        self.zh_Hans = zh_Hans
    }

    public var localized: [String] {
        let lang = Locale.current.language.languageCode?.identifier ?? "en"
        return value(for: lang)
    }

    public func value(for languageCode: String) -> [String] {
        // Check specific regional variants first
        let regional: [String]?
        switch languageCode {
        case "en-GB":   regional = en_GB.isEmpty ? nil : en_GB
        case "en-CA":   regional = en_CA.isEmpty ? nil : en_CA
        case "pt-BR":   regional = pt_BR.isEmpty ? nil : pt_BR
        case "zh-Hans": regional = zh_Hans.isEmpty ? nil : zh_Hans
        default:        regional = nil
        }
        if let r = regional { return r }

        // Base language match
        let resolved: [String]
        switch true {
        case languageCode.hasPrefix("fr"): resolved = fr
        case languageCode.hasPrefix("es"): resolved = es
        case languageCode.hasPrefix("ja"): resolved = ja
        case languageCode.hasPrefix("zh"): resolved = zh
        case languageCode.hasPrefix("ko"): resolved = ko
        case languageCode.hasPrefix("ru"): resolved = ru
        case languageCode.hasPrefix("de"): resolved = de
        case languageCode.hasPrefix("ar"): resolved = ar
        case languageCode.hasPrefix("it"): resolved = it
        case languageCode.hasPrefix("pt"): resolved = pt
        default: resolved = en
        }
        return resolved.isEmpty ? en : resolved
    }
}
