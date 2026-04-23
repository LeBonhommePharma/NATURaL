import XCTest
@testable import BonhommeCore

final class LocalizationTests: XCTestCase {

    // MARK: - LocalizedString (scalar) tests

    func testPortugueseBrazilResolution() {
        let s = LocalizedString(
            en: "Hello",
            fr: "Bonjour",
            pt: "Olá",
            pt_BR: "Oi"
        )
        XCTAssertEqual(s.value(for: "pt-BR"), "Oi", "pt-BR should resolve to pt_BR variant")
        XCTAssertEqual(s.value(for: "pt-PT"), "Olá", "pt-PT should fall back to base pt")
    }

    func testPortugueseBrazilFallbackToEnglishWhenEmpty() {
        let s = LocalizedString(
            en: "Hello",
            fr: "Bonjour",
            pt: "",
            pt_BR: ""
        )
        XCTAssertEqual(s.value(for: "pt-BR"), "Hello", "Empty pt_BR and pt should fall back to English")
    }

    func testChineseSimplifiedResolution() {
        let s = LocalizedString(
            en: "Chair Yoga",
            fr: "Yoga sur chaise",
            zh: "椅子瑜伽",
            zh_Hans: "椅子瑜伽（简体）"
        )
        XCTAssertEqual(s.value(for: "zh-Hans"), "椅子瑜伽（简体）")
        XCTAssertEqual(s.value(for: "zh-CN"), "椅子瑜伽", "zh-CN should resolve to base zh when zh-Hans not explicitly matched")
    }

    func testChineseFallbackToEnglishWhenEmpty() {
        let s = LocalizedString(
            en: "Chair Yoga",
            fr: "Yoga sur chaise",
            zh: "",
            zh_Hans: ""
        )
        XCTAssertEqual(s.value(for: "zh-Hans"), "Chair Yoga")
        XCTAssertEqual(s.value(for: "zh-HK"), "Chair Yoga")
    }

    func testEnglishRegionalVariants() {
        let s = LocalizedString(
            en: "Color",
            fr: "Couleur",
            en_GB: "Colour",
            en_CA: "Colour"
        )
        XCTAssertEqual(s.value(for: "en-GB"), "Colour")
        XCTAssertEqual(s.value(for: "en-CA"), "Colour")
        XCTAssertEqual(s.value(for: "en-AU"), "Color", "Unknown regional en should fall back to base en")
    }

    // MARK: - LocalizedStringArray (array) tests

    func testArrayPortugueseResolution() {
        let a = LocalizedStringArray(
            en: ["A"],
            fr: ["B"],
            pt: ["PT"],
            pt_BR: ["PT-BR"]
        )
        XCTAssertEqual(a.value(for: "pt-BR"), ["PT-BR"])
        XCTAssertEqual(a.value(for: "pt-PT"), ["PT"]) 
    }

    func testArrayFallbackToEnglishWhenEmpty() {
        let a = LocalizedStringArray(
            en: ["base"],
            fr: ["fr"],
            pt: [],
            pt_BR: []
        )
        XCTAssertEqual(a.value(for: "pt-BR"), ["base"]) 
    }

    func testArrayChineseSimplifiedResolution() {
        let a = LocalizedStringArray(
            en: ["Chair"],
            fr: ["Chaise"],
            zh: ["椅子"],
            zh_Hans: ["椅子（简体）"]
        )
        XCTAssertEqual(a.value(for: "zh-Hans"), ["椅子（简体）"])
        XCTAssertEqual(a.value(for: "zh-HK"), ["椅子"], "zh-HK should fall back to base zh in our current logic")
    }
}
