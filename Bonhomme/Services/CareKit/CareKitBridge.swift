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
///
/// Task namespaces:
/// - Yoga workouts: `natural.yoga.<planId>` (`groupIdentifier == "yoga"`)
/// - Medications: `natural.med.<medicationId>` (`groupIdentifier == "medication"`)
@MainActor
final class CareKitBridge: ObservableObject {
    @Published var prescribedTasks: [OCKTask] = []
    @Published var isLoaded = false

    private let store: OCKStore

    init(storeName: String = "NATURaLCareKit") {
        self.store = OCKStore(name: storeName)
    }

    // MARK: - Task classification

    /// Active yoga workout prescriptions only.
    var yogaPrescribedTasks: [OCKTask] {
        prescribedTasks.filter { YogaTaskBuilder.isYogaTask($0) }
    }

    /// Active medication prescriptions only.
    var medicationPrescribedTasks: [OCKTask] {
        prescribedTasks.filter { MedicationTaskBuilder.isMedicationTask($0) }
    }

    /// True when any CareKit task is active (yoga or medication).
    var hasPrescriptions: Bool {
        !prescribedTasks.isEmpty
    }

    /// True when at least one yoga workout is prescribed.
    var hasYogaPrescriptions: Bool {
        !yogaPrescribedTasks.isEmpty
    }

    /// True when at least one medication task is prescribed.
    var hasMedicationPrescriptions: Bool {
        !medicationPrescribedTasks.isEmpty
    }

    /// Whether a catalog workout plan is currently prescribed in CareKit.
    func isPlanPrescribed(_ planId: String) -> Bool {
        let taskId = YogaTaskBuilder.taskId(for: planId)
        return yogaPrescribedTasks.contains { $0.id == taskId }
    }

    /// Whether a medication has an active CareKit task.
    func isMedicationPrescribed(_ medicationId: String) -> Bool {
        let taskId = MedicationTaskBuilder.taskId(for: medicationId)
        return medicationPrescribedTasks.contains { $0.id == taskId }
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
                existing.title = task.title
                existing.groupIdentifier = task.groupIdentifier
                existing.impactsAdherence = task.impactsAdherence
                try await store.updateTask(existing)
            } catch {
                // Task doesn't exist yet — add it
                try await store.addTask(task)
            }
        }

        await refreshPrescribedTasks()
    }

    /// Records a completed workout as a CareKit outcome against the prescribed task.
    /// No-ops (without throwing) when the plan is not currently prescribed.
    ///
    /// - Parameters:
    ///   - planId: The workout plan ID (matches the OCKTask ID suffix).
    ///   - result: The workout result containing duration, poses, calories, etc.
    ///   - sciScore: The final SCI score at workout completion.
    func recordCompletion(
        planId: String,
        result: WorkoutResult,
        sciScore: Double?
    ) async throws {
        let taskId = YogaTaskBuilder.taskId(for: planId)

        let task: OCKTask
        do {
            task = try await store.fetchTask(withID: taskId)
        } catch {
            // Plan is not prescribed — nothing to record
            return
        }

        let outcomeValues = YogaTaskBuilder.buildOutcomeValues(
            from: result,
            sciScore: sciScore
        )

        try await addOutcomeIfNeeded(
            for: task,
            values: outcomeValues,
            at: result.endDate
        )
    }

    /// Records a medication dose event as a CareKit outcome for adherence.
    /// Call when the user marks a dose taken (or late). Missed/skipped do not
    /// write completion outcomes (they are non-adherence signals in-app only).
    ///
    /// - Parameters:
    ///   - medicationId: Stable medication identifier (matches CareKit task suffix).
    ///   - doseValue: Dose amount.
    ///   - doseUnit: Dose unit string.
    ///   - event: Taken / late (others are ignored for CareKit outcomes).
    ///   - at: Event timestamp (defaults to now).
    func recordMedicationDose(
        medicationId: String,
        doseValue: Double,
        doseUnit: String,
        event: MedicationEvent = .taken,
        at date: Date = Date()
    ) async throws {
        guard event == .taken || event == .late else { return }

        let taskId = MedicationTaskBuilder.taskId(for: medicationId)
        let task: OCKTask
        do {
            task = try await store.fetchTask(withID: taskId)
        } catch {
            // Medication not synced to CareKit yet
            return
        }

        let values = MedicationTaskBuilder.buildOutcomeValues(
            doseValue: doseValue,
            doseUnit: doseUnit,
            event: event,
            at: date
        )

        try await addOutcomeIfNeeded(for: task, values: values, at: date)
    }

    /// Calculates adherence percentage for a specific prescribed yoga plan
    /// over the last N days.
    ///
    /// - Parameters:
    ///   - planId: The workout plan ID.
    ///   - days: Number of days to look back (default 30).
    /// - Returns: Adherence as a 0.0–1.0 fraction.
    func fetchAdherence(for planId: String, days: Int = 30) async throws -> Double {
        let taskId = YogaTaskBuilder.taskId(for: planId)
        return try await fetchAdherence(taskId: taskId, days: days)
    }

    /// Calculates adherence for a medication CareKit task over the last N days.
    func fetchMedicationAdherence(for medicationId: String, days: Int = 30) async throws -> Double {
        let taskId = MedicationTaskBuilder.taskId(for: medicationId)
        return try await fetchAdherence(taskId: taskId, days: days)
    }

    /// Fetches all active prescribed tasks from the CareKit store.
    /// Independent of HealthKit — CareKit uses a local OCKStore.
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
        guard YogaTaskBuilder.isYogaTask(task) else { return nil }
        let planId = YogaTaskBuilder.planId(from: task.id)
        return PoseCatalog.allPlans.first { $0.id == planId }
    }

    /// Removes a prescribed yoga task (e.g., when therapist cancels the prescription).
    func removePrescription(planId: String) async throws {
        let taskId = YogaTaskBuilder.taskId(for: planId)
        let task = try await store.fetchTask(withID: taskId)
        try await store.deleteTask(task)
        await refreshPrescribedTasks()
    }

    // MARK: - Medication Prescriptions (consent-gated caller)

    /// Syncs user-managed medication prescriptions into CareKit as daily tasks.
    /// Call only after explicit clinical/medication consent.
    /// Does not invent pharmacy credentials — titles/doses come from HealthKit clinical
    /// import or user manual entry only.
    func syncMedicationPrescriptions(_ medications: [MedicationPrescriptionSummary]) async throws {
        let desiredIds = Set(medications.map { MedicationTaskBuilder.taskId(for: $0.id) })

        for med in medications {
            let task = MedicationTaskBuilder.buildTask(from: med)
            do {
                var existing = try await store.fetchTask(withID: task.id)
                existing.effectiveDate = Date()
                existing.schedule = task.schedule
                existing.instructions = task.instructions
                existing.title = task.title
                existing.groupIdentifier = task.groupIdentifier
                existing.impactsAdherence = task.impactsAdherence
                try await store.updateTask(existing)
            } catch {
                try await store.addTask(task)
            }
        }

        // Drop CareKit med tasks no longer present in the user-managed list
        for task in medicationPrescribedTasks where !desiredIds.contains(task.id) {
            try? await store.deleteTask(task)
        }

        await refreshPrescribedTasks()
    }

    /// Removes a CareKit medication task by medication id.
    func removeMedicationPrescription(medicationId: String) async throws {
        let taskId = MedicationTaskBuilder.taskId(for: medicationId)
        let task = try await store.fetchTask(withID: taskId)
        try await store.deleteTask(task)
        await refreshPrescribedTasks()
    }

    // MARK: - Private helpers

    private func fetchAdherence(taskId: String, days: Int) async throws -> Double {
        let task = try await store.fetchTask(withID: taskId)

        let calendar = Calendar.current
        let endDate = Date()
        guard let startDate = calendar.date(byAdding: .day, value: -days, to: endDate) else {
            return 0
        }

        let scheduledEvents = task.schedule.events(from: startDate, to: endDate)
        let totalScheduled = scheduledEvents.count
        guard totalScheduled > 0 else { return 0 }

        var query = OCKOutcomeQuery(dateInterval: DateInterval(start: startDate, end: endDate))
        query.taskIDs = [task.id]
        let outcomes = try await store.fetchOutcomes(query: query)
        let completedCount = outcomes.filter { $0.taskUUID == task.uuid }.count

        return min(1.0, Double(completedCount) / Double(totalScheduled))
    }

    /// Adds an outcome for today's (or nearest) schedule occurrence if one
    /// does not already exist for that occurrence index.
    private func addOutcomeIfNeeded(
        for task: OCKTask,
        values: [OCKOutcomeValue],
        at date: Date
    ) async throws {
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: date)
        guard let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay) else {
            return
        }

        let dayEvents = task.schedule.events(from: startOfDay, to: endOfDay)
        let occurrenceIndex: Int
        if let nearest = dayEvents.min(by: {
            abs($0.start.timeIntervalSince(date)) < abs($1.start.timeIntervalSince(date))
        }) {
            occurrenceIndex = nearest.occurrence
        } else {
            // No event scheduled today — still record against occurrence 0 so
            // therapists see activity outside the strict schedule window.
            occurrenceIndex = 0
        }

        // Skip if an outcome already exists for this occurrence
        var existingQuery = OCKOutcomeQuery(dateInterval: DateInterval(start: startOfDay, end: endOfDay))
        existingQuery.taskIDs = [task.id]
        if let existing = try? await store.fetchOutcomes(query: existingQuery),
           existing.contains(where: {
               $0.taskUUID == task.uuid && $0.taskOccurrenceIndex == occurrenceIndex
           }) {
            return
        }

        let outcome = OCKOutcome(
            taskUUID: task.uuid,
            taskOccurrenceIndex: occurrenceIndex,
            values: values
        )

        do {
            try await store.addOutcome(outcome)
        } catch {
            // Duplicate or store conflict — treat as already recorded
        }
    }
}

// MARK: - Medication CareKit Task Builder

/// Maps user-managed medication prescriptions to CareKit tasks.
/// Separate from yoga prescriptions (`YogaTaskBuilder`).
enum MedicationTaskBuilder {
    static let taskPrefix = "natural.med."
    static let groupIdentifier = "medication"

    static func taskId(for medicationId: String) -> String {
        "\(taskPrefix)\(medicationId)"
    }

    static func medicationId(from taskId: String) -> String {
        String(taskId.dropFirst(taskPrefix.count))
    }

    static func isMedicationTask(_ task: OCKTask) -> Bool {
        task.groupIdentifier == groupIdentifier || task.id.hasPrefix(taskPrefix)
    }

    static func buildTask(from summary: MedicationPrescriptionSummary) -> OCKTask {
        let schedule = buildSchedule(hours: summary.scheduledHours)
        let doseLine = summary.doseDescription.isEmpty || summary.doseDescription == "—"
            ? ""
            : " Dose: \(summary.doseDescription)."

        var task = OCKTask(
            id: taskId(for: summary.id),
            title: summary.title,
            carePlanUUID: nil,
            schedule: schedule
        )
        task.instructions = summary.instructions + doseLine
            + " User-managed — confirm with your clinician. Not medical advice."
        task.impactsAdherence = true
        task.groupIdentifier = groupIdentifier
        return task
    }

    /// Outcome values for a logged dose (adherence completion).
    static func buildOutcomeValues(
        doseValue: Double,
        doseUnit: String,
        event: MedicationEvent,
        at date: Date
    ) -> [OCKOutcomeValue] {
        var values: [OCKOutcomeValue] = []

        var taken = OCKOutcomeValue(true)
        taken.kind = "dose_taken"
        values.append(taken)

        var dose = OCKOutcomeValue(doseValue)
        dose.kind = "dose_value"
        values.append(dose)

        var unit = OCKOutcomeValue(doseUnit)
        unit.kind = "dose_unit"
        values.append(unit)

        var eventKind = OCKOutcomeValue(event.rawValue)
        eventKind.kind = "medication_event"
        values.append(eventKind)

        var timestamp = OCKOutcomeValue(date.timeIntervalSince1970)
        timestamp.kind = "logged_at"
        values.append(timestamp)

        return values
    }

    private static func buildSchedule(hours: [Int]) -> OCKSchedule {
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: Date())
        let activeHours = hours.isEmpty ? [8] : hours.sorted()

        var elements: [OCKScheduleElement] = []
        for hour in activeHours {
            var components = calendar.dateComponents([.year, .month, .day], from: startOfDay)
            components.hour = hour
            components.minute = 0
            guard let date = calendar.date(from: components) else { continue }
            elements.append(
                OCKScheduleElement(
                    start: date,
                    end: nil,
                    interval: DateComponents(day: 1),
                    text: nil,
                    targetValues: []
                )
            )
        }

        if elements.isEmpty {
            elements = [
                OCKScheduleElement(
                    start: startOfDay,
                    end: nil,
                    interval: DateComponents(day: 1),
                    text: nil,
                    targetValues: []
                )
            ]
        }

        return OCKSchedule(composing: elements)
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
