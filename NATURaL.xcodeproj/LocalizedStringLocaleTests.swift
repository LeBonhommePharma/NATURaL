import Testing
import Foundation

@Suite("LocalizedString and LocalizedStringArray Locale Resolution")
struct LocalizedStringLocaleTests {
    @Test("Resolves Italian and Portuguese translations when present")
    func resolveItalianAndPortuguese() async throws {
        let string = LocalizedString(
            en: "Hello",
            fr: "Bonjour",
            it: "Ciao",
            pt: "Olá"
        )
        
        // Simulate language code resolution
        #expect(string.value(for: "it") == "Ciao")
        #expect(string.value(for: "it-IT") == "Ciao")
        #expect(string.value(for: "pt") == "Olá")
        #expect(string.value(for: "pt-BR") == "Olá")
    }

    @Test("Falls back to English if Italian or Portuguese is missing/empty")
    func fallbackToEnglishForMissingTranslations() async throws {
        let string = LocalizedString(
            en: "Hello",
            fr: "Bonjour"
            // it and pt intentionally not set
        )
        #expect(string.value(for: "it") == "Hello")
        #expect(string.value(for: "pt-BR") == "Hello")

        let emptyString = LocalizedString(
            en: "Hello",
            fr: "Bonjour",
            it: "",
            pt: ""
        )
        #expect(emptyString.value(for: "it") == "Hello")
        #expect(emptyString.value(for: "pt") == "Hello")
    }

    @Test("LocalizedStringArray resolves arrays for Italian and Portuguese")
    func localizedStringArrayItalianPortuguese() async throws {
        let arr = LocalizedStringArray(
            en: ["A", "B"],
            fr: ["F1", "F2"],
            it: ["I1"],
            pt: ["P1", "P2"]
        )
        #expect(arr.value(for: "it") == ["I1"])
        #expect(arr.value(for: "pt-BR") == ["P1", "P2"])
        #expect(arr.value(for: "es") == ["A", "B"], "Fallback to en for non-present language")
    }

    @Test("Supported languages include Italian and Portuguese")
    func supportedLanguagesIncludesItAndPt() async throws {
        #expect(LocalizedString.supportedLanguages.contains("it"))
        #expect(LocalizedString.supportedLanguages.contains("pt"))
        #expect(LocalizedString.supportedLanguages.count >= 11)
    }

    @Test("All supported language codes resolve the correct value or fallback to English")
    func supportedLanguageCodesResolution() async throws {
        let string = LocalizedString(
            en: "Hello",
            fr: "Bonjour",
            es: "Hola",
            ja: "こんにちは",
            zh: "你好",
            ko: "안녕하세요",
            ru: "Здравствуйте",
            de: "Hallo",
            ar: "مرحبا",
            it: "Ciao",
            pt: "Olá"
        )
        let languages = LocalizedString.supportedLanguages
        let expected: [String: String] = [
            "en": "Hello",
            "fr": "Bonjour",
            "es": "Hola",
            "ja": "こんにちは",
            "zh": "你好",
            "ko": "안녕하세요",
            "ru": "Здравствуйте",
            "de": "Hallo",
            "ar": "مرحبا",
            "it": "Ciao",
            "pt": "Olá"
        ]
        for code in languages {
            let resolved = string.value(for: code)
            let expectedValue = expected[code] ?? "Hello"
            #expect(resolved == expectedValue, "Expected \(expectedValue) for code \(code), got \(resolved)")
        }
        // Also test an unknown code falls back to English
        #expect(string.value(for: "xx") == "Hello")
    }
}
