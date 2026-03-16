import XCTest
@testable import BonhommeCore

final class LocalizedStringTests: XCTestCase {

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
            zh: "山", ko: "산", ru: "Гора", de: "Berg", ar: "جبل"
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
        // Unsupported language falls back to English
        XCTAssertEqual(str.value(for: "pt"), "Mountain")
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
        XCTAssertEqual(LocalizedString.supportedLanguages.count, 9)
        XCTAssertTrue(LocalizedString.supportedLanguages.contains("en"))
        XCTAssertTrue(LocalizedString.supportedLanguages.contains("fr"))
        XCTAssertTrue(LocalizedString.supportedLanguages.contains("es"))
        XCTAssertTrue(LocalizedString.supportedLanguages.contains("ja"))
        XCTAssertTrue(LocalizedString.supportedLanguages.contains("zh"))
        XCTAssertTrue(LocalizedString.supportedLanguages.contains("ko"))
        XCTAssertTrue(LocalizedString.supportedLanguages.contains("ru"))
        XCTAssertTrue(LocalizedString.supportedLanguages.contains("de"))
        XCTAssertTrue(LocalizedString.supportedLanguages.contains("ar"))
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
        {"en":"Hello","fr":"Bonjour","es":"","ja":"","zh":"","ko":"","ru":"","de":"","ar":""}
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
