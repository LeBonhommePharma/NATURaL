import XCTest
@testable import BonhommeCore

final class RRIntervalProxyTests: XCTestCase {

    func testRawConstantBPMIsMeaninglessForSCI() {
        let constant = Array(repeating: 72.0, count: 10)
        let raw = RRIntervalProxy.rawProxyRR(fromBPMSamples: constant)
        XCTAssertTrue(RRIntervalProxy.isMeaninglessForSCI(raw),
                      "Pure 60000/bpm from constant HR has zero variance → meaningless SCI")
    }

    func testSyntheticJitterMakesConstantBPMUsable() {
        let constant = Array(repeating: 72.0, count: 10)
        let synthetic = RRIntervalProxy.syntheticRR(fromBPMSamples: constant)
        XCTAssertEqual(synthetic.count, 10)
        XCTAssertFalse(RRIntervalProxy.isMeaninglessForSCI(synthetic),
                       "Light physiological jitter must unstick SCI from pure-constant RR")
        // Mean stays near 60000/72
        let mean = synthetic.reduce(0, +) / Double(synthetic.count)
        XCTAssertEqual(mean, 60000.0 / 72.0, accuracy: 50)
    }

    func testSyntheticIsDeterministic() {
        let bpms = [70.0, 72.0, 74.0, 71.0, 73.0, 72.0]
        let a = RRIntervalProxy.syntheticRR(fromBPMSamples: bpms)
        let b = RRIntervalProxy.syntheticRR(fromBPMSamples: bpms)
        XCTAssertEqual(a, b)
    }

    func testRmssdAndSDNNNonNegative() {
        let rr = RRIntervalProxy.syntheticRR(fromBPMSamples: [68, 70, 72, 74, 71, 69])
        XCTAssertGreaterThan(RRIntervalProxy.standardDeviation(rr), 0)
        XCTAssertGreaterThan(RRIntervalProxy.rmssd(rr), 0)
    }

    func testTooFewSamplesMeaningless() {
        XCTAssertTrue(RRIntervalProxy.isMeaninglessForSCI([800, 810, 820]))
        XCTAssertTrue(RRIntervalProxy.isMeaninglessForSCI([]))
    }
}
