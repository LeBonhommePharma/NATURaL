import XCTest
@testable import BonhommeCore

final class LocalizedStringTests: XCTestCase {

    func testBundledSupplementalCatalogLoadsAllSupportedLanguages() {
        XCTAssertFalse(SupplementalLocalization.catalog.isEmpty, "Supplemental resources must ship with BonhommeCore")
        for key in ["Cancel", "Pose guide", "Pairing key"] {
            XCTAssertNotNil(SupplementalLocalization.catalog[key], "Each supplemental resource must be bundled: \(key)")
        }
        for (english, translations) in SupplementalLocalization.catalog {
            // Subset, not equality. The catalog deliberately retains all eleven
            // languages so a deferred one can be restored by flipping
            // supportedLanguages back; asserting equality would fail on that
            // retention rather than on a real gap. What must hold is that every
            // SUPPORTED language is covered — a catalog missing one still fails,
            // and the message names it.
            let missing = Set(LocalizedString.supportedLanguages).subtracting(translations.keys)
            XCTAssertTrue(missing.isEmpty,
                          "\(english): catalog is missing supported language(s) \(missing.sorted())")
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
        // Supplemental lookup is gated on supportedLanguages, so the nine languages
        // deferred from 1.0 resolve to English. The catalog still contains them —
        // they are unsupported, not absent — so restoring one needs no catalog
        // change. Resolution itself is still asserted, through a shipping language.
        XCTAssertEqual(LocalizedString(en: "Pose guide", fr: "").value(for: "fr-CA"),
                       "Guide de la posture")
        XCTAssertEqual(guide.value(for: "ja-JP"), "Pose guide")
        XCTAssertEqual(guide.value(for: "zh-Hant-TW"), "Pose guide")
        XCTAssertEqual(guide.value(for: "pt-BR"), "Pose guide")
        XCTAssertEqual(guide.value(for: "it-IT"), "Pose guide")
        XCTAssertEqual(guide.value(for: "en-US"), "Pose guide")
        XCTAssertEqual(guide.value(for: "sv-SE"), "Pose guide")
        // A deferred language in the OS list is skipped, so English is selected.
        let osLanguage = LocalizedString.preferredLanguage(in: ["sv-SE", "ko-KR", "en-US"])
        XCTAssertEqual(osLanguage, "en")
        XCTAssertEqual(guide.value(for: osLanguage), "Pose guide")
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
        // (a) supplemental fills listed items individually, leaving unlisted ones in
        // English — routed through French, which 1.0 actually ships.
        XCTAssertEqual(items.value(for: "fr-CA"), ["Guide de la posture", "Unlisted movement", "Annuler"])
        // (b) an explicit array still wins over the supplemental catalog.
        XCTAssertEqual(items.value(for: "es-MX"), ["Custom translated list"])
        // (c) English and unknown languages resolve to the English array.
        XCTAssertEqual(items.value(for: "en-US"), items.en)
        XCTAssertEqual(items.value(for: "sv"), items.en)
        // (d) A language deferred from 1.0 falls back to English rather than
        // resolving partially. The previous version of this test asserted through
        // it-IT that Italian resolved; that is now the stated contract's opposite,
        // so it is asserted rather than implied. Italian is still in the catalog —
        // it is unsupported, not absent.
        XCTAssertEqual(items.value(for: "it-IT"), items.en)
        XCTAssertEqual(LocalizedStringArray(en: [], fr: []).value(for: "de"), [])
    }

    func testSupplementalLookupPreservesCodableFieldsAndEquality() throws {
        let text = LocalizedString(en: "Pose guide", fr: "Texte choisi")
        let original = try JSONEncoder().encode(text)
        // German is deferred, so supplemental lookup returns English. The Codable
        // assertions below are this test's subject and are unchanged.
        XCTAssertEqual(text.value(for: "de"), "Pose guide")
        XCTAssertEqual(text.value(for: "fr"), "Texte choisi")
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
        // Region and script normalisation is unchanged; what changed is which
        // normalised codes survive the supportedLanguages filter.
        XCTAssertEqual(LocalizedString.preferredLanguage(in: ["pt-BR", "en"]), "en")
        XCTAssertEqual(LocalizedString.preferredLanguage(in: ["zh-Hant-TW"]), "en")
        XCTAssertEqual(LocalizedString.preferredLanguage(in: ["ar-SA"]), "en")
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
        // 1.0 ships exactly en + fr. This is the assertion that changes when a
        // language is restored — alongside CFBundleLocalizations and the
        // InfoPlist.strings variant-group children. See the doc comment on
        // LocalizedString.supportedLanguages.
        XCTAssertEqual(LocalizedString.supportedLanguages, ["en", "fr"])
        for deferred in ["es", "ja", "zh", "ko", "ru", "de", "ar", "it", "pt"] {
            XCTAssertFalse(LocalizedString.supportedLanguages.contains(deferred),
                           "\(deferred) is deferred from 1.0 and must not be advertised")
        }
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

    // MARK: - 1.0 locale narrowing (20 September 2026)

    /// The nine deferred languages must resolve to clean English, not to a
    /// partially translated screen. Before narrowing, es/ja/zh/ko/ru/de/ar were
    /// 64.7% translated and it/pt 13.3%, so those devices rendered a mix.
    func testDeferredLanguagesResolveToEnglishRatherThanPartialTranslation() {
        let deferred = ["es", "ja", "zh", "ko", "ru", "de", "ar", "it", "pt"]
        let sample = LocalizedString(
            en: "Come back to yourself.", fr: "Revenez à vous.", es: "Vuelve a ti.",
            ja: "自分に還る。", zh: "回到你自己。", ko: "나에게로 돌아오세요.",
            ru: "Вернитесь к себе.", de: "Kommen Sie zu sich zurück.",
            ar: "عُد إلى ذاتك.", it: "Torna a te stesso.", pt: "Volte para você.")
        for code in deferred {
            XCTAssertEqual(LocalizedString.preferredLanguage(in: ["\(code)-XX", code]), "en",
                           "\(code) must resolve to en while it is deferred from 1.0")
            XCTAssertFalse(LocalizedString.supportedLanguages.contains(code),
                           "\(code) must not be advertised as supported while deferred")
        }
        // The inline translations are retained for the 1.1 restore, not deleted.
        XCTAssertEqual(sample.value(for: "es"), "Vuelve a ti.")
        XCTAssertEqual(sample.value(for: "ja"), "自分に還る。")
    }

    /// French must keep working, including the Canadian regional code the store uses.
    func testFrenchIncludingCanadianRegionStillResolves() {
        XCTAssertEqual(LocalizedString.preferredLanguage(in: ["fr-CA", "fr"]), "fr")
        XCTAssertEqual(LocalizedString.preferredLanguage(in: ["fr-FR"]), "fr")
        XCTAssertEqual(LocalizedString.supportedLanguages, ["en", "fr"])
    }
}
