import Foundation

/// A single yoga pose with timing, instructions, and categorization.
public struct YogaPose: Identifiable, Codable, Sendable {
    public let id: UUID
    public let name: LocalizedString
    public let durationSeconds: TimeInterval
    public let category: PoseCategory
    public let instructions: LocalizedString?
    public let difficulty: PoseDifficulty
    public let breathingPattern: BreathingPattern?
    
    public init(
        id: UUID = UUID(),
        name: LocalizedString,
        durationSeconds: TimeInterval,
        category: PoseCategory,
        instructions: LocalizedString? = nil,
        difficulty: PoseDifficulty = .beginner,
        breathingPattern: BreathingPattern? = nil
    ) {
        self.id = id
        self.name = name
        self.durationSeconds = durationSeconds
        self.category = category
        self.instructions = instructions
        self.difficulty = difficulty
        self.breathingPattern = breathingPattern
    }
}

/// Category of yoga pose (e.g., standing, seated, prone).
public enum PoseCategory: String, Codable, Sendable {
    case standing
    case seated
    case prone
    case supine
    case balancing
    case inverted
    case breathing
    
    public var localizedName: LocalizedString {
        switch self {
        case .standing:
            return LocalizedString(en: "Standing", fr: "Debout")
        case .seated:
            return LocalizedString(en: "Seated", fr: "Assis")
        case .prone:
            return LocalizedString(en: "Prone", fr: "Allongé face")
        case .supine:
            return LocalizedString(en: "Supine", fr: "Allongé dos")
        case .balancing:
            return LocalizedString(en: "Balancing", fr: "Équilibre")
        case .inverted:
            return LocalizedString(en: "Inverted", fr: "Inversé")
        case .breathing:
            return LocalizedString(en: "Breathing", fr: "Respiration")
        }
    }
    
    public var symbolName: String {
        switch self {
        case .standing:
            return "figure.stand"
        case .seated:
            return "figure.seated.side"
        case .prone:
            return "figure.roll"
        case .supine:
            return "figure.cooldown"
        case .balancing:
            return "figure.core.training"
        case .inverted:
            return "figure.strengthtraining.traditional"
        case .breathing:
            return "wind"
        }
    }
    
    public var accentHue: Double {
        switch self {
        case .standing:
            return 0.35 // Green
        case .seated:
            return 0.55 // Cyan
        case .prone:
            return 0.15 // Orange
        case .supine:
            return 0.75 // Purple
        case .balancing:
            return 0.6  // Blue
        case .inverted:
            return 0.0  // Red
        case .breathing:
            return 0.5  // Cyan
        }
    }
}

/// Difficulty level for a yoga pose.
public enum PoseDifficulty: String, Codable, Sendable {
    case beginner
    case intermediate
    case advanced
    
    public var dotCount: Int {
        switch self {
        case .beginner: return 1
        case .intermediate: return 2
        case .advanced: return 3
        }
    }
}

/// Breathing pattern for a yoga pose.
public enum BreathingPattern: String, Codable, Sendable {
    case inhale
    case exhale
    case hold
    case alternate
    case continuous
}
