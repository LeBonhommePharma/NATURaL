import HealthKit
import BonhommeCore

/// Reads medication records from HealthKit clinical data and manages
/// user-reported medication events.
///
/// HealthKit provides access to clinical medication records (CDA/FHIR)
/// via HKClinicalType when the user has connected a health provider.
/// This service bridges those records into MedicationSignal for the
/// FeedbackEngine, and also supports manual dose logging.
@MainActor
final class MedicationTracker: ObservableObject {
    @Published var activeMedications: [MedicationProfile] = []
    @Published var recentEvents: [MedicationSignal] = []

    private let healthStore = HKHealthStore()
    private let feedbackEngine: FeedbackEngine

    init(feedbackEngine: FeedbackEngine) {
        self.feedbackEngine = feedbackEngine
    }

    // MARK: - Clinical Record Import

    /// Fetches medication records from HealthKit clinical data (health provider records).
    /// Requires the user to have connected their health provider in the Health app.
    func fetchClinicalMedications() async throws {
        guard HKHealthStore.isHealthDataAvailable() else { return }

        let medType = HKClinicalType(.medicationRecord)
        let predicate = HKQuery.predicateForClinicalRecords(
            withFHIRResourceType: .medicationRequest
        )

        let descriptor = HKSampleQueryDescriptor(
            predicates: [.clinicalRecord(type: medType, predicate: predicate)],
            sortDescriptors: [SortDescriptor(\.startDate, order: .reverse)],
            limit: 100
        )

        let records = try await descriptor.result(for: healthStore)

        // Parse clinical records into medication profiles
        for record in records {
            guard let clinicalRecord = record as? HKClinicalRecord,
                  let fhirResource = clinicalRecord.fhirResource else { continue }

            if let profile = parseFHIRMedication(fhirResource, record: clinicalRecord) {
                if !activeMedications.contains(where: { $0.id == profile.id }) {
                    activeMedications.append(profile)
                }
            }
        }
    }

    // MARK: - Manual Dose Logging

    /// Record a medication event (taken, missed, skipped).
    /// Ingests the signal into the FeedbackEngine for cross-analysis with HRV.
    func logDose(
        medicationId: String,
        name: LocalizedString,
        doseValue: Double,
        doseUnit: String,
        event: MedicationEvent,
        at timestamp: Date = Date()
    ) {
        let signal = MedicationSignal(
            timestamp: timestamp,
            medicationId: medicationId,
            name: name,
            doseValue: doseValue,
            doseUnit: doseUnit,
            event: event
        )

        recentEvents.append(signal)
        feedbackEngine.ingest(signal)
    }

    // MARK: - HRV Query for Medication Windows

    /// Fetches HRV samples around a medication event to detect physiological response.
    /// Returns HRV readings from 30 minutes before to 2 hours after the dose.
    func fetchHRVAroundDose(
        doseTimestamp: Date
    ) async throws -> [HRVSignal] {
        let hrvType = HKQuantityType(.heartRateVariabilitySDNN)
        let start = doseTimestamp.addingTimeInterval(-1800)   // 30 min before
        let end = doseTimestamp.addingTimeInterval(7200)       // 2 hours after

        let predicate = HKQuery.predicateForSamples(
            withStart: start,
            end: end,
            options: .strictStartDate
        )

        let descriptor = HKSampleQueryDescriptor(
            predicates: [.quantitySample(type: hrvType, predicate: predicate)],
            sortDescriptors: [SortDescriptor(\.startDate)]
        )

        let samples = try await descriptor.result(for: healthStore)

        return samples.compactMap { sample -> HRVSignal? in
            guard let quantitySample = sample as? HKQuantitySample else { return nil }
            let sdnn = quantitySample.quantity.doubleValue(for: .secondUnit(with: .milli))
            return HRVSignal(
                timestamp: quantitySample.startDate,
                sdnn: sdnn,
                rmssd: sdnn, // Approximate — HealthKit only provides SDNN directly
                rrIntervals: []
            )
        }
    }

    // MARK: - FHIR Parsing

    private func parseFHIRMedication(
        _ resource: HKFHIRResource,
        record: HKClinicalRecord
    ) -> MedicationProfile? {
        // Extract medication name from the clinical record display
        let displayName = record.displayName

        return MedicationProfile(
            id: resource.identifier,
            name: LocalizedString(en: displayName, fr: displayName),
            source: .clinicalRecord
        )
    }
}

/// A medication the user is tracking, sourced from clinical records or manual entry.
struct MedicationProfile: Identifiable, Sendable {
    let id: String
    let name: LocalizedString
    let source: MedicationSource
}

enum MedicationSource: String, Sendable {
    case clinicalRecord
    case manualEntry
}
