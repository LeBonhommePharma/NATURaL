import Foundation

/// Difficulty levels for chair yoga poses.
public enum PoseDifficulty: String, Codable, Sendable, CaseIterable {
    case beginner
    case intermediate
    case advanced

    public var localizedName: LocalizedString {
        switch self {
        case .beginner:
            return LocalizedString(en: "Beginner", fr: "Débutant")
        case .intermediate:
            return LocalizedString(en: "Intermediate", fr: "Intermédiaire")
        case .advanced:
            return LocalizedString(en: "Advanced", fr: "Avancé")
        }
    }

    /// Number of filled dots to represent this difficulty level.
    public var dotCount: Int {
        switch self {
        case .beginner: return 1
        case .intermediate: return 2
        case .advanced: return 3
        }
    }
}

/// Target body area for filtering and categorization.
public enum PoseCategory: String, Codable, Sendable, CaseIterable {
    case spine
    case hips
    case shoulders
    case neck
    case fullBody
    case breathing
    case balance

    public var localizedName: LocalizedString {
        switch self {
        case .spine:     return LocalizedString(en: "Spine", fr: "Colonne vertébrale")
        case .hips:      return LocalizedString(en: "Hips", fr: "Hanches")
        case .shoulders: return LocalizedString(en: "Shoulders", fr: "Épaules")
        case .neck:      return LocalizedString(en: "Neck", fr: "Cou")
        case .fullBody:  return LocalizedString(en: "Full Body", fr: "Corps complet")
        case .breathing: return LocalizedString(en: "Breathing", fr: "Respiration")
        case .balance:   return LocalizedString(en: "Balance", fr: "Équilibre")
        }
    }

    /// SF Symbol name representing this body category.
    public var symbolName: String {
        switch self {
        case .spine:     return "figure.flexibility"
        case .hips:      return "figure.walk"
        case .shoulders: return "figure.arms.open"
        case .neck:      return "head.profile"
        case .fullBody:  return "figure.yoga"
        case .breathing: return "wind"
        case .balance:   return "figure.stand"
        }
    }

    /// Accent color tint for this category.
    public var accentHue: Double {
        switch self {
        case .spine:     return 0.52   // cyan-blue
        case .hips:      return 0.75   // purple
        case .shoulders: return 0.58   // teal
        case .neck:      return 0.45   // cyan
        case .fullBody:  return 0.55   // blue-cyan
        case .breathing: return 0.33   // green
        case .balance:   return 0.65   // indigo
        }
    }
}

/// A single chair yoga pose with bilingual metadata for guided instruction.
public struct Pose: Codable, Sendable, Identifiable, Hashable {
    public let id: String
    public let name: LocalizedString
    public let description: LocalizedString
    public let durationSeconds: TimeInterval
    public let difficulty: PoseDifficulty
    public let category: PoseCategory
    public let imageName: String
    public let voiceCueText: LocalizedString
    public let modifications: LocalizedStringArray
    public let contraindications: LocalizedStringArray
    public let breathingPattern: LocalizedString
    public let isFree: Bool

    public init(
        id: String,
        name: LocalizedString,
        description: LocalizedString,
        durationSeconds: TimeInterval,
        difficulty: PoseDifficulty,
        category: PoseCategory,
        imageName: String,
        voiceCueText: LocalizedString,
        modifications: LocalizedStringArray,
        contraindications: LocalizedStringArray = LocalizedStringArray(en: [], fr: []),
        breathingPattern: LocalizedString = LocalizedString(en: "", fr: ""),
        isFree: Bool
    ) {
        self.id = id
        self.name = name
        self.description = description
        self.durationSeconds = durationSeconds
        self.difficulty = difficulty
        self.category = category
        self.imageName = imageName
        self.voiceCueText = voiceCueText
        self.modifications = modifications
        self.contraindications = contraindications
        self.breathingPattern = breathingPattern
        self.isFree = isFree
    }
}
