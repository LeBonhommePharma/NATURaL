import Foundation

/// Difficulty levels for yoga poses.
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

/// Body position required by the pose.
public enum PosePosition: String, Codable, Sendable, CaseIterable {
    case seated       // Chair yoga, seated meditation
    case standing     // Vinyasa, hatha standing, power
    case supine       // Lying on back — yin, restorative, savasana
    case prone        // Lying face down — cobra, locust, bow
    case kneeling     // Tabletop, low lunge, camel
    case inversion    // Downward dog, legs-up-the-wall, headstand prep

    public var localizedName: LocalizedString {
        switch self {
        case .seated:    return LocalizedString(en: "Seated", fr: "Assis")
        case .standing:  return LocalizedString(en: "Standing", fr: "Debout")
        case .supine:    return LocalizedString(en: "Supine", fr: "Couché sur le dos")
        case .prone:     return LocalizedString(en: "Prone", fr: "Couché sur le ventre")
        case .kneeling:  return LocalizedString(en: "Kneeling", fr: "À genoux")
        case .inversion: return LocalizedString(en: "Inversion", fr: "Inversion")
        }
    }

    public var symbolName: String {
        switch self {
        case .seated:    return "figure.seated.side"
        case .standing:  return "figure.stand"
        case .supine:    return "figure.roll"
        case .prone:     return "figure.roll"
        case .kneeling:  return "figure.flexibility"
        case .inversion: return "figure.yoga"
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
    case core
    case arms
    case legs
    case chest
    case back
    case relaxation
    case inversion

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
        case .spine:       return "figure.flexibility"
        case .hips:        return "figure.walk"
        case .shoulders:   return "figure.arms.open"
        case .neck:        return "head.profile"
        case .fullBody:    return "figure.yoga"
        case .breathing:   return "wind"
        case .balance:     return "figure.stand"
        case .core:        return "figure.core.training"
        case .arms:        return "figure.arms.open"
        case .legs:        return "figure.run"
        case .chest:       return "figure.arms.open"
        case .back:        return "figure.flexibility"
        case .relaxation:  return "moon.zzz"
        case .inversion:   return "figure.yoga"
        }
    }

    /// Accent color tint for this category.
    public var accentHue: Double {
        switch self {
        case .spine:       return 0.52   // cyan-blue
        case .hips:        return 0.75   // purple
        case .shoulders:   return 0.58   // teal
        case .neck:        return 0.45   // cyan
        case .fullBody:    return 0.55   // blue-cyan
        case .breathing:   return 0.33   // green
        case .balance:     return 0.65   // indigo
        case .core:        return 0.08   // orange
        case .arms:        return 0.60   // blue
        case .legs:        return 0.70   // violet
        case .chest:       return 0.10   // red-orange
        case .back:        return 0.50   // cyan
        case .relaxation:  return 0.80   // lavender
        case .inversion:   return 0.15   // red
        }
    }
}

/// A single yoga pose with bilingual metadata for guided instruction.
public struct Pose: Codable, Sendable, Identifiable, Hashable {
    public let id: String
    public let name: LocalizedString
    public let description: LocalizedString
    public let durationSeconds: TimeInterval
    public let difficulty: PoseDifficulty
    public let category: PoseCategory
    public let position: PosePosition
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
        position: PosePosition = .seated,
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
        self.position = position
        self.imageName = imageName
        self.voiceCueText = voiceCueText
        self.modifications = modifications
        self.contraindications = contraindications
        self.breathingPattern = breathingPattern
        self.isFree = isFree
    }
}
