import HealthKit

/// Manages HealthKit authorization and capability checks.
final class HealthKitManager: Sendable {
    let healthStore = HKHealthStore()

    static var isAvailable: Bool {
        HKHealthStore.isHealthDataAvailable()
    }

    /// Requests HealthKit authorization for workout, heart rate, HRV,
    /// medication records, and activity data.
    func requestAuthorization() async throws {
        var typesToRead: Set<HKObjectType> = [
            HKQuantityType(.heartRate),
            HKQuantityType(.heartRateVariabilitySDNN),
            HKQuantityType(.activeEnergyBurned),
            HKQuantityType(.appleExerciseTime),
            HKObjectType.workoutType(),
            HKObjectType.activitySummaryType(),
            HKCategoryType(.mindfulSession),
        ]

        // Clinical medication records (requires Health Records entitlement)
        if HKHealthStore.isHealthDataAvailable() {
            typesToRead.insert(HKClinicalType(.medicationRecord))
        }

        let typesToShare: Set<HKSampleType> = [
            HKQuantityType(.activeEnergyBurned),
            HKSampleType.workoutType(),
        ]

        try await healthStore.requestAuthorization(
            toShare: typesToShare,
            read: typesToRead
        )
    }
}
