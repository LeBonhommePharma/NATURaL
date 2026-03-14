import HealthKit
import BonhommeCore

/// Manages the HKWorkoutSession + HKLiveWorkoutBuilder lifecycle for recording
/// chair yoga sessions to HealthKit.
@MainActor
final class WorkoutRecorder: NSObject, ObservableObject {
    @Published var isRecording = false
    @Published var currentHeartRate: Double?
    @Published var activeCalories: Double = 0
    @Published var averageHeartRate: Double?
    @Published var heartRateSamples: [HeartRateSample] = []

    private let healthStore = HKHealthStore()
    private var session: HKWorkoutSession?
    private var builder: HKLiveWorkoutBuilder?

    func start() async throws {
        let config = HKWorkoutConfiguration()
        config.activityType = .yoga
        config.locationType = .indoor

        session = try HKWorkoutSession(healthStore: healthStore, configuration: config)
        session?.delegate = self

        builder = session?.associatedWorkoutBuilder()
        builder?.delegate = self
        builder?.dataSource = HKLiveWorkoutDataSource(
            healthStore: healthStore,
            workoutConfiguration: config
        )

        session?.startActivity(with: Date())
        try await builder?.beginCollection(at: Date())
        isRecording = true
    }

    func pause() {
        session?.pause()
    }

    func resume() {
        session?.resume()
    }

    /// Ends the workout using the correct ordering:
    /// 1. session.end()  2. builder.endCollection()  3. builder.finishWorkout()
    func end() async throws {
        session?.end()
        try await builder?.endCollection(at: Date())
        _ = try await builder?.finishWorkout()
        isRecording = false
    }
}

extension WorkoutRecorder: HKWorkoutSessionDelegate {
    nonisolated func workoutSession(
        _ workoutSession: HKWorkoutSession,
        didChangeTo toState: HKWorkoutSessionState,
        from fromState: HKWorkoutSessionState,
        date: Date
    ) {
        // State changes handled by published properties
    }

    nonisolated func workoutSession(
        _ workoutSession: HKWorkoutSession,
        didFailWithError error: Error
    ) {
        // Log error; in production, surface to UI
    }
}

extension WorkoutRecorder: HKLiveWorkoutBuilderDelegate {
    nonisolated func workoutBuilder(
        _ workoutBuilder: HKLiveWorkoutBuilder,
        didCollectDataOf collectedTypes: Set<HKSampleType>
    ) {
        Task { @MainActor in
            for type in collectedTypes {
                guard let quantityType = type as? HKQuantityType else { continue }

                if quantityType == HKQuantityType(.heartRate) {
                    let stats = workoutBuilder.statistics(for: quantityType)
                    if let bpm = stats?.mostRecentQuantity()?
                        .doubleValue(for: .count().unitDivided(by: .minute())) {
                        currentHeartRate = bpm
                        heartRateSamples.append(HeartRateSample(bpm: bpm, timestamp: Date()))
                    }
                    if let avg = stats?.averageQuantity()?
                        .doubleValue(for: .count().unitDivided(by: .minute())) {
                        averageHeartRate = avg
                    }
                }

                if quantityType == HKQuantityType(.activeEnergyBurned) {
                    let stats = workoutBuilder.statistics(for: quantityType)
                    if let cal = stats?.sumQuantity()?
                        .doubleValue(for: .kilocalorie()) {
                        activeCalories = cal
                    }
                }
            }
        }
    }

    nonisolated func workoutBuilderDidCollectEvent(
        _ workoutBuilder: HKLiveWorkoutBuilder
    ) {
        // Handle workout events if needed
    }
}
