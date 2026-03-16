import Foundation

/// The ten core molecular scaffolds that function as PokeDrug "species."
///
/// Each scaffold is a recognizable structural chassis that determines which
/// PokeDrug types a compound can express. The scaffold predicts receptor affinity
/// more reliably than any other single variable, because selectivity arises from
/// structural mimicry of endogenous ligands.
public enum MolecularScaffold: String, Codable, Sendable, CaseIterable {
    /// Indole core + ethylamine sidechain. Serotonin itself is a tryptamine.
    /// Ki at 5-HT2A: psilocin 25-107 nM, DMT 77-360 nM.
    case tryptamine

    /// Fused tetracyclic indole. Tryptamine's "final evolution" — locked into
    /// optimal binding conformation. LSD Ki at 5-HT2A: 3-7 nM.
    case ergoline

    /// Pentacyclic morphinan mimics enkephalin Tyr1 residue.
    /// Morphine Ki at MOR: 1.2-14 nM.
    case morphinan

    /// Minimalist scaffold: phenyl ring + 2-carbon chain + amine.
    /// Parent structure of dopamine, norepinephrine, epinephrine.
    case phenethylamine

    /// Rigid bicyclic ring supporting DAT block (cocaine) or mAChR antagonism (atropine).
    case tropane

    /// Phytocannabinoid or neoclerodane diterpene scaffold.
    /// THC Ki at CB1: 5-80 nM. Salvinorin A Ki at KOR: 1.9 nM.
    case terpenoid

    /// Benzylisoquinoline — biosynthetic precursor to morphinan.
    /// Diverse non-CNS activities; morphinan's less-specialized ancestor.
    case isoquinoline

    /// 3,4-Methylenedioxy substitution pattern. Shifts SERT/DAT selectivity
    /// toward empathogenic profile. MDMA SERT/DAT ratio ~10:1.
    case benzodioxole

    /// Purine derivative structurally related to adenosine.
    /// Caffeine Ki at A1: ~12 uM, A2A: ~2.4-44 uM.
    case xanthine

    /// Complex polycyclic isoquinuclidine framework from Tabernanthe iboga.
    /// Hits alpha3beta4 nAChR (Ki ~20 nM), NMDA (~10-50 nM), sigma-2 (~90-200 nM),
    /// SERT (~500 nM), MOR (~130 nM), KOR (~2-4 uM).
    case iboga
}

// MARK: - Metadata

extension MolecularScaffold {

    /// The primary PokeDrug type(s) this scaffold expresses.
    public var primaryTypes: [PokeDrugType] {
        switch self {
        case .tryptamine:       return [.serotonin]
        case .ergoline:         return [.serotonin, .dopamine]
        case .morphinan:        return [.opioid]
        case .phenethylamine:   return [.dopamine]
        case .tropane:          return [.dopamine]
        case .terpenoid:        return [.cannabinoid]
        case .isoquinoline:     return [.cholinergic]
        case .benzodioxole:     return [.empathogen]
        case .xanthine:         return [.adenosine]
        case .iboga:            return [.opioid, .dissociative, .empathogen]
        }
    }

    /// Display name.
    public var displayName: LocalizedString {
        switch self {
        case .tryptamine:
            return LocalizedString(en: "Tryptamine", fr: "Tryptamine")
        case .ergoline:
            return LocalizedString(en: "Ergoline", fr: "Ergoline")
        case .morphinan:
            return LocalizedString(en: "Morphinan", fr: "Morphinane")
        case .phenethylamine:
            return LocalizedString(en: "Phenethylamine", fr: "Phenethylamine")
        case .tropane:
            return LocalizedString(en: "Tropane", fr: "Tropane")
        case .terpenoid:
            return LocalizedString(en: "Terpenoid", fr: "Terpenoide")
        case .isoquinoline:
            return LocalizedString(en: "Isoquinoline", fr: "Isoquinoline")
        case .benzodioxole:
            return LocalizedString(en: "Benzodioxole", fr: "Benzodioxole")
        case .xanthine:
            return LocalizedString(en: "Xanthine", fr: "Xanthine")
        case .iboga:
            return LocalizedString(en: "Iboga Alkaloid", fr: "Alcaloide d'iboga")
        }
    }

    /// Core structural description.
    public var coreStructure: LocalizedString {
        switch self {
        case .tryptamine:
            return LocalizedString(
                en: "Indole ring + 2-carbon aminoethyl sidechain",
                fr: "Noyau indole + chaine aminoethyle a 2 carbones"
            )
        case .ergoline:
            return LocalizedString(
                en: "Rigid tetracyclic ring system (fused indole)",
                fr: "Systeme tetracyclique rigide (indole fusionne)"
            )
        case .morphinan:
            return LocalizedString(
                en: "Pentacyclic phenanthrene with basic nitrogen",
                fr: "Phenanthrene pentacyclique avec azote basique"
            )
        case .phenethylamine:
            return LocalizedString(
                en: "Phenyl ring + 2-carbon chain + amine",
                fr: "Cycle phenyle + chaine a 2 carbones + amine"
            )
        case .tropane:
            return LocalizedString(
                en: "Rigid bicyclic 8-azabicyclo[3.2.1]octane",
                fr: "Bicyclique rigide 8-azabicyclo[3.2.1]octane"
            )
        case .terpenoid:
            return LocalizedString(
                en: "Monoterpenoid C-ring fused to resorcinol via pyran",
                fr: "Anneau C terpenoide fusionne au resorcinol via pyrane"
            )
        case .isoquinoline:
            return LocalizedString(
                en: "Benzylisoquinoline — morphinan biosynthetic precursor",
                fr: "Benzylisoquinoline — precurseur biosynthetique du morphinane"
            )
        case .benzodioxole:
            return LocalizedString(
                en: "3,4-Methylenedioxy ring on phenethylamine backbone",
                fr: "Anneau 3,4-methylenedioxy sur squelette phenethylamine"
            )
        case .xanthine:
            return LocalizedString(
                en: "Purine derivative (1,3,7-trimethylxanthine for caffeine)",
                fr: "Derive purique (1,3,7-trimethylxanthine pour la cafeine)"
            )
        case .iboga:
            return LocalizedString(
                en: "Polycyclic isoquinuclidine with embedded indole",
                fr: "Isoquinuclidine polycyclique avec indole integre"
            )
        }
    }
}
