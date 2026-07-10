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
/// ## RR / SCI provenance
/// Prefer real beat-to-beat intervals from `HKHeartbeatSeriesSample` when HealthKit has them.
/// Otherwise BPM samples are converted via `RRIntervalProxy.syntheticRR` — a **proxy**, not
/// clinical HRV. Light physiological jitter prevents SCI from locking at 1.0 on constant BPM.
/// Adaptive music should consult `lastRRUsableForAdaptiveMusic` before reacting to SCI.
@MainActor
final class WorkoutRecorder: NSObject, ObservableObject {
    @Published var isRecording = false
    @Published var currentHeartRate: Double?
    @Published var activeCalories: Double = 0
    @Published var averageHeartRate: Double?
    /// Peak BPM for the session (O(1) update; avoids full-buffer scan on result).
    @Published private(set) var maxHeartRate: Double?
    @Published var heartRateSamples: [HeartRateSample] = []

    /// Provenance of the last RR window sent to SCI ingest.
    @Published private(set) var lastRRSource: RRIntervalSource = .synthetic
    /// `false` when the last RR window is meaningless for SCI (near-constant) even after proxy.
    @Published private(set) var lastRRUsableForAdaptiveMusic: Bool = false

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
    /// Builder-path queries are suspended on pause (iOS 17–25 have no session.pause()).
    private var queriesSuspended = false
    /// Running sum for O(1) average; recomputed only when the ring buffer is trimmed.
    private var heartRateSum: Double = 0
    /// Cached real RR intervals (ms) from the most recent heartbeat series query.
    private var cachedRealRR: [Double] = []
    private var lastHeartbeatSeriesFetch: Date = .distantPast

    /// Start (or **reuse**) a HealthKit workout session for `style`.
    /// If already recording, returns immediately so restore cannot orphan a second session.
    func start(style: YogaStyle = .chairYoga) async throws {
        if isRecording {
            // Reuse active session — avoids dual/orphaned workouts on restore.
            return
        }

        heartRateSamples.removeAll(keepingCapacity: true)
        heartRateSum = 0
        currentHeartRate = nil
        averageHeartRate = nil
        maxHeartRate = nil
        activeCalories = 0
        cachedRealRR.removeAll(keepingCapacity: true)
        lastRRSource = .synthetic
        lastRRUsableForAdaptiveMusic = false
        queriesSuspended = false

        if #available(iOS 26.0, *) {
            do {
                try await startLiveSession(style: style)
            } catch {
                // Live path failed (beginCollection timeout / auth) — fall back to builder.
                await teardownLiveSessionArtifacts()
                try await startBuilderSession(style: style)
            }
        } else {
            try await startBuilderSession(style: style)
        }
    }

    func pause() {
        if #available(iOS 26.0, *), usesLiveSession, let session = session as? HKWorkoutSession {
            session.pause()
        }
        // iOS 17–25 (and live path with anchored fallback): suspend HR/energy queries.
        if heartRateQuery != nil || energyQuery != nil {
            stopQueries()
            queriesSuspended = true
        }
    }

    func resume() {
        if #available(iOS 26.0, *), usesLiveSession, let session = session as? HKWorkoutSession {
            session.resume()
        }
        if queriesSuspended && !usesLiveSession {
            startHeartRateQuery()
            startEnergyQuery()
            queriesSuspended = false
        } else if queriesSuspended && usesLiveSession {
            // Live path normally uses builder statistics; only re-arm if we had anchored queries.
            queriesSuspended = false
        }
    }

    /// Ends the workout using the correct ordering:
    /// 1. session.end() (live path)  2. endCollection  3. addMetadata  4. finishWorkout
    func end(metadata: WorkoutMetadata? = nil) async throws {
        stopQueries()
        queriesSuspended = false

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
        // Only mark recording on confirmed success; otherwise throw so caller can fall back.
        let began = await withTaskGroup(of: Bool.self) { group -> Bool in
            group.addTask {
                do {
                    try await builder.beginCollection(at: Date())
                    return true
                } catch {
                    return false
                }
            }
            group.addTask {
                try? await Task.sleep(for: .seconds(3))
                return false
            }
            let first = await group.next() ?? false
            group.cancelAll()
            return first
        }

        guard began else {
            session.end()
            self.session = nil
            self.builder = nil
            usesLiveSession = false
            throw WorkoutRecorderError.beginCollectionFailed
        }

        isRecording = true
    }

    @available(iOS 26.0, *)
    private func teardownLiveSessionArtifacts() async {
        if let session = session as? HKWorkoutSession {
            session.end()
        }
        session = nil
        builder = nil
        usesLiveSession = false
        isRecording = false
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

    /// Record BPM, ring-buffer samples, and synthesize / prefer real RR for FeedbackEngine ingest.
    func recordHeartRate(bpm: Double, timestamp: Date = Date()) {
        currentHeartRate = bpm
        heartRateSamples.append(HeartRateSample(bpm: bpm, timestamp: timestamp))
        heartRateSum += bpm
        if let peak = maxHeartRate {
            maxHeartRate = max(peak, bpm)
        } else {
            maxHeartRate = bpm
        }
        // Batch-trim (slack) so we don't O(n)-shift on every sample once at capacity.
        if heartRateSamples.count > Self.maxHeartRateSamples + 64 {
            let overflow = heartRateSamples.count - Self.maxHeartRateSamples
            for i in 0..<overflow {
                heartRateSum -= heartRateSamples[i].bpm
            }
            heartRateSamples.removeFirst(overflow)
            // Guard float drift after large trims.
            if heartRateSamples.count > 0 {
                heartRateSum = heartRateSamples.reduce(0.0) { $0 + $1.bpm }
            } else {
                heartRateSum = 0
            }
        }
        let n = heartRateSamples.count
        averageHeartRate = n > 0 ? heartRateSum / Double(n) : nil
        processHeartRateForSCI(bpm: bpm)
        // Opportunistically refresh real RR cache (throttled).
        Task { await self.refreshRealRRIfNeeded() }
    }

    /// Prefer real heartbeat-series RR when cached; else BPM→RR **proxy** with light jitter.
    ///
    /// Pure-constant BPM→RR without jitter yields SCI≈1.0 and must not drive adaptive music
    /// (`lastRRUsableForAdaptiveMusic` gates that path).
    private func processHeartRateForSCI(bpm: Double) {
        _ = bpm
        let recentBPM = heartRateSamples.suffix(10).map(\.bpm)
        guard recentBPM.count >= 4 else { return }

        let rr: [Double]
        let source: RRIntervalSource
        if cachedRealRR.count >= 4 {
            rr = Array(cachedRealRR.suffix(32))
            source = .real
        } else {
            // Proxy: BPM samples → RR ms with ~5% SDNN-scale jitter (not clinical HRV).
            rr = RRIntervalProxy.syntheticRR(fromBPMSamples: Array(recentBPM))
            source = .synthetic
        }

        lastRRSource = source
        // Gate adaptive music when RR variance is still negligible (pure-constant proxy).
        // Jittered synthetic is normally usable; real series always preferred.
        lastRRUsableForAdaptiveMusic = !RRIntervalProxy.isMeaninglessForSCI(rr)

        // Always ingest jittered / real RR so SCI can leave a 1.0 floor; music checks the gate.
        let sdnn = RRIntervalProxy.standardDeviation(rr)
        let rmssdValue = RRIntervalProxy.rmssd(rr)
        onHRVIngest?(sdnn, rmssdValue, rr)
    }

    /// Throttled fetch of recent `HKHeartbeatSeriesSample` beat-to-beat intervals.
    private func refreshRealRRIfNeeded() async {
        let now = Date()
        guard now.timeIntervalSince(lastHeartbeatSeriesFetch) >= 15 else { return }
        lastHeartbeatSeriesFetch = now

        let seriesType = HKSeriesType.heartbeat()
        let predicate = HKQuery.predicateForSamples(
            withStart: now.addingTimeInterval(-120),
            end: now,
            options: .strictStartDate
        )

        await withCheckedContinuation { (cont: CheckedContinuation<Void, Never>) in
            let sampleQuery = HKSampleQuery(
                sampleType: seriesType,
                predicate: predicate,
                limit: 3,
                sortDescriptors: [NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: false)]
            ) { [weak self] _, samples, _ in
                guard let self, let seriesSamples = samples as? [HKHeartbeatSeriesSample], !seriesSamples.isEmpty else {
                    cont.resume()
                    return
                }
                Task { @MainActor in
                    var intervals: [Double] = []
                    for series in seriesSamples {
                        if let beats = await self.fetchHeartbeatSeriesBeats(series) {
                            intervals.append(contentsOf: beats)
                        }
                    }
                    if intervals.count >= 4 {
                        self.cachedRealRR = Array(intervals.suffix(64))
                    }
                    cont.resume()
                }
            }
            healthStore.execute(sampleQuery)
        }
    }

    /// Returns beat-to-beat RR intervals in ms, or nil on error / empty.
    private func fetchHeartbeatSeriesBeats(_ series: HKHeartbeatSeriesSample) async -> [Double]? {
        await withCheckedContinuation { cont in
            var rr: [Double] = []
            var previous: TimeInterval?
            var settled = false
            let finish: ([Double]?) -> Void = { result in
                guard !settled else { return }
                settled = true
                cont.resume(returning: result)
            }
            let query = HKHeartbeatSeriesQuery(heartbeatSeries: series) { _, timeSinceSeriesStart, _, done, error in
                if error != nil {
                    finish(nil)
                    return
                }
                if let previous {
                    let deltaMs = (timeSinceSeriesStart - previous) * 1000.0
                    if deltaMs > 200 && deltaMs < 2000 {
                        rr.append(deltaMs)
                    }
                }
                previous = timeSinceSeriesStart
                if done {
                    finish(rr.isEmpty ? nil : rr)
                }
            }
            healthStore.execute(query)
        }
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

// MARK: - Errors

enum WorkoutRecorderError: Error {
    case beginCollectionFailed
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
