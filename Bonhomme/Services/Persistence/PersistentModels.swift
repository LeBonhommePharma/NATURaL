import Foundation
import SwiftData
import SwiftUI
import Observation
import BonhommeCore

// MARK: - Workout Record

/// Persisted on-device workout history in SwiftData.
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
    var yogaStyleRaw: String?

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
        sciScore: Double?,
        yogaStyleRaw: String? = nil
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
        self.yogaStyleRaw = yogaStyleRaw
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
            sciScore: sciScore,
            yogaStyleRaw: result.yogaStyle.rawValue
        )
    }

    /// Resolved YogaStyle from the persisted raw string.
    var yogaStyle: YogaStyle? {
        guard let raw = yogaStyleRaw else { return nil }
        return YogaStyle(rawValue: raw)
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

/// On-device user preferences.
@Model
final class UserPreferences {
    var preferredLanguage: String?
    var musicMoodPreference: String?
    var notificationsEnabled: Bool = false
    var dailyReminderHour: Int = 8
    var dailyReminderMinute: Int = 0
    var adaptiveMusicEnabled: Bool = true
    var showSCIVisualization: Bool = true

    // MARK: Clinical / medication consent (mirror of ConsentStore)
    // Authoritative gate is ConsentStore (UserDefaults); these fields support
    // local UI binding when a ModelContext is available.

    /// Whether the user explicitly opted in to clinical medication reads.
    var clinicalMedicationConsentGranted: Bool = false
    /// ISO-8601 or absolute date of last grant (nil if never granted).
    var clinicalMedicationConsentGrantedAt: Date?
    /// Date of last revoke (nil if currently granted or never granted).
    var clinicalMedicationConsentRevokedAt: Date?
    /// Policy version accepted at last grant (must match ClinicalConsent.currentPolicyVersion).
    var clinicalMedicationConsentPolicyVersion: String?

    init() {}

    /// Resolved WorkoutMood from the persisted string preference.
    var resolvedMusicMood: MusicService.WorkoutMood {
        guard let raw = musicMoodPreference,
              let mood = MusicService.WorkoutMood(rawValue: raw) else {
            return .calm
        }
        return mood
    }

    /// Mirrors a `ClinicalConsent` snapshot into SwiftData preferences.
    func applyClinicalConsent(_ consent: ClinicalConsent) {
        clinicalMedicationConsentGranted = consent.isGranted
        clinicalMedicationConsentGrantedAt = consent.grantedAt
        clinicalMedicationConsentRevokedAt = consent.revokedAt
        clinicalMedicationConsentPolicyVersion = consent.policyVersion
    }
}

// MARK: - Session Streak

/// Tracks daily practice streaks on this device.
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

/// User-defined medication reminders stored on this device.
/// Complements HealthKit clinical records with user-managed schedules.
@Model
final class MedicationSchedule {
    var medicationId: String
    var name: String
    var doseValue: Double
    var doseUnit: String
    /// Stored as comma-separated String because SwiftData on iOS 17 cannot
    /// persist [Int] natively — schema validation fails even for in-memory
    /// containers, which is the true cause of the fatal ModelContainer crash.
    var scheduledHoursRaw: String = ""

    /// Public accessor — unchanged API surface for all call sites.
    var scheduledHours: [Int] {
        get { scheduledHoursRaw.split(separator: ",").compactMap { Int($0.trimmingCharacters(in: .whitespaces)) } }
        set { scheduledHoursRaw = newValue.map(String.init).joined(separator: ",") }
    }
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
        self.scheduledHoursRaw = scheduledHours.map(String.init).joined(separator: ",")
        self.createdAt = Date()
        self.notes = notes
    }

    /// Human-readable dose string (e.g., "100 mg").
    var formattedDose: String {
        guard doseValue.isFinite, doseValue >= 0 else { return "—" }
        let doseStr = Int(exactly: doseValue).map(String.init) ?? String(doseValue)
        return doseUnit.isEmpty ? doseStr : "\(doseStr) \(doseUnit)"
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

// MARK: - Drug Response Record

/// Persisted result from DrugResponseAnalyzer analysis around a medication dose event.
/// Stores the key metrics for historical trend tracking and dose-response curves.
@Model
final class DrugResponseRecord {
    var medicationId: String
    var medicationName: String
    var doseValue: Double
    var doseUnit: String
    var doseTimestamp: Date
    var baselineEntropy: Double
    var peakDeltaH: Double
    var peakTimeMinutes: Double
    /// ResponseDirection raw value (SwiftData requires a primitive stored type).
    var responseDirection: String
    var effectSize: Double
    var deltaHAUC: Double
    var bindingDetected: Bool
    var profileMatchId: String?
    var profileMatchConfidence: Double?
    var analysisDate: Date

    init(
        medicationId: String,
        medicationName: String,
        doseValue: Double,
        doseUnit: String,
        doseTimestamp: Date,
        baselineEntropy: Double,
        peakDeltaH: Double,
        peakTimeMinutes: Double,
        responseDirection: String,
        effectSize: Double,
        deltaHAUC: Double,
        bindingDetected: Bool,
        profileMatchId: String? = nil,
        profileMatchConfidence: Double? = nil,
        analysisDate: Date = Date()
    ) {
        self.medicationId = medicationId
        self.medicationName = medicationName
        self.doseValue = doseValue
        self.doseUnit = doseUnit
        self.doseTimestamp = doseTimestamp
        self.baselineEntropy = baselineEntropy
        self.peakDeltaH = peakDeltaH
        self.peakTimeMinutes = peakTimeMinutes
        self.responseDirection = responseDirection
        self.effectSize = effectSize
        self.deltaHAUC = deltaHAUC
        self.bindingDetected = bindingDetected
        self.profileMatchId = profileMatchId
        self.profileMatchConfidence = profileMatchConfidence
        self.analysisDate = analysisDate
    }

    /// Human-readable ΔH string with direction indicator.
    var formattedDeltaH: String {
        let arrow = peakDeltaH < 0 ? "↓" : (peakDeltaH > 0 ? "↑" : "→")
        return String(format: "%+.2f bits %@", peakDeltaH, arrow)
    }
}

// MARK: - Persistence Mode & Storage Status

/// How SwiftData is hosting app data after ModelContainer initialization.
enum PersistenceStorageMode: String, Sendable, Equatable, CaseIterable {
    /// Durable on-device store. This is the shipping mode; analysis never leaves the device.
    case localOnly
    /// In-memory only — not durable across app launches.
    case ephemeral
}

/// Result of the local → memory ModelContainer bootstrap.
struct PersistenceBootstrap {
    let container: ModelContainer
    let mode: PersistenceStorageMode
    /// Underlying error from a failed local store, if any.
    let underlyingErrorDescription: String?
}

/// Observable on-device storage status. Local storage is the intended product,
/// not a fallback from iCloud. The banner is only for ephemeral/unusable disk.
@Observable
@MainActor
final class PersistenceSyncStatus {
    private(set) var mode: PersistenceStorageMode = .localOnly
    private(set) var underlyingErrorDescription: String?
    private(set) var isRetrying = false
    /// User-facing result of the last Retry attempt (success path recommends restart).
    private(set) var retryFeedback: String?
    /// True when retry proved local storage can open but the live container was not swapped mid-session.
    private(set) var restartRecommended = false
    /// User dismissed the home banner; settings card can still show status.
    var isBannerDismissed = false

    var needsAttention: Bool { mode == .ephemeral || underlyingErrorDescription != nil }

    var shouldShowBanner: Bool { needsAttention && !isBannerDismissed }

    func apply(mode: PersistenceStorageMode, errorDescription: String?) {
        self.mode = mode
        self.underlyingErrorDescription = errorDescription
        if mode == .localOnly && errorDescription == nil {
            retryFeedback = nil
            restartRecommended = false
        }
    }

    func apply(_ bootstrap: PersistenceBootstrap) {
        apply(mode: bootstrap.mode, errorDescription: bootstrap.underlyingErrorDescription)
    }

    func dismissBanner() {
        isBannerDismissed = true
    }

    // MARK: User-facing copy (EN / FR-CA via LocalizedString)

    var bannerTitle: String {
        switch mode {
        case .localOnly:
            return LocalizedString(
                en: "On this device",
                fr: "Sur cet appareil"
            ).localized
        case .ephemeral:
            return LocalizedString(
                en: "Temporary storage only",
                fr: "Stockage temporaire uniquement"
            ).localized
        }
    }

    var bannerMessage: String {
        switch mode {
        case .localOnly:
            return LocalizedString(
                en: "Your records stay on this device. Analysis runs locally. NATURaL does not collect or receive them.",
                fr: "Vos dossiers restent sur cet appareil. L’analyse s’exécute localement. NATURaL ne les collecte pas et ne les reçoit pas."
            ).localized
        case .ephemeral:
            return LocalizedString(
                en: "This session uses temporary memory storage. New entries may not remain after you quit. Existing on-device files were not removed.",
                fr: "Cette session utilise une mémoire temporaire. Les nouvelles entrées peuvent ne pas rester après la fermeture. Les fichiers déjà sur l'appareil n'ont pas été effacés."
            ).localized
        }
    }

    var settingsDetail: String {
        switch mode {
        case .localOnly:
            return LocalizedString(
                en: "Health, medication and session records stay on this device. We do not collect them.",
                fr: "Les dossiers de santé, de médicaments et de séances restent sur cet appareil. Nous ne les collectons pas."
            ).localized
        case .ephemeral:
            return LocalizedString(
                en: "Temporary memory storage. Free disk space, then retry and reopen the app.",
                fr: "Stockage temporaire. Libérez de l’espace, puis réessayez et rouvrez l’app."
            ).localized
        }
    }

    var systemImageName: String {
        switch mode {
        case .localOnly: return "lock.iphone"
        case .ephemeral: return "exclamationmark.triangle.fill"
        }
    }

    var accentColor: Color {
        switch mode {
        case .localOnly: return .mint
        case .ephemeral: return .red
        }
    }

    /// Tests local storage without swapping the live container during a workout.
    func retryLocalStorage() async {
        guard !isRetrying else { return }
        isRetrying = true
        defer { isRetrying = false }
        do {
            _ = try PersistenceConfiguration.makeLocalContainer()
            restartRecommended = true
            retryFeedback = LocalizedString(en: "Local storage is available. Reopen NATURaL after finishing this session.", fr: "Le stockage local est disponible. Rouvrez NATURaL après cette séance.").localized
        } catch {
            retryFeedback = LocalizedString(en: "Storage is still unavailable. Check available space and try again. Existing files have not been removed.", fr: "Le stockage reste indisponible. Vérifiez l’espace disponible et réessayez. Les fichiers existants n’ont pas été supprimés.").localized
        }
    }
}

// MARK: - Model Container Configuration

/// Creates the on-device health-data ModelContainer for the NATURaL app.
/// Shipping path: durable local storage, then visible in-memory fallback. Never CloudKit.
enum PersistenceConfiguration {
    static let storeName = "NATURaL"
    static let sharedStoreName = "NATURaLShared"

    static func makeSchema() -> Schema {
        Schema([
            WorkoutRecord.self,
            UserPreferences.self,
            SessionStreak.self,
            MedicationSchedule.self,
            DrugResponseRecord.self,
        ])
    }

    /// Health records and recovery snapshots must not enter device backups.
    /// Exclude their containing directories, including future SQLite WAL and preferences files.
    /// The named store is preserved; this does not move or delete existing records.
    static func protectLocalHealthStorage() throws {
        let files = FileManager.default
        let library = try files.url(for: .libraryDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
        var directories = [
            library.appendingPathComponent("Application Support", isDirectory: true),
            library.appendingPathComponent("Preferences", isDirectory: true),
            try files.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
        ]
        if let group = files.containerURL(forSecurityApplicationGroupIdentifier: "group.com.natural.Bonhomme") {
            directories.append(group)
        }
        for var directory in directories {
            try files.createDirectory(at: directory, withIntermediateDirectories: true)
            var values = URLResourceValues()
            values.isExcludedFromBackup = true
            try directory.setResourceValues(values)
            try files.setAttributes([.protectionKey: FileProtectionType.completeUntilFirstUserAuthentication], ofItemAtPath: directory.path)
        }
    }

    /// Durable on-device store. Analysis never leaves this container.
    static func makeLocalContainer(schema: Schema? = nil) throws -> ModelContainer {
        try protectLocalHealthStorage()
        let schema = schema ?? makeSchema()
        let config = ModelConfiguration(
            storeName,
            schema: schema,
            cloudKitDatabase: .none
        )
        return try ModelContainer(for: schema, configurations: [config])
    }

    /// Ephemeral in-memory container (session-only).
    static func makeEphemeralContainer(schema: Schema? = nil) throws -> ModelContainer {
        let schema = schema ?? makeSchema()
        let config = ModelConfiguration(
            schema: schema,
            isStoredInMemoryOnly: true
        )
        return try ModelContainer(for: schema, configurations: [config])
    }

    /// Preferred app entry: never leaves the caller without a container when any tier works.
    static func bootstrap() -> PersistenceBootstrap {
        let schema = makeSchema()

        do {
            return PersistenceBootstrap(container: try makeLocalContainer(schema: schema), mode: .localOnly, underlyingErrorDescription: nil)
        } catch {
            let localError = error
            do {
                return PersistenceBootstrap(container: try makeEphemeralContainer(schema: schema), mode: .ephemeral, underlyingErrorDescription: localError.localizedDescription)
            } catch {
                // An unusable model schema is a programming error, not a recoverable disk failure.
                fatalError("Unable to create even an in-memory model container: \(error.localizedDescription)")
            }
        }
    }

    /// Backward-compatible entry point for the on-device bootstrap.
    static func makeContainer() throws -> ModelContainer {
        bootstrap().container
    }

    /// Shared app group container for widget access on this device only.
    static func makeSharedContainer() throws -> ModelContainer {
        let schema = Schema([
            WorkoutRecord.self,
            SessionStreak.self,
        ])

        let config = ModelConfiguration(
            sharedStoreName,
            schema: schema,
            cloudKitDatabase: .none
        )

        return try ModelContainer(for: schema, configurations: [config])
    }
}
