import Foundation
import HealthKit
import SwiftData
import BonhommeCore

// MARK: - OS / platform limits (documentation)

/// ## HealthKit medication / clinical record limits
///
/// - **Clinical records** (`HKClinicalTypeIdentifier.medicationRecord`) require:
///   1. Explicit **in-app** consent (`ConsentStore.hasValidClinicalConsent`)
///   2. HealthKit authorization for clinical types (separate permission sheet)
///   3. Entitlement `com.apple.developer.healthkit.access` → `health-records`
///   4. User connection to a health institution in the **Health** app
///   5. Availability: primarily US institutions; not all regions / devices
/// - Clinical types are **read-only**. Apps cannot write medication clinical records.
/// - **Pharmacy websites are never scraped.** There are no pharmacy credentials in this app.
/// - User-entered pharmacy notes are free-text on `MedicationSchedule.notes` only.
/// - Manual schedules always work without HealthKit clinical access.
/// - iOS 26+ may expose additional per-object medication APIs (`HKUserAnnotatedMedicationType`);
///   this service uses clinical FHIR records + manual entry, which remain the portable path.
///
/// ## Privacy
/// Never call clinical reads without `ConsentStore.hasValidClinicalConsent`.
/// Revoking consent stops sync and clears in-memory clinical profiles (local manual schedules remain).

/// Orchestrates user-managed prescriptions: explicit consent → HealthKit clinical import
/// → map into `MedicationSchedule` / `MedicationProfile` → optional CareKit sync.
/// Manual entry is the always-available fallback when pharmacy/clinical data is unavailable.
@MainActor
final class MedicationPrescriptionService: ObservableObject {
    @Published private(set) var consent: ClinicalConsent
    @Published private(set) var lastSyncDate: Date?
    @Published private(set) var lastSyncError: String?
    @Published private(set) var isSyncing = false
    @Published private(set) var clinicalAuthorized = false
    /// User-facing status of clinical import (not medical advice).
    @Published private(set) var importStatusMessage: String?

    let consentStore: ConsentStore
    private let healthKitManager: HealthKitManager
    private let medicationTracker: MedicationTracker
    private let careKitBridge: CareKitBridge

    init(
        healthKitManager: HealthKitManager,
        medicationTracker: MedicationTracker,
        careKitBridge: CareKitBridge,
        consentStore: ConsentStore = .shared
    ) {
        self.healthKitManager = healthKitManager
        self.medicationTracker = medicationTracker
        self.careKitBridge = careKitBridge
        self.consentStore = consentStore
        self.consent = consentStore.consent
    }

    // MARK: - Consent Gate

    /// User opts in. Stores timestamp + policy version, audits, then may request HK clinical auth.
    func grantConsent(requestHealthKit: Bool = true) async {
        consent = consentStore.grant()
        mirrorConsentToUserPreferencesIfPossible()

        if requestHealthKit {
            await requestClinicalAuthorizationIfNeeded()
        }
    }

    /// User opts out. Stops clinical reads immediately; audits revoke.
    func revokeConsent() {
        consent = consentStore.revoke()
        clinicalAuthorized = false
        lastSyncDate = nil
        importStatusMessage = nil
        // Clear in-memory clinical profiles only (manual entry source remains via schedules).
        medicationTracker.clearClinicalMedications()
        mirrorConsentToUserPreferencesIfPossible()
    }

    /// Refresh published consent from store (e.g. after external change).
    func refreshConsentState() {
        consent = consentStore.consent
    }

    // MARK: - HealthKit clinical authorization (post-consent only)

    /// Requests `HKClinicalType.medicationRecord` only after explicit consent.
    /// Safe to call repeatedly; never invents pharmacy credentials.
    func requestClinicalAuthorizationIfNeeded() async {
        guard consentStore.hasValidClinicalConsent else {
            consentStore.appendAudit(ConsentAuditEntry(
                action: .clinicalReadBlocked,
                detail: "auth_request_blocked no_consent"
            ))
            clinicalAuthorized = false
            return
        }

        do {
            let ok = try await healthKitManager.requestClinicalMedicationAuthorization()
            clinicalAuthorized = ok
            if !ok {
                importStatusMessage = LocalizedString(
                    en: "Clinical records not available on this device or not entitled. You can still add medications manually.",
                    fr: "Les dossiers cliniques ne sont pas disponibles sur cet appareil. Vous pouvez toujours ajouter des médicaments manuellement."
                ).localized
            }
        } catch {
            clinicalAuthorized = false
            lastSyncError = error.localizedDescription
            importStatusMessage = LocalizedString(
                en: "Could not request clinical HealthKit access. Manual entry remains available.",
                fr: "Impossible de demander l'accès clinique HealthKit. La saisie manuelle reste disponible."
            ).localized
            consentStore.appendAudit(ConsentAuditEntry(
                action: .clinicalReadFailure,
                detail: "auth_error \(error.localizedDescription)"
            ))
        }
    }

    // MARK: - Load / Sync

    /// Full sync path: consent → HK clinical meds → map to schedules → CareKit.
    /// Pass a `ModelContext` to persist `MedicationSchedule` rows for clinical imports.
    func syncPrescriptions(modelContext: ModelContext?) async {
        guard consentStore.hasValidClinicalConsent else {
            consentStore.appendAudit(ConsentAuditEntry(
                action: .clinicalReadBlocked,
                detail: "sync_blocked no_consent"
            ))
            importStatusMessage = LocalizedString(
                en: "Enable medication data access to import clinical records.",
                fr: "Activez l'accès aux données de médicaments pour importer les dossiers cliniques."
            ).localized
            return
        }

        isSyncing = true
        lastSyncError = nil
        defer { isSyncing = false }

        consentStore.appendAudit(ConsentAuditEntry(
            action: .clinicalReadAttempt,
            detail: "sync_start"
        ))

        // 1. Clinical import (best-effort)
        do {
            try await medicationTracker.fetchClinicalMedications(consentStore: consentStore)
            clinicalAuthorized = true
        } catch {
            lastSyncError = error.localizedDescription
            consentStore.appendAudit(ConsentAuditEntry(
                action: .clinicalReadFailure,
                detail: "fetch_error \(error.localizedDescription)"
            ))
            // Continue with manual schedules even if clinical fetch fails
        }

        // 2. Map clinical profiles → MedicationSchedule (SwiftData) without inventing doses
        if let modelContext {
            mergeClinicalIntoSchedules(modelContext: modelContext)
        }

        // 3. CareKit medication tasks from active schedules + clinical profiles
        do {
            let summaries = buildMedicationSummaries(modelContext: modelContext)
            try await careKitBridge.syncMedicationPrescriptions(summaries)
            consentStore.appendAudit(ConsentAuditEntry(
                action: .careKitSync,
                detail: "synced_count=\(summaries.count)"
            ))
        } catch {
            lastSyncError = error.localizedDescription
            consentStore.appendAudit(ConsentAuditEntry(
                action: .clinicalReadFailure,
                detail: "carekit_sync_error \(error.localizedDescription)"
            ))
        }

        lastSyncDate = Date()
        importStatusMessage = LocalizedString(
            en: "Last sync finished. User-managed list — confirm with your clinician. Not medical advice.",
            fr: "Dernière synchronisation terminée. Liste gérée par l'utilisateur — confirmez avec votre clinicien. Ce n'est pas un avis médical."
        ).localized

        if medicationTracker.activeMedications.contains(where: { $0.source == .clinicalRecord }) {
            consentStore.appendAudit(ConsentAuditEntry(
                action: .clinicalReadSuccess,
                detail: "clinical_profiles=\(medicationTracker.activeMedications.filter { $0.source == .clinicalRecord }.count)"
            ))
        }
    }

    // MARK: - Manual entry

    /// Adds a user-entered medication (no pharmacy login). Persists schedule + tracker profile.
    @discardableResult
    func addManualMedication(
        name: String,
        doseValue: Double,
        doseUnit: String,
        scheduledHours: [Int],
        pharmacyNotes: String?,
        modelContext: ModelContext
    ) -> MedicationSchedule {
        let id = "manual.\(UUID().uuidString)"
        let schedule = MedicationSchedule(
            medicationId: id,
            name: name,
            doseValue: doseValue,
            doseUnit: doseUnit,
            scheduledHours: scheduledHours,
            notes: pharmacyNotes
        )
        modelContext.insert(schedule)
        try? modelContext.save()

        medicationTracker.addManualProfile(
            id: id,
            name: LocalizedString(en: name, fr: name),
            doseValue: doseValue,
            doseUnit: doseUnit
        )

        consentStore.appendAudit(ConsentAuditEntry(
            action: .manualEntry,
            detail: "manual_schedule_added hours=\(scheduledHours.count)"
        ))

        return schedule
    }

    /// Combined display list: clinical profiles + manual tracker profiles.
    var trackedMedications: [MedicationProfile] {
        medicationTracker.activeMedications
    }

    // MARK: - Private helpers

    private func mergeClinicalIntoSchedules(modelContext: ModelContext) {
        let clinical = medicationTracker.activeMedications.filter { $0.source == .clinicalRecord }
        guard !clinical.isEmpty else { return }

        let descriptor = FetchDescriptor<MedicationSchedule>()
        let existing = (try? modelContext.fetch(descriptor)) ?? []
        let existingIds = Set(existing.map(\.medicationId))

        for profile in clinical where !existingIds.contains(profile.id) {
            let schedule = MedicationSchedule(
                medicationId: profile.id,
                name: profile.name.localized,
                doseValue: profile.doseValue ?? 0,
                doseUnit: profile.doseUnit ?? "",
                scheduledHours: [],
                notes: LocalizedString(
                    en: "Imported from Health clinical records. Confirm schedule with your clinician.",
                    fr: "Importé des dossiers cliniques Santé. Confirmez l'horaire avec votre clinicien."
                ).localized
            )
            modelContext.insert(schedule)
        }
        try? modelContext.save()
    }

    private func buildMedicationSummaries(modelContext: ModelContext?) -> [MedicationPrescriptionSummary] {
        var byId: [String: MedicationPrescriptionSummary] = [:]

        for profile in medicationTracker.activeMedications {
            byId[profile.id] = MedicationPrescriptionSummary(
                id: profile.id,
                title: profile.name.localized,
                doseDescription: profile.formattedDose,
                scheduledHours: [],
                source: profile.source == .clinicalRecord ? .clinical : .manual,
                instructions: LocalizedString(
                    en: "User-managed prescription. Confirm with your clinician. Not medical advice.",
                    fr: "Ordonnance gérée par l'utilisateur. Confirmez avec votre clinicien. Ce n'est pas un avis médical."
                ).localized
            )
        }

        if let modelContext {
            let descriptor = FetchDescriptor<MedicationSchedule>(
                predicate: #Predicate { $0.isActive }
            )
            if let schedules = try? modelContext.fetch(descriptor) {
                for schedule in schedules {
                    if var existing = byId[schedule.medicationId] {
                        existing.scheduledHours = schedule.scheduledHours
                        existing.doseDescription = schedule.formattedDose
                        if let notes = schedule.notes, !notes.isEmpty {
                            existing.instructions = notes
                        }
                        byId[schedule.medicationId] = existing
                    } else {
                        byId[schedule.medicationId] = MedicationPrescriptionSummary(
                            id: schedule.medicationId,
                            title: schedule.name,
                            doseDescription: schedule.formattedDose,
                            scheduledHours: schedule.scheduledHours,
                            source: .manual,
                            instructions: schedule.notes ?? LocalizedString(
                                en: "User-managed. Confirm with your clinician.",
                                fr: "Géré par l'utilisateur. Confirmez avec votre clinicien."
                            ).localized
                        )
                    }
                }
            }
        }

        return Array(byId.values).sorted { $0.title.localizedCaseInsensitiveCompare($1.title) == .orderedAscending }
    }

    private func mirrorConsentToUserPreferencesIfPossible() {
        // Soft mirror — UserPreferences may not be on this actor's context.
        // UI layer can also write these fields when it has a ModelContext.
        NotificationCenter.default.post(
            name: .clinicalConsentDidChange,
            object: nil,
            userInfo: [
                "isGranted": consent.isGranted,
                "policyVersion": consent.policyVersion as Any,
                "grantedAt": consent.grantedAt as Any,
                "revokedAt": consent.revokedAt as Any,
            ]
        )
    }
}

// MARK: - Summary DTO (CareKit bridge)

struct MedicationPrescriptionSummary: Identifiable, Sendable, Equatable {
    enum Source: String, Sendable {
        case clinical
        case manual
    }

    let id: String
    var title: String
    var doseDescription: String
    var scheduledHours: [Int]
    var source: Source
    var instructions: String
}

extension Notification.Name {
    static let clinicalConsentDidChange = Notification.Name("natural.clinicalConsentDidChange")
}
