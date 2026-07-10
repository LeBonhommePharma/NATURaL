import Foundation
import CareKitStore
import BonhommeCore

/// Converts between NATURaL's workout models and CareKit's task/outcome models.
/// Used by CareKitBridge to map therapist prescriptions to CareKit tasks
/// and workout results to CareKit outcomes.
enum YogaTaskBuilder {

    /// Prefix used to namespace NATURaL task IDs in the CareKit store.
    static let taskPrefix = "natural.yoga."
    static let groupIdentifier = "yoga"

    /// Generates a CareKit task ID from a workout plan ID.
    static func taskId(for planId: String) -> String {
        "\(taskPrefix)\(planId)"
    }

    /// Extracts the original workout plan ID from a CareKit task ID.
    static func planId(from taskId: String) -> String {
        String(taskId.dropFirst(taskPrefix.count))
    }

    /// Whether a CareKit task is a NATURaL yoga workout prescription.
    static func isYogaTask(_ task: OCKTask) -> Bool {
        task.groupIdentifier == groupIdentifier || task.id.hasPrefix(taskPrefix)
    }

    // MARK: - Task Building

    /// Creates an OCKTask from a WorkoutPlan with the specified schedule.
    ///
    /// - Parameters:
    ///   - plan: The workout plan to prescribe.
    ///   - frequency: Sessions per week (1-7).
    ///   - startDate: When the prescription begins.
    ///   - endDate: Optional end date for time-limited prescriptions.
    /// - Returns: A configured OCKTask ready for insertion into the CareKit store.
    static func buildTask(
        from plan: WorkoutPlan,
        frequency: Int,
        startDate: Date,
        endDate: Date?
    ) -> OCKTask {
        let schedule = buildSchedule(
            frequency: frequency,
            startDate: startDate,
            endDate: endDate
        )

        let duration = Int(plan.totalDuration) / 60
        let instructions = LocalizedString(
            en: "Complete the \(plan.name.en) session (\(plan.poseCount) poses, ~\(duration) min). "
                + "Focus on breathing and maintaining steady posture.",
            fr: "Complétez la séance \(plan.name.fr) (\(plan.poseCount) postures, ~\(duration) min). "
                + "Concentrez-vous sur la respiration et le maintien d'une posture stable."
        ).localized

        var task = OCKTask(
            id: taskId(for: plan.id),
            title: plan.name.localized,
            carePlanUUID: nil,
            schedule: schedule
        )
        task.instructions = instructions
        task.impactsAdherence = true
        task.groupIdentifier = groupIdentifier

        return task
    }

    /// Builds a CareKit schedule for the given frequency.
    /// Distributes sessions evenly across the week.
    private static func buildSchedule(
        frequency: Int,
        startDate: Date,
        endDate: Date?
    ) -> OCKSchedule {
        let clampedFrequency = max(1, min(7, frequency))

        // Distribute days evenly across the week
        let daySpacing = 7.0 / Double(clampedFrequency)
        var elements: [OCKScheduleElement] = []

        for i in 0..<clampedFrequency {
            let dayOffset = Int(Double(i) * daySpacing)
            let calendar = Calendar.current

            guard let elementStart = calendar.date(
                byAdding: .day,
                value: dayOffset,
                to: calendar.startOfDay(for: startDate)
            ) else { continue }

            // Set session time to 8:00 AM by default
            var components = calendar.dateComponents([.year, .month, .day], from: elementStart)
            components.hour = 8
            components.minute = 0
            guard let sessionDate = calendar.date(from: components) else { continue }

            let element = OCKScheduleElement(
                start: sessionDate,
                end: nil,
                interval: DateComponents(weekOfYear: 1),
                text: nil,
                targetValues: [],
                duration: .allDay
            )

            elements.append(element)
        }

        if elements.isEmpty {
            // Fallback: daily schedule
            elements = [OCKScheduleElement(
                start: startDate,
                end: endDate,
                interval: DateComponents(day: 1),
                text: nil,
                targetValues: [],
                duration: .allDay
            )]
        }

        return OCKSchedule(composing: elements)
    }

    // MARK: - Outcome Values

    /// Converts a WorkoutResult into CareKit outcome values for recording
    /// a completed session against the prescribed task.
    static func buildOutcomeValues(
        from result: WorkoutResult,
        sciScore: Double?
    ) -> [OCKOutcomeValue] {
        var values: [OCKOutcomeValue] = []

        // Duration in minutes
        var durationValue = OCKOutcomeValue(result.totalDuration / 60.0)
        durationValue.kind = "duration_minutes"
        values.append(durationValue)

        // Poses completed
        var posesValue = OCKOutcomeValue(Double(result.posesCompleted))
        posesValue.kind = "poses_completed"
        values.append(posesValue)

        // Total poses
        var totalPosesValue = OCKOutcomeValue(Double(result.totalPoses))
        totalPosesValue.kind = "total_poses"
        values.append(totalPosesValue)

        // Active calories
        var caloriesValue = OCKOutcomeValue(result.activeCalories)
        caloriesValue.kind = "active_calories"
        values.append(caloriesValue)

        // Average heart rate
        if let avgHR = result.averageHeartRate {
            var hrValue = OCKOutcomeValue(avgHR)
            hrValue.kind = "average_heart_rate"
            values.append(hrValue)
        }

        // Max heart rate
        if let maxHR = result.maxHeartRate {
            var maxHRValue = OCKOutcomeValue(maxHR)
            maxHRValue.kind = "max_heart_rate"
            values.append(maxHRValue)
        }

        // SCI focus score
        if let sci = sciScore {
            var sciValue = OCKOutcomeValue(sci)
            sciValue.kind = "sci_focus_score"
            values.append(sciValue)
        }

        // Completion rate
        let completionRate = result.totalPoses > 0
            ? Double(result.posesCompleted) / Double(result.totalPoses)
            : 0
        var completionValue = OCKOutcomeValue(completionRate)
        completionValue.kind = "completion_rate"
        values.append(completionValue)

        return values
    }

    /// Extracts a human-readable summary from CareKit outcome values.
    static func summarizeOutcome(_ values: [OCKOutcomeValue]) -> LocalizedString {
        let duration = values.first { $0.kind == "duration_minutes" }?.doubleValue ?? 0
        let poses = values.first { $0.kind == "poses_completed" }?.integerValue ?? 0
        let calories = values.first { $0.kind == "active_calories" }?.doubleValue ?? 0
        let sci = values.first { $0.kind == "sci_focus_score" }?.doubleValue

        let sciText = sci.map { String(format: ", focus %.0f%%", $0 * 100) } ?? ""

        return LocalizedString(
            en: "\(poses) poses in \(Int(duration))min, \(Int(calories)) cal\(sciText)",
            fr: "\(poses) postures en \(Int(duration))min, \(Int(calories)) cal\(sciText)"
        )
    }
}
