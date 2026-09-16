import XCTest
@testable import BonhommeCore

final class SessionHUDMetricsTests: XCTestCase {

    func testEntropyGroundingWinsOverHighSCI() {
        let state = SessionEntropyState.resolve(sciScore: 0.95, isGrounding: true)
        XCTAssertEqual(state, .grounding)
    }

    func testEntropyBandsFromSCI() {
        XCTAssertEqual(SessionEntropyState.resolve(sciScore: nil, isGrounding: false), .unknown)
        XCTAssertEqual(SessionEntropyState.resolve(sciScore: 0.1, isGrounding: false), .collapsed)
        XCTAssertEqual(SessionEntropyState.resolve(sciScore: 0.45, isGrounding: false), .settling)
        XCTAssertEqual(SessionEntropyState.resolve(sciScore: 0.7, isGrounding: false), .focused)
        XCTAssertEqual(SessionEntropyState.resolve(sciScore: 0.9, isGrounding: false), .coherent)
    }

    func testFormattingClampsAndPlaceholders() {
        let empty = SessionHUDMetrics()
        XCTAssertEqual(empty.sciPercentText, "—")
        XCTAssertEqual(empty.heartRateText, "—")
        XCTAssertEqual(empty.poseProgressText, "—")
        XCTAssertEqual(empty.elapsedText, "0:00")

        let live = SessionHUDMetrics(
            sciScore: 0.724,
            heartRate: 68.4,
            elapsed: 125,
            poseIndex: 2,
            poseCount: 7
        )
        XCTAssertEqual(live.sciPercentText, "72")
        XCTAssertEqual(live.heartRateText, "68")
        XCTAssertEqual(live.elapsedText, "2:05")
        XCTAssertEqual(live.poseProgressText, "3/7")
        XCTAssertEqual(live.poseProgressFraction, 3.0 / 7.0, accuracy: 0.0001)
    }

    func testCountdownFormatting() {
        XCTAssertEqual(SessionHUDMetrics.formatCountdown(9), "9")
        XCTAssertEqual(SessionHUDMetrics.formatCountdown(75), "1:15")
        XCTAssertEqual(SessionHUDMetrics.formatCountdown(-1), "0")
    }

    func testBiofeedbackMapsIntoHUD() {
        let snap = BiofeedbackSnapshot(heartRate: 72, sciScore: 0.8, sciTrend: .improving, activeCalories: 12)
        let hud = snap.hudMetrics(
            elapsed: 30,
            poseIndex: 0,
            poseCount: 5,
            tempoBPM: 92,
            isGrounding: false
        )
        XCTAssertEqual(hud.sciScore, 0.8)
        XCTAssertEqual(hud.sciTrend, .improving)
        XCTAssertEqual(hud.heartRate, 72)
        XCTAssertEqual(hud.tempoBPM, 92)
        XCTAssertEqual(hud.entropyState, .coherent)
        XCTAssertEqual(hud.calories, 12)
    }

    func testNonFiniteSCITreatedAsUnknown() {
        XCTAssertEqual(SessionEntropyState.resolve(sciScore: .nan, isGrounding: false), .unknown)
        XCTAssertEqual(SessionEntropyState.resolve(sciScore: .infinity, isGrounding: false), .unknown)
    }
}
