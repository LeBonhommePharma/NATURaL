import XCTest
@testable import BonhommeCore

final class HealthSignalTests: XCTestCase {

    // MARK: - HRVSignal

    func testHRVSignalCodableRoundtrip() throws {
        let signal = HRVSignal(
            timestamp: Date(timeIntervalSince1970: 1000),
            sdnn: 45.2,
            rmssd: 38.7,
            rrIntervals: [810, 820, 790, 830, 815]
        )

        let data = try JSONEncoder().encode(signal)
        let decoded = try JSONDecoder().decode(HRVSignal.self, from: data)

        XCTAssertEqual(decoded.sdnn, 45.2)
        XCTAssertEqual(decoded.rmssd, 38.7)
        XCTAssertEqual(decoded.rrIntervals.count, 5)
        XCTAssertEqual(HRVSignal.signalType, .heartRateVariability)
    }

    // MARK: - MedicationSignal

    func testMedicationSignalCodableRoundtrip() throws {
        let signal = MedicationSignal(
            timestamp: Date(timeIntervalSince1970: 2000),
            medicationId: "rx-12345",
            name: LocalizedString(en: "Ibuprofen", fr: "Ibuprofène"),
            doseValue: 400,
            doseUnit: "mg",
            event: .taken
        )

        let data = try JSONEncoder().encode(signal)
        let decoded = try JSONDecoder().decode(MedicationSignal.self, from: data)

        XCTAssertEqual(decoded.medicationId, "rx-12345")
        XCTAssertEqual(decoded.doseValue, 400)
        XCTAssertEqual(decoded.doseUnit, "mg")
        XCTAssertEqual(decoded.event, .taken)
        XCTAssertEqual(MedicationSignal.signalType, .medication)
    }

    func testMedicationEventAllCases() throws {
        for event in [MedicationEvent.taken, .missed, .skipped, .late] {
            let signal = MedicationSignal(
                timestamp: Date(),
                medicationId: "test",
                name: LocalizedString(en: "Test", fr: "Test"),
                doseValue: 1,
                doseUnit: "tab",
                event: event
            )
            let data = try JSONEncoder().encode(signal)
            let decoded = try JSONDecoder().decode(MedicationSignal.self, from: data)
            XCTAssertEqual(decoded.event, event)
        }
    }

    // MARK: - SurveySignal

    func testSurveySignalCodableRoundtrip() throws {
        let signal = SurveySignal(
            timestamp: Date(timeIntervalSince1970: 3000),
            instrumentId: "pain-vas",
            normalizedScore: 0.75,
            responses: ["pain_score": "2.5"]
        )

        let data = try JSONEncoder().encode(signal)
        let decoded = try JSONDecoder().decode(SurveySignal.self, from: data)

        XCTAssertEqual(decoded.instrumentId, "pain-vas")
        XCTAssertEqual(decoded.normalizedScore, 0.75)
        XCTAssertEqual(decoded.responses["pain_score"], "2.5")
        XCTAssertEqual(SurveySignal.signalType, .survey)
    }
}
