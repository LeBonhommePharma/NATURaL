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
    /// Languages the shipping app actually resolves. Narrowed to en + fr for 1.0 on
    /// 20 September 2026: the other nine were only 64.7% translated (13.3% for it/pt),
    /// so a Spanish device rendered roughly two strings in three translated and the
    /// rest English, interleaved mid-screen. `preferredLanguage` returns "en" for any
    /// code absent here, so those users now get clean English instead.
    ///
    /// Nothing was deleted to achieve this. The inline translations, the supplemental
    /// catalogs and every locale's InfoPlist.strings remain in the repo. Restoring a
    /// language is this array, CFBundleLocalizations in Bonhomme + BonhommeWatch, and
    /// the InfoPlist.strings variant-group children in project.pbxproj — no file moves.
    ///
    /// The restore is also free on the **data** side, which is a property of the wire
    /// format rather than an accident. `LocalizedString` keeps all eleven language
    /// fields whatever `supportedLanguages` says, so a deferred language encodes as an
    /// empty string rather than being dropped: saved sessions, relayed payloads and
    /// anything already on disk survive the narrowing untouched, and restoring a
    /// language needs no migration and recovers nothing. Verified against the real
    /// encoder — eleven keys present, deferred fields empty, arrays identical — and
    /// asserted by `testSupplementalLookupPreservesCodableFieldsAndEquality`, which
    /// checks the struct's own fields rather than borrowing this list. The two were
    /// equal before 1.0 and are deliberately decoupled now; a test comparing them was
    /// relying on a coincidence.
    public static let supportedLanguages = ["en", "fr"]

    /// Match the ordered OS language list, including regional and script variants.
    public static func preferredLanguage(in identifiers: [String]) -> String {
        identifiers.lazy.map(normalizedLanguage).first(where: supportedLanguages.contains) ?? "en"
    }

    public static func normalizedLanguage(_ identifier: String) -> String {
        identifier.replacingOccurrences(of: "_", with: "-")
            .split(separator: "-").first.map { String($0).lowercased() } ?? "en"
    }

    /// Returns the appropriate translation for the current locale.
    /// Missing inline translations use the bundled supplemental catalog, then English.
    public var localized: String {
        let lang = LocalizedString.preferredLanguage(in: Locale.preferredLanguages)
        return value(for: lang)
    }

    /// Explicitly resolve for a given language code.
    /// Explicit inline translations take precedence; missing entries use the exact
    /// English key in the bundled catalog, then fall back to English.
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
        return resolved.isEmpty ? SupplementalLocalization.value(for: en, language: languageCode) ?? en : resolved
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
        guard resolved.isEmpty else { return resolved }
        return en.map { SupplementalLocalization.value(for: $0, language: languageCode) ?? $0 }
    }
}


/// Exact-key, offline fallback only. No interpolation, network translation or
/// mutation of Codable fields: saved and relayed content retains its original bytes.
enum SupplementalLocalization {
    static let resourceNames = ["SupplementalNavigation", "SupplementalGuidance", "SupplementalTV"]
    static let catalog: [String: [String: String]] = {
        #if SWIFT_PACKAGE
        let bundle = Bundle.module
        #else
        let bundle = Bundle(for: SupplementalLocalizationBundle.self)
        #endif
        var result: [String: [String: String]] = [:]
        for name in resourceNames {
            guard let url = bundle.url(forResource: name, withExtension: "json"),
                  let data = try? Data(contentsOf: url),
                  let entries = try? JSONDecoder().decode([String: [String: String]].self, from: data) else { continue }
            for (english, translations) in entries where !english.isEmpty && result[english] == nil {
                result[english] = translations
            }
        }
        return result
    }()

    static func value(for english: String, language: String) -> String? {
        guard language != "en", LocalizedString.supportedLanguages.contains(language),
              let value = catalog[english]?[language], !value.isEmpty else { return nil }
        return value
    }
}

#if !SWIFT_PACKAGE
private final class SupplementalLocalizationBundle: NSObject {}
#endif
