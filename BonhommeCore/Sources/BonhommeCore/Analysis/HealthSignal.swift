import Foundation

// MARK: - Core Protocol

/// A discrete health observation from any data source (HealthKit, ResearchKit, manual entry).
/// Implementations include HRV readings, medication events, survey responses, etc.
public protocol HealthSignal: Codable, Sendable {
    /// Unique type identifier for routing signals to the correct analyzer.
    static var signalType: SignalType { get }

    /// When this signal was captured.
    var timestamp: Date { get }
}

/// Identifies the category of health signal for analyzer dispatch.
public enum SignalType: String, Codable, Sendable {
    case heartRateVariability
    case medication
    case survey
    case molecularDocking
}

// MARK: - Concrete Signals

/// A single HRV observation derived from HealthKit beat-to-beat intervals.
public struct HRVSignal: HealthSignal {
    public static let signalType: SignalType = .heartRateVariability

    public let timestamp: Date
    /// SDNN in milliseconds — standard deviation of NN intervals.
    public let sdnn: Double
    /// RMSSD in milliseconds — root mean square of successive differences.
    public let rmssd: Double
    /// Raw RR intervals in milliseconds, if available.
    public let rrIntervals: [Double]

    public init(timestamp: Date, sdnn: Double, rmssd: Double, rrIntervals: [Double] = []) {
        self.timestamp = timestamp
        self.sdnn = sdnn
        self.rmssd = rmssd
        self.rrIntervals = rrIntervals
    }
}

/// A medication event: dose taken, missed, or skipped.
public struct MedicationSignal: HealthSignal {
    public static let signalType: SignalType = .medication

    public let timestamp: Date
    /// Stable identifier for the medication (e.g. RxNorm CUI or user-defined ID).
    public let medicationId: String
    /// Display name for the medication.
    public let name: LocalizedString
    /// Dose amount (e.g. 500 for "500 mg").
    public let doseValue: Double
    /// Unit string (e.g. "mg", "mL", "IU").
    public let doseUnit: String
    /// What happened at this timestamp.
    public let event: MedicationEvent

    public init(
        timestamp: Date,
        medicationId: String,
        name: LocalizedString,
        doseValue: Double,
        doseUnit: String,
        event: MedicationEvent
    ) {
        self.timestamp = timestamp
        self.medicationId = medicationId
        self.name = name
        self.doseValue = doseValue
        self.doseUnit = doseUnit
        self.event = event
    }
}

public enum MedicationEvent: String, Codable, Sendable {
    case taken
    case missed
    case skipped
    case late
}

/// A subjective response collected via ResearchKit survey or manual entry.
public struct SurveySignal: HealthSignal {
    public static let signalType: SignalType = .survey

    public let timestamp: Date
    /// Survey instrument identifier (e.g. "pain-vas", "mood-likert", "well-being-5").
    public let instrumentId: String
    /// Normalized score in 0.0–1.0 range regardless of the instrument's native scale.
    public let normalizedScore: Double
    /// Raw responses keyed by question identifier.
    public let responses: [String: String]

    public init(
        timestamp: Date,
        instrumentId: String,
        normalizedScore: Double,
        responses: [String: String] = [:]
    ) {
        self.timestamp = timestamp
        self.instrumentId = instrumentId
        self.normalizedScore = normalizedScore
        self.responses = responses
    }
}

/// Summary of a molecular docking run (FlexAID∆S) for a substance.
///
/// Carries the computed configurational entropy penalty for FeedbackEngine integration.
/// Each signal represents one docking analysis: the entropy of the ligand in free solution
/// vs. bound in the receptor pocket.
public struct DockingSignal: HealthSignal {
    public static let signalType: SignalType = .molecularDocking

    public let timestamp: Date

    /// The substance this docking result pertains to (matches PharmacokineticProfile.substanceId).
    public let substanceId: String

    /// Display name for the substance.
    public let substanceName: LocalizedString

    /// Total configurational entropy of the free (unbound) ligand (bits).
    /// Computed from torsional angle distributions in solution sampling.
    public let freeEntropy: Double

    /// Total configurational entropy of the bound ligand (bits).
    /// Computed from torsional angle distributions in the docking pose.
    public let boundEntropy: Double

    /// ΔS_config = boundEntropy - freeEntropy (bits).
    /// Negative = binding constrains the ligand (entropy penalty).
    public var deltaSConfig: Double { boundEntropy - freeEntropy }

    /// Number of rotatable bonds analyzed.
    public let rotatableBondCount: Int

    /// Receptor/target identifier (e.g., PDB ID).
    public let receptorId: String

    /// Binding affinity score from the docking program (arbitrary units, lower = better).
    public let dockingScore: Double?

    public init(
        timestamp: Date = Date(),
        substanceId: String,
        substanceName: LocalizedString,
        freeEntropy: Double,
        boundEntropy: Double,
        rotatableBondCount: Int,
        receptorId: String,
        dockingScore: Double? = nil
    ) {
        self.timestamp = timestamp
        self.substanceId = substanceId
        self.substanceName = substanceName
        self.freeEntropy = freeEntropy
        self.boundEntropy = boundEntropy
        self.rotatableBondCount = rotatableBondCount
        self.receptorId = receptorId
        self.dockingScore = dockingScore
    }
}
