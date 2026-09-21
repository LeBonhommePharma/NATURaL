import XCTest
@testable import BonhommeCore

/// Pins the grounding-line timestamp format.
///
/// The shared `ISO8601DateFormatter` was replaced with `Date.ISO8601Format()`
/// to clear a Swift 6 concurrency diagnostic. That is only a safe swap if the
/// rendered string is unchanged — a log format that silently shifts is a
/// behaviour change, and nothing else in this package reads these lines back.
final class ActuatorBusTimestampTests: XCTestCase {

    /// The replacement must match the formatter it replaced, exactly.
    func testTimestampMatchesTheFormatterItReplaced() {
        let legacy = ISO8601DateFormatter()
        legacy.formatOptions = [.withInternetDateTime]
        for i in 0..<2000 {
            let date = Date(timeIntervalSince1970: 1_600_000_000 + Double(i) * 1234.567)
            XCTAssertEqual(
                SessionLogActuatorChannel.timestamp(date), legacy.string(from: date),
                "timestamp drifted from the ISO8601DateFormatter output it replaced")
        }
    }

    /// Shape, so a future change to a different-but-also-self-consistent
    /// format cannot pass by replacing both sides at once.
    func testTimestampIsInternetDateTimeUTC() {
        let stamp = SessionLogActuatorChannel.timestamp(Date(timeIntervalSince1970: 1_600_000_000))
        XCTAssertEqual(stamp, "2020-09-13T12:26:40Z")
        XCTAssertEqual(stamp.count, 20)
        XCTAssertTrue(stamp.hasSuffix("Z"), "grounding timestamps must be UTC")
    }

    /// The grounding line still carries the stamp where it did.
    func testGroundingLineCarriesTheTimestamp() async {
        let channel = SessionLogActuatorChannel(log: SessionEventLog())
        let result = await channel.execute(.grounding(sigmaIrr: 0.01, bpm: 90, beta: 0.5))
        XCTAssertTrue(result.success)
        XCTAssertTrue(result.detail.contains("t="), "grounding line lost its timestamp")
        let stamp = result.detail.components(separatedBy: "t=").last ?? ""
        XCTAssertTrue(stamp.hasSuffix("Z") && stamp.count == 20,
                      "grounding timestamp is not an internet-date-time UTC stamp: \(stamp)")
    }
}
