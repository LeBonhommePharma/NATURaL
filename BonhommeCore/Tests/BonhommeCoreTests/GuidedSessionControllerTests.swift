import XCTest
@testable import BonhommeCore

@MainActor
final class GuidedSessionControllerTests: XCTestCase {

    func testStartPauseResumeStopReset() {
        let controller = GuidedSessionController(plan: PoseCatalog.beginnerFlow)
        XCTAssertEqual(controller.phase, .ready)
        XCTAssertFalse(controller.isPaused)
        XCTAssertEqual(controller.hudMetrics.poseCount, PoseCatalog.beginnerFlow.poseCount)

        controller.start()
        guard case .active(let idx) = controller.phase else {
            return XCTFail("expected active pose after start, got \(controller.phase)")
        }
        XCTAssertEqual(idx, 0)
        XCTAssertGreaterThan(controller.poseTimeRemaining, 0)

        controller.pause()
        XCTAssertTrue(controller.isPaused)
        XCTAssertTrue(controller.hudMetrics.isPaused)

        controller.resume()
        XCTAssertFalse(controller.isPaused)

        controller.stop()
        XCTAssertEqual(controller.phase, .complete)
        XCTAssertFalse(controller.isPaused)

        controller.reset()
        XCTAssertEqual(controller.phase, .ready)
        XCTAssertEqual(controller.elapsedTime, 0, accuracy: 0.001)
        XCTAssertEqual(controller.posesCompletedCount, 0)
    }

    func testStartIsIdempotentWhileActive() {
        let controller = GuidedSessionController(plan: PoseCatalog.beginnerFlow)
        controller.start()
        controller.pause()
        controller.start()
        XCTAssertTrue(controller.isPaused, "start() must not restart a live session")
        guard case .active = controller.phase else {
            return XCTFail("phase should remain active")
        }
    }

    func testEarlyEndIsDistinctFromCompletionAndResetClearsIt() {
        let controller = GuidedSessionController(plan: PoseCatalog.beginnerFlow)
        controller.start()
        controller.stop()
        XCTAssertTrue(controller.endedEarly)
        XCTAssertEqual(controller.posesCompletedCount, 0)
        controller.stop()
        XCTAssertTrue(controller.endedEarly, "Repeated stop preserves the outcome")
        controller.reset()
        XCTAssertFalse(controller.endedEarly)
    }

    func testStopBeforeStartDoesNotInventCompletion() {
        let controller = GuidedSessionController(plan: PoseCatalog.beginnerFlow)
        controller.stop()
        XCTAssertEqual(controller.phase, .ready)
        XCTAssertFalse(controller.endedEarly)
        XCTAssertNil(controller.upcomingPose)
    }

    func testTransitionPreviewsNextPoseRatherThanFinishedPose() async {
        let original = PoseCatalog.beginnerFlow.poses[0]
        let immediate = Pose(
            id: "immediate", name: original.name, description: original.description,
            durationSeconds: 0, difficulty: original.difficulty, category: original.category,
            imageName: original.imageName, voiceCueText: original.voiceCueText,
            modifications: original.modifications
        )
        let next = PoseCatalog.beginnerFlow.poses[1]
        let plan = WorkoutPlan(id: "transition-test", name: original.name,
                               description: original.description, poses: [immediate, next])
        let controller = GuidedSessionController(plan: plan)
        defer { controller.reset() }
        controller.start()
        for _ in 0..<100 {
            if controller.upcomingPose != nil { break }
            await Task.yield()
        }
        XCTAssertEqual(controller.upcomingPose?.id, next.id)
        XCTAssertEqual(controller.posesCompletedCount, 1)
    }

    func testHUDUsesPlanTempo() {
        let plan = PoseCatalog.beginnerFlow
        let controller = GuidedSessionController(plan: plan)
        XCTAssertEqual(controller.hudMetrics.tempoBPM, plan.style.nominalBPM)
        XCTAssertEqual(controller.hudMetrics.sciPercentText, "—")
    }
}
