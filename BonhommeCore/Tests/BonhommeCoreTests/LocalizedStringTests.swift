import XCTest
@testable import BonhommeCore

final class LocalizedStringTests: XCTestCase {

    func testBundledSupplementalCatalogLoadsAllSupportedLanguages() {
        XCTAssertFalse(SupplementalLocalization.catalog.isEmpty, "Supplemental resources must ship with BonhommeCore")
        for key in ["Cancel", "Pose guide", "Pairing key"] {
            XCTAssertNotNil(SupplementalLocalization.catalog[key], "Each supplemental resource must be bundled: \(key)")
        }
        for (english, translations) in SupplementalLocalization.catalog {
            XCTAssertEqual(Set(translations.keys), Set(LocalizedString.supportedLanguages), english)
            XCTAssertEqual(translations["en"], english)
            XCTAssertTrue(translations.values.allSatisfy { !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }, english)
        }
        let guide = LocalizedString(en: "Pose guide", fr: "")
        for language in LocalizedString.supportedLanguages where language != "en" {
            XCTAssertNotEqual(guide.value(for: language), guide.en, language)
        }
    }

    func testSupplementalFallbackResolvesOSRegionsAndPreservesExplicitOverrides() {
        let guide = LocalizedString(en: "Pose guide", fr: "Texte choisi", es: "Texto explícito")
        XCTAssertEqual(guide.value(for: "fr-CA"), "Texte choisi")
        XCTAssertEqual(guide.value(for: "ES_mx"), "Texto explícito")
        XCTAssertEqual(guide.value(for: "ja-JP"), "ポーズガイド")
        XCTAssertEqual(guide.value(for: "zh-Hant-TW"), "体式指南")
        XCTAssertEqual(guide.value(for: "pt-BR"), "Guia da postura")
        XCTAssertEqual(guide.value(for: "it-IT"), "Guida alla posizione")
        XCTAssertEqual(guide.value(for: "en-US"), "Pose guide")
        XCTAssertEqual(guide.value(for: "sv-SE"), "Pose guide")
        let osLanguage = LocalizedString.preferredLanguage(in: ["sv-SE", "ko-KR", "en-US"])
        XCTAssertEqual(guide.value(for: osLanguage), "자세 가이드")
    }

    func testMissingKeysAndRuntimeTextRemainEnglishWithoutPartialReplacement() {
        let unknown = "A test phrase absent from the bundled catalog"
        XCTAssertEqual(LocalizedString(en: unknown, fr: "").value(for: "ja"), unknown)
        let runtimeCopy = "Pose guide: \(17)"
        XCTAssertEqual(LocalizedString(en: runtimeCopy, fr: "").value(for: "de"), runtimeCopy)
        XCTAssertEqual(LocalizedString(en: "", fr: "").value(for: "pt"), "")
        XCTAssertEqual(LocalizedString(en: "Pose guide", fr: "", es: " ").value(for: "es"), " ",
                       "Existing explicit strings are not rewritten or trimmed")
    }

    func testArrayFallbackResolvesItemsWithoutReplacingExplicitArrays() {
        let items = LocalizedStringArray(en: ["Pose guide", "Unlisted movement", "Cancel"], fr: [],
                                         es: ["Custom translated list"])
        XCTAssertEqual(items.value(for: "it-IT"), ["Guida alla posizione", "Unlisted movement", "Annulla"])
        XCTAssertEqual(items.value(for: "es-MX"), ["Custom translated list"])
        XCTAssertEqual(items.value(for: "en-US"), items.en)
        XCTAssertEqual(items.value(for: "sv"), items.en)
        XCTAssertEqual(LocalizedStringArray(en: [], fr: []).value(for: "de"), [])
    }

    func testSupplementalLookupPreservesCodableFieldsAndEquality() throws {
        let text = LocalizedString(en: "Pose guide", fr: "Texte choisi")
        let original = try JSONEncoder().encode(text)
        XCTAssertEqual(text.value(for: "de"), "Posenanleitung")
        let fields = try XCTUnwrap(JSONSerialization.jsonObject(with: JSONEncoder().encode(text)) as? [String: String])
        XCTAssertEqual(fields["de"], "")
        XCTAssertEqual(fields["fr"], "Texte choisi")
        XCTAssertEqual(Set(fields.keys), Set(LocalizedString.supportedLanguages))
        XCTAssertEqual(try JSONDecoder().decode(LocalizedString.self, from: original), text)

        let array = LocalizedStringArray(en: ["Pose guide"], fr: [])
        _ = array.value(for: "pt")
        let arrayFields = try XCTUnwrap(JSONSerialization.jsonObject(with: JSONEncoder().encode(array)) as? [String: [String]])
        XCTAssertEqual(arrayFields["pt"], [])
        XCTAssertEqual(arrayFields["en"], ["Pose guide"])
        XCTAssertEqual(try JSONDecoder().decode(LocalizedStringArray.self, from: JSONEncoder().encode(array)), array)
    }


    func testOSLanguagePreferenceMatching() {
        XCTAssertEqual(LocalizedString.preferredLanguage(in: ["sv-SE", "FR_ca", "en-US"]), "fr")
        XCTAssertEqual(LocalizedString.preferredLanguage(in: ["pt-BR", "en"]), "pt")
        XCTAssertEqual(LocalizedString.preferredLanguage(in: ["zh-Hant-TW"]), "zh")
        XCTAssertEqual(LocalizedString.preferredLanguage(in: ["ar-SA"]), "ar")
        XCTAssertEqual(LocalizedString.preferredLanguage(in: ["french", "sv"]), "en")
        XCTAssertEqual(LocalizedString.preferredLanguage(in: []), "en")
        XCTAssertEqual(LocalizedString(en: "Hello", fr: "Bonjour").value(for: "FR_ca"), "Bonjour")
        XCTAssertEqual(LocalizedStringArray(en: ["Hello"], fr: ["Bonjour"]).value(for: "FR_ca"), ["Bonjour"])
    }

    // MARK: - LocalizedString

    func testLocalizedStringStoresValues() {
        let str = LocalizedString(en: "Hello", fr: "Bonjour")
        XCTAssertEqual(str.en, "Hello")
        XCTAssertEqual(str.fr, "Bonjour")
    }

    func testLocalizedStringAllLanguages() {
        let str = LocalizedString(
            en: "Hello", fr: "Bonjour", es: "Hola", ja: "こんにちは",
            zh: "你好", ko: "안녕하세요", ru: "Привет", de: "Hallo", ar: "مرحبا"
        )
        XCTAssertEqual(str.en, "Hello")
        XCTAssertEqual(str.fr, "Bonjour")
        XCTAssertEqual(str.es, "Hola")
        XCTAssertEqual(str.ja, "こんにちは")
        XCTAssertEqual(str.zh, "你好")
        XCTAssertEqual(str.ko, "안녕하세요")
        XCTAssertEqual(str.ru, "Привет")
        XCTAssertEqual(str.de, "Hallo")
        XCTAssertEqual(str.ar, "مرحبا")
    }

    func testExplicitLanguageResolution() {
        let str = LocalizedString(
            en: "Mountain", fr: "Montagne", es: "Montaña", ja: "山",
            zh: "山", ko: "산", ru: "Гора", de: "Berg", ar: "جبل",
            it: "Montagna", pt: "Montanha"
        )
        XCTAssertEqual(str.value(for: "en"), "Mountain")
        XCTAssertEqual(str.value(for: "fr"), "Montagne")
        XCTAssertEqual(str.value(for: "fr-CA"), "Montagne")
        XCTAssertEqual(str.value(for: "es"), "Montaña")
        XCTAssertEqual(str.value(for: "es-MX"), "Montaña")
        XCTAssertEqual(str.value(for: "ja"), "山")
        XCTAssertEqual(str.value(for: "zh"), "山")
        XCTAssertEqual(str.value(for: "zh-Hans"), "山")
        XCTAssertEqual(str.value(for: "ko"), "산")
        XCTAssertEqual(str.value(for: "ru"), "Гора")
        XCTAssertEqual(str.value(for: "de"), "Berg")
        XCTAssertEqual(str.value(for: "de-AT"), "Berg")
        XCTAssertEqual(str.value(for: "ar"), "جبل")
        XCTAssertEqual(str.value(for: "it"), "Montagna")
        XCTAssertEqual(str.value(for: "pt"), "Montanha")
        // Unsupported language falls back to English
        XCTAssertEqual(str.value(for: "sv"), "Mountain")
    }

    func testFallbackToEnglishWhenEmpty() {
        // When new languages default to empty string, should fall back to English
        let str = LocalizedString(en: "Hello", fr: "Bonjour")
        XCTAssertEqual(str.value(for: "es"), "Hello", "Empty es should fall back to English")
        XCTAssertEqual(str.value(for: "ja"), "Hello", "Empty ja should fall back to English")
        XCTAssertEqual(str.value(for: "zh"), "Hello", "Empty zh should fall back to English")
        XCTAssertEqual(str.value(for: "ko"), "Hello", "Empty ko should fall back to English")
        XCTAssertEqual(str.value(for: "ru"), "Hello", "Empty ru should fall back to English")
        XCTAssertEqual(str.value(for: "de"), "Hello", "Empty de should fall back to English")
        XCTAssertEqual(str.value(for: "ar"), "Hello", "Empty ar should fall back to English")
    }

    func testSupportedLanguages() {
        XCTAssertEqual(LocalizedString.supportedLanguages.count, 11)
        XCTAssertTrue(LocalizedString.supportedLanguages.contains("en"))
        XCTAssertTrue(LocalizedString.supportedLanguages.contains("fr"))
        XCTAssertTrue(LocalizedString.supportedLanguages.contains("es"))
        XCTAssertTrue(LocalizedString.supportedLanguages.contains("ja"))
        XCTAssertTrue(LocalizedString.supportedLanguages.contains("zh"))
        XCTAssertTrue(LocalizedString.supportedLanguages.contains("ko"))
        XCTAssertTrue(LocalizedString.supportedLanguages.contains("ru"))
        XCTAssertTrue(LocalizedString.supportedLanguages.contains("de"))
        XCTAssertTrue(LocalizedString.supportedLanguages.contains("ar"))
        XCTAssertTrue(LocalizedString.supportedLanguages.contains("it"))
        XCTAssertTrue(LocalizedString.supportedLanguages.contains("pt"))
    }

    func testLocalizedStringHashableConformance() {
        let a = LocalizedString(en: "A", fr: "A-FR")
        let b = LocalizedString(en: "A", fr: "A-FR")
        let c = LocalizedString(en: "B", fr: "B-FR")
        XCTAssertEqual(a, b)
        XCTAssertNotEqual(a, c)
        XCTAssertEqual(a.hashValue, b.hashValue)
    }

    func testLocalizedStringCodable() throws {
        let original = LocalizedString(
            en: "Test", fr: "Essai", es: "Prueba", ja: "テスト",
            zh: "测试", ko: "테스트", ru: "Тест", de: "Test", ar: "اختبار"
        )
        let data = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(LocalizedString.self, from: data)
        XCTAssertEqual(original, decoded)
    }

    func testLocalizedStringCodableBackwardsCompatibility() throws {
        // Test decoding JSON with only en/fr (older format) still works
        let json = """
        {"en":"Hello","fr":"Bonjour","es":"","ja":"","zh":"","ko":"","ru":"","de":"","ar":"","it":"","pt":""}
        """.data(using: .utf8)!
        let decoded = try JSONDecoder().decode(LocalizedString.self, from: json)
        XCTAssertEqual(decoded.en, "Hello")
        XCTAssertEqual(decoded.fr, "Bonjour")
        XCTAssertEqual(decoded.value(for: "es"), "Hello") // Falls back to English
    }

    // MARK: - LocalizedStringArray

    func testLocalizedStringArrayStoresValues() {
        let arr = LocalizedStringArray(
            en: ["Option A", "Option B"],
            fr: ["Option A-FR", "Option B-FR"]
        )
        XCTAssertEqual(arr.en.count, 2)
        XCTAssertEqual(arr.fr.count, 2)
    }

    func testLocalizedStringArrayAllLanguages() {
        let arr = LocalizedStringArray(
            en: ["Hello"], fr: ["Bonjour"], es: ["Hola"], ja: ["こんにちは"],
            zh: ["你好"], ko: ["안녕하세요"], ru: ["Привет"], de: ["Hallo"], ar: ["مرحبا"]
        )
        XCTAssertEqual(arr.value(for: "es"), ["Hola"])
        XCTAssertEqual(arr.value(for: "ja"), ["こんにちは"])
        XCTAssertEqual(arr.value(for: "zh"), ["你好"])
        XCTAssertEqual(arr.value(for: "ko"), ["안녕하세요"])
        XCTAssertEqual(arr.value(for: "ru"), ["Привет"])
        XCTAssertEqual(arr.value(for: "de"), ["Hallo"])
        XCTAssertEqual(arr.value(for: "ar"), ["مرحبا"])
    }

    func testLocalizedStringArrayExplicitResolution() {
        let arr = LocalizedStringArray(
            en: ["Mod 1"],
            fr: ["Mod 1-FR"]
        )
        XCTAssertEqual(arr.value(for: "en"), ["Mod 1"])
        XCTAssertEqual(arr.value(for: "fr"), ["Mod 1-FR"])
        XCTAssertEqual(arr.value(for: "fr-CA"), ["Mod 1-FR"])
    }

    func testLocalizedStringArrayFallbackToEnglish() {
        let arr = LocalizedStringArray(en: ["A", "B"], fr: ["X", "Y"])
        // Empty arrays should fall back to English
        XCTAssertEqual(arr.value(for: "es"), ["A", "B"])
        XCTAssertEqual(arr.value(for: "ja"), ["A", "B"])
    }

    func testLocalizedStringArrayCodable() throws {
        let original = LocalizedStringArray(
            en: ["A", "B"], fr: ["X", "Y"],
            es: ["C", "D"], ja: ["E", "F"]
        )
        let data = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(LocalizedStringArray.self, from: data)
        XCTAssertEqual(original, decoded)
    }

    func testEmptyLocalizedStringArray() {
        let arr = LocalizedStringArray(en: [], fr: [])
        XCTAssertTrue(arr.value(for: "en").isEmpty)
        XCTAssertTrue(arr.value(for: "fr").isEmpty)
    }
}
