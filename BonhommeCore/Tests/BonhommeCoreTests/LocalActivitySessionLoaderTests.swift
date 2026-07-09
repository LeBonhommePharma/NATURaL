import XCTest
@testable import BonhommeCore

/// Drives the shipped detect → load path for recoverable local activity.
/// Seeds the real `WorkoutStateStore` key/format and calls `LocalActivitySessionLoader`.
final class LocalActivitySessionLoaderTests: XCTestCase {

    private var suiteName: String!
    private var defaults: UserDefaults!
    private var store: WorkoutStateStore!

    override func setUp() {
        super.setUp()
        suiteName = "com.natural.tests.localActivity.\(UUID().uuidString)"
        defaults = UserDefaults(suiteName: suiteName)
        defaults.removePersistentDomain(forName: suiteName)
        store = WorkoutStateStore(defaults: defaults)
    }

    override func tearDown() {
        defaults.removePersistentDomain(forName: suiteName)
        defaults = nil
        store = nil
        suiteName = nil
        super.tearDown()
    }

    // MARK: - Seed activity → detect → loaded session

    func testSeededActiveWorkout_DetectAndLoad_ReturnsMatchingSession() {
        let plan = PoseCatalog.beginnerFlow
        let start = Date().addingTimeInterval(-120)
        store.save(
            planId: plan.id,
            phase: .active(poseIndex: 2),
            poseTimeRemaining: 25,
            elapsedTime: 90,
            sessionStartDate: start,
            currentPoseIndex: 2
        )

        let loader = LocalActivitySessionLoader(store: store)

        // Detect
        XCTAssertTrue(loader.hasRecoverableActivity(), "Seeded active workout must be detected")

        // Load (same entry point the app uses via detectAndLoad / restoreIfAvailable)
        guard let session = loader.detectAndLoad() else {
            return XCTFail("detectAndLoad must return a non-nil session for seeded activity")
        }

        XCTAssertEqual(session.plan.id, plan.id, "Loaded plan must match seeded planId")
        XCTAssertEqual(session.phase, .active(poseIndex: 2))
        XCTAssertEqual(session.poseTimeRemaining, 25, accuracy: 0.001)
        XCTAssertEqual(session.elapsedTime, 90, accuracy: 0.001)
        XCTAssertEqual(session.sessionStartDate.timeIntervalSince1970, start.timeIntervalSince1970, accuracy: 1)
        XCTAssertEqual(session.posesCompletedCount, 2, "Active at index 2 ⇒ 2 poses completed")
        XCTAssertEqual(session.currentPoseIndex, 2)
    }

    func testSeededTransitionWorkout_Load_MapsNextPoseDurationAndCompletedCount() {
        let plan = PoseCatalog.beginnerFlow
        XCTAssertGreaterThan(plan.poses.count, 2, "Catalog plan must have enough poses")

        let nextIdx = 2
        store.save(
            planId: plan.id,
            phase: .transition(nextPoseIndex: nextIdx, secondsRemaining: 3),
            poseTimeRemaining: 0,
            elapsedTime: 60,
            sessionStartDate: Date().addingTimeInterval(-60),
            currentPoseIndex: 1
        )

        let loader = LocalActivitySessionLoader(store: store)
        guard let session = loader.loadIfAvailable() else {
            return XCTFail("transition phase must load")
        }

        XCTAssertEqual(session.phase, .transition(nextPoseIndex: nextIdx, secondsRemaining: 3))
        XCTAssertEqual(session.posesCompletedCount, nextIdx)
        XCTAssertEqual(session.currentPoseIndex, nextIdx - 1)
        XCTAssertEqual(
            session.poseTimeRemaining,
            plan.poses[nextIdx].durationSeconds,
            accuracy: 0.001,
            "Transition restore must set pose time to next pose duration"
        )
    }

    func testSeededCountdownWorkout_Load_ReturnsCountdownPhase() {
        let plan = PoseCatalog.beginnerFlow
        store.save(
            planId: plan.id,
            phase: .countdown(secondsRemaining: 2),
            poseTimeRemaining: 0,
            elapsedTime: 1,
            sessionStartDate: Date(),
            currentPoseIndex: 0
        )

        let session = LocalActivitySessionLoader(store: store).detectAndLoad()
        XCTAssertNotNil(session)
        XCTAssertEqual(session?.phase, .countdown(secondsRemaining: 2))
        XCTAssertEqual(session?.plan.id, plan.id)
        XCTAssertEqual(session?.posesCompletedCount, 0)
    }

    // MARK: - Empty / absent / expired → no load

    func testEmptyStore_NoDetect_NoLoad() {
        let loader = LocalActivitySessionLoader(store: store)
        XCTAssertFalse(loader.hasRecoverableActivity())
        XCTAssertNil(loader.detectAndLoad())
        XCTAssertNil(loader.loadIfAvailable())
    }

    func testAfterClear_NoDetect_NoLoad() {
        let plan = PoseCatalog.beginnerFlow
        store.save(
            planId: plan.id,
            phase: .active(poseIndex: 0),
            poseTimeRemaining: 30,
            elapsedTime: 5,
            sessionStartDate: Date(),
            currentPoseIndex: 0
        )
        XCTAssertTrue(LocalActivitySessionLoader(store: store).hasRecoverableActivity())

        store.clear()

        let loader = LocalActivitySessionLoader(store: store)
        XCTAssertFalse(loader.hasRecoverableActivity())
        XCTAssertNil(loader.detectAndLoad())
    }

    func testExpiredState_NoLoad() {
        let plan = PoseCatalog.beginnerFlow
        let expired = WorkoutStateStore.PersistedWorkoutState(
            planId: plan.id,
            phase: .active(poseIndex: 1),
            poseTimeRemaining: 20,
            elapsedTime: 40,
            sessionStartDate: Date().addingTimeInterval(-8000),
            currentPoseIndex: 1,
            savedAt: Date().addingTimeInterval(-8000) // > 2h
        )
        store.saveState(expired)

        let loader = LocalActivitySessionLoader(store: store)
        XCTAssertFalse(loader.hasRecoverableActivity())
        XCTAssertNil(loader.detectAndLoad())
    }

    func testCompletePhase_NoLoad() {
        let plan = PoseCatalog.beginnerFlow
        store.save(
            planId: plan.id,
            phase: .complete,
            poseTimeRemaining: 0,
            elapsedTime: 300,
            sessionStartDate: Date().addingTimeInterval(-300),
            currentPoseIndex: plan.poseCount - 1
        )

        XCTAssertNil(LocalActivitySessionLoader(store: store).detectAndLoad())
        XCTAssertFalse(LocalActivitySessionLoader(store: store).hasRecoverableActivity())
    }

    func testReadyPhase_NoLoad() {
        let plan = PoseCatalog.beginnerFlow
        store.save(
            planId: plan.id,
            phase: .ready,
            poseTimeRemaining: 0,
            elapsedTime: 0,
            sessionStartDate: Date(),
            currentPoseIndex: 0
        )

        XCTAssertNil(LocalActivitySessionLoader(store: store).detectAndLoad())
    }

    func testUnknownPlanId_NoLoad() {
        store.save(
            planId: "not-a-real-plan-id-\(UUID().uuidString)",
            phase: .active(poseIndex: 0),
            poseTimeRemaining: 10,
            elapsedTime: 10,
            sessionStartDate: Date(),
            currentPoseIndex: 0
        )

        // Detect may still see raw recoverable bytes, but load must fail plan resolution.
        XCTAssertNil(LocalActivitySessionLoader(store: store).detectAndLoad())
    }

    // MARK: - Storage contract used by the app

    func testStorageKey_IsStableAppKey() {
        XCTAssertEqual(WorkoutStateStore.storageKey, "com.natural.activeWorkoutState")
    }

    func testSaveRoundTrip_ThroughSameKey() throws {
        let plan = PoseCatalog.beginnerFlow
        store.save(
            planId: plan.id,
            phase: .cooldown,
            poseTimeRemaining: 0,
            elapsedTime: 200,
            sessionStartDate: Date().addingTimeInterval(-200),
            currentPoseIndex: plan.poseCount - 1
        )

        let raw = try XCTUnwrap(defaults.data(forKey: WorkoutStateStore.storageKey))
        let decoded = try JSONDecoder().decode(WorkoutStateStore.PersistedWorkoutState.self, from: raw)
        XCTAssertEqual(decoded.planId, plan.id)
        XCTAssertEqual(decoded.phase, .cooldown)

        let session = try XCTUnwrap(LocalActivitySessionLoader(store: store).loadIfAvailable())
        XCTAssertEqual(session.phase, .cooldown)
        XCTAssertEqual(session.posesCompletedCount, plan.poseCount)
    }
}
