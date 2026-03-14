import HealthKit

/// Reads Fitness+ yoga workouts from HealthKit by filtering on Apple's
/// source bundle identifiers. Fitness+ sessions write standard HKWorkout
/// objects through Apple's own workout infrastructure.
final class FitnessPlusReader {
    private let store = HKHealthStore()

    /// Apple bundle identifiers that Fitness+ workouts are recorded under.
    private let appleSourceBundles: Set<String> = [
        "com.apple.health.workout-app",
        "com.apple.Health",
        "com.apple.workout",
    ]

    /// Fetches yoga workouts from Fitness+ (Apple-sourced) within a date range.
    func fetchFitnessPlusYogaSessions(
        from startDate: Date,
        to endDate: Date
    ) async throws -> [HKWorkout] {
        let yogaPredicate = HKQuery.predicateForWorkouts(with: .yoga)
        let datePredicate = HKQuery.predicateForSamples(
            withStart: startDate,
            end: endDate,
            options: .strictStartDate
        )
        let compound = NSCompoundPredicate(
            andPredicateWithSubpredicates: [yogaPredicate, datePredicate]
        )

        let descriptor = HKSampleQueryDescriptor(
            predicates: [.workout(compound)],
            sortDescriptors: [SortDescriptor(\.startDate, order: .reverse)]
        )

        let results = try await descriptor.result(for: store)

        return results.filter { workout in
            appleSourceBundles.contains(
                workout.sourceRevision.source.bundleIdentifier
            )
        }
    }

    /// Fetches all yoga workouts (any source) within a date range.
    func fetchAllYogaSessions(
        from startDate: Date,
        to endDate: Date
    ) async throws -> [HKWorkout] {
        let yogaPredicate = HKQuery.predicateForWorkouts(with: .yoga)
        let datePredicate = HKQuery.predicateForSamples(
            withStart: startDate,
            end: endDate,
            options: .strictStartDate
        )
        let compound = NSCompoundPredicate(
            andPredicateWithSubpredicates: [yogaPredicate, datePredicate]
        )

        let descriptor = HKSampleQueryDescriptor(
            predicates: [.workout(compound)],
            sortDescriptors: [SortDescriptor(\.startDate, order: .reverse)]
        )

        return try await descriptor.result(for: store)
    }
}
