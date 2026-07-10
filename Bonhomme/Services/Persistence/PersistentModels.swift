import Foundation
import SwiftData
import SwiftUI
import Observation
import BonhommeCore
#if canImport(CloudKit)
import CloudKit
#endif

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

    // MARK: Clinical / medication consent (mirror of ConsentStore)
    // Authoritative gate is ConsentStore (UserDefaults); these fields support
    // CloudKit-visible preference sync and UI binding when a ModelContext is available.

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
    /// ResponseDirection raw value (CloudKit requires primitive types).
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

// MARK: - Persistence Mode & Sync Status

/// How SwiftData is hosting app data after ModelContainer initialization.
/// Used for user-visible CloudKit fallback / conflict messaging.
enum PersistenceStorageMode: String, Sendable, Equatable, CaseIterable {
    /// SwiftData + CloudKit iCloud sync is active.
    case cloudKitSynced
    /// On-device durable store; iCloud sync is not active this session.
    case localOnly
    /// In-memory only — not durable across app launches.
    case ephemeral
}

/// Result of the three-tier ModelContainer bootstrap (CloudKit → local → memory).
struct PersistenceBootstrap {
    let container: ModelContainer
    let mode: PersistenceStorageMode
    /// Underlying error from a failed higher tier (CloudKit and/or local), if any.
    let underlyingErrorDescription: String?
}

/// Observable CloudKit / storage status for banners and settings copy.
/// Messaging deliberately avoids silent-data-loss claims: we state what is
/// available (on-device vs temporary) without asserting that data vanished.
@Observable
@MainActor
final class PersistenceSyncStatus {
    private(set) var mode: PersistenceStorageMode = .localOnly
    private(set) var underlyingErrorDescription: String?
    private(set) var isRetrying = false
    /// User-facing result of the last Retry attempt (success path recommends restart).
    private(set) var retryFeedback: String?
    /// True when retry proved CloudKit can open but the live container was not swapped mid-session.
    private(set) var restartRecommended = false
    /// User dismissed the home banner; settings card can still show status.
    var isBannerDismissed = false

    var needsAttention: Bool { mode != .cloudKitSynced }

    var shouldShowBanner: Bool { needsAttention && !isBannerDismissed }

    func apply(mode: PersistenceStorageMode, errorDescription: String?) {
        self.mode = mode
        self.underlyingErrorDescription = errorDescription
        if mode == .cloudKitSynced {
            isBannerDismissed = true
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
        case .cloudKitSynced:
            return LocalizedString(en: "iCloud sync on", fr: "Sync iCloud activée").localized
        case .localOnly:
            return LocalizedString(
                en: "iCloud sync unavailable",
                fr: "Sync iCloud indisponible"
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
        case .cloudKitSynced:
            return LocalizedString(
                en: "Workouts and preferences sync across your devices with iCloud.",
                fr: "Les séances et préférences se synchronisent sur vos appareils via iCloud."
            ).localized
        case .localOnly:
            return LocalizedString(
                en: "Your data stays on this device. Cross-device iCloud sync is not active right now — nothing was silently discarded.",
                fr: "Vos données restent sur cet appareil. La sync iCloud multi-appareils n'est pas active — rien n'a été supprimé en silence."
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
        case .cloudKitSynced:
            return LocalizedString(
                en: "CloudKit sync active for history, streaks, and preferences.",
                fr: "Sync CloudKit active pour l'historique, les séries et les préférences."
            ).localized
        case .localOnly:
            return LocalizedString(
                en: "Local-only mode. Sign into iCloud and use Retry, then reopen the app if prompted.",
                fr: "Mode local uniquement. Connectez-vous à iCloud, réessayez, puis rouvrez l'app si demandé."
            ).localized
        case .ephemeral:
            return LocalizedString(
                en: "In-memory fallback. Free disk space or fix iCloud, then Retry / reopen the app.",
                fr: "Repli en mémoire. Libérez de l'espace ou corrigez iCloud, puis Réessayer / rouvrir l'app."
            ).localized
        }
    }

    var systemImageName: String {
        switch mode {
        case .cloudKitSynced: return "checkmark.icloud.fill"
        case .localOnly: return "icloud.slash"
        case .ephemeral: return "exclamationmark.triangle.fill"
        }
    }

    var accentColor: Color {
        switch mode {
        case .cloudKitSynced: return .green
        case .localOnly: return .orange
        case .ephemeral: return .red
        }
    }

    /// Attempts to open a CloudKit-backed container without replacing the live store mid-session.
    /// On success, recommends restart so the next launch can adopt CloudKit safely.
    func retryCloudKitConnection() async {
        guard !isRetrying else { return }
        isRetrying = true
        retryFeedback = nil
        restartRecommended = false
        defer { isRetrying = false }

        #if canImport(CloudKit)
        do {
            let account = try await CKContainer.default().accountStatus()
            switch account {
            case .noAccount:
                retryFeedback = LocalizedString(
                    en: "No iCloud account on this device. Sign in under Settings → Apple ID, then try again. On-device data is unchanged.",
                    fr: "Aucun compte iCloud sur cet appareil. Connectez-vous dans Réglages → Identifiant Apple, puis réessayez. Les données sur l'appareil sont inchangées."
                ).localized
                return
            case .restricted:
                retryFeedback = LocalizedString(
                    en: "iCloud access is restricted on this device (Screen Time / MDM). On-device data is unchanged.",
                    fr: "L'accès iCloud est restreint sur cet appareil (Temps d'écran / MDM). Les données sur l'appareil sont inchangées."
                ).localized
                return
            case .temporarilyUnavailable:
                retryFeedback = LocalizedString(
                    en: "iCloud is temporarily unavailable. Check your network and try again. On-device data is unchanged.",
                    fr: "iCloud est temporairement indisponible. Vérifiez le réseau et réessayez. Les données sur l'appareil sont inchangées."
                ).localized
                return
            case .couldNotDetermine:
                // Continue to container probe — status alone is inconclusive.
                break
            case .available:
                break
            @unknown default:
                break
            }
        } catch {
            // Account probe failed; still try ModelContainer open below.
            underlyingErrorDescription = error.localizedDescription
        }
        #endif

        do {
            _ = try PersistenceConfiguration.makeCloudKitContainer()
            restartRecommended = true
            retryFeedback = LocalizedString(
                en: "iCloud is reachable. Quit and reopen NATURaL to enable cross-device sync. Data already on this device stays on this device until then.",
                fr: "iCloud est joignable. Quittez et rouvrez NATURaL pour activer la sync multi-appareils. Les données déjà sur cet appareil y restent d'ici là."
            ).localized
        } catch {
            underlyingErrorDescription = error.localizedDescription
            restartRecommended = false
            retryFeedback = LocalizedString(
                en: "Still unable to start iCloud sync. Check network and iCloud sign-in, then try again. Your data on this device is unchanged.",
                fr: "Impossible de démarrer la sync iCloud. Vérifiez le réseau et la connexion iCloud, puis réessayez. Vos données sur cet appareil sont inchangées."
            ).localized
        }
    }
}

// MARK: - Model Container Configuration

/// Creates the shared ModelContainer with CloudKit sync for the NATURaL app.
/// Three-tier bootstrap: CloudKit → local-only → in-memory.
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

    /// CloudKit-backed container only (throws on failure). Used by bootstrap and Retry.
    static func makeCloudKitContainer(schema: Schema? = nil) throws -> ModelContainer {
        let schema = schema ?? makeSchema()
        let config = ModelConfiguration(
            storeName,
            schema: schema,
            cloudKitDatabase: .automatic
        )
        return try ModelContainer(for: schema, configurations: [config])
    }

    /// Durable on-device store without CloudKit.
    static func makeLocalContainer(schema: Schema? = nil) throws -> ModelContainer {
        let schema = schema ?? makeSchema()
        // Same store name as CloudKit path so a previously local "NATURaL" file remains reachable
        // when CloudKit cannot attach.
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
            let container = try makeCloudKitContainer(schema: schema)
            print("✅ ModelContainer ready with CloudKit sync")
            return PersistenceBootstrap(
                container: container,
                mode: .cloudKitSynced,
                underlyingErrorDescription: nil
            )
        } catch {
            let cloudError = error
            print("⚠️ Failed to create CloudKit container: \(error.localizedDescription)")
            print("   Falling back to local-only storage.")

            do {
                let container = try makeLocalContainer(schema: schema)
                return PersistenceBootstrap(
                    container: container,
                    mode: .localOnly,
                    underlyingErrorDescription: cloudError.localizedDescription
                )
            } catch {
                let localError = error
                print("❌ CRITICAL: Failed to create local container: \(error.localizedDescription)")
                print("   Using in-memory storage. Data will not persist across launches.")

                do {
                    let container = try makeEphemeralContainer(schema: schema)
                    return PersistenceBootstrap(
                        container: container,
                        mode: .ephemeral,
                        underlyingErrorDescription:
                            "\(cloudError.localizedDescription); \(localError.localizedDescription)"
                    )
                } catch {
                    // Minimal single-model in-memory so the app can still present UI.
                    print("❌ FATAL: Full in-memory container failed: \(error.localizedDescription)")
                    do {
                        let minimal = try ModelContainer(
                            for: WorkoutRecord.self,
                            configurations: ModelConfiguration(isStoredInMemoryOnly: true)
                        )
                        return PersistenceBootstrap(
                            container: minimal,
                            mode: .ephemeral,
                            underlyingErrorDescription: error.localizedDescription
                        )
                    } catch {
                        // Absolute last resort — bootstrap has nowhere left to go.
                        fatalError(
                            "SwiftData ModelContainer could not be created: \(error.localizedDescription)"
                        )
                    }
                }
            }
        }
    }

    /// Back-compat: prefer CloudKit; on failure fall through to local/ephemeral via bootstrap.
    static func makeContainer() throws -> ModelContainer {
        bootstrap().container
    }

    /// Shared app group container for widget access (local; no CloudKit requirement).
    static func makeSharedContainer() throws -> ModelContainer {
        let schema = Schema([
            WorkoutRecord.self,
            SessionStreak.self,
        ])

        // groupContainer: .automatic needs App Groups entitlement at runtime.
        // Keep CloudKit off for the shared store until widget sync is explicitly enabled.
        let config = ModelConfiguration(
            sharedStoreName,
            schema: schema,
            cloudKitDatabase: .none
        )

        return try ModelContainer(for: schema, configurations: [config])
    }
}
