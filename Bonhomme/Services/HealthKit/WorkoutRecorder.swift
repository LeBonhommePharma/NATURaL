import HealthKit
import BonhommeCore

/// Manages HealthKit workout recording and live HR → SCI ingest for iOS sessions.
///
/// **Dual path (Apple API reality):**
/// - **iOS 26+**: `HKWorkoutSession` + `HKLiveWorkoutBuilder` (primary local sessions).
/// - **iOS 17–25**: `HKWorkoutBuilder` + anchored HR query — `init(healthStore:configuration:)`
///   and `associatedWorkoutBuilder()` are only available on iOS 26+; the session class itself
///   exists from iOS 17 for mirrored Watch workouts.
///
/// HR samples synthesize RR windows and invoke `onHRVIngest` so the session
/// `FeedbackEngine` receives the same SCI path as Watch (`processHeartRateForSCI`).
@MainActor
final class WorkoutRecorder: NSObject, ObservableObject {
    @Published var isRecording = false
    @Published var currentHeartRate: Double?
    @Published var activeCalories: Double = 0
    @Published var averageHeartRate: Double?
    @Published var heartRateSamples: [HeartRateSample] = []

    /// Ring-buffer cap (~1 hour at 1 Hz). Prevents unbounded growth during long sessions.
    static let maxHeartRateSamples = 3600

    /// SCI ingest callback: (sdnn, rmssd, rrIntervalsMs). Wired by `WorkoutFlowViewModel`.
    var onHRVIngest: ((Double, Double, [Double]) -> Void)?

    private let healthStore = HKHealthStore()
    private var session: AnyObject?
    private var builder: AnyObject?
    private var heartRateQuery: HKAnchoredObjectQuery?
    private var energyQuery: HKAnchoredObjectQuery?
    private var usesLiveSession = false

    func start(style: YogaStyle = .chairYoga) async throws {
        heartRateSamples.removeAll(keepingCapacity: true)
        currentHeartRate = nil
        averageHeartRate = nil
        activeCalories = 0

        if #available(iOS 26.0, *) {
            try await startLiveSession(style: style)
        } else {
            try await startBuilderSession(style: style)
        }
    }

    func pause() {
        if #available(iOS 26.0, *), usesLiveSession, let session = session as? HKWorkoutSession {
            session.pause()
        }
    }

    func resume() {
        if #available(iOS 26.0, *), usesLiveSession, let session = session as? HKWorkoutSession {
            session.resume()
        }
    }

    /// Ends the workout using the correct ordering:
    /// 1. session.end() (live path)  2. endCollection  3. addMetadata  4. finishWorkout
    func end(metadata: WorkoutMetadata? = nil) async throws {
        stopQueries()

        if #available(iOS 26.0, *), usesLiveSession,
           let session = session as? HKWorkoutSession,
           let builder = builder as? HKLiveWorkoutBuilder {
            session.end()
            try await builder.endCollection(at: Date())
            if let metadata {
                try await builder.addMetadata(Self.healthKitMetadata(from: metadata))
            }
            _ = try await builder.finishWorkout()
        } else if let builder = builder as? HKWorkoutBuilder {
            try await builder.endCollection(at: Date())
            if let metadata {
                try await builder.addMetadata(Self.healthKitMetadata(from: metadata))
            }
            _ = try await withCheckedThrowingContinuation { (cont: CheckedContinuation<HKWorkout?, Error>) in
                builder.finishWorkout { workout, error in
                    if let error {
                        cont.resume(throwing: error)
                    } else {
                        cont.resume(returning: workout)
                    }
                }
            }
        }

        isRecording = false
        session = nil
        builder = nil
        usesLiveSession = false
    }

    // MARK: - iOS 26+ Live Session

    @available(iOS 26.0, *)
    private func startLiveSession(style: YogaStyle) async throws {
        let config = HKWorkoutConfiguration()
        config.activityType = style.healthKitActivityType
        config.locationType = .indoor

        let session = try HKWorkoutSession(healthStore: healthStore, configuration: config)
        session.delegate = self
        self.session = session

        let builder = session.associatedWorkoutBuilder()
        builder.delegate = self
        builder.dataSource = HKLiveWorkoutDataSource(
            healthStore: healthStore,
            workoutConfiguration: config
        )
        self.builder = builder
        usesLiveSession = true

        session.startActivity(with: Date())

        // beginCollection can stall on simulator / incomplete auth — race a timeout.
        await withTaskGroup(of: Void.self) { group in
            group.addTask { try? await builder.beginCollection(at: Date()) }
            group.addTask { try? await Task.sleep(for: .seconds(3)) }
            _ = await group.next()
            group.cancelAll()
        }

        isRecording = true
    }

    // MARK: - iOS 17–25 Builder + Anchored HR

    private func startBuilderSession(style: YogaStyle) async throws {
        let config = HKWorkoutConfiguration()
        config.activityType = style.healthKitActivityType
        config.locationType = .indoor

        let builder = HKWorkoutBuilder(
            healthStore: healthStore,
            configuration: config,
            device: .local()
        )
        self.builder = builder
        usesLiveSession = false

        try await builder.beginCollection(at: Date())
        startHeartRateQuery()
        startEnergyQuery()
        isRecording = true
    }

    private func startHeartRateQuery() {
        let hrType = HKQuantityType(.heartRate)
        let predicate = HKQuery.predicateForSamples(
            withStart: Date(),
            end: nil,
            options: .strictStartDate
        )

        let query = HKAnchoredObjectQuery(
            type: hrType,
            predicate: predicate,
            anchor: nil,
            limit: HKObjectQueryNoLimit
        ) { [weak self] _, samples, _, _, _ in
            Task { @MainActor in
                self?.processHeartRateSamples(samples)
            }
        }
        query.updateHandler = { [weak self] _, samples, _, _, _ in
            Task { @MainActor in
                self?.processHeartRateSamples(samples)
            }
        }
        heartRateQuery = query
        healthStore.execute(query)
    }

    private func startEnergyQuery() {
        let energyType = HKQuantityType(.activeEnergyBurned)
        let predicate = HKQuery.predicateForSamples(
            withStart: Date(),
            end: nil,
            options: .strictStartDate
        )
        let query = HKAnchoredObjectQuery(
            type: energyType,
            predicate: predicate,
            anchor: nil,
            limit: HKObjectQueryNoLimit
        ) { [weak self] _, samples, _, _, _ in
            Task { @MainActor in
                self?.processEnergySamples(samples)
            }
        }
        query.updateHandler = { [weak self] _, samples, _, _, _ in
            Task { @MainActor in
                self?.processEnergySamples(samples)
            }
        }
        energyQuery = query
        healthStore.execute(query)
    }

    private func stopQueries() {
        if let heartRateQuery {
            healthStore.stop(heartRateQuery)
        }
        if let energyQuery {
            healthStore.stop(energyQuery)
        }
        heartRateQuery = nil
        energyQuery = nil
    }

    private func processHeartRateSamples(_ samples: [HKSample]?) {
        guard let quantitySamples = samples as? [HKQuantitySample] else { return }
        for sample in quantitySamples {
            let bpm = sample.quantity.doubleValue(for: .count().unitDivided(by: .minute()))
            recordHeartRate(bpm: bpm, timestamp: sample.endDate)
        }
    }

    private func processEnergySamples(_ samples: [HKSample]?) {
        guard let quantitySamples = samples as? [HKQuantitySample] else { return }
        var added = 0.0
        for sample in quantitySamples {
            added += sample.quantity.doubleValue(for: .kilocalorie())
        }
        if added > 0 {
            activeCalories += added
        }
    }

    // MARK: - Shared HR → SCI

    /// Record BPM, ring-buffer samples, and synthesize RR for FeedbackEngine ingest.
    func recordHeartRate(bpm: Double, timestamp: Date = Date()) {
        currentHeartRate = bpm
        heartRateSamples.append(HeartRateSample(bpm: bpm, timestamp: timestamp))
        if heartRateSamples.count > Self.maxHeartRateSamples {
            heartRateSamples.removeFirst(heartRateSamples.count - Self.maxHeartRateSamples)
        }
        let sum = heartRateSamples.reduce(0.0) { $0 + $1.bpm }
        averageHeartRate = sum / Double(heartRateSamples.count)
        processHeartRateForSCI(bpm: bpm)
    }

    /// Mirror of Watch `processHeartRateForSCI`: BPM → synthetic RR window → ingest.
    private func processHeartRateForSCI(bpm: Double) {
        let recentRR = heartRateSamples.suffix(10).map { 60000.0 / max($0.bpm, 1) }
        guard recentRR.count >= 4 else { return }

        let sdnn = standardDeviation(Array(recentRR))
        let rmssdValue = rmssd(Array(recentRR))
        onHRVIngest?(sdnn, rmssdValue, Array(recentRR))
    }

    private func standardDeviation(_ values: [Double]) -> Double {
        guard values.count >= 2 else { return 0 }
        let mean = values.reduce(0, +) / Double(values.count)
        let squaredDiffs = values.map { ($0 - mean) * ($0 - mean) }
        return sqrt(squaredDiffs.reduce(0, +) / Double(values.count - 1))
    }

    private func rmssd(_ intervals: [Double]) -> Double {
        guard intervals.count >= 2 else { return 0 }
        var sumSquaredDiff = 0.0
        for i in 1..<intervals.count {
            let diff = intervals[i] - intervals[i - 1]
            sumSquaredDiff += diff * diff
        }
        return sqrt(sumSquaredDiff / Double(intervals.count - 1))
    }

    private static func healthKitMetadata(from metadata: WorkoutMetadata) -> [String: Any] {
        [
            HKMetadataKeyWorkoutBrandName: "NATURaL",
            "NATURaLYogaStyle": metadata.styleName,
            "NATURaLPlanId": metadata.planId,
            "NATURaLPlanName": metadata.planName,
            "NATURaLSCIScore": metadata.sciScore as Any,
        ]
    }
}

// MARK: - Live session delegates (iOS 26+)

@available(iOS 26.0, *)
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

@available(iOS 26.0, *)
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
                        recordHeartRate(bpm: bpm)
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
