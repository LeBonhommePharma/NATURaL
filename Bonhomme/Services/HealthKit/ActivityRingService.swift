import HealthKit

/// Queries HealthKit for activity summary data (Move, Exercise, Stand rings).
final class ActivityRingService {
    private let store = HKHealthStore()

    struct RingData: Sendable {
        let moveProgress: Double    // 0.0 – 1.0+
        let exerciseProgress: Double
        let standProgress: Double
        let moveCalories: Double
        let moveGoal: Double
        let exerciseMinutes: Double
        let exerciseGoal: Double
        let standHours: Int
        let standGoal: Int
    }

    /// Fetches today's activity summary.
    func todaySummary() async throws -> RingData? {
        let calendar = Calendar.current
        let components = calendar.dateComponents([.year, .month, .day], from: Date())

        let predicate = HKQuery.predicateForActivitySummary(with: components)
        let descriptor = HKActivitySummaryQueryDescriptor(predicate: predicate)

        let results = try await descriptor.result(for: store)
        guard let summary = results.first else { return nil }

        let moveGoal = summary.activeEnergyBurnedGoal.doubleValue(for: .kilocalorie())
        let moveActual = summary.activeEnergyBurned.doubleValue(for: .kilocalorie())
        let exerciseGoal = summary.appleExerciseTimeGoal.doubleValue(for: .minute())
        let exerciseActual = summary.appleExerciseTime.doubleValue(for: .minute())
        let standGoal = summary.appleStandHoursGoal.doubleValue(for: .count())
        let standActual = summary.appleStandHours.doubleValue(for: .count())

        return RingData(
            moveProgress: moveGoal > 0 ? moveActual / moveGoal : 0,
            exerciseProgress: exerciseGoal > 0 ? exerciseActual / exerciseGoal : 0,
            standProgress: standGoal > 0 ? standActual / standGoal : 0,
            moveCalories: moveActual,
            moveGoal: moveGoal,
            exerciseMinutes: exerciseActual,
            exerciseGoal: exerciseGoal,
            standHours: Int(standActual),
            standGoal: Int(standGoal)
        )
    }
}
