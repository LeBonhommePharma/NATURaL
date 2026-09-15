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
    @Published private(set) var isStarting = false
    @Published private(set) var isEnding = false
    @Published private(set) var recordingError: Error?
    private var isPaused = false
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
    private var recordingGeneration = UUID()

    /// Start (or **reuse**) a HealthKit workout session for `style`.
    /// If already recording, returns immediately so restore cannot orphan a second session.
    func start(style: YogaStyle = .chairYoga) async throws {
        guard !isStarting, !isEnding else { throw WorkoutRecorderError.operationInProgress }
        if isRecording {
            // Reuse active session — avoids dual/orphaned workouts on restore.
            return
        }

        isStarting = true
        defer { isStarting = false }
        try Task.checkCancellation()
        recordingError = nil
        isPaused = false
        lastHeartbeatSeriesFetch = .distantPast
        recordingGeneration = UUID()
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
                try Task.checkCancellation()
                try await startBuilderSession(style: style)
            }
        } else {
            try await startBuilderSession(style: style)
        }
    }

    func pause() {
        guard isRecording, !isEnding, !isPaused else { return }
        isPaused = true
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
        guard isRecording, !isEnding, isPaused else { return }
        isPaused = false
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
        guard !isEnding else { throw WorkoutRecorderError.operationInProgress }
        guard isRecording else {
            if let recordingError { throw recordingError }
            throw WorkoutRecorderError.notRecording
        }
        isEnding = true
        stopQueries()
        queriesSuspended = false
        defer {
            isRecording = false
            isEnding = false
            isPaused = false
            session = nil
            builder = nil
            usesLiveSession = false
        }
        do {
            if #available(iOS 26.0, *), let session = session as? HKWorkoutSession {
                session.end()
            }
            guard let builder = builder as? HKWorkoutBuilder else {
                throw WorkoutRecorderError.saveFailed
            }
            try await builder.endCollection(at: Date())
            if let metadata {
                try await builder.addMetadata(Self.healthKitMetadata(from: metadata))
            }
            let workout = try await builder.finishWorkout()
            guard workout != nil else { throw WorkoutRecorderError.saveFailed }
        } catch {
            recordingError = error
            (builder as? HKWorkoutBuilder)?.discardWorkout()
            throw error
        }
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

        // A callback gate returns on timeout without waiting for an uncancellable
        // HealthKit child task. Late callbacks cannot resume the continuation twice.
        try await beginCollection(builder)
        try Task.checkCancellation()
        guard self.session === session else {
            throw recordingError ?? WorkoutRecorderError.beginCollectionFailed
        }

        recordingError = nil
        isRecording = true
    }

    @available(iOS 26.0, *)
    private func teardownLiveSessionArtifacts() async {
        if let session = session as? HKWorkoutSession {
            session.end()
        }
        (builder as? HKWorkoutBuilder)?.discardWorkout()
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

        do {
            try await beginCollection(builder)
            try Task.checkCancellation()
        } catch {
            builder.discardWorkout()
            self.builder = nil
            recordingError = error
            throw error
        }
        startHeartRateQuery()
        startEnergyQuery()
        recordingError = nil
        isRecording = true
    }

    private func beginCollection(_ builder: HKWorkoutBuilder) async throws {
        let gate = WorkoutCollectionStartGate()
        try await withTaskCancellationHandler {
            try await withCheckedThrowingContinuation { continuation in
                gate.continuation = continuation
                if Task.isCancelled {
                    gate.finish(.failure(CancellationError()))
                    return
                }
                gate.timeout = Task {
                    do { try await Task.sleep(for: .seconds(5)) }
                    catch { return }
                    gate.finish(.failure(WorkoutRecorderError.beginCollectionFailed))
                }
                builder.beginCollection(withStart: Date()) { success, error in
                    Task { @MainActor in
                        if let error { gate.finish(.failure(error)) }
                        else if success { gate.finish(.success(())) }
                        else { gate.finish(.failure(WorkoutRecorderError.beginCollectionFailed)) }
                    }
                }
            }
        } onCancel: {
            Task { @MainActor in gate.finish(.failure(CancellationError())) }
        }
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
        ) { [weak self] query, samples, _, _, _ in
            Task { @MainActor in
                guard let self, self.heartRateQuery === query else { return }
                self.processHeartRateSamples(samples)
            }
        }
        query.updateHandler = { [weak self] query, samples, _, _, _ in
            Task { @MainActor in
                guard let self, self.heartRateQuery === query else { return }
                self.processHeartRateSamples(samples)
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
        ) { [weak self] query, samples, _, _, _ in
            Task { @MainActor in
                guard let self, self.energyQuery === query else { return }
                self.processEnergySamples(samples)
            }
        }
        query.updateHandler = { [weak self] query, samples, _, _, _ in
            Task { @MainActor in
                guard let self, self.energyQuery === query else { return }
                self.processEnergySamples(samples)
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
        guard isRecording, !isPaused, !isEnding, let quantitySamples = samples as? [HKQuantitySample] else { return }
        for sample in quantitySamples {
            let bpm = sample.quantity.doubleValue(for: .count().unitDivided(by: .minute()))
            recordHeartRate(bpm: bpm, timestamp: sample.endDate)
        }
    }

    private func processEnergySamples(_ samples: [HKSample]?) {
        guard isRecording, !isPaused, !isEnding, let quantitySamples = samples as? [HKQuantitySample] else { return }
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
        guard isRecording, !isPaused, !isEnding, bpm.isFinite, bpm > 0 else { return }
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
        guard isRecording, !isEnding else { return }
        let generation = recordingGeneration
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
                    if self.recordingGeneration == generation, self.isRecording, !self.isEnding, intervals.count >= 4 {
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
            let query = HKHeartbeatSeriesQuery(heartbeatSeries: series) { _, timeSinceSeriesStart, precededByGap, done, error in
                if error != nil {
                    finish(nil)
                    return
                }
                if let previous, !precededByGap {
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
        var values: [String: Any] = [
            HKMetadataKeyWorkoutBrandName: "NATURaL",
            "NATURaLYogaStyle": metadata.styleName,
            "NATURaLPlanId": metadata.planId,
            "NATURaLPlanName": metadata.planName,
        ]
        if let score = metadata.sciScore, score.isFinite {
            values["NATURaLSCIScore"] = score
        }
        return values
    }
}

// MARK: - Errors

enum WorkoutRecorderError: Error {
    case beginCollectionFailed
    case operationInProgress
    case saveFailed
    case notRecording
}

@MainActor
private final class WorkoutCollectionStartGate {
    var continuation: CheckedContinuation<Void, Error>?
    var timeout: Task<Void, Never>?

    func finish(_ result: Result<Void, Error>) {
        guard let continuation else { return }
        self.continuation = nil
        timeout?.cancel()
        timeout = nil
        continuation.resume(with: result)
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
        Task { @MainActor in
            guard self.session === workoutSession else { return }
            self.recordingError = error
            guard !self.isEnding else { return }
            self.stopQueries()
            workoutSession.end()
            (self.builder as? HKWorkoutBuilder)?.discardWorkout()
            self.session = nil
            self.builder = nil
            self.isRecording = false
            self.usesLiveSession = false
        }
    }
}

@available(iOS 26.0, *)
extension WorkoutRecorder: HKLiveWorkoutBuilderDelegate {
    nonisolated func workoutBuilder(
        _ workoutBuilder: HKLiveWorkoutBuilder,
        didCollectDataOf collectedTypes: Set<HKSampleType>
    ) {
        Task { @MainActor in
            guard self.builder === workoutBuilder, isRecording, !isPaused, !isEnding else { return }
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
