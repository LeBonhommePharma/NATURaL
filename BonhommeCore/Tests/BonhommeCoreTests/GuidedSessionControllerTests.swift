import XCTest
@testable import BonhommeCore

@MainActor
final class GuidedSessionControllerTests: XCTestCase {
    private final class TestClock {
        var now: TimeInterval = 0
    }

    private func plan(durations: [TimeInterval], transition: TimeInterval = 0) -> WorkoutPlan {
        let original = PoseCatalog.beginnerFlow.poses[0]
        let poses = durations.enumerated().map { index, duration in
            Pose(id: "test-\(index)", name: original.name, description: original.description,
                 durationSeconds: duration, difficulty: original.difficulty, category: original.category,
                 imageName: original.imageName, voiceCueText: original.voiceCueText,
                 modifications: original.modifications)
        }
        return WorkoutPlan(id: "clock-test", name: original.name, description: original.description,
                           poses: poses, transitionSeconds: transition)
    }

    private func controller(_ plan: WorkoutPlan, clock: TestClock) -> GuidedSessionController {
        GuidedSessionController(plan: plan, clock: { clock.now }, automaticallyTicks: false)
    }

    func testIrregularCallbacksConsumeActualTimeAndPauseExcludesGap() {
        let clock = TestClock()
        let session = controller(plan(durations: [10]), clock: clock)
        session.start()
        clock.now = 1.7
        session.tick()
        XCTAssertEqual(session.elapsedTime, 1.7, accuracy: 0.0001)
        XCTAssertEqual(session.poseTimeRemaining, 8.3, accuracy: 0.0001)
        clock.now = 2.1
        session.pause()
        XCTAssertEqual(session.elapsedTime, 2.1, accuracy: 0.0001)
        clock.now = 1002.1
        session.tick()
        XCTAssertEqual(session.elapsedTime, 2.1, accuracy: 0.0001)
        session.resume()
        clock.now += 0.6
        session.tick()
        XCTAssertEqual(session.elapsedTime, 2.7, accuracy: 0.0001)
        XCTAssertEqual(session.poseTimeRemaining, 7.3, accuracy: 0.0001)
    }

    func testLongSuspensionPausesWithoutCompletingUnseenPoses() {
        let clock = TestClock()
        let session = controller(plan(durations: [5, 5]), clock: clock)
        session.start()
        clock.now = 1
        session.tick()
        clock.now += 3600
        session.tick()
        XCTAssertTrue(session.isPaused)
        XCTAssertTrue(session.pausedForSuspension)
        XCTAssertEqual(session.phase, .active(poseIndex: 0))
        XCTAssertEqual(session.elapsedTime, 1)
        XCTAssertEqual(session.poseTimeRemaining, 4)
        XCTAssertEqual(session.posesCompletedCount, 0)
        session.resume()
        clock.now += 1
        session.tick()
        XCTAssertFalse(session.pausedForSuspension)
        XCTAssertEqual(session.elapsedTime, 2)
        XCTAssertEqual(session.poseTimeRemaining, 3)
    }

    func testFractionalTransitionAndNaturalCompletionKeepExactElapsed() {
        let clock = TestClock()
        let session = controller(plan(durations: [1, 1], transition: 0.5), clock: clock)
        session.start()
        clock.now = 1
        session.tick()
        XCTAssertEqual(session.phase, .transition(nextPoseIndex: 1, secondsRemaining: 1))
        XCTAssertEqual(session.upcomingPose?.id, "test-1")
        XCTAssertEqual(session.currentPose?.id, "test-0")
        XCTAssertEqual(session.posesCompletedCount, 1)
        clock.now = 1.5
        session.tick()
        XCTAssertNil(session.upcomingPose)
        XCTAssertEqual(session.phase, .active(poseIndex: 1))
        clock.now = 2.8
        session.tick()
        XCTAssertEqual(session.phase, .complete)
        XCTAssertFalse(session.endedEarly)
        XCTAssertEqual(session.posesCompletedCount, 2)
        XCTAssertEqual(session.currentPoseIndex, 1)
        XCTAssertEqual(session.elapsedTime, 2.5)
    }

    func testTransitionPausePreservesFractionAndSuspensionDoesNotAdvanceIt() {
        let clock = TestClock()
        let session = controller(plan(durations: [1, 10], transition: 2.5), clock: clock)
        session.start()
        clock.now = 1.4
        session.pause()
        XCTAssertEqual(session.phase, .transition(nextPoseIndex: 1, secondsRemaining: 3))
        clock.now = 100
        session.resume()
        clock.now += 0.6
        session.tick()
        XCTAssertEqual(session.phase, .transition(nextPoseIndex: 1, secondsRemaining: 2))
        XCTAssertEqual(session.elapsedTime, 2, accuracy: 0.0001)
        clock.now += 100
        session.tick()
        XCTAssertTrue(session.pausedForSuspension)
        XCTAssertEqual(session.phase, .transition(nextPoseIndex: 1, secondsRemaining: 2))
        XCTAssertEqual(session.posesCompletedCount, 1)
    }

    func testZeroTransitionsAndDurationsDoNotAddPhantomSeconds() {
        let clock = TestClock()
        let session = controller(plan(durations: [0, 0, 1], transition: 0), clock: clock)
        session.start()
        XCTAssertEqual(session.phase, .active(poseIndex: 2))
        XCTAssertEqual(session.posesCompletedCount, 2)
        XCTAssertEqual(session.elapsedTime, 0)
        clock.now = 1
        session.tick()
        XCTAssertEqual(session.phase, .complete)
        XCTAssertEqual(session.elapsedTime, 1)
    }

    func testOneDelayedTickCarriesFractionAcrossPoseAndTransition() {
        let clock = TestClock()
        let session = controller(plan(durations: [1, 3], transition: 0.5), clock: clock)
        session.start()
        clock.now = 2.5
        session.tick()
        XCTAssertEqual(session.phase, .active(poseIndex: 1))
        XCTAssertEqual(session.posesCompletedCount, 1)
        XCTAssertEqual(session.elapsedTime, 2.5)
        XCTAssertEqual(session.poseTimeRemaining, 2)
    }

    func testClockDiscontinuityPausesWithoutNegativeElapsed() {
        let clock = TestClock()
        let session = controller(plan(durations: [10]), clock: clock)
        session.start()
        clock.now = -1
        session.tick()
        XCTAssertTrue(session.pausedForSuspension)
        XCTAssertEqual(session.elapsedTime, 0)
        XCTAssertEqual(session.poseTimeRemaining, 10)
    }

    func testEarlyStopConsumesOnlyTimeBeforeStopAndCannotRestartTimer() {
        let clock = TestClock()
        let session = controller(plan(durations: [10]), clock: clock)
        session.start()
        clock.now = 0.3
        session.stop()
        XCTAssertTrue(session.endedEarly)
        XCTAssertEqual(session.elapsedTime, 0.3)
        XCTAssertEqual(session.posesCompletedCount, 0)
        clock.now = 100
        session.resume()
        session.tick()
        XCTAssertEqual(session.elapsedTime, 0.3)
        session.reset()
        XCTAssertFalse(session.endedEarly)
        XCTAssertFalse(session.pausedForSuspension)
    }

    func testEmptyPlanCompletesWithoutStartingATimer() {
        let clock = TestClock()
        let session = controller(plan(durations: []), clock: clock)
        session.start()
        XCTAssertEqual(session.phase, .complete)
        XCTAssertFalse(session.endedEarly)
        XCTAssertEqual(session.elapsedTime, 0)
    }

    func testTimerDoesNotRetainControllerWhileSleeping() async {
        let clock = TestClock()
        var session: GuidedSessionController? = GuidedSessionController(
            plan: plan(durations: [10]), clock: { clock.now }, automaticallyTicks: true)
        weak var weakSession = session
        session?.start()
        await Task.yield()
        session = nil
        XCTAssertNil(weakSession)
    }

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
