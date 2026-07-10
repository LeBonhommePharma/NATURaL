import HealthKit

/// Manages HealthKit authorization, capability checks, and background delivery
/// for the generalized health signal analysis pipeline.
final class HealthKitManager: Sendable {
    let healthStore = HKHealthStore()

    static var isAvailable: Bool {
        HKHealthStore.isHealthDataAvailable()
    }

    /// Whether clinical medication records can be requested on this OS / entitlement surface.
    /// Clinical types exist from iOS 12+; actual data still requires Health Records entitlement,
    /// institutional connection in the Health app, and **explicit in-app consent**.
    static var isClinicalMedicationTypeAvailable: Bool {
        #if os(iOS)
        return HKObjectType.clinicalType(forIdentifier: .medicationRecord) != nil
        #else
        return false
        #endif
    }

    /// Requests HealthKit authorization for the **non-clinical** signal pipeline:
    /// HR, HRV, sleep, respiratory rate, resting HR, VO2 max,
    /// workouts, and activity summaries.
    ///
    /// **Clinical medication records are intentionally excluded** from this call.
    /// Request them only after explicit user consent via
    /// `requestClinicalMedicationAuthorization()`. Mixing clinical types into the
    /// launch-time sheet can fail the entire authorization if Health Records is
    /// not provisioned, producing a forever-loading launch.
    func requestAuthorization() async throws {
        let typesToRead: Set<HKObjectType> = [
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

            // ECG for high-fidelity RR intervals (Apple Watch Series 4+)
            HKObjectType.electrocardiogramType(),
        ]

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

    // MARK: - Clinical medication authorization (consent-gated caller)

    /// Requests read access for `HKClinicalTypeIdentifier.medicationRecord`.
    ///
    /// **Call only after explicit in-app consent** (`ConsentStore.hasValidClinicalConsent`).
    ///
    /// OS / product limits:
    /// - Clinical types are **read-only** (pass empty share set).
    /// - Requires Health Records entitlement (`health-records` in entitlements).
    /// - User must connect a health institution in the Health app; not all regions
    ///   support Health Records; many devices return zero samples even when authorized.
    /// - Does **not** use pharmacy credentials or scrape pharmacy websites.
    /// - HealthKit may present a **separate** clinical permission sheet.
    ///
    /// - Returns: `true` if the authorization request completed without throw.
    ///   HealthKit does not reveal whether the user allowed a read type (privacy).
    @discardableResult
    func requestClinicalMedicationAuthorization() async throws -> Bool {
        guard Self.isAvailable else { return false }
        guard Self.isClinicalMedicationTypeAvailable else { return false }

        #if os(iOS)
        guard let medType = HKObjectType.clinicalType(forIdentifier: .medicationRecord) else {
            return false
        }
        // Clinical records are read-only.
        try await healthStore.requestAuthorization(toShare: [], read: [medType])
        return true
        #else
        return false
        #endif
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
            let quantitySample = sample
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
