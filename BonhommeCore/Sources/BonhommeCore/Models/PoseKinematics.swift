import Foundation

public enum BodyRegion: String, Sendable, CaseIterable {
    case spine, hips, shoulders, neck, core, arms, legs, chest, back, head, breathing, balance

    public var localizedName: LocalizedString {
        switch self {
        case .spine:      return LocalizedString(en: "Spine", fr: "Colonne")
        case .hips:       return LocalizedString(en: "Hips", fr: "Hanches")
        case .shoulders:  return LocalizedString(en: "Shoulders", fr: "Épaules")
        case .neck:       return LocalizedString(en: "Neck", fr: "Cou")
        case .core:       return LocalizedString(en: "Core", fr: "Abdos")
        case .arms:       return LocalizedString(en: "Arms", fr: "Bras")
        case .legs:       return LocalizedString(en: "Legs", fr: "Jambes")
        case .chest:      return LocalizedString(en: "Chest", fr: "Poitrine")
        case .back:       return LocalizedString(en: "Back", fr: "Dos")
        case .head:       return LocalizedString(en: "Head", fr: "Tête")
        case .breathing:  return LocalizedString(en: "Breathing", fr: "Respiration")
        case .balance:    return LocalizedString(en: "Balance", fr: "Équilibre")
        }
    }

    public var jointScaleFactor: CGFloat {
        switch self {
        case .spine, .back:   return 2.0
        case .hips:           return 2.0
        case .shoulders:      return 2.2
        case .neck, .head:    return 2.4
        case .core:           return 1.8
        case .arms:           return 2.0
        case .legs:           return 2.0
        case .chest:          return 2.0
        case .breathing:      return 1.6
        case .balance:        return 2.0
        }
    }

    public var glowRadius: CGFloat { 8 }
}

public enum OscillationJoint: String, Sendable, CaseIterable {
    case torso, leftArm, rightArm, leftLeg, rightLeg, head, breathing
}

public struct PoseKinematics: Sendable, Hashable {
    public var forwardLean: Double
    public var sideLean: Double
    public var headTilt: Double
    public var spineArch: Double

    public var leftUpperArmAngle: Double
    public var rightUpperArmAngle: Double
    public var leftForearmBend: Double
    public var rightForearmBend: Double
    public var leftArmCross: Double
    public var rightArmCross: Double

    public var leftThighOffset: Double
    public var rightThighOffset: Double
    public var leftKneeSpread: Double
    public var rightKneeSpread: Double
    public var leftShinOffset: Double
    public var rightShinOffset: Double

    public var holdOscillationScale: Double
    public var oscillationJoints: Set<OscillationJoint>

    public var highlightedRegions: Set<BodyRegion>

    public var setupSteps: [LocalizedString]

    public static let neutral = PoseKinematics(
        forwardLean: 0,
        sideLean: 0,
        headTilt: 0,
        spineArch: 0,
        leftUpperArmAngle: .pi * 0.55,
        rightUpperArmAngle: .pi * 0.55,
        leftForearmBend: 0.95,
        rightForearmBend: 0.95,
        leftArmCross: 0,
        rightArmCross: 0,
        leftThighOffset: 0,
        rightThighOffset: 0,
        leftKneeSpread: 0,
        rightKneeSpread: 0,
        leftShinOffset: 0,
        rightShinOffset: 0,
        holdOscillationScale: 0.3,
        oscillationJoints: [.torso, .breathing],
        highlightedRegions: [],
        setupSteps: []
    )

    public init(
        forwardLean: Double = 0,
        sideLean: Double = 0,
        headTilt: Double = 0,
        spineArch: Double = 0,
        leftUpperArmAngle: Double = .pi * 0.55,
        rightUpperArmAngle: Double = .pi * 0.55,
        leftForearmBend: Double = 0.95,
        rightForearmBend: Double = 0.95,
        leftArmCross: Double = 0,
        rightArmCross: Double = 0,
        leftThighOffset: Double = 0,
        rightThighOffset: Double = 0,
        leftKneeSpread: Double = 0,
        rightKneeSpread: Double = 0,
        leftShinOffset: Double = 0,
        rightShinOffset: Double = 0,
        holdOscillationScale: Double = 0.3,
        oscillationJoints: Set<OscillationJoint> = [.torso, .breathing],
        highlightedRegions: Set<BodyRegion> = [],
        setupSteps: [LocalizedString] = []
    ) {
        self.forwardLean = forwardLean
        self.sideLean = sideLean
        self.headTilt = headTilt
        self.spineArch = spineArch
        self.leftUpperArmAngle = leftUpperArmAngle
        self.rightUpperArmAngle = rightUpperArmAngle
        self.leftForearmBend = leftForearmBend
        self.rightForearmBend = rightForearmBend
        self.leftArmCross = leftArmCross
        self.rightArmCross = rightArmCross
        self.leftThighOffset = leftThighOffset
        self.rightThighOffset = rightThighOffset
        self.leftKneeSpread = leftKneeSpread
        self.rightKneeSpread = rightKneeSpread
        self.leftShinOffset = leftShinOffset
        self.rightShinOffset = rightShinOffset
        self.holdOscillationScale = holdOscillationScale
        self.oscillationJoints = oscillationJoints
        self.highlightedRegions = highlightedRegions
        self.setupSteps = setupSteps
    }

    func blended(with other: PoseKinematics, factor: Double) -> PoseKinematics {
        let t = clamp01(factor)
        func lerp(_ a: Double, _ b: Double) -> Double { a + (b - a) * t }
        return PoseKinematics(
            forwardLean: lerp(other.forwardLean, forwardLean),
            sideLean: lerp(other.sideLean, sideLean),
            headTilt: lerp(other.headTilt, headTilt),
            spineArch: lerp(other.spineArch, spineArch),
            leftUpperArmAngle: lerp(other.leftUpperArmAngle, leftUpperArmAngle),
            rightUpperArmAngle: lerp(other.rightUpperArmAngle, rightUpperArmAngle),
            leftForearmBend: lerp(other.leftForearmBend, leftForearmBend),
            rightForearmBend: lerp(other.rightForearmBend, rightForearmBend),
            leftArmCross: lerp(other.leftArmCross, leftArmCross),
            rightArmCross: lerp(other.rightArmCross, rightArmCross),
            leftThighOffset: lerp(other.leftThighOffset, leftThighOffset),
            rightThighOffset: lerp(other.rightThighOffset, rightThighOffset),
            leftKneeSpread: lerp(other.leftKneeSpread, leftKneeSpread),
            rightKneeSpread: lerp(other.rightKneeSpread, rightKneeSpread),
            leftShinOffset: lerp(other.leftShinOffset, leftShinOffset),
            rightShinOffset: lerp(other.rightShinOffset, rightShinOffset),
            holdOscillationScale: lerp(other.holdOscillationScale, holdOscillationScale),
            oscillationJoints: t > 0.5 ? oscillationJoints : other.oscillationJoints,
            highlightedRegions: t > 0.5 ? highlightedRegions : other.highlightedRegions,
            setupSteps: t > 0.5 ? setupSteps : other.setupSteps
        )
    }
}

private func clamp01(_ v: Double) -> Double {
    max(0, min(1, v))
}

public enum PoseKinematicsCatalog {
    public static func kinematics(for poseID: String) -> PoseKinematics {
        switch poseID {
        case "seated-mountain":        return seatedMountain
        case "seated-cat-cow":         return seatedCatCow
        case "seated-twist":           return seatedSpinalTwist
        case "seated-forward-fold":    return seatedForwardFold
        case "neck-rolls":             return neckRolls
        case "shoulder-rolls":         return shoulderRolls
        case "seated-ankle-circles":   return seatedAnkleCircles
        case "seated-wrist-stretches": return seatedWristStretches
        case "seated-knee-lifts":      return seatedHighKneeLifts
        case "seated-meditation":      return seatedMeditation
        case "seated-eagle-arms":      return seatedEagleArms
        case "seated-pigeon":          return seatedPigeon
        case "seated-warrior-2":       return seatedWarriorII
        case "seated-side-bend":       return seatedSideBend
        case "seated-heart-opener":    return seatedHeartOpener
        case "seated-ankles-to-knees": return seatedAnklesToKnees
        case "seated-extended-side-angle": return seatedExtendedSideBend
        case "seated-goddess":         return seatedGoddess
        case "seated-reverse-warrior": return seatedReverseWarrior
        case "seated-crescent-moon":   return seatedCrescentMoon
        case "seated-chest-expansion": return seatedChestExpansion
        case "seated-sun-salutation":  return seatedSunSalutation
        case "seated-tree":            return seatedTreePose
        case "seated-thread-needle":   return seatedThreadTheNeedle
        case "seated-breath-of-joy":   return seatedBreathOfJoy
        case "seated-half-moon":       return seatedHalfMoon
        default:                       return .neutral
        }
    }

    private static let seatedMountain = PoseKinematics(
        forwardLean: 0,
        leftUpperArmAngle: 1.0,
        rightUpperArmAngle: 1.0,
        leftForearmBend: 1.0,
        rightForearmBend: 1.0,
        holdOscillationScale: 0.25,
        oscillationJoints: [.breathing],
        highlightedRegions: [.spine],
        setupSteps: [
            LocalizedString(en: "Sit tall at chair edge", fr: "Asseyez-vous droit au bord de la chaise"),
            LocalizedString(en: "Feet flat, hip-width apart", fr: "Pieds à plat, largeur des hanches"),
            LocalizedString(en: "Hands on thighs, palms down", fr: "Mains sur les cuisses, paumes vers le bas")
        ]
    )

    private static let seatedCatCow = PoseKinematics(
        forwardLean: 0.12,
        leftUpperArmAngle: 0.9,
        rightUpperArmAngle: 0.9,
        leftForearmBend: 0.85,
        rightForearmBend: 0.85,
        holdOscillationScale: 0.9,
        oscillationJoints: [.torso, .head, .breathing],
        highlightedRegions: [.spine],
        setupSteps: [
            LocalizedString(en: "Hands on knees", fr: "Mains sur les genoux"),
            LocalizedString(en: "Inhale: arch back, lift chest", fr: "Inspirez: cambrez le dos, soulevez la poitrine"),
            LocalizedString(en: "Exhale: round spine, tuck chin", fr: "Expirez: arrondissez la colonne, rentrez le menton")
        ]
    )

    private static let seatedSpinalTwist = PoseKinematics(
        forwardLean: 0.06,
        leftUpperArmAngle: 0.5,
        rightUpperArmAngle: -0.7,
        leftForearmBend: 0.7,
        rightForearmBend: 1.3,
        leftArmCross: 0.45,
        holdOscillationScale: 0.5,
        oscillationJoints: [.torso],
        highlightedRegions: [.spine],
        setupSteps: [
            LocalizedString(en: "Sit tall, feet grounded", fr: "Asseyez-vous droit, pieds ancrés"),
            LocalizedString(en: "Right hand to outer left knee", fr: "Main droite sur le genou gauche"),
            LocalizedString(en: "Left hand behind on chair", fr: "Main gauche derrière sur la chaise")
        ]
    )

    private static let seatedForwardFold = PoseKinematics(
        forwardLean: 0.42,
        leftUpperArmAngle: 1.3,
        rightUpperArmAngle: 1.3,
        leftForearmBend: 0.7,
        rightForearmBend: 0.7,
        holdOscillationScale: 0.35,
        oscillationJoints: [.torso, .breathing],
        highlightedRegions: [.spine, .back],
        setupSteps: [
            LocalizedString(en: "Hinge forward from hips", fr: "Penchez-vous depuis les hanches"),
            LocalizedString(en: "Let arms dangle toward floor", fr: "Laissez les bras pendre vers le sol"),
            LocalizedString(en: "Relax neck completely", fr: "Détendez complètement le cou")
        ]
    )

    private static let neckRolls = PoseKinematics(
        leftUpperArmAngle: 1.1,
        rightUpperArmAngle: 1.1,
        leftForearmBend: 1.0,
        rightForearmBend: 1.0,
        holdOscillationScale: 0.7,
        oscillationJoints: [.head],
        highlightedRegions: [.neck, .head],
        setupSteps: [
            LocalizedString(en: "Drop chin to chest", fr: "Baissez le menton vers la poitrine"),
            LocalizedString(en: "Roll head to one side", fr: "Faites rouler la tête d'un côté"),
            LocalizedString(en: "Continue in slow circles", fr: "Continuez en cercles lents")
        ]
    )

    private static let shoulderRolls = PoseKinematics(
        leftUpperArmAngle: 1.1,
        rightUpperArmAngle: 1.1,
        leftForearmBend: 1.0,
        rightForearmBend: 1.0,
        holdOscillationScale: 0.6,
        oscillationJoints: [.leftArm, .rightArm],
        highlightedRegions: [.shoulders],
        setupSteps: [
            LocalizedString(en: "Lift shoulders toward ears", fr: "Soulevez les épaules vers les oreilles"),
            LocalizedString(en: "Roll them back and down", fr: "Roulez-les vers l'arrière et le bas"),
            LocalizedString(en: "Smooth circular motion", fr: "Mouvement circulaire fluide")
        ]
    )

    private static let seatedAnkleCircles = PoseKinematics(
        leftUpperArmAngle: 1.0,
        rightUpperArmAngle: 1.0,
        rightThighOffset: -0.25,
        rightKneeSpread: 0.08,
        holdOscillationScale: 0.55,
        oscillationJoints: [.rightLeg],
        highlightedRegions: [.legs, .balance],
        setupSteps: [
            LocalizedString(en: "Extend right leg slightly", fr: "Étendez légèrement la jambe droite"),
            LocalizedString(en: "Circle ankle slowly", fr: "Faites des cercles lents avec la cheville"),
            LocalizedString(en: "Reverse direction halfway", fr: "Inversez la direction à mi-chemin")
        ]
    )

    private static let seatedWristStretches = PoseKinematics(
        leftUpperArmAngle: 0.15,
        rightUpperArmAngle: 0.15,
        leftForearmBend: 2.7,
        rightForearmBend: 2.7,
        holdOscillationScale: 0.4,
        oscillationJoints: [.leftArm, .rightArm],
        highlightedRegions: [.shoulders, .arms],
        setupSteps: [
            LocalizedString(en: "Extend arms forward", fr: "Tendez les bras vers l'avant"),
            LocalizedString(en: "Flex wrists upward", fr: "Fléchissez les poignets vers le haut"),
            LocalizedString(en: "Then stretch downward", fr: "Puis étirez vers le bas")
        ]
    )

    private static let seatedHighKneeLifts = PoseKinematics(
        forwardLean: 0.06,
        leftUpperArmAngle: 0.8,
        rightUpperArmAngle: 0.8,
        leftForearmBend: 1.0,
        rightForearmBend: 1.0,
        leftThighOffset: -0.45,
        leftKneeSpread: 0.06,
        holdOscillationScale: 0.75,
        oscillationJoints: [.leftLeg, .rightLeg, .torso],
        highlightedRegions: [.legs, .core],
        setupSteps: [
            LocalizedString(en: "Sit tall, engage core", fr: "Asseyez-vous droit, engagez le centre"),
            LocalizedString(en: "Lift one knee toward chest", fr: "Soulevez un genou vers la poitrine"),
            LocalizedString(en: "Alternate sides with control", fr: "Alternez les côtés avec contrôle")
        ]
    )

    private static let seatedMeditation = PoseKinematics(
        leftUpperArmAngle: 0.95,
        rightUpperArmAngle: 0.95,
        leftForearmBend: 1.0,
        rightForearmBend: 1.0,
        holdOscillationScale: 0.08,
        oscillationJoints: [.breathing],
        highlightedRegions: [.breathing],
        setupSteps: [
            LocalizedString(en: "Close your eyes gently", fr: "Fermez doucement les yeux"),
            LocalizedString(en: "Rest hands on thighs", fr: "Reposez les mains sur les cuisses"),
            LocalizedString(en: "Breathe naturally", fr: "Respirez naturellement")
        ]
    )

    private static let seatedEagleArms = PoseKinematics(
        leftUpperArmAngle: 0.35,
        rightUpperArmAngle: 0.35,
        leftForearmBend: 1.7,
        rightForearmBend: 1.7,
        leftArmCross: 0.55,
        rightArmCross: 0.55,
        holdOscillationScale: 0.3,
        oscillationJoints: [.leftArm, .rightArm, .breathing],
        highlightedRegions: [.shoulders, .arms],
        setupSteps: [
            LocalizedString(en: "Extend arms forward", fr: "Tendez les bras vers l'avant"),
            LocalizedString(en: "Cross right under left", fr: "Croisez le droit sous le gauche"),
            LocalizedString(en: "Press palms together", fr: "Pressez les paumes l'une contre l'autre")
        ]
    )

    private static let seatedPigeon = PoseKinematics(
        forwardLean: 0.1,
        leftUpperArmAngle: 1.0,
        rightUpperArmAngle: 1.0,
        leftForearmBend: 1.0,
        rightForearmBend: 1.0,
        rightKneeSpread: 0.4,
        rightShinOffset: 0.35,
        holdOscillationScale: 0.4,
        oscillationJoints: [.torso, .breathing],
        highlightedRegions: [.hips],
        setupSteps: [
            LocalizedString(en: "Place right ankle on left knee", fr: "Placez la cheville droite sur le genou gauche"),
            LocalizedString(en: "Keep spine tall", fr: "Gardez la colonne droite"),
            LocalizedString(en: "Gently lean forward for depth", fr: "Penchez-vous doucement vers l'avant")
        ]
    )

    private static let seatedWarriorII = PoseKinematics(
        leftUpperArmAngle: 2.9,
        rightUpperArmAngle: 0.25,
        leftForearmBend: 2.8,
        rightForearmBend: 2.8,
        holdOscillationScale: 0.2,
        oscillationJoints: [.breathing],
        highlightedRegions: [.shoulders, .arms, .legs],
        setupSteps: [
            LocalizedString(en: "Open arms to sides", fr: "Ouvrez les bras sur les côtés"),
            LocalizedString(en: "Palms face down, arms level", fr: "Paumes vers le bas, bras à l'horizontale"),
            LocalizedString(en: "Gaze over front fingertips", fr: "Regardez au-delà des doigts avant")
        ]
    )

    private static let seatedSideBend = PoseKinematics(
        sideLean: 0.28,
        leftUpperArmAngle: -1.1,
        rightUpperArmAngle: 1.1,
        leftForearmBend: 2.5,
        rightForearmBend: 1.0,
        holdOscillationScale: 0.35,
        oscillationJoints: [.torso, .leftArm, .breathing],
        highlightedRegions: [.spine],
        setupSteps: [
            LocalizedString(en: "Reach left arm overhead", fr: "Tendez le bras gauche au-dessus de la tête"),
            LocalizedString(en: "Bend to the right side", fr: "Inclinez-vous vers la droite"),
            LocalizedString(en: "Keep both sitting bones grounded", fr: "Gardez les ischions ancrés")
        ]
    )

    private static let seatedHeartOpener = PoseKinematics(
        forwardLean: -0.08,
        spineArch: 0.15,
        leftUpperArmAngle: -0.4,
        rightUpperArmAngle: -0.4,
        leftForearmBend: 1.2,
        rightForearmBend: 1.2,
        holdOscillationScale: 0.3,
        oscillationJoints: [.torso, .breathing],
        highlightedRegions: [.chest, .spine],
        setupSteps: [
            LocalizedString(en: "Clasp hands behind back", fr: "Joignez les mains derrière le dos"),
            LocalizedString(en: "Roll shoulders back and down", fr: "Roulez les épaules vers l'arrière"),
            LocalizedString(en: "Lift chest toward ceiling", fr: "Soulevez la poitrine vers le plafond")
        ]
    )

    private static let seatedAnklesToKnees = PoseKinematics(
        forwardLean: 0.1,
        leftUpperArmAngle: 0.9,
        rightUpperArmAngle: 0.9,
        leftKneeSpread: 0.35,
        rightKneeSpread: 0.35,
        holdOscillationScale: 0.35,
        oscillationJoints: [.torso, .breathing],
        highlightedRegions: [.hips],
        setupSteps: [
            LocalizedString(en: "Cross right ankle over left knee", fr: "Croisez la cheville droite sur le genou gauche"),
            LocalizedString(en: "Stack left ankle on right knee", fr: "Placez la cheville gauche sur le genou droit"),
            LocalizedString(en: "Sit tall, hinge forward gently", fr: "Asseyez-vous droit, penchez-vous doucement")
        ]
    )

    private static let seatedExtendedSideBend = PoseKinematics(
        sideLean: 0.22,
        leftUpperArmAngle: -1.3,
        rightUpperArmAngle: 1.1,
        leftForearmBend: 2.5,
        rightForearmBend: 1.0,
        holdOscillationScale: 0.35,
        oscillationJoints: [.torso, .leftArm, .breathing],
        highlightedRegions: [.spine, .shoulders],
        setupSteps: [
            LocalizedString(en: "Right hand on chair for support", fr: "Main droite sur la chaise pour soutien"),
            LocalizedString(en: "Reach left arm up and over", fr: "Tendez le bras gauche vers le haut et par-dessus"),
            LocalizedString(en: "Lengthen through left side body", fr: "Allongez le côté gauche du corps")
        ]
    )

    private static let seatedGoddess = PoseKinematics(
        leftUpperArmAngle: 0.05,
        rightUpperArmAngle: 0.05,
        leftForearmBend: 1.57,
        rightForearmBend: 1.57,
        leftKneeSpread: 0.35,
        rightKneeSpread: 0.35,
        holdOscillationScale: 0.3,
        oscillationJoints: [.leftArm, .rightArm, .breathing],
        highlightedRegions: [.hips, .arms],
        setupSteps: [
            LocalizedString(en: "Open knees wide to sides", fr: "Ouvrez les genoux largement sur les côtés"),
            LocalizedString(en: "Arms in cactus position", fr: "Bras en position cactus"),
            LocalizedString(en: "Elbows at 90 degrees", fr: "Coudes à 90 degrés")
        ]
    )

    private static let seatedReverseWarrior = PoseKinematics(
        sideLean: -0.18,
        leftUpperArmAngle: 1.1,
        rightUpperArmAngle: -1.2,
        leftForearmBend: 1.0,
        rightForearmBend: 2.5,
        holdOscillationScale: 0.3,
        oscillationJoints: [.torso, .rightArm, .breathing],
        highlightedRegions: [.spine, .shoulders],
        setupSteps: [
            LocalizedString(en: "Left hand rests on left thigh", fr: "Main gauche repose sur la cuisse gauche"),
            LocalizedString(en: "Reach right arm up and back", fr: "Tendez le bras droit vers le haut et l'arrière"),
            LocalizedString(en: "Open through right side body", fr: "Ouvrez le côté droit du corps")
        ]
    )

    private static let seatedCrescentMoon = PoseKinematics(
        sideLean: 0.2,
        leftUpperArmAngle: -1.4,
        rightUpperArmAngle: -1.4,
        leftForearmBend: 2.7,
        rightForearmBend: 2.7,
        holdOscillationScale: 0.3,
        oscillationJoints: [.torso, .leftArm, .rightArm, .breathing],
        highlightedRegions: [.spine, .shoulders],
        setupSteps: [
            LocalizedString(en: "Interlace fingers overhead", fr: "Croisez les doigts au-dessus de la tête"),
            LocalizedString(en: "Bend gently to one side", fr: "Inclinez-vous doucement d'un côté"),
            LocalizedString(en: "Breathe into the stretch", fr: "Respirez dans l'étirement")
        ]
    )

    private static let seatedChestExpansion = PoseKinematics(
        forwardLean: -0.06,
        spineArch: 0.12,
        leftUpperArmAngle: -0.25,
        rightUpperArmAngle: -0.25,
        leftForearmBend: 1.35,
        rightForearmBend: 1.35,
        holdOscillationScale: 0.3,
        oscillationJoints: [.torso, .leftArm, .rightArm, .breathing],
        highlightedRegions: [.chest, .shoulders],
        setupSteps: [
            LocalizedString(en: "Reach arms behind your back", fr: "Tendez les bras derrière le dos"),
            LocalizedString(en: "Interlace fingers if possible", fr: "Croisez les doigts si possible"),
            LocalizedString(en: "Lift arms away from body", fr: "Soulevez les bras loin du corps")
        ]
    )

    private static let seatedSunSalutation = PoseKinematics(
        leftUpperArmAngle: -1.35,
        rightUpperArmAngle: -1.35,
        leftForearmBend: 2.6,
        rightForearmBend: 2.6,
        holdOscillationScale: 0.85,
        oscillationJoints: [.torso, .leftArm, .rightArm, .breathing],
        highlightedRegions: [.spine, .shoulders, .chest],
        setupSteps: [
            LocalizedString(en: "Palms together at heart center", fr: "Paumes jointes au centre du cœur"),
            LocalizedString(en: "Reach arms overhead on inhale", fr: "Tendez les bras vers le haut à l'inspire"),
            LocalizedString(en: "Fold forward on exhale", fr: "Penchez-vous vers l'avant à l'expire")
        ]
    )

    private static let seatedTreePose = PoseKinematics(
        leftUpperArmAngle: -1.35,
        rightUpperArmAngle: -1.35,
        leftForearmBend: 2.6,
        rightForearmBend: 2.6,
        rightThighOffset: -0.35,
        rightKneeSpread: 0.3,
        rightShinOffset: 0.2,
        holdOscillationScale: 0.25,
        oscillationJoints: [.torso, .breathing],
        highlightedRegions: [.balance, .legs],
        setupSteps: [
            LocalizedString(en: "Place right foot on inner left thigh", fr: "Placez le pied droit sur la cuisse gauche interne"),
            LocalizedString(en: "Press palms together overhead", fr: "Pressez les paumes ensemble au-dessus"),
            LocalizedString(en: "Find a steady gaze point", fr: "Trouvez un point de regard fixe")
        ]
    )

    private static let seatedThreadTheNeedle = PoseKinematics(
        forwardLean: 0.18,
        sideLean: -0.1,
        leftUpperArmAngle: 0.75,
        rightUpperArmAngle: 1.0,
        leftForearmBend: 0.6,
        rightForearmBend: 1.0,
        leftArmCross: 0.6,
        holdOscillationScale: 0.4,
        oscillationJoints: [.torso, .leftArm, .breathing],
        highlightedRegions: [.spine, .shoulders],
        setupSteps: [
            LocalizedString(en: "Thread left arm under right", fr: "Passez le bras gauche sous le droit"),
            LocalizedString(en: "Lower left shoulder and ear", fr: "Baissez l'épaule et l'oreille gauches"),
            LocalizedString(en: "Breathe into upper back", fr: "Respirez dans le haut du dos")
        ]
    )

    private static let seatedBreathOfJoy = PoseKinematics(
        leftUpperArmAngle: -1.1,
        rightUpperArmAngle: -1.1,
        leftForearmBend: 2.5,
        rightForearmBend: 2.5,
        holdOscillationScale: 0.95,
        oscillationJoints: [.torso, .leftArm, .rightArm, .breathing],
        highlightedRegions: [.breathing, .shoulders],
        setupSteps: [
            LocalizedString(en: "Inhale: arms halfway up", fr: "Inspirez: bras à mi-hauteur"),
            LocalizedString(en: "Inhale: arms to sides", fr: "Inspirez: bras sur les côtés"),
            LocalizedString(en: "Inhale: arms overhead, then exhale fold", fr: "Inspirez: bras en haut, expirez penchez-vous")
        ]
    )

    private static let seatedHalfMoon = PoseKinematics(
        sideLean: 0.32,
        leftUpperArmAngle: -1.45,
        rightUpperArmAngle: 1.2,
        leftForearmBend: 2.5,
        rightForearmBend: 1.0,
        holdOscillationScale: 0.35,
        oscillationJoints: [.torso, .leftArm, .breathing],
        highlightedRegions: [.spine, .balance],
        setupSteps: [
            LocalizedString(en: "Right hand reaches to side", fr: "Main droite tendue sur le côté"),
            LocalizedString(en: "Left arm reaches up and over", fr: "Bras gauche tendu vers le haut et par-dessus"),
            LocalizedString(en: "Deep lateral stretch", fr: "Étirement latéral profond")
        ]
    )
}
