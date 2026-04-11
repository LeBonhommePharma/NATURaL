import Foundation
import CareKitStore
import BonhommeCore

/// Bridges CareKit's care plan system with NATURaL's workout engine for
/// clinical/rehabilitation settings where a therapist prescribes yoga regimens.
///
/// Uses CareKitStore's `OCKStore` for local persistence of prescribed tasks
/// and outcomes. The therapist creates a care plan (via a companion portal or
/// in-app configuration), and patients see their prescribed workouts in the
/// NATURaL home screen with adherence tracking.
@MainActor
final class CareKitBridge: ObservableObject {
    @Published var prescribedTasks: [OCKTask] = []
    @Published var isLoaded = false

    private let store: OCKStore

    init(storeName: String = "NATURaLCareKit") {
        self.store = OCKStore(name: storeName)
    }

    // MARK: - Prescription Management

    /// Imports a therapist-prescribed yoga regimen into the CareKit store.
    /// Each WorkoutPlan becomes an OCKTask with the specified schedule.
    ///
    /// - Parameters:
    ///   - plans: The workout plans to prescribe.
    ///   - frequency: How many times per week the patient should practice.
    ///   - startDate: When the prescription begins (defaults to today).
    ///   - endDate: Optional end date for time-limited prescriptions.
    func importPrescription(
        plans: [WorkoutPlan],
        frequency: Int = 3,
        startDate: Date = Date(),
        endDate: Date? = nil
    ) async throws {
        for plan in plans {
            let task = YogaTaskBuilder.buildTask(
                from: plan,
                frequency: frequency,
                startDate: startDate,
                endDate: endDate
            )

            // Check if task already exists
            do {
                var existing = try await store.fetchTask(withID: task.id)
                existing.effectiveDate = startDate
                existing.schedule = task.schedule
                existing.instructions = task.instructions
                try await store.updateTask(existing)
            } catch {
                // Task doesn't exist yet — add it
                try await store.addTask(task)
            }
        }

        await refreshPrescribedTasks()
    }

    /// Records a completed workout as a CareKit outcome against the prescribed task.
    ///
    /// - Parameters:
    ///   - planId: The workout plan ID (matches the OCKTask ID).
    ///   - result: The workout result containing duration, poses, calories, etc.
    ///   - sciScore: The final SCI score at workout completion.
    func recordCompletion(
        planId: String,
        result: WorkoutResult,
        sciScore: Double?
    ) async throws {
        let taskId = YogaTaskBuilder.taskId(for: planId)

        // Find the task and its schedule event for today
        let task = try await store.fetchTask(withID: taskId)

        // Create outcome values from the workout result
        let outcomeValues = YogaTaskBuilder.buildOutcomeValues(
            from: result,
            sciScore: sciScore
        )

        // Find today's schedule event index
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: Date())
        let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay)!

        let events = task.schedule.events(
            from: startOfDay,
            to: endOfDay
        )

        let eventIndex = events.isEmpty ? 0 : 0 // Use first event of the day

        let outcome = OCKOutcome(
            taskUUID: task.uuid,
            taskOccurrenceIndex: eventIndex,
            values: outcomeValues
        )

        try await store.addOutcome(outcome)
    }

    /// Calculates adherence percentage for a specific prescribed plan
    /// over the last N days.
    ///
    /// - Parameters:
    ///   - planId: The workout plan ID.
    ///   - days: Number of days to look back (default 30).
    /// - Returns: Adherence as a 0.0–1.0 fraction.
    func fetchAdherence(for planId: String, days: Int = 30) async throws -> Double {
        let taskId = YogaTaskBuilder.taskId(for: planId)
        let task = try await store.fetchTask(withID: taskId)

        let calendar = Calendar.current
        let endDate = Date()
        guard let startDate = calendar.date(byAdding: .day, value: -days, to: endDate) else {
            return 0
        }

        // Count scheduled events in the window
        let scheduledEvents = task.schedule.events(from: startDate, to: endDate)
        let totalScheduled = scheduledEvents.count
        guard totalScheduled > 0 else { return 0 }

        // Count outcomes (completed sessions)
        let query = OCKOutcomeQuery(for: Date())
        let outcomes = try await store.fetchOutcomes(query: query)
        let completedCount = outcomes.filter { $0.taskUUID == task.uuid }.count

        return min(1.0, Double(completedCount) / Double(totalScheduled))
    }

    /// Fetches all active prescribed tasks from the CareKit store.
    func refreshPrescribedTasks() async {
        do {
            let query = OCKTaskQuery(for: Date())
            prescribedTasks = try await store.fetchTasks(query: query)
            isLoaded = true
        } catch {
            prescribedTasks = []
            isLoaded = true
        }
    }

    /// Returns the WorkoutPlan for a prescribed task, if it exists in the catalog.
    func resolveWorkoutPlan(for task: OCKTask) -> WorkoutPlan? {
        let planId = YogaTaskBuilder.planId(from: task.id)
        return PoseCatalog.allPlans.first { $0.id == planId }
    }

    /// Checks if there are any active prescriptions.
    var hasPrescriptions: Bool {
        !prescribedTasks.isEmpty
    }

    /// Removes a prescribed task (e.g., when therapist cancels the prescription).
    func removePrescription(planId: String) async throws {
        let taskId = YogaTaskBuilder.taskId(for: planId)
        let task = try await store.fetchTask(withID: taskId)
        try await store.deleteTask(task)
        await refreshPrescribedTasks()
    }
}

// MARK: - OCKStore Async Helpers

private extension OCKStore {
    func fetchTask(withID id: String) async throws -> OCKTask {
        try await withCheckedThrowingContinuation { continuation in
            fetchTask(withID: id) { result in
                continuation.resume(with: result)
            }
        }
    }

    func fetchTasks(query: OCKTaskQuery) async throws -> [OCKTask] {
        try await withCheckedThrowingContinuation { continuation in
            fetchTasks(query: query) { result in
                continuation.resume(with: result)
            }
        }
    }

    func addTask(_ task: OCKTask) async throws {
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            addTask(task) { result in
                switch result {
                case .success: continuation.resume()
                case .failure(let error): continuation.resume(throwing: error)
                }
            }
        }
    }

    func updateTask(_ task: OCKTask) async throws {
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            updateTask(task) { result in
                switch result {
                case .success: continuation.resume()
                case .failure(let error): continuation.resume(throwing: error)
                }
            }
        }
    }

    func deleteTask(_ task: OCKTask) async throws {
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            deleteTask(task) { result in
                switch result {
                case .success: continuation.resume()
                case .failure(let error): continuation.resume(throwing: error)
                }
            }
        }
    }

    func addOutcome(_ outcome: OCKOutcome) async throws {
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            addOutcome(outcome) { result in
                switch result {
                case .success: continuation.resume()
                case .failure(let error): continuation.resume(throwing: error)
                }
            }
        }
    }

    func fetchOutcomes(query: OCKOutcomeQuery) async throws -> [OCKOutcome] {
        try await withCheckedThrowingContinuation { continuation in
            fetchOutcomes(query: query) { result in
                continuation.resume(with: result)
            }
        }
    }
}
