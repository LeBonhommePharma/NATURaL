import Foundation

/// A simple structure for bilingual localized strings (English and French).
public struct LocalizedString: Codable, Sendable {
    public let en: String
    public let fr: String
    
    public init(en: String, fr: String) {
        self.en = en
        self.fr = fr
    }
    
    /// Returns the localized string based on current locale.
    /// Falls back to English if French is not available or locale doesn't match.
    public var localized: String {
        let languageCode = Locale.current.language.languageCode?.identifier ?? "en"
        return languageCode.hasPrefix("fr") ? fr : en
    }
}
