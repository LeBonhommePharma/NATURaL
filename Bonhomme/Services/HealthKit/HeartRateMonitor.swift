import HealthKit

/// Standalone heart rate monitor using HKAnchoredObjectQuery for scenarios
/// outside an active workout session (e.g., resting HR display).
@MainActor
final class HeartRateMonitor: ObservableObject {
    @Published var currentBPM: Double?

    private let healthStore = HKHealthStore()
    private var query: HKAnchoredObjectQuery?

    func startMonitoring() {
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
            self?.processSamples(samples)
        }

        query.updateHandler = { [weak self] _, samples, _, _, _ in
            self?.processSamples(samples)
        }

        self.query = query
        healthStore.execute(query)
    }

    func stopMonitoring() {
        if let query {
            healthStore.stop(query)
        }
        query = nil
    }

    private nonisolated func processSamples(_ samples: [HKSample]?) {
        guard let quantitySamples = samples as? [HKQuantitySample],
              let latest = quantitySamples.last else { return }

        let bpm = latest.quantity.doubleValue(for: .count().unitDivided(by: .minute()))
        Task { @MainActor in
            currentBPM = bpm
        }
    }
}
