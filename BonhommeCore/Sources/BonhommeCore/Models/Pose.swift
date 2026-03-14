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
