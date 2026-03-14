import XCTest
@testable import BonhommeCore

/// Tests for WorkoutFlowViewModel state machine logic.
/// Run on iOS Simulator: Xcode > Product > Test (Cmd+U)
/// Target: iPhone 15 Pro Simulator (iOS 17+)
final class WorkoutFlowViewModelTests: XCTestCase {

    // MARK: - WorkoutPlan Duration

    func testBeginnerFlowTotalDuration() {
        let plan = PoseCatalog.beginnerFlow
        XCTAssertGreaterThan(plan.totalDuration, 0)
        // Beginner: 7 free poses + transitions
        let poseDuration = plan.poses.reduce(0) { $0 + $1.durationSeconds }
        let transitions = TimeInterval(max(0, plan.poses.count - 1)) * plan.transitionSeconds
        XCTAssertEqual(plan.totalDuration, poseDuration + transitions)
    }

    func testMorningWakeUpPlanStructure() {
        let plan = PoseCatalog.morningWakeUp
        XCTAssertFalse(plan.isFree)
        XCTAssertGreaterThan(plan.poseCount, 5)
        XCTAssertEqual(plan.name.en, "Morning Wake-Up Flow")
        XCTAssertEqual(plan.name.fr, "Enchaînement réveil matinal")
    }

    func testHipOpenerPlanContainsHipPoses() {
        let plan = PoseCatalog.hipOpener
        let hipPoses = plan.poses.filter { $0.category == .hips }
        XCTAssertGreaterThanOrEqual(hipPoses.count, 2, "Hip opener should have at least 2 hip-focused poses")
    }

    // MARK: - TV Payload Construction

    func testTVPayloadEncoding() throws {
        let pose = PoseCatalog.seatedMountain
        let bio = BiofeedbackSnapshot(heartRate: 75, sciScore: 0.8, sciTrend: .improving, activeCalories: 20)
        let payload = TVDisplayPayload(
            currentPose: pose,
            poseTimeRemaining: 20,
            totalPoseTime: 30,
            biofeedback: bio,
            sessionElapsed: 60,
            isPaused: false,
            sequenceIndex: 0,
            sequenceTotal: 7
        )

        let data = try JSONEncoder().encode(payload)
        XCTAssertGreaterThan(data.count, 0)

        let decoded = try JSONDecoder().decode(TVDisplayPayload.self, from: data)
        XCTAssertEqual(decoded.currentPose.id, "seated-mountain")
        XCTAssertEqual(decoded.biofeedback.heartRate, 75)
    }

    // MARK: - Localization Consistency

    func testAllPoseNamesHaveFrenchTranslation() {
        for pose in PoseCatalog.allPoses {
            XCTAssertFalse(pose.name.fr.isEmpty, "\(pose.id) missing French name")
            // French names should not equal English (they should be translated)
            XCTAssertNotEqual(pose.name.en, pose.name.fr,
                              "\(pose.id) has identical EN/FR names — likely untranslated")
        }
    }

    func testAllPlanDescriptionsTranslated() {
        for plan in PoseCatalog.allPlans {
            XCTAssertNotEqual(plan.description.en, plan.description.fr,
                              "\(plan.id) has identical EN/FR descriptions")
        }
    }
}
