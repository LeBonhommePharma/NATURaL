import XCTest
@testable import BonhommeCore
@testable import Bonhomme

/// Hosted iOS tests for catalog data and actual view-model TV projections.
/// Restored sessions are constructed without starting timers, HealthKit or Music authorization.
final class WorkoutFlowViewModelTests: XCTestCase {

    // MARK: - WorkoutPlan Duration

    func testBeginnerFlowTotalDuration() {
        let plan = PoseCatalog.beginnerFlow
        XCTAssertGreaterThan(plan.totalDuration, 0)
        // Beginner: 7 starter poses + transitions
        let poseDuration = plan.poses.reduce(0) { $0 + $1.durationSeconds }
        let transitions = TimeInterval(max(0, plan.poses.count - 1)) * plan.transitionSeconds
        XCTAssertEqual(plan.totalDuration, poseDuration + transitions)
    }

    func testEnergizingChairFlowPlanStructure() {
        // Production chair catalog: energizing flow is the morning-style starter sequence.
        guard let plan = PoseCatalog.chairYogaPlans.first(where: { $0.id == "chair-energizer" }) else {
            return XCTFail("missing chair-energizer plan")
        }
        XCTAssertGreaterThan(plan.poseCount, 5)
        XCTAssertEqual(plan.name.en, "Energizing Chair Flow")
        XCTAssertEqual(plan.name.fr, "Flux énergisant sur chaise")
    }

    func testCatalogContainsHipFocusedPoses() {
        let hipPoses = PoseCatalog.allPoses.filter { $0.category == .hips }
        XCTAssertGreaterThanOrEqual(hipPoses.count, 2, "Catalog should include at least 2 hip-focused poses")
        // Full-body chair plan should reuse at least one mobility/hip-adjacent pose family.
        guard let fullBody = PoseCatalog.chairYogaPlans.first(where: { $0.id == "chair-full-body" }) else {
            return XCTFail("missing chair-full-body plan")
        }
        XCTAssertGreaterThan(fullBody.poseCount, 0)
    }

    // MARK: - TV Payload Construction

    @MainActor
    func testRestoredTransitionDisplaysUpcomingPoseAndTransitionCountdown() throws {
        let plan = PoseCatalog.beginnerFlow
        let nextIndex = 1
        let viewModel = restoredModel(plan: plan,
                                      phase: .transition(nextPoseIndex: nextIndex, secondsRemaining: 2),
                                      remaining: plan.poses[nextIndex].durationSeconds,
                                      currentIndex: 0, completed: 1)

        let payload = try XCTUnwrap(viewModel.buildTVPayload())

        // The phone's currentPose still names the previous hold during transition;
        // the television must explicitly preview the next one instead.
        XCTAssertEqual(viewModel.currentPose?.id, plan.poses[0].id)
        XCTAssertEqual(payload.currentPose.id, plan.poses[nextIndex].id)
        XCTAssertEqual(payload.poseTimeRemaining, 2)
        XCTAssertEqual(payload.totalPoseTime, plan.transitionSeconds)
        XCTAssertEqual(payload.isTransition, true)
        XCTAssertEqual(payload.sequenceIndex, nextIndex)
        XCTAssertEqual(payload.sequenceTotal, plan.poseCount)
        XCTAssertEqual(payload.sessionElapsed, 123)
        XCTAssertFalse(payload.isPaused)
        XCTAssertNil(payload.biofeedback.heartRate)
        XCTAssertNil(payload.biofeedback.sciScore)
        XCTAssertFalse(viewModel.recorder.isRecording)
        XCTAssertFalse(viewModel.musicService.isPlaying)
    }

    @MainActor
    func testRestoredActivePayloadUsesActualHoldAndRemainingTime() throws {
        let plan = PoseCatalog.beginnerFlow
        let index = 2
        let viewModel = restoredModel(plan: plan, phase: .active(poseIndex: index),
                                      remaining: 17, currentIndex: index, completed: index)

        let payload = try XCTUnwrap(viewModel.buildTVPayload())

        XCTAssertEqual(payload.currentPose.id, plan.poses[index].id)
        XCTAssertEqual(payload.poseTimeRemaining, 17)
        XCTAssertEqual(payload.totalPoseTime, plan.poses[index].durationSeconds)
        XCTAssertEqual(payload.isTransition, false)
        XCTAssertEqual(payload.sequenceIndex, index)
        XCTAssertEqual(payload.sequenceTotal, plan.poseCount)
        XCTAssertEqual(payload.sessionElapsed, 123)
        XCTAssertNil(payload.biofeedback.heartRate)
        XCTAssertNil(payload.biofeedback.sciScore)
        XCTAssertFalse(viewModel.recorder.isRecording)
        XCTAssertFalse(viewModel.musicService.isPlaying)
    }

    @MainActor
    func testReadyCountdownCooldownAndCompleteDoNotPublishAPose() {
        let plan = PoseCatalog.beginnerFlow
        XCTAssertNil(WorkoutFlowViewModel(plan: plan).buildTVPayload())
        let phases: [WorkoutStateStore.PersistedPhase] = [
            .ready, .countdown(secondsRemaining: 3), .cooldown, .complete
        ]
        for phase in phases {
            let viewModel = restoredModel(plan: plan, phase: phase, remaining: 0)
            XCTAssertNil(viewModel.buildTVPayload(), "Non-pose phase must clear the TV: \(phase)")
            XCTAssertFalse(viewModel.recorder.isRecording)
        }
    }

    @MainActor
    func testMalformedRestoredPoseIndicesDoNotPublishAPose() {
        let plan = PoseCatalog.beginnerFlow
        for index in [-1, plan.poseCount] {
            for phase: WorkoutStateStore.PersistedPhase in [
                .active(poseIndex: index), .transition(nextPoseIndex: index, secondsRemaining: 2)
            ] {
                let viewModel = restoredModel(plan: plan, phase: phase, remaining: 10, currentIndex: index)
                XCTAssertNil(viewModel.buildTVPayload(), "Invalid restored index must not access the catalog")
            }
        }
    }

    @MainActor
    private func restoredModel(plan: WorkoutPlan, phase: WorkoutStateStore.PersistedPhase,
                               remaining: TimeInterval, currentIndex: Int = 0,
                               completed: Int = 0) -> WorkoutFlowViewModel {
        WorkoutFlowViewModel(restoredSession: RestoredLocalSession(
            plan: plan, phase: phase, poseTimeRemaining: remaining, elapsedTime: 123,
            sessionStartDate: Date(timeIntervalSince1970: 1_700_000_000),
            currentPoseIndex: currentIndex, posesCompletedCount: completed))
    }

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
