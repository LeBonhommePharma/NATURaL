import Foundation

/// The twelve PokeDrug pharmacological "types," each corresponding to a major
/// pharmacological target class — a receptor, transporter, or ion channel
/// through which psychoactive molecules exert their effects.
///
/// Modeled after Pokemon elemental types. Most scaffolds carry a single primary
/// type; the most pharmacologically interesting molecules (LSD, MDMA, ibogaine)
/// are dual-type or triple-type.
public enum PokeDrugType: String, Codable, Sendable, CaseIterable {
    /// 5-HT2A receptor agonism. Endogenous: serotonin.
    case serotonin

    /// Mu-opioid receptor agonism. Endogenous: beta-endorphin.
    case opioid

    /// DAT inhibition / dopamine release. Endogenous: dopamine.
    case dopamine

    /// SERT release (serotonin flood). Endogenous: serotonin.
    case empathogen

    /// NMDA receptor antagonism. Endogenous: glutamate (blocked).
    case dissociative

    /// CB1/CB2 receptor agonism. Endogenous: anandamide.
    case cannabinoid

    /// Kappa-opioid receptor agonism. Endogenous: dynorphin.
    case kappa

    /// NET release / DAT release. Endogenous: norepinephrine.
    case stimulant

    /// GABA-A receptor positive allosteric modulation. Endogenous: GABA.
    case sedative

    /// nAChR agonism or mAChR antagonism. Endogenous: acetylcholine.
    case cholinergic

    /// A1/A2A adenosine receptor antagonism. Endogenous: adenosine.
    case adenosine

    /// Sigma-1/2 receptor modulation. Endogenous: neurosteroids.
    case sigma
}

// MARK: - Metadata

extension PokeDrugType {

    /// The primary pharmacological target for this type.
    public var pharmacologicalTarget: LocalizedString {
        switch self {
        case .serotonin:
            return LocalizedString(en: "5-HT2A receptor (agonism)", fr: "Recepteur 5-HT2A (agonisme)")
        case .opioid:
            return LocalizedString(en: "Mu-opioid receptor (agonism)", fr: "Recepteur mu-opioide (agonisme)")
        case .dopamine:
            return LocalizedString(en: "DAT inhibition / DA release", fr: "Inhibition du DAT / liberation de DA")
        case .empathogen:
            return LocalizedString(en: "SERT release (serotonin flood)", fr: "Liberation du SERT (inondation de serotonine)")
        case .dissociative:
            return LocalizedString(en: "NMDA receptor (antagonism)", fr: "Recepteur NMDA (antagonisme)")
        case .cannabinoid:
            return LocalizedString(en: "CB1/CB2 receptor (agonism)", fr: "Recepteur CB1/CB2 (agonisme)")
        case .kappa:
            return LocalizedString(en: "Kappa-opioid receptor (agonism)", fr: "Recepteur kappa-opioide (agonisme)")
        case .stimulant:
            return LocalizedString(en: "NET release / DAT release", fr: "Liberation du NET / liberation du DAT")
        case .sedative:
            return LocalizedString(en: "GABA-A receptor (PAM)", fr: "Recepteur GABA-A (MAP)")
        case .cholinergic:
            return LocalizedString(en: "nAChR agonism / mAChR antagonism", fr: "Agonisme nAChR / antagonisme mAChR")
        case .adenosine:
            return LocalizedString(en: "A1/A2A receptor antagonism", fr: "Antagonisme du recepteur A1/A2A")
        case .sigma:
            return LocalizedString(en: "Sigma-1/2 receptor", fr: "Recepteur sigma-1/2")
        }
    }

    /// The endogenous ligand for the target receptor.
    public var endogenousLigand: LocalizedString {
        switch self {
        case .serotonin:
            return LocalizedString(en: "Serotonin", fr: "Serotonine")
        case .opioid:
            return LocalizedString(en: "Beta-endorphin", fr: "Beta-endorphine")
        case .dopamine:
            return LocalizedString(en: "Dopamine", fr: "Dopamine")
        case .empathogen:
            return LocalizedString(en: "Serotonin", fr: "Serotonine")
        case .dissociative:
            return LocalizedString(en: "Glutamate (blocked)", fr: "Glutamate (bloque)")
        case .cannabinoid:
            return LocalizedString(en: "Anandamide", fr: "Anandamide")
        case .kappa:
            return LocalizedString(en: "Dynorphin", fr: "Dynorphine")
        case .stimulant:
            return LocalizedString(en: "Norepinephrine", fr: "Noradrenaline")
        case .sedative:
            return LocalizedString(en: "GABA", fr: "GABA")
        case .cholinergic:
            return LocalizedString(en: "Acetylcholine", fr: "Acetylcholine")
        case .adenosine:
            return LocalizedString(en: "Adenosine", fr: "Adenosine")
        case .sigma:
            return LocalizedString(en: "Neurosteroids", fr: "Neurosteroides")
        }
    }

    /// The prototype drug that exemplifies this type.
    public var prototypeDrug: LocalizedString {
        switch self {
        case .serotonin:
            return LocalizedString(en: "Psilocin", fr: "Psilocine")
        case .opioid:
            return LocalizedString(en: "Morphine", fr: "Morphine")
        case .dopamine:
            return LocalizedString(en: "Amphetamine", fr: "Amphetamine")
        case .empathogen:
            return LocalizedString(en: "MDMA", fr: "MDMA")
        case .dissociative:
            return LocalizedString(en: "Ketamine", fr: "Ketamine")
        case .cannabinoid:
            return LocalizedString(en: "THC", fr: "THC")
        case .kappa:
            return LocalizedString(en: "Salvinorin A", fr: "Salvinorine A")
        case .stimulant:
            return LocalizedString(en: "Cathinone", fr: "Cathinone")
        case .sedative:
            return LocalizedString(en: "Apigenin", fr: "Apigenine")
        case .cholinergic:
            return LocalizedString(en: "Nicotine / Atropine", fr: "Nicotine / Atropine")
        case .adenosine:
            return LocalizedString(en: "Caffeine", fr: "Cafeine")
        case .sigma:
            return LocalizedString(en: "DMT (secondary)", fr: "DMT (secondaire)")
        }
    }

    /// Hex color code for UI rendering.
    public var color: String {
        switch self {
        case .serotonin:    return "#7B68EE"  // Medium slate blue
        case .opioid:       return "#DC143C"  // Crimson
        case .dopamine:     return "#FF8C00"  // Dark orange
        case .empathogen:   return "#FF69B4"  // Hot pink
        case .dissociative: return "#4682B4"  // Steel blue
        case .cannabinoid:  return "#228B22"  // Forest green
        case .kappa:        return "#8B008B"  // Dark magenta
        case .stimulant:    return "#FFD700"  // Gold
        case .sedative:     return "#6B8E23"  // Olive drab
        case .cholinergic:  return "#CD853F"  // Peru
        case .adenosine:    return "#8B4513"  // Saddle brown
        case .sigma:        return "#708090"  // Slate gray
        }
    }
}
