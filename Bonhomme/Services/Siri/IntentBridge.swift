import Foundation
import SwiftData
import BonhommeCore

// MARK: - Notifications

extension Notification.Name {
    /// Posted when an App Intent requests starting a workout plan.
    /// `userInfo["planId"]` is a `String`.
    static let intentStartWorkoutPlan = Notification.Name("natural.intentStartWorkoutPlan")
}

// MARK: - Intent Bridge

/// Process-wide bridge so App Intents can read live analysis state and hand off
/// workout starts to the UI. Snapshots are also persisted to UserDefaults so
/// cold-start Siri queries still return the last known values.
@MainActor
final class IntentBridge {
    static let shared = IntentBridge()

    private(set) weak var feedbackEngine: FeedbackEngine?
    private(set) weak var medicationTracker: MedicationTracker?

    /// Plan id requested by StartWorkoutPlanIntent / StartChairYogaIntent.
    /// Consumed by ContentView / HomeView when the app comes to foreground.
    var pendingPlanId: String? {
        didSet {
            if let id = pendingPlanId {
                defaults.set(id, forKey: Keys.pendingPlanId)
            } else {
                defaults.removeObject(forKey: Keys.pendingPlanId)
            }
        }
    }

    private let defaults: UserDefaults
    private let medicationAnalyzer = MedicationAnalyzer(windowDays: 7)

    private enum Keys {
        static let pendingPlanId = "intent.pendingPlanId"
        static let lastSCIScore = "intent.lastSCIScore"
        static let lastSCITrend = "intent.lastSCITrend"
        static let lastSCISummary = "intent.lastSCISummary"
        static let lastSCIAt = "intent.lastSCIAt"
        static let lastAdherenceScore = "intent.lastAdherenceScore"
        static let lastAdherenceSummary = "intent.lastAdherenceSummary"
        static let lastAdherenceAt = "intent.lastAdherenceAt"
        static let medicationEvents = "intent.medicationEvents"
        static let suiteName = "group.com.natural.Bonhomme"
    }

    private init() {
        defaults = UserDefaults(suiteName: Keys.suiteName) ?? .standard
        if let stored = defaults.string(forKey: Keys.pendingPlanId) {
            pendingPlanId = stored
        }
    }

    // MARK: - Binding

    func bind(feedbackEngine: FeedbackEngine, medicationTracker: MedicationTracker) {
        self.feedbackEngine = feedbackEngine
        self.medicationTracker = medicationTracker
    }

    // MARK: - Workout start handoff

    /// Queue a plan start and notify the UI (if already running).
    func requestStartPlan(id: String) {
        pendingPlanId = id
        NotificationCenter.default.post(
            name: .intentStartWorkoutPlan,
            object: nil,
            userInfo: ["planId": id]
        )
    }

    /// Consume and clear a pending plan id (call from UI after navigation).
    func consumePendingPlanId() -> String? {
        let id = pendingPlanId
        pendingPlanId = nil
        return id
    }

    /// Best plan for a target duration (minutes). Prefers free plans closest in length.
    func planMatching(durationMinutes: Int?) -> WorkoutPlan {
        guard let minutes = durationMinutes, minutes > 0 else {
            return PoseCatalog.beginnerFlow
        }
        let target = TimeInterval(minutes * 60)
        let candidates = PoseCatalog.allPlans
        let free = candidates.filter(\.isFree)
        let pool = free.isEmpty ? candidates : free
        return pool.min(by: {
            abs($0.totalDuration - target) < abs($1.totalDuration - target)
        }) ?? PoseCatalog.beginnerFlow
    }

    // MARK: - SCI / focus score

    struct FocusSnapshot: Sendable {
        let score: Double?
        let trend: InsightTrend
        let summary: String
        let source: String
    }

    func currentFocusSnapshot() -> FocusSnapshot {
        // 1. Live FeedbackEngine (active session)
        if let engine = feedbackEngine {
            if engine.latestInsight(for: .heartRateVariability) == nil {
                _ = engine.analyze(for: .heartRateVariability)
            }
            if let insight = engine.latestInsight(for: .heartRateVariability),
               insight.score != nil || !insight.summary.localized.isEmpty {
                publishSCI(score: insight.score, trend: insight.trend, summary: insight.summary.localized)
                return FocusSnapshot(
                    score: insight.score,
                    trend: insight.trend,
                    summary: insight.summary.localized,
                    source: "live"
                )
            }
        }

        // 2. App Group (written by Live Activity / session metrics)
        if let appGroupSCI = AppGroupStore.latestSCI() {
            let summary = LocalizedString(
                en: "Current focus score (SCI) is \(pct(appGroupSCI)).",
                fr: "Le score de concentration (SCI) actuel est de \(pct(appGroupSCI))."
            ).localized
            return FocusSnapshot(score: appGroupSCI, trend: .stable, summary: summary, source: "appgroup")
        }

        // 3. Persisted IntentBridge snapshot
        if defaults.object(forKey: Keys.lastSCIAt) != nil {
            let score = defaults.object(forKey: Keys.lastSCIScore) as? Double
            let trendRaw = defaults.string(forKey: Keys.lastSCITrend) ?? InsightTrend.stable.rawValue
            let trend = InsightTrend(rawValue: trendRaw) ?? .stable
            let summary = defaults.string(forKey: Keys.lastSCISummary) ?? ""
            if score != nil || !summary.isEmpty {
                return FocusSnapshot(score: score, trend: trend, summary: summary, source: "cache")
            }
        }

        // 4. Latest WorkoutRecord with SCI
        if let record = latestWorkoutWithSCI() {
            let summary = LocalizedString(
                en: "Last session focus score was \(pct(record.sciScore)).",
                fr: "Le score de concentration de la dernière séance était de \(pct(record.sciScore))."
            ).localized
            return FocusSnapshot(
                score: record.sciScore,
                trend: .stable,
                summary: summary,
                source: "history"
            )
        }

        return FocusSnapshot(
            score: nil,
            trend: .stable,
            summary: LocalizedString(
                en: "No focus score yet. Start a session to measure SCI.",
                fr: "Aucun score de concentration pour le moment. Lancez une séance pour mesurer le SCI."
            ).localized,
            source: "none"
        )
    }

    func publishSCI(score: Double?, trend: InsightTrend, summary: String) {
        if let score {
            defaults.set(score, forKey: Keys.lastSCIScore)
        }
        defaults.set(trend.rawValue, forKey: Keys.lastSCITrend)
        defaults.set(summary, forKey: Keys.lastSCISummary)
        defaults.set(Date(), forKey: Keys.lastSCIAt)
        // Keep App Group in sync for widgets + cold-start intents
        AppGroupStore.writeSessionMetrics(sci: score, heartRate: nil, breathRate: nil)
    }

    // MARK: - Medication adherence

    struct AdherenceSnapshot: Sendable {
        let score: Double?
        let summary: String
        let source: String
    }

    func currentAdherenceSnapshot() -> AdherenceSnapshot {
        // 1. Live FeedbackEngine medication insight
        if let engine = feedbackEngine {
            if let insight = engine.analyze(for: .medication), insight.score != nil {
                publishAdherence(score: insight.score, summary: insight.summary.localized)
                return AdherenceSnapshot(
                    score: insight.score,
                    summary: insight.summary.localized,
                    source: "live"
                )
            }
        }

        // 2. Recompute from persisted dose events
        let events = loadMedicationEvents()
        if !events.isEmpty {
            let insight = medicationAnalyzer.analyze(
                signals: events,
                context: AnalysisContext()
            )
            publishAdherence(score: insight.score, summary: insight.summary.localized)
            return AdherenceSnapshot(
                score: insight.score,
                summary: insight.summary.localized,
                source: "events"
            )
        }

        // 3. Cached snapshot
        if defaults.object(forKey: Keys.lastAdherenceAt) != nil {
            let score = defaults.object(forKey: Keys.lastAdherenceScore) as? Double
            let summary = defaults.string(forKey: Keys.lastAdherenceSummary) ?? ""
            if score != nil || !summary.isEmpty {
                return AdherenceSnapshot(score: score, summary: summary, source: "cache")
            }
        }

        // 4. Active schedules only — report scheduled meds without inventing adherence
        if let schedules = activeSchedules(), !schedules.isEmpty {
            let names = schedules.map(\.name).joined(separator: ", ")
            let summary = LocalizedString(
                en: "Tracking \(schedules.count) medication(s) (\(names)). No dose events logged yet — log doses in the app for an adherence score.",
                fr: "Suivi de \(schedules.count) médicament(s) (\(names)). Aucun événement de dose enregistré — enregistrez les doses dans l'app pour un score d'adhérence."
            ).localized
            return AdherenceSnapshot(score: nil, summary: summary, source: "schedules")
        }

        return AdherenceSnapshot(
            score: nil,
            summary: LocalizedString(
                en: "No medication data yet. Add prescriptions and log doses in NATURaL.",
                fr: "Aucune donnée de médicament. Ajoutez des ordonnances et enregistrez les doses dans NATURaL."
            ).localized,
            source: "none"
        )
    }

    func publishAdherence(score: Double?, summary: String) {
        if let score {
            defaults.set(score, forKey: Keys.lastAdherenceScore)
        }
        defaults.set(summary, forKey: Keys.lastAdherenceSummary)
        defaults.set(Date(), forKey: Keys.lastAdherenceAt)
    }

    /// Persist a dose event for cold-start adherence analysis.
    func recordMedicationEvent(_ signal: MedicationSignal) {
        var stored = loadStoredEvents()
        stored.append(CodableMedicationEvent(signal))
        // Keep 60 days of history
        let cutoff = Calendar.current.date(byAdding: .day, value: -60, to: Date()) ?? .distantPast
        stored = stored.filter { $0.timestamp >= cutoff }
        if let data = try? JSONEncoder().encode(stored) {
            defaults.set(data, forKey: Keys.medicationEvents)
        }

        let events = stored.compactMap { $0.toSignal() }

        // Refresh adherence snapshot
        let insight = medicationAnalyzer.analyze(signals: events, context: AnalysisContext())
        publishAdherence(score: insight.score, summary: insight.summary.localized)

        // Also re-analyze via live engine when available
        if let engine = feedbackEngine,
           let live = engine.analyze(for: .medication) {
            publishAdherence(score: live.score, summary: live.summary.localized)
        }
    }

    // MARK: - Drug response / SCI after dose

    struct DrugResponseSnapshot: Sendable {
        let medicationName: String?
        let peakDeltaH: Double?
        let peakTimeMinutes: Double?
        let responseDirection: String?
        let bindingDetected: Bool?
        let effectSize: Double?
        let doseTimestamp: Date?
        let summary: String
        let source: String
    }

    func lastDrugResponseSnapshot() -> DrugResponseSnapshot {
        // 1. Live MedicationTracker
        if let result = medicationTracker?.latestDrugResponse {
            return snapshot(from: result, source: "live")
        }

        // 2. SwiftData DrugResponseRecord
        if let record = latestDrugResponseRecord() {
            let directionLabel = humanDirection(record.responseDirection)
            let delta = String(format: "%+.2f", record.peakDeltaH)
            let minutes = String(format: "%.0f", record.peakTimeMinutes)
            let binding = record.bindingDetected
                ? LocalizedString(en: "binding signal detected", fr: "signal de liaison détecté").localized
                : LocalizedString(en: "no significant binding signal", fr: "aucun signal de liaison significatif").localized
            let summary = LocalizedString(
                en: "Last response for \(record.medicationName): ΔH = \(delta) bits at +\(minutes) min (\(directionLabel)); \(binding). Effect size \(String(format: "%.0f", record.effectSize * 100))%.",
                fr: "Dernière réponse pour \(record.medicationName) : ΔH = \(delta) bits à +\(minutes) min (\(directionLabel)); \(binding). Taille d'effet \(String(format: "%.0f", record.effectSize * 100)) %."
            ).localized
            return DrugResponseSnapshot(
                medicationName: record.medicationName,
                peakDeltaH: record.peakDeltaH,
                peakTimeMinutes: record.peakTimeMinutes,
                responseDirection: record.responseDirection,
                bindingDetected: record.bindingDetected,
                effectSize: record.effectSize,
                doseTimestamp: record.doseTimestamp,
                summary: summary,
                source: "history"
            )
        }

        return DrugResponseSnapshot(
            medicationName: nil,
            peakDeltaH: nil,
            peakTimeMinutes: nil,
            responseDirection: nil,
            bindingDetected: nil,
            effectSize: nil,
            doseTimestamp: nil,
            summary: LocalizedString(
                en: "No drug-response analysis yet. Log a dose and complete a session for HRV entropy around the dose.",
                fr: "Aucune analyse de réponse médicamenteuse. Enregistrez une dose et terminez une séance pour l'entropie HRV autour de la dose."
            ).localized,
            source: "none"
        )
    }

    private func snapshot(from result: DrugResponseResult, source: String) -> DrugResponseSnapshot {
        DrugResponseSnapshot(
            medicationName: result.doseEvent.name,
            peakDeltaH: result.peakDeltaH,
            peakTimeMinutes: result.peakTimeMinutes,
            responseDirection: result.responseDirection.rawValue,
            bindingDetected: result.bindingDetected,
            effectSize: result.effectSize,
            doseTimestamp: result.doseEvent.timestamp,
            summary: result.summary.localized,
            source: source
        )
    }

    // MARK: - Dialog helpers

    func focusDialog() -> String {
        let snap = currentFocusSnapshot()
        if let score = snap.score {
            let pctStr = pct(score)
            let trend = trendPhrase(snap.trend)
            return LocalizedString(
                en: "Your focus score (SCI) is \(pctStr) — \(trend). \(snap.summary)",
                fr: "Votre score de concentration (SCI) est de \(pctStr) — \(trend). \(snap.summary)"
            ).localized
        }
        return snap.summary
    }

    func adherenceDialog() -> String {
        let snap = currentAdherenceSnapshot()
        if let score = snap.score {
            let pctStr = pct(score)
            return LocalizedString(
                en: "Your medication adherence is \(pctStr). \(snap.summary)",
                fr: "Votre adhérence médicamenteuse est de \(pctStr). \(snap.summary)"
            ).localized
        }
        return snap.summary
    }

    func drugResponseDialog() -> String {
        lastDrugResponseSnapshot().summary
    }

    // MARK: - Private persistence

    private struct CodableMedicationEvent: Codable {
        let timestamp: Date
        let medicationId: String
        let nameEn: String
        let nameFr: String
        let doseValue: Double
        let doseUnit: String
        let event: String

        init(_ signal: MedicationSignal) {
            timestamp = signal.timestamp
            medicationId = signal.medicationId
            nameEn = signal.name.en
            nameFr = signal.name.fr
            doseValue = signal.doseValue
            doseUnit = signal.doseUnit
            event = signal.event.rawValue
        }

        func toSignal() -> MedicationSignal? {
            guard let event = MedicationEvent(rawValue: event) else { return nil }
            return MedicationSignal(
                timestamp: timestamp,
                medicationId: medicationId,
                name: LocalizedString(en: nameEn, fr: nameFr.isEmpty ? nameEn : nameFr),
                doseValue: doseValue,
                doseUnit: doseUnit,
                event: event
            )
        }
    }

    private func loadStoredEvents() -> [CodableMedicationEvent] {
        guard let data = defaults.data(forKey: Keys.medicationEvents),
              let decoded = try? JSONDecoder().decode([CodableMedicationEvent].self, from: data) else {
            return []
        }
        return decoded
    }

    private func loadMedicationEvents() -> [MedicationSignal] {
        loadStoredEvents().compactMap { $0.toSignal() }
    }

    private func makeModelContext() -> ModelContext? {
        do {
            let container = try PersistenceConfiguration.makeContainer()
            return ModelContext(container)
        } catch {
            // Local-only fallback matching BonhommeApp
            let schema = Schema([
                WorkoutRecord.self,
                UserPreferences.self,
                SessionStreak.self,
                MedicationSchedule.self,
                DrugResponseRecord.self,
            ])
            do {
                let config = ModelConfiguration("NATURaLLocal", schema: schema)
                let container = try ModelContainer(for: schema, configurations: [config])
                return ModelContext(container)
            } catch {
                return nil
            }
        }
    }

    private func latestWorkoutWithSCI() -> WorkoutRecord? {
        guard let context = makeModelContext() else { return nil }
        var descriptor = FetchDescriptor<WorkoutRecord>(
            sortBy: [SortDescriptor(\.endDate, order: .reverse)]
        )
        descriptor.fetchLimit = 20
        let records = (try? context.fetch(descriptor)) ?? []
        return records.first { $0.sciScore != nil }
    }

    private func latestDrugResponseRecord() -> DrugResponseRecord? {
        guard let context = makeModelContext() else { return nil }
        var descriptor = FetchDescriptor<DrugResponseRecord>(
            sortBy: [SortDescriptor(\.analysisDate, order: .reverse)]
        )
        descriptor.fetchLimit = 1
        return try? context.fetch(descriptor).first
    }

    private func activeSchedules() -> [MedicationSchedule]? {
        guard let context = makeModelContext() else { return nil }
        let descriptor = FetchDescriptor<MedicationSchedule>(
            predicate: #Predicate { $0.isActive },
            sortBy: [SortDescriptor(\.createdAt)]
        )
        return try? context.fetch(descriptor)
    }

    private func pct(_ score: Double?) -> String {
        guard let score else { return "—" }
        return String(format: "%.0f%%", score * 100)
    }

    private func trendPhrase(_ trend: InsightTrend) -> String {
        switch trend {
        case .improving:
            return LocalizedString(en: "improving", fr: "en amélioration").localized
        case .declining:
            return LocalizedString(en: "declining", fr: "en baisse").localized
        case .stable:
            return LocalizedString(en: "stable", fr: "stable").localized
        }
    }

    private func humanDirection(_ raw: String) -> String {
        switch ResponseDirection(rawValue: raw) {
        case .sympathomimeticCollapse:
            return LocalizedString(en: "entropy collapse", fr: "effondrement d'entropie").localized
        case .parasympathomimeticExpansion:
            return LocalizedString(en: "entropy expansion", fr: "expansion d'entropie").localized
        case .noSignificantChange, .none:
            return LocalizedString(en: "no significant change", fr: "pas de changement significatif").localized
        }
    }
}
