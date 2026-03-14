import Foundation

/// A string with English and French Canadian translations.
/// Resolves automatically based on the current locale.
public struct LocalizedString: Codable, Sendable, Hashable {
    public let en: String
    public let fr: String

    public init(en: String, fr: String) {
        self.en = en
        self.fr = fr
    }

    /// Returns the appropriate translation for the current locale.
    /// Defaults to English if locale is not French.
    public var localized: String {
        let lang = Locale.current.language.languageCode?.identifier ?? "en"
        return lang.hasPrefix("fr") ? fr : en
    }

    /// Explicitly resolve for a given language code.
    public func value(for languageCode: String) -> String {
        languageCode.hasPrefix("fr") ? fr : en
    }
}

/// A localized array of strings (e.g., modifications).
public struct LocalizedStringArray: Codable, Sendable, Hashable {
    public let en: [String]
    public let fr: [String]

    public init(en: [String], fr: [String]) {
        self.en = en
        self.fr = fr
    }

    public var localized: [String] {
        let lang = Locale.current.language.languageCode?.identifier ?? "en"
        return lang.hasPrefix("fr") ? fr : en
    }

    public func value(for languageCode: String) -> [String] {
        languageCode.hasPrefix("fr") ? fr : en
    }
}
