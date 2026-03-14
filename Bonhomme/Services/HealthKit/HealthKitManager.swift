import HealthKit

/// Manages HealthKit authorization and capability checks.
final class HealthKitManager: Sendable {
    let healthStore = HKHealthStore()

    static var isAvailable: Bool {
        HKHealthStore.isHealthDataAvailable()
    }

    /// Requests HealthKit authorization for workout, heart rate, and activity data.
    func requestAuthorization() async throws {
        let typesToRead: Set<HKObjectType> = [
            HKQuantityType(.heartRate),
            HKQuantityType(.activeEnergyBurned),
            HKQuantityType(.appleExerciseTime),
            HKObjectType.workoutType(),
            HKObjectType.activitySummaryType(),
            HKCategoryType(.mindfulSession),
        ]

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
