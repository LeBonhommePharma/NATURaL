import XCTest
@testable import BonhommeCore

final class WorkoutPlanTests: XCTestCase {

    func testWorkoutPlanInitialization() {
        let plan = makeTestPlan()
        XCTAssertEqual(plan.id, "test-plan")
        XCTAssertEqual(plan.name.en, "Test Plan")
        XCTAssertEqual(plan.name.fr, "Plan test")
        XCTAssertEqual(plan.poseCount, 2)
        XCTAssertFalse(plan.isFree)
    }

    func testPoseCount() {
        let plan = makeTestPlan()
        XCTAssertEqual(plan.poseCount, plan.poses.count)
    }

    func testTotalDurationWithTransitions() {
        let plan = makeTestPlan(transitionSeconds: 5)
        // 2 poses of 30s each = 60s, plus 1 transition of 5s = 65s
        XCTAssertEqual(plan.totalDuration, 65)
    }

    func testTotalDurationSinglePose() {
        let pose = makePose(duration: 45)
        let plan = WorkoutPlan(
            id: "single",
            name: LocalizedString(en: "Single", fr: "Seul"),
            description: LocalizedString(en: "One pose", fr: "Une posture"),
            poses: [pose],
            transitionSeconds: 10
        )
        // Single pose = no transitions
        XCTAssertEqual(plan.totalDuration, 45)
    }

    func testTotalDurationEmptyPlan() {
        let plan = WorkoutPlan(
            id: "empty",
            name: LocalizedString(en: "Empty", fr: "Vide"),
            description: LocalizedString(en: "No poses", fr: "Pas de postures"),
            poses: [],
            transitionSeconds: 5
        )
        XCTAssertEqual(plan.totalDuration, 0)
        XCTAssertEqual(plan.poseCount, 0)
    }

    func testWorkoutPlanCodable() throws {
        let original = makeTestPlan()
        let data = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(WorkoutPlan.self, from: data)
        XCTAssertEqual(decoded.id, original.id)
        XCTAssertEqual(decoded.name, original.name)
        XCTAssertEqual(decoded.poseCount, original.poseCount)
        XCTAssertEqual(decoded.transitionSeconds, original.transitionSeconds)
        XCTAssertEqual(decoded.isFree, original.isFree)
    }

    // MARK: - Helpers

    private func makePose(duration: TimeInterval = 30) -> Pose {
        Pose(
            id: "pose-\(UUID().uuidString.prefix(4))",
            name: LocalizedString(en: "Pose", fr: "Posture"),
            description: LocalizedString(en: "Desc", fr: "Desc"),
            durationSeconds: duration,
            difficulty: .beginner,
            category: .spine,
            imageName: "pose.test",
            voiceCueText: LocalizedString(en: "Cue", fr: "Indice"),
            modifications: LocalizedStringArray(en: ["Mod"], fr: ["Mod"]),
            isFree: false
        )
    }

    private func makeTestPlan(transitionSeconds: TimeInterval = 5) -> WorkoutPlan {
        WorkoutPlan(
            id: "test-plan",
            name: LocalizedString(en: "Test Plan", fr: "Plan test"),
            description: LocalizedString(en: "A test plan", fr: "Un plan test"),
            poses: [makePose(), makePose()],
            transitionSeconds: transitionSeconds,
            isFree: false
        )
    }
}
