import XCTest
import SwiftUI
@testable import BonhommeCore

final class SessionPaletteTests: XCTestCase {

    func testSCIBandsMatchEntropyCutPoints() {
        XCTAssertEqual(SessionPalette.SCIBand.resolve(nil), .apo)
        XCTAssertEqual(SessionPalette.SCIBand.resolve(.nan), .apo)
        XCTAssertEqual(SessionPalette.SCIBand.resolve(0.1), .fail)
        XCTAssertEqual(SessionPalette.SCIBand.resolve(0.29), .fail)
        XCTAssertEqual(SessionPalette.SCIBand.resolve(0.3), .warn)
        XCTAssertEqual(SessionPalette.SCIBand.resolve(0.59), .warn)
        XCTAssertEqual(SessionPalette.SCIBand.resolve(0.6), .signal)
        XCTAssertEqual(SessionPalette.SCIBand.resolve(0.79), .signal)
        XCTAssertEqual(SessionPalette.SCIBand.resolve(0.8), .pass)
        XCTAssertEqual(SessionPalette.SCIBand.resolve(1.4), .pass)
    }

    func testHeartRateBandsFollowTemperatureRamp() {
        XCTAssertEqual(SessionPalette.HeartRateBand.resolve(nil), .apo)
        XCTAssertEqual(SessionPalette.HeartRateBand.resolve(72), .cryo)
        XCTAssertEqual(SessionPalette.HeartRateBand.resolve(110), .cold)
        XCTAssertEqual(SessionPalette.HeartRateBand.resolve(145), .physio)
        XCTAssertEqual(SessionPalette.HeartRateBand.resolve(170), .denature)
    }

    func testSCIColorsBindToBrandTokens() {
        XCTAssertEqual(SessionPalette.sci(nil), BrandColor.magnesium)
        XCTAssertEqual(SessionPalette.sci(0.1), BrandColor.firetruck)
        XCTAssertEqual(SessionPalette.sci(0.45), BrandColor.strawberry)
        XCTAssertEqual(SessionPalette.sci(0.7), BrandColor.violet)
        XCTAssertEqual(SessionPalette.sci(0.9), BrandColor.mint)
        XCTAssertEqual(SessionPalette.sciSignal, BrandColor.violet)
        XCTAssertEqual(SessionPalette.accent, BrandColor.mint)
    }

    func testEntropyColors() {
        XCTAssertEqual(SessionPalette.entropy(.unknown), BrandColor.magnesium)
        XCTAssertEqual(SessionPalette.entropy(.grounding), BrandColor.strawberry)
        XCTAssertEqual(SessionPalette.entropy(.collapsed), BrandColor.firetruck)
        XCTAssertEqual(SessionPalette.entropy(.focused), BrandColor.violet)
        XCTAssertEqual(SessionPalette.entropy(.coherent), BrandColor.mint)
    }

    func testTrendColors() {
        XCTAssertEqual(SessionPalette.trend(.improving), BrandColor.mint)
        XCTAssertEqual(SessionPalette.trend(.stable), BrandColor.magnesium)
        XCTAssertEqual(SessionPalette.trend(.declining), BrandColor.strawberry)
    }

    func testReduceMotionDisablesDecorativeSessionMotion() {
        XCTAssertNil(SessionMotion.animation(reduceMotion: true))
        XCTAssertNotNil(SessionMotion.animation(reduceMotion: false))
        XCTAssertNil(SessionMotion.spring(reduceMotion: true))
        XCTAssertNotNil(SessionMotion.spring(reduceMotion: false))
        XCTAssertTrue(SessionMotion.timelinePaused(true))
        XCTAssertFalse(SessionMotion.timelinePaused(false))
        XCTAssertEqual(SessionMotion.timelineInterval(true), 1.0)
        XCTAssertLessThan(SessionMotion.timelineInterval(false), 0.05)
        XCTAssertEqual(SessionMotion.moveDuration(true), 0)
        XCTAssertEqual(SessionMotion.moveDuration(false), 1.0)
        XCTAssertEqual(SessionSpacing.minTapTarget, 44)
    }
}
