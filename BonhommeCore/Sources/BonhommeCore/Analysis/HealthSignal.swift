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
