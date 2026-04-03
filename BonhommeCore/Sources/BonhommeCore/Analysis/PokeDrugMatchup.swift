import Foundation

/// Effectiveness of a molecular scaffold against a pharmacological target type.
///
/// Derived from crystal structure data, binding affinity measurements, and the
/// principle that selectivity arises from structural mimicry of endogenous ligands.
public enum TypeEffectiveness: Int, Codable, Sendable, Comparable {
    /// Confirmed zero binding despite structural possibility.
    case immune = 0

    /// Wrong pharmacophore; negligible interaction.
    case notEffective = 1

    /// Allosteric or weak binding only (uM range).
    case weaklyEffective = 2

    /// Moderate binding, often requiring specific substitution pattern.
    case effective = 3

    /// Endogenous-ligand-level structural match or sub-100 nM affinity.
    case superEffective = 4

    public static func < (lhs: TypeEffectiveness, rhs: TypeEffectiveness) -> Bool {
        lhs.rawValue < rhs.rawValue
    }

    /// Star rating display string.
    public var starRating: String {
        switch self {
        case .immune:           return "✗ Immune"
        case .notEffective:     return "✗ Not effective"
        case .weaklyEffective:  return "★★"
        case .effective:        return "★★★"
        case .superEffective:   return "★★★★"
        }
    }
}

// MARK: - Type Matchup Chart

/// The PokeDrug type matchup chart: which scaffolds are effective against which
/// pharmacological targets, based on structural complementarity and published
/// binding data.
public enum PokeDrugMatchup {

    /// Compute the effectiveness of a scaffold against a pharmacological target.
    ///
    /// Based on real binding affinity data, crystal structures from the Roth and
    /// Kobilka labs, and the structural mimicry principle.
    public static func effectiveness(
        scaffold: MolecularScaffold,
        against target: PokeDrugType
    ) -> TypeEffectiveness {
        matchupChart[scaffold]?[target] ?? .notEffective
    }

    // MARK: - Internal Chart

    private static let matchupChart: [MolecularScaffold: [PokeDrugType: TypeEffectiveness]] = [

        // Tryptamine: endogenous ligand IS a tryptamine → super effective at 5-HT2A
        .tryptamine: [
            .serotonin:     .superEffective,  // Ki 25-360 nM at 5-HT2A
            .sigma:         .effective,        // DMT shows sigma-1 affinity
            .opioid:        .notEffective,     // Wrong pharmacophore
            .dopamine:      .notEffective,
            .empathogen:    .weaklyEffective,
            .dissociative:  .notEffective,
            .cannabinoid:   .notEffective,
            .kappa:         .notEffective,
            .stimulant:     .notEffective,
            .sedative:      .notEffective,
            .cholinergic:   .notEffective,
            .adenosine:     .notEffective,
        ],

        // Ergoline: locked tryptamine + phenethylamine → pan-aminergic
        .ergoline: [
            .serotonin:     .superEffective,  // LSD Ki 3-7 nM at 5-HT2A + lid mechanism
            .dopamine:      .effective,        // D1 Ki ~52 nM, D2 Ki ~100-340 nM, D3 Ki ~9 nM
            .sigma:         .weaklyEffective,
            .opioid:        .notEffective,
            .empathogen:    .weaklyEffective,
            .dissociative:  .notEffective,
            .cannabinoid:   .notEffective,
            .kappa:         .notEffective,
            .stimulant:     .weaklyEffective,
            .sedative:      .notEffective,
            .cholinergic:   .notEffective,
            .adenosine:     .notEffective,
        ],

        // Morphinan: mimics enkephalin Tyr1 → super effective at MOR
        .morphinan: [
            .opioid:        .superEffective,  // Morphine Ki 1.2-14 nM at MOR
            .kappa:         .effective,        // Some morphinans hit KOR
            .serotonin:     .notEffective,     // Too large, wrong geometry
            .dopamine:      .notEffective,
            .empathogen:    .notEffective,
            .dissociative:  .notEffective,
            .cannabinoid:   .notEffective,
            .stimulant:     .notEffective,
            .sedative:      .notEffective,
            .cholinergic:   .notEffective,
            .adenosine:     .notEffective,
            .sigma:         .notEffective,
        ],

        // Phenethylamine: endogenous ligands ARE phenethylamines → super effective at DAT/NET
        .phenethylamine: [
            .dopamine:      .superEffective,  // Amphetamine NET Ki ~70-100 nM
            .stimulant:     .superEffective,  // Same mechanism via reverse transport
            .serotonin:     .effective,        // Only with 2,4,5- or 3,4,5-trimethoxy (mescaline)
            .empathogen:    .weaklyEffective,  // Requires methylenedioxy modification
            .opioid:        .notEffective,
            .dissociative:  .notEffective,
            .cannabinoid:   .immune,           // Too small/polar for hydrophobic CB1 pocket
            .kappa:         .notEffective,
            .sedative:      .notEffective,
            .cholinergic:   .notEffective,
            .adenosine:     .notEffective,
            .sigma:         .notEffective,
        ],

        // Tropane: fills dopamine binding pocket (cocaine) or mAChR (atropine)
        .tropane: [
            .dopamine:      .superEffective,  // Cocaine DAT Ki ~200-700 nM
            .cholinergic:   .superEffective,  // Atropine: potent mAChR antagonist
            .stimulant:     .effective,
            .serotonin:     .notEffective,
            .opioid:        .notEffective,
            .empathogen:    .weaklyEffective,  // Cocaine hits SERT weakly
            .dissociative:  .notEffective,
            .cannabinoid:   .notEffective,
            .kappa:         .notEffective,
            .sedative:      .notEffective,
            .adenosine:     .notEffective,
            .sigma:         .weaklyEffective,
        ],

        // Terpenoid: lipophilic fit for CB1 (THC) or non-canonical KOR (salvinorin A)
        .terpenoid: [
            .cannabinoid:   .superEffective,  // THC Ki 5-80 nM at CB1
            .kappa:         .superEffective,  // Salvinorin A Ki 1.9 nM at KOR, >5000x selective
            .serotonin:     .immune,           // Salvinorin A: confirmed zero binding at 5-HT2A
            .opioid:        .weaklyEffective,  // Salvinorin A is technically a KOR opioid
            .dopamine:      .notEffective,
            .empathogen:    .notEffective,
            .dissociative:  .notEffective,
            .stimulant:     .notEffective,
            .sedative:      .notEffective,
            .cholinergic:   .notEffective,
            .adenosine:     .notEffective,
            .sigma:         .notEffective,
        ],

        // Isoquinoline: morphinan precursor but less rigid/optimized
        .isoquinoline: [
            .opioid:        .weaklyEffective,  // Precursor but not optimized
            .cholinergic:   .effective,         // Tubocurarine at nAChR
            .serotonin:     .notEffective,
            .dopamine:      .notEffective,
            .empathogen:    .notEffective,
            .dissociative:  .notEffective,
            .cannabinoid:   .notEffective,
            .kappa:         .notEffective,
            .stimulant:     .notEffective,
            .sedative:      .notEffective,
            .adenosine:     .notEffective,
            .sigma:         .notEffective,
        ],

        // Benzodioxole: methylenedioxy shifts SERT/DAT ratio → empathogen
        .benzodioxole: [
            .empathogen:    .superEffective,  // MDMA SERT Ki ~238-740 nM, SERT/DAT ~10:1
            .dopamine:      .effective,        // Residual DAT activity
            .stimulant:     .effective,        // Amphetamine backbone retained
            .serotonin:     .effective,        // MDA has 5-HT2A agonism
            .opioid:        .notEffective,
            .dissociative:  .notEffective,
            .cannabinoid:   .notEffective,
            .kappa:         .notEffective,
            .sedative:      .notEffective,
            .cholinergic:   .notEffective,
            .adenosine:     .notEffective,
            .sigma:         .notEffective,
        ],

        // Xanthine: purine analog fits adenosine receptor hydrophobic pocket
        .xanthine: [
            .adenosine:     .superEffective,  // Caffeine Ki ~12 uM A1, ~2.4-44 uM A2A
            .opioid:        .immune,           // No basic nitrogen, wrong shape entirely
            .serotonin:     .notEffective,
            .dopamine:      .weaklyEffective,  // Indirect dopamine release via A2A block
            .empathogen:    .notEffective,
            .dissociative:  .notEffective,
            .cannabinoid:   .notEffective,
            .kappa:         .notEffective,
            .stimulant:     .weaklyEffective,  // Indirect via adenosine antagonism
            .sedative:      .notEffective,
            .cholinergic:   .notEffective,
            .sigma:         .notEffective,
        ],

        // Iboga: massive polycyclic framework hits 6+ targets simultaneously
        .iboga: [
            .cholinergic:   .superEffective,  // alpha3beta4 nAChR Ki ~20 nM
            .dissociative:  .superEffective,  // NMDA Ki ~10-50 nM
            .empathogen:    .effective,        // SERT Ki ~500 nM
            .opioid:        .effective,        // MOR Ki ~130 nM
            .sigma:         .effective,        // Sigma-2 Ki ~90-200 nM
            .kappa:         .weaklyEffective,  // KOR Ki ~2-4 uM
            .serotonin:     .weaklyEffective,  // Tryptamine substructure
            .dopamine:      .weaklyEffective,
            .stimulant:     .notEffective,
            .cannabinoid:   .notEffective,
            .sedative:      .notEffective,
            .adenosine:     .notEffective,
        ],

        // Benzodiazepine: 1,4-BZD ring system is a PAM at GABA-A BZD site
        .benzodiazepine: [
            .sedative:      .superEffective,  // Diazepam Ki ~3-20 nM at BZD site
            .opioid:        .notEffective,
            .serotonin:     .notEffective,
            .dopamine:      .notEffective,
            .empathogen:    .notEffective,
            .dissociative:  .notEffective,
            .cannabinoid:   .notEffective,
            .kappa:         .notEffective,
            .stimulant:     .notEffective,
            .cholinergic:   .notEffective,
            .adenosine:     .notEffective,
            .sigma:         .notEffective,
        ],

        // Beta-carboline: tricyclic indole → 5-HT2A + potent MAO-A inhibition
        .betaCarboline: [
            .serotonin:     .superEffective,  // Harmine 5-HT2A Ki ~300 nM + MAO-A Ki ~5 nM
            .sigma:         .weaklyEffective,  // Some sigma affinity
            .opioid:        .notEffective,
            .dopamine:      .weaklyEffective,  // Indirect via MAO-A inhibition
            .empathogen:    .weaklyEffective,  // MAO-A block potentiates SERT release
            .dissociative:  .notEffective,
            .cannabinoid:   .notEffective,
            .kappa:         .notEffective,
            .stimulant:     .notEffective,
            .sedative:      .notEffective,
            .cholinergic:   .notEffective,
            .adenosine:     .notEffective,
        ],

        // Isoxazole: GABA bioisostere → orthosteric GABA-A agonist
        .isoxazole: [
            .sedative:      .superEffective,  // Muscimol Ki ~6-10 nM at GABA-A orthosteric
            .opioid:        .notEffective,
            .serotonin:     .notEffective,
            .dopamine:      .notEffective,
            .empathogen:    .notEffective,
            .dissociative:  .notEffective,
            .cannabinoid:   .notEffective,
            .kappa:         .notEffective,
            .stimulant:     .notEffective,
            .cholinergic:   .notEffective,
            .adenosine:     .notEffective,
            .sigma:         .notEffective,
        ],
    ]
}
