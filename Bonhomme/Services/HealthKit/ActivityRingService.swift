import HealthKit

// MARK: - Error type

enum ActivityRingError: LocalizedError {
    case healthDataUnavailable
    case notAuthorized
    /// Regression guard for Task 102: DateComponents must carry a calendar.
    case missingCalendar
    case queryFailed(underlying: Error)

    var errorDescription: String? {
        switch self {
        case .healthDataUnavailable:
            return "HealthKit is not available on this device."
        case .notAuthorized:
            return "HealthKit authorisation was not granted."
        case .missingCalendar:
            return "DateComponents is missing a calendar (internal error — see Task 102)."
        case .queryFailed(let e):
            return "Activity summary query failed: \(e.localizedDescription)"
        }
    }
}

// MARK: - Service

/// Queries HealthKit for today's activity summary (Move / Exercise / Stand rings).
final class ActivityRingService {

    // MARK: Nested types

    struct RingData: Sendable {
        let moveProgress:     Double   // 0.0 – 1.0+
        let exerciseProgress: Double
        let standProgress:    Double
        let moveCalories:     Double
        let moveGoal:         Double
        let exerciseMinutes:  Double
        let exerciseGoal:     Double
        let standHours:       Int
        let standGoal:        Int
    }

    // MARK: Private state

    private let store = HKHealthStore()

    // MARK: Authorisation

    /// Requests the minimal HealthKit read authorisation needed by this service.
    /// Safe to call multiple times — HealthKit is idempotent on re-request.
    func requestAuthorisation() async throws {
        guard HKHealthStore.isHealthDataAvailable() else {
            throw ActivityRingError.healthDataUnavailable
        }
        try await store.requestAuthorization(
            toShare: [],
            read: [HKObjectType.activitySummaryType()]
        )
    }

    // MARK: Query

    /// Fetches today's activity summary rings.
    ///
    /// - Parameter calendar: The calendar used to derive today's date components.
    ///   Defaults to `Calendar.current`. Inject a fixed calendar in tests.
    /// - Returns: `RingData` when HealthKit has a summary for today, `nil` otherwise.
    /// - Throws: `ActivityRingError` on availability, auth, or query failure.
    func todaySummary(calendar: Calendar = .current) async throws -> RingData? {
        guard HKHealthStore.isHealthDataAvailable() else {
            throw ActivityRingError.healthDataUnavailable
        }

        // ── Fix for Task 102 ────────────────────────────────────────────────
        // `Calendar.dateComponents(_:from:)` copies only the requested fields
        // and does NOT populate `.calendar` on the result.
        // `HKQuery.predicateForActivitySummary(with:)` calls `components.date`
        // internally; that method requires `.calendar != nil` and throws
        // "Date components require a calendar" otherwise.
        //
        // `Calendar.dateComponents(in:from:)` always embeds both `.calendar`
        // and `.timeZone`, satisfying the HKQuery precondition.
        // ────────────────────────────────────────────────────────────────────
        let components = Self.todayComponents(calendar: calendar)

        // Defensive: catch any future regression in DEBUG builds immediately.
        assert(components.calendar != nil,
               "[ActivityRingService] DateComponents.calendar is nil — HKQuery will crash. See Task 102.")
        guard components.calendar != nil else {
            throw ActivityRingError.missingCalendar
        }

        let predicate  = HKQuery.predicateForActivitySummary(with: components)
        let descriptor = HKActivitySummaryQueryDescriptor(predicate: predicate)

        let results: [HKActivitySummary]
        do {
            results = try await descriptor.result(for: store)
        } catch {
            throw ActivityRingError.queryFailed(underlying: error)
        }

        return results.first.map(RingData.init)
    }

    // MARK: - Private helpers

    /// Builds `DateComponents` for today that carry an embedded `.calendar`,
    /// which is required by `HKQuery.predicateForActivitySummary(with:)`.
    ///
    /// `Calendar.dateComponents(in:from:)` always populates `.calendar` and
    /// `.timeZone` on its result, unlike the component-set overload.
    private static func todayComponents(calendar: Calendar) -> DateComponents {
        calendar.dateComponents(in: calendar.timeZone, from: Date())
    }
}

// MARK: - RingData convenience init

private extension ActivityRingService.RingData {
    /// Converts an `HKActivitySummary` into the unit-normalised `RingData`
    /// value type. All unit conversions are co-located here.
    init(from summary: HKActivitySummary) {
        let moveGoal       = summary.activeEnergyBurnedGoal.doubleValue(for: .kilocalorie())
        let moveActual     = summary.activeEnergyBurned.doubleValue(for: .kilocalorie())
        let exerciseGoal   = summary.appleExerciseTimeGoal.doubleValue(for: .minute())
        let exerciseActual = summary.appleExerciseTime.doubleValue(for: .minute())
        let standGoal      = summary.appleStandHoursGoal.doubleValue(for: .count())
        let standActual    = summary.appleStandHours.doubleValue(for: .count())

        self.init(
            moveProgress:     moveGoal     > 0 ? moveActual     / moveGoal     : 0,
            exerciseProgress: exerciseGoal > 0 ? exerciseActual / exerciseGoal : 0,
            standProgress:    standGoal    > 0 ? standActual    / standGoal    : 0,
            moveCalories:     moveActual,
            moveGoal:         moveGoal,
            exerciseMinutes:  exerciseActual,
            exerciseGoal:     exerciseGoal,
            standHours:       Int(standActual),
            standGoal:        Int(standGoal)
        )
    }
}
