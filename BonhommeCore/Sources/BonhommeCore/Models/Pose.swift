import Foundation

/// Difficulty levels for chair yoga poses.
public enum PoseDifficulty: String, Codable, Sendable, CaseIterable {
    case beginner
    case intermediate
    case advanced

    public var localizedName: LocalizedString {
        switch self {
        case .beginner:
            return LocalizedString(en: "Beginner", fr: "Débutant", es: "Principiante", ja: "初級", zh: "初学者", ko: "초급", ru: "Начинающий", de: "Anfänger", ar: "مبتدئ")
        case .intermediate:
            return LocalizedString(en: "Intermediate", fr: "Intermédiaire", es: "Intermedio", ja: "中級", zh: "中级", ko: "중급", ru: "Средний", de: "Mittel", ar: "متوسط")
        case .advanced:
            return LocalizedString(en: "Advanced", fr: "Avancé", es: "Avanzado", ja: "上級", zh: "高级", ko: "고급", ru: "Продвинутый", de: "Fortgeschritten", ar: "متقدم")
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
        case .spine:     return LocalizedString(en: "Spine", fr: "Colonne vertébrale", es: "Columna vertebral", ja: "背骨", zh: "脊柱", ko: "척추", ru: "Позвоночник", de: "Wirbelsäule", ar: "العمود الفقري")
        case .hips:      return LocalizedString(en: "Hips", fr: "Hanches", es: "Caderas", ja: "股関節", zh: "臀部", ko: "골반", ru: "Бёдра", de: "Hüften", ar: "الوركان")
        case .shoulders: return LocalizedString(en: "Shoulders", fr: "Épaules", es: "Hombros", ja: "肩", zh: "肩膀", ko: "어깨", ru: "Плечи", de: "Schultern", ar: "الكتفان")
        case .neck:      return LocalizedString(en: "Neck", fr: "Cou", es: "Cuello", ja: "首", zh: "颈部", ko: "목", ru: "Шея", de: "Nacken", ar: "الرقبة")
        case .fullBody:  return LocalizedString(en: "Full Body", fr: "Corps complet", es: "Cuerpo completo", ja: "全身", zh: "全身", ko: "전신", ru: "Всё тело", de: "Ganzkörper", ar: "الجسم بالكامل")
        case .breathing: return LocalizedString(en: "Breathing", fr: "Respiration", es: "Respiración", ja: "呼吸", zh: "呼吸", ko: "호흡", ru: "Дыхание", de: "Atmung", ar: "التنفس")
        case .balance:   return LocalizedString(en: "Balance", fr: "Équilibre", es: "Equilibrio", ja: "バランス", zh: "平衡", ko: "균형", ru: "Баланс", de: "Gleichgewicht", ar: "التوازن")
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
        contraindications: LocalizedStringArray = LocalizedStringArray(en: [], fr: [], es: [], ja: [], zh: [], ko: [], ru: [], de: [], ar: []),
        breathingPattern: LocalizedString = LocalizedString(en: "", fr: "", es: "", ja: "", zh: "", ko: "", ru: "", de: "", ar: ""),
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
