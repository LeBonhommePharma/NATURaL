import Foundation
import SwiftData
import BonhommeCore

// MARK: - Workout Record

/// Persisted workout history with CloudKit sync via SwiftData.
/// Each completed workout is saved here for offline access and cross-device sync.
@Model
final class WorkoutRecord {
    var planId: String
    var planName: String
    var startDate: Date
    var endDate: Date
    var totalDuration: TimeInterval
    var posesCompleted: Int
    var totalPoses: Int
    var activeCalories: Double
    var averageHeartRate: Double?
    var maxHeartRate: Double?
    var sciScore: Double?

    init(
        planId: String,
        planName: String,
        startDate: Date,
        endDate: Date,
        totalDuration: TimeInterval,
        posesCompleted: Int,
        totalPoses: Int,
        activeCalories: Double,
        averageHeartRate: Double?,
        maxHeartRate: Double?,
        sciScore: Double?
    ) {
        self.planId = planId
        self.planName = planName
        self.startDate = startDate
        self.endDate = endDate
        self.totalDuration = totalDuration
        self.posesCompleted = posesCompleted
        self.totalPoses = totalPoses
        self.activeCalories = activeCalories
        self.averageHeartRate = averageHeartRate
        self.maxHeartRate = maxHeartRate
        self.sciScore = sciScore
    }

    /// Creates a WorkoutRecord from a WorkoutResult and optional final SCI score.
    convenience init(from result: WorkoutResult, sciScore: Double?) {
        self.init(
            planId: result.workoutPlanId,
            planName: result.workoutPlanName,
            startDate: result.startDate,
            endDate: result.endDate,
            totalDuration: result.totalDuration,
            posesCompleted: result.posesCompleted,
            totalPoses: result.totalPoses,
            activeCalories: result.activeCalories,
            averageHeartRate: result.averageHeartRate,
            maxHeartRate: result.maxHeartRate,
            sciScore: sciScore
        )
    }

    /// Formatted duration string (e.g., "12m 30s").
    var formattedDuration: String {
        let minutes = Int(totalDuration) / 60
        let seconds = Int(totalDuration) % 60
        return seconds > 0 ? "\(minutes)m \(seconds)s" : "\(minutes)m"
    }

    /// Completion percentage (poses completed / total).
    var completionRate: Double {
        guard totalPoses > 0 else { return 0 }
        return Double(posesCompleted) / Double(totalPoses)
    }
}

// MARK: - User Preferences

/// User preferences synced across devices via CloudKit.
@Model
final class UserPreferences {
    var preferredLanguage: String?
    var musicMoodPreference: String?
    var notificationsEnabled: Bool = false
    var dailyReminderHour: Int = 8
    var dailyReminderMinute: Int = 0
    var adaptiveMusicEnabled: Bool = true
    var showSCIVisualization: Bool = true

    init() {}

    /// Resolved WorkoutMood from the persisted string preference.
    var resolvedMusicMood: MusicService.WorkoutMood {
        guard let raw = musicMoodPreference,
              let mood = MusicService.WorkoutMood(rawValue: raw) else {
            return .calm
        }
        return mood
    }
}

// MARK: - Session Streak

/// Tracks daily practice streaks synced via CloudKit.
@Model
final class SessionStreak {
    var currentStreak: Int = 0
    var longestStreak: Int = 0
    var lastSessionDate: Date?
    var totalSessions: Int = 0

    init() {}

    /// Records a completed session and updates streak counters.
    /// Call this after each workout completion.
    func recordSession(date: Date = Date()) {
        totalSessions += 1

        let calendar = Calendar.current
        if let lastDate = lastSessionDate {
            let daysBetween = calendar.dateComponents([.day], from: calendar.startOfDay(for: lastDate), to: calendar.startOfDay(for: date)).day ?? 0

            if daysBetween == 1 {
                // Consecutive day — extend streak
                currentStreak += 1
            } else if daysBetween > 1 {
                // Streak broken — reset
                currentStreak = 1
            }
            // daysBetween == 0: same day, don't change streak
        } else {
            // First ever session
            currentStreak = 1
        }

        longestStreak = max(longestStreak, currentStreak)
        lastSessionDate = date
    }

    /// Returns true if the user has practiced today.
    var practicedToday: Bool {
        guard let lastDate = lastSessionDate else { return false }
        return Calendar.current.isDateInToday(lastDate)
    }

    /// Returns true if the streak is at risk (last session was yesterday).
    var streakAtRisk: Bool {
        guard let lastDate = lastSessionDate else { return false }
        return Calendar.current.isDateInYesterday(lastDate)
    }
}

// MARK: - Medication Schedule

/// User-defined medication reminders, synced via CloudKit.
/// Complements HealthKit clinical records with user-managed schedules.
@Model
final class MedicationSchedule {
    var medicationId: String
    var name: String
    var doseValue: Double
    var doseUnit: String
    var scheduledHours: [Int]
    var isActive: Bool = true
    var createdAt: Date
    var notes: String?

    init(
        medicationId: String,
        name: String,
        doseValue: Double,
        doseUnit: String,
        scheduledHours: [Int],
        notes: String? = nil
    ) {
        self.medicationId = medicationId
        self.name = name
        self.doseValue = doseValue
        self.doseUnit = doseUnit
        self.scheduledHours = scheduledHours
        self.createdAt = Date()
        self.notes = notes
    }

    /// Human-readable dose string (e.g., "100 mg").
    var formattedDose: String {
        let intDose = Int(doseValue)
        let doseStr = doseValue == Double(intDose) ? "\(intDose)" : String(format: "%.1f", doseValue)
        return "\(doseStr) \(doseUnit)"
    }

    /// Human-readable schedule (e.g., "8:00 AM, 8:00 PM").
    var formattedSchedule: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "h:00 a"
        return scheduledHours.map { hour -> String in
            var components = DateComponents()
            components.hour = hour
            let date = Calendar.current.date(from: components) ?? Date()
            return formatter.string(from: date)
        }.joined(separator: ", ")
    }

    /// Returns the next scheduled dose time from now.
    var nextDoseTime: Date? {
        let calendar = Calendar.current
        let now = Date()
        let currentHour = calendar.component(.hour, from: now)

        // Find next scheduled hour today or tomorrow
        if let nextHour = scheduledHours.sorted().first(where: { $0 > currentHour }) {
            var components = calendar.dateComponents([.year, .month, .day], from: now)
            components.hour = nextHour
            components.minute = 0
            return calendar.date(from: components)
        }

        // No more doses today — next is first dose tomorrow
        if let firstHour = scheduledHours.sorted().first,
           let tomorrow = calendar.date(byAdding: .day, value: 1, to: now) {
            var components = calendar.dateComponents([.year, .month, .day], from: tomorrow)
            components.hour = firstHour
            components.minute = 0
            return calendar.date(from: components)
        }

        return nil
    }
}

// MARK: - Model Container Configuration

/// Creates the shared ModelContainer with CloudKit sync for the NATURaL app.
/// Use `ModelConfiguration(cloudKitDatabase: .automatic)` for iCloud sync.
enum PersistenceConfiguration {
    static func makeContainer() throws -> ModelContainer {
        let schema = Schema([
            WorkoutRecord.self,
            UserPreferences.self,
            SessionStreak.self,
            MedicationSchedule.self,
        ])

        let config = ModelConfiguration(
            "NATURaL",
            schema: schema,
            cloudKitDatabase: .automatic
        )

        return try ModelContainer(for: schema, configurations: [config])
    }

    /// Shared app group container for widget access.
    static func makeSharedContainer() throws -> ModelContainer {
        let schema = Schema([
            WorkoutRecord.self,
            SessionStreak.self,
        ])

        let config = ModelConfiguration(
            "NATURaLShared",
            schema: schema,
            groupContainer: .automatic,
            cloudKitDatabase: .automatic
        )

        return try ModelContainer(for: schema, configurations: [config])
    }
}
