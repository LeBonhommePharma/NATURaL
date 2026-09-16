import XCTest
@testable import BonhommeCore

final class SCIExplanationCopyTests: XCTestCase {

    func testTechnicalUnavailable() {
        let copy = SCIExplanationCopy.technical(score: nil, trend: .stable)
        XCTAssertTrue(copy.en.contains("waiting") || copy.en.contains("HRV"))
        XCTAssertFalse(copy.en.isEmpty)
        XCTAssertFalse(copy.fr.isEmpty)
    }

    func testPlainLanguageBandsAreDeterministic() {
        let low = SCIExplanationCopy.plainLanguage(score: 0.12, trend: .declining)
        XCTAssertTrue(low.en.contains("12%"))
        XCTAssertTrue(low.en.lowercased().contains("low") || low.en.lowercased().contains("soften"))

        let high = SCIExplanationCopy.plainLanguage(score: 0.91, trend: .improving)
        XCTAssertTrue(high.en.contains("91%"))
        XCTAssertTrue(high.en.lowercased().contains("high") || high.en.lowercased().contains("unhurried"))

        let nan = SCIExplanationCopy.plainLanguage(score: .nan, trend: .stable)
        XCTAssertTrue(nan.en.lowercased().contains("not") || nan.en.lowercased().contains("yet"))
    }

    func testTechnicalIncludesPercentAndTrend() {
        let copy = SCIExplanationCopy.technical(score: 0.72, trend: .improving)
        XCTAssertTrue(copy.en.contains("72%"))
        XCTAssertTrue(copy.en.lowercased().contains("improving"))
        XCTAssertTrue(copy.en.contains("Shannon") || copy.en.contains("entropy") || copy.en.contains("SCI"))
    }
}
