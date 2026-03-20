import Foundation

/// Yoga tradition or practice style.
public enum YogaStyle: String, Codable, Sendable, CaseIterable {
    case chairYoga
    case vinyasa
    case hatha
    case yin
    case restorative
    case power
    case standingBalance
    case prenatal
    case pranayama

    public var localizedName: LocalizedString {
        switch self {
        case .chairYoga:       return LocalizedString(en: "Chair Yoga", fr: "Yoga sur chaise")
        case .vinyasa:         return LocalizedString(en: "Vinyasa Flow", fr: "Vinyasa Flow")
        case .hatha:           return LocalizedString(en: "Hatha Yoga", fr: "Hatha Yoga")
        case .yin:             return LocalizedString(en: "Yin Yoga", fr: "Yin Yoga")
        case .restorative:     return LocalizedString(en: "Restorative", fr: "Restauratif")
        case .power:           return LocalizedString(en: "Power Yoga", fr: "Power Yoga")
        case .standingBalance: return LocalizedString(en: "Balance", fr: "Équilibre")
        case .prenatal:        return LocalizedString(en: "Prenatal", fr: "Prénatal")
        case .pranayama:       return LocalizedString(en: "Pranayama", fr: "Pranayama")
        }
    }

    public var localizedDescription: LocalizedString {
        switch self {
        case .chairYoga:
            return LocalizedString(
                en: "Accessible yoga performed entirely from a chair — perfect for the office, limited mobility, or gentle practice.",
                fr: "Yoga accessible pratiqué entièrement sur une chaise — parfait pour le bureau, la mobilité réduite ou une pratique douce."
            )
        case .vinyasa:
            return LocalizedString(
                en: "Dynamic, breath-synchronized flowing sequences linking poses in continuous movement.",
                fr: "Séquences dynamiques synchronisées avec le souffle, reliant les postures en mouvement continu."
            )
        case .hatha:
            return LocalizedString(
                en: "Classical yoga with longer holds, mixing standing and floor poses for strength and flexibility.",
                fr: "Yoga classique avec des maintiens prolongés, mêlant postures debout et au sol pour la force et la souplesse."
            )
        case .yin:
            return LocalizedString(
                en: "Passive floor poses held for 90–120 seconds, targeting deep connective tissue and fascia.",
                fr: "Postures passives au sol maintenues 90 à 120 secondes, ciblant les tissus conjonctifs profonds et les fascias."
            )
        case .restorative:
            return LocalizedString(
                en: "Gentle, prop-supported poses for deep relaxation and nervous system recovery.",
                fr: "Postures douces soutenues par des accessoires pour une relaxation profonde et la récupération du système nerveux."
            )
        case .power:
            return LocalizedString(
                en: "Vigorous, strength-focused sequences with planks, arm balances, and dynamic movement.",
                fr: "Séquences vigoureuses axées sur la force avec des planches, des équilibres sur les bras et des mouvements dynamiques."
            )
        case .standingBalance:
            return LocalizedString(
                en: "Standing poses that develop proprioception, focus, and single-leg stability.",
                fr: "Postures debout qui développent la proprioception, la concentration et la stabilité sur une jambe."
            )
        case .prenatal:
            return LocalizedString(
                en: "Safe, pregnancy-adapted poses supporting comfort, strength, and breathing for each trimester.",
                fr: "Postures adaptées à la grossesse favorisant le confort, la force et la respiration pour chaque trimestre."
            )
        case .pranayama:
            return LocalizedString(
                en: "Breathing exercises and guided meditation techniques for mental clarity and calm.",
                fr: "Exercices de respiration et techniques de méditation guidée pour la clarté mentale et le calme."
            )
        }
    }

    /// SF Symbol for the style card.
    public var symbolName: String {
        switch self {
        case .chairYoga:       return "chair"
        case .vinyasa:         return "figure.yoga"
        case .hatha:           return "figure.mind.and.body"
        case .yin:             return "moon.stars"
        case .restorative:     return "leaf"
        case .power:           return "bolt.fill"
        case .standingBalance: return "figure.stand"
        case .prenatal:        return "heart.circle"
        case .pranayama:       return "wind"
        }
    }

    /// Accent color hue for style card.
    public var accentHue: Double {
        switch self {
        case .chairYoga:       return 0.52   // cyan
        case .vinyasa:         return 0.08   // orange
        case .hatha:           return 0.55   // blue
        case .yin:             return 0.75   // purple
        case .restorative:     return 0.33   // green
        case .power:           return 0.02   // red
        case .standingBalance: return 0.65   // indigo
        case .prenatal:        return 0.90   // pink
        case .pranayama:       return 0.45   // teal
        }
    }
}

/// A structured sequence of poses forming a complete yoga session.
public struct WorkoutPlan: Codable, Sendable, Identifiable {
    public let id: String
    public let name: LocalizedString
    public let description: LocalizedString
    public let style: YogaStyle
    public let poses: [Pose]
    public let transitionSeconds: TimeInterval
    public let isFree: Bool

    public var totalDuration: TimeInterval {
        let poseDuration = poses.reduce(0) { $0 + $1.durationSeconds }
        let transitions = TimeInterval(max(0, poses.count - 1)) * transitionSeconds
        return poseDuration + transitions
    }

    public var poseCount: Int { poses.count }

    public init(
        id: String,
        name: LocalizedString,
        description: LocalizedString,
        style: YogaStyle = .chairYoga,
        poses: [Pose],
        transitionSeconds: TimeInterval = 5,
        isFree: Bool = false
    ) {
        self.id = id
        self.name = name
        self.description = description
        self.style = style
        self.poses = poses
        self.transitionSeconds = transitionSeconds
        self.isFree = isFree
    }
}
