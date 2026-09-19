import XCTest
import SwiftData
@testable import Bonhomme
import BonhommeCore

/// Hosted iOS tests: require the Bonhomme app target and Xcode's XCTest SDK.
@MainActor
final class MedicationPrescriptionServiceTests: XCTestCase {
    private enum SaveFailure: Error { case diskUnavailable }

    func testFailedManualSaveKeepsOtherEditsAndRetryCreatesOneRecord() async throws {
        let container = try PersistenceConfiguration.makeEphemeralContainer()
        let context = ModelContext(container)
        context.autosaveEnabled = false
        let unrelatedPreferences = UserPreferences()
        context.insert(unrelatedPreferences)

        let suite = "MedicationPersistenceTests.\(UUID().uuidString)"
        let defaults = try XCTUnwrap(UserDefaults(suiteName: suite))
        defer { defaults.removePersistentDomain(forName: suite) }
        let consent = ConsentStore(defaults: defaults)
        let tracker = MedicationTracker(feedbackEngine: FeedbackEngine())
        var shouldFail = true
        let service = MedicationPrescriptionService(
            healthKitManager: HealthKitManager(),
            medicationTracker: tracker,
            careKitBridge: CareKitBridge(storeName: suite),
            consentStore: consent,
            saveModelContext: { context in
                if shouldFail { throw SaveFailure.diskUnavailable }
                try context.save()
            }
        )
        await service.grantConsent(requestHealthKit: false)

        XCTAssertThrowsError(try addMedication(service, context: context))
        XCTAssertTrue(tracker.activeMedications.isEmpty)
        XCTAssertFalse(consent.auditLog.contains { $0.action == .manualEntry })
        XCTAssertTrue(try context.fetch(FetchDescriptor<MedicationSchedule>()).isEmpty)
        XCTAssertEqual(try context.fetch(FetchDescriptor<UserPreferences>()).count, 1,
                       "A failed medication save must not roll back unrelated pending edits")

        shouldFail = false
        _ = try addMedication(service, context: context)
        let reader = ModelContext(container)
        let saved = try reader.fetch(FetchDescriptor<MedicationSchedule>())
        XCTAssertEqual(saved.count, 1, "Retry must not autosave a ghost from the failed insertion")
        XCTAssertEqual(saved.first?.name, "Test medication")
        XCTAssertEqual(tracker.activeMedications.count, 1)
        XCTAssertEqual(consent.auditLog.filter { $0.action == .manualEntry }.count, 1)
    }

    func testClinicalMergeThrowsAndRemovesOnlyFailedInsertions() async throws {
        let container = try PersistenceConfiguration.makeEphemeralContainer()
        let context = ModelContext(container)
        context.autosaveEnabled = false
        let existing = MedicationSchedule(
            medicationId: "manual.existing", name: "Existing medication",
            doseValue: 1, doseUnit: "mg", scheduledHours: [8]
        )
        context.insert(existing)
        try context.save()

        let suite = "ClinicalImportPersistenceTests.\(UUID().uuidString)"
        let defaults = try XCTUnwrap(UserDefaults(suiteName: suite))
        defer { defaults.removePersistentDomain(forName: suite) }
        let tracker = MedicationTracker(feedbackEngine: FeedbackEngine())
        tracker.activeMedications = [MedicationProfile(
            id: "clinical.test", name: LocalizedString(en: "Imported", fr: "Importé"),
            source: .clinicalRecord, doseValue: 2, doseUnit: "mg"
        )]
        var shouldFail = true
        let service = MedicationPrescriptionService(
            healthKitManager: HealthKitManager(), medicationTracker: tracker,
            careKitBridge: CareKitBridge(storeName: suite),
            consentStore: ConsentStore(defaults: defaults),
            saveModelContext: { context in
                if shouldFail { throw SaveFailure.diskUnavailable }
                try context.save()
            }
        )
        await service.grantConsent(requestHealthKit: false)

        XCTAssertThrowsError(try service.mergeClinicalIntoSchedules(modelContext: context))
        XCTAssertEqual(try context.fetch(FetchDescriptor<MedicationSchedule>()).map(\.medicationId), ["manual.existing"])
        XCTAssertNil(service.lastSyncDate)

        shouldFail = false
        try service.mergeClinicalIntoSchedules(modelContext: context)
        try service.mergeClinicalIntoSchedules(modelContext: context)
        let reader = ModelContext(container)
        XCTAssertEqual(try reader.fetch(FetchDescriptor<MedicationSchedule>()).count, 2,
                       "Repeated import must not duplicate the clinical record")
    }

    func testDoseLabelsDoNotTrapOrRoundSmallDosesToZero() {
        for (dose, expected) in [(5.0, "5 mg"), (0.01, "0.01 mg"), (1e100, "1e+100 mg"),
                                  (Double.infinity, "—"), (Double.nan, "—"), (-1.0, "—")] {
            let schedule = MedicationSchedule(medicationId: "format", name: "Test",
                                               doseValue: dose, doseUnit: "mg", scheduledHours: [])
            let profile = MedicationProfile(id: "format", name: LocalizedString(en: "Test", fr: "Test"),
                                            source: .manualEntry, doseValue: dose, doseUnit: "mg")
            XCTAssertEqual(schedule.formattedDose, expected)
            XCTAssertEqual(profile.formattedDose, expected)
        }
    }

    private func addMedication(_ service: MedicationPrescriptionService, context: ModelContext) throws -> MedicationSchedule {
        try service.addManualMedication(
            name: "Test medication", doseValue: 5, doseUnit: "mg",
            scheduledHours: [8], pharmacyNotes: "Preserved notes", modelContext: context
        )
    }
}
