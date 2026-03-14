import XCTest
@testable import BonhommeCore

final class LocalizedStringTests: XCTestCase {

    // MARK: - LocalizedString

    func testLocalizedStringStoresValues() {
        let str = LocalizedString(en: "Hello", fr: "Bonjour")
        XCTAssertEqual(str.en, "Hello")
        XCTAssertEqual(str.fr, "Bonjour")
    }

    func testExplicitLanguageResolution() {
        let str = LocalizedString(en: "Mountain", fr: "Montagne")
        XCTAssertEqual(str.value(for: "en"), "Mountain")
        XCTAssertEqual(str.value(for: "fr"), "Montagne")
        XCTAssertEqual(str.value(for: "fr-CA"), "Montagne")
        // Non-French defaults to English
        XCTAssertEqual(str.value(for: "es"), "Mountain")
        XCTAssertEqual(str.value(for: "de"), "Mountain")
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
        let original = LocalizedString(en: "Test", fr: "Essai")
        let data = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(LocalizedString.self, from: data)
        XCTAssertEqual(original, decoded)
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

    func testLocalizedStringArrayExplicitResolution() {
        let arr = LocalizedStringArray(
            en: ["Mod 1"],
            fr: ["Mod 1-FR"]
        )
        XCTAssertEqual(arr.value(for: "en"), ["Mod 1"])
        XCTAssertEqual(arr.value(for: "fr"), ["Mod 1-FR"])
        XCTAssertEqual(arr.value(for: "fr-CA"), ["Mod 1-FR"])
    }

    func testLocalizedStringArrayCodable() throws {
        let original = LocalizedStringArray(en: ["A", "B"], fr: ["X", "Y"])
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
