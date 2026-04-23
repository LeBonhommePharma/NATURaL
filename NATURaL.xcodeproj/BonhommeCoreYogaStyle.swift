import Foundation

/// Yoga practice styles with distinct characteristics and benefits.
public enum YogaStyle: String, CaseIterable, Codable, Sendable {
    case pranayama
    case chairYoga
    case vinyasa
    case hatha
    case yin
    case restorative
    case power
    case standingBalance
    case prenatal
    
    public var localizedName: LocalizedString {
        switch self {
        case .pranayama:
            return LocalizedString(en: "Pranayama", fr: "Pranayama")
        case .chairYoga:
            return LocalizedString(en: "Chair Yoga", fr: "Yoga sur chaise")
        case .vinyasa:
            return LocalizedString(en: "Vinyasa", fr: "Vinyasa")
        case .hatha:
            return LocalizedString(en: "Hatha", fr: "Hatha")
        case .yin:
            return LocalizedString(en: "Yin", fr: "Yin")
        case .restorative:
            return LocalizedString(en: "Restorative", fr: "Réparateur")
        case .power:
            return LocalizedString(en: "Power", fr: "Puissance")
        case .standingBalance:
            return LocalizedString(en: "Standing Balance", fr: "Équilibre debout")
        case .prenatal:
            return LocalizedString(en: "Prenatal", fr: "Prénatal")
        }
    }
    
    public var symbolName: String {
        switch self {
        case .pranayama:
            return "wind"
        case .chairYoga:
            return "chair.fill"
        case .vinyasa:
            return "figure.yoga"
        case .hatha:
            return "figure.mind.and.body"
        case .yin:
            return "moon.stars.fill"
        case .restorative:
            return "bed.double.fill"
        case .power:
            return "bolt.fill"
        case .standingBalance:
            return "figure.stand"
        case .prenatal:
            return "heart.circle.fill"
        }
    }
    
    public var accentHue: Double {
        switch self {
        case .pranayama:
            return 0.55 // Cyan/Blue
        case .chairYoga:
            return 0.35 // Green
        case .vinyasa:
            return 0.6  // Blue
        case .hatha:
            return 0.15 // Orange
        case .yin:
            return 0.75 // Purple
        case .restorative:
            return 0.8  // Purple/Pink
        case .power:
            return 0.0  // Red
        case .standingBalance:
            return 0.45 // Teal
        case .prenatal:
            return 0.9  // Pink
        }
    }
}
