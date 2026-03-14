import HealthKit

/// Manages HealthKit authorization, capability checks, and background delivery
/// for the generalized health signal analysis pipeline.
final class HealthKitManager: Sendable {
    let healthStore = HKHealthStore()

    static var isAvailable: Bool {
        HKHealthStore.isHealthDataAvailable()
    }

    /// Requests HealthKit authorization for the full signal pipeline:
    /// HR, HRV, sleep, respiratory rate, resting HR, VO2 max, mood,
    /// medication records, workouts, and activity summaries.
    func requestAuthorization() async throws {
        var typesToRead: Set<HKObjectType> = [
            // Core biofeedback
            HKQuantityType(.heartRate),
            HKQuantityType(.heartRateVariabilitySDNN),
            HKQuantityType(.restingHeartRate),

            // Workout & activity
            HKQuantityType(.activeEnergyBurned),
            HKQuantityType(.appleExerciseTime),
            HKObjectType.workoutType(),
            HKObjectType.activitySummaryType(),

            // Breathing & fitness
            HKQuantityType(.respiratoryRate),
            HKQuantityType(.vo2Max),

            // Sleep & mindfulness
            HKCategoryType(.sleepAnalysis),
            HKCategoryType(.mindfulSession),
        ]

        // Clinical medication records (requires Health Records entitlement)
        if HKHealthStore.isHealthDataAvailable() {
            typesToRead.insert(HKClinicalType(.medicationRecord))
        }

        // ECG for high-fidelity RR intervals (Apple Watch Series 4+)
        typesToRead.insert(HKObjectType.electrocardiogramType())

        let typesToShare: Set<HKSampleType> = [
            HKQuantityType(.activeEnergyBurned),
            HKSampleType.workoutType(),
            // Write mindful sessions for yoga as mindfulness data
            HKCategoryType(.mindfulSession),
        ]

        try await healthStore.requestAuthorization(
            toShare: typesToShare,
            read: typesToRead
        )
    }

    // MARK: - Background Delivery

    /// Enables background delivery for key health signals so the FeedbackEngine
    /// can process data even when the app is not foregrounded.
    /// Call once during app launch after authorization is granted.
    func enableBackgroundDelivery() async throws {
        let backgroundTypes: [(HKObjectType, HKUpdateFrequency)] = [
            (HKQuantityType(.heartRateVariabilitySDNN), .immediate),
            (HKQuantityType(.heartRate), .immediate),
            (HKCategoryType(.sleepAnalysis), .hourly),
            (HKQuantityType(.restingHeartRate), .daily),
            (HKQuantityType(.respiratoryRate), .hourly),
        ]

        for (type, frequency) in backgroundTypes {
            guard let sampleType = type as? HKSampleType else { continue }
            try await healthStore.enableBackgroundDelivery(
                for: sampleType,
                frequency: frequency
            )
        }
    }

    // MARK: - Observer Queries

    /// Creates a long-running observer query for a given sample type.
    /// The completion handler fires whenever new samples of that type appear.
    func observeType(
        _ type: HKSampleType,
        handler: @escaping @Sendable () -> Void
    ) -> HKObserverQuery {
        let query = HKObserverQuery(sampleType: type, predicate: nil) { _, completionHandler, _ in
            handler()
            completionHandler()
        }
        healthStore.execute(query)
        return query
    }

    // MARK: - HRV Query

    /// Fetches recent HRV SDNN samples for the FeedbackEngine.
    func fetchRecentHRV(
        since startDate: Date
    ) async throws -> [(sdnn: Double, timestamp: Date)] {
        let hrvType = HKQuantityType(.heartRateVariabilitySDNN)
        let predicate = HKQuery.predicateForSamples(
            withStart: startDate,
            end: nil,
            options: .strictStartDate
        )

        let descriptor = HKSampleQueryDescriptor(
            predicates: [.quantitySample(type: hrvType, predicate: predicate)],
            sortDescriptors: [SortDescriptor(\.startDate)]
        )

        let samples = try await descriptor.result(for: healthStore)

        return samples.compactMap { sample -> (sdnn: Double, timestamp: Date)? in
            guard let quantitySample = sample as? HKQuantitySample else { return nil }
            let sdnn = quantitySample.quantity.doubleValue(for: .secondUnit(with: .milli))
            return (sdnn: sdnn, timestamp: quantitySample.startDate)
        }
    }

    // MARK: - Mindful Session Writing

    /// Saves a completed yoga session as a mindful session in HealthKit.
    func saveMindfulSession(start: Date, end: Date) async throws {
        let mindfulType = HKCategoryType(.mindfulSession)
        let sample = HKCategorySample(
            type: mindfulType,
            value: HKCategoryValue.notApplicable.rawValue,
            start: start,
            end: end
        )
        try await healthStore.save(sample)
    }
}
