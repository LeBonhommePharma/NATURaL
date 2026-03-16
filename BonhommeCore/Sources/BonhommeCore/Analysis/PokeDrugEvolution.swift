import Foundation

/// A single chemical modification step in an evolution chain.
///
/// Each step changes binding selectivity, potency, metabolic stability, or
/// BBB penetration — the pharmacological equivalent of gaining new abilities.
public struct EvolutionStep: Sendable {
    /// Substance ID of the precursor compound.
    public let fromSubstanceId: String

    /// Substance ID of the product compound.
    public let toSubstanceId: String

    /// The chemical modification performed (e.g., "N,N-dimethylation").
    public let modification: LocalizedString

    /// Pharmacological consequence of the modification.
    public let pharmacologicalEffect: LocalizedString

    public init(
        fromSubstanceId: String,
        toSubstanceId: String,
        modification: LocalizedString,
        pharmacologicalEffect: LocalizedString
    ) {
        self.fromSubstanceId = fromSubstanceId
        self.toSubstanceId = toSubstanceId
        self.modification = modification
        self.pharmacologicalEffect = pharmacologicalEffect
    }
}

/// A linear or branching evolution chain for a molecular scaffold.
public struct EvolutionChain: Sendable {
    /// The scaffold family this chain belongs to.
    public let scaffold: MolecularScaffold

    /// Display name for this chain.
    public let name: LocalizedString

    /// Ordered evolution steps.
    public let steps: [EvolutionStep]

    public init(scaffold: MolecularScaffold, name: LocalizedString, steps: [EvolutionStep]) {
        self.scaffold = scaffold
        self.name = name
        self.steps = steps
    }
}

// MARK: - Known Evolution Chains

extension EvolutionChain {

    /// All known evolution chains in the PokeDrug system.
    public static let knownChains: [EvolutionChain] = [

        // MARK: Tryptamine line: Tryptamine → DMT → Psilocin → Psilocybin

        EvolutionChain(
            scaffold: .tryptamine,
            name: LocalizedString(en: "Tryptamine Main Line", fr: "Ligne principale tryptamine"),
            steps: [
                EvolutionStep(
                    fromSubstanceId: "tryptamine",
                    toSubstanceId: "dmt",
                    modification: LocalizedString(
                        en: "N,N-dimethylation",
                        fr: "N,N-dimethylation"
                    ),
                    pharmacologicalEffect: LocalizedString(
                        en: "Adds MAO resistance, increases lipophilicity for rapid CNS penetration. Peak brain concentration in under 30 seconds (smoked).",
                        fr: "Ajoute la resistance aux MAO, augmente la lipophilie pour une penetration rapide du SNC. Concentration cerebrale maximale en moins de 30 secondes (fume)."
                    )
                ),
                EvolutionStep(
                    fromSubstanceId: "dmt",
                    toSubstanceId: "psilocin",
                    modification: LocalizedString(
                        en: "4-hydroxylation",
                        fr: "4-hydroxylation"
                    ),
                    pharmacologicalEffect: LocalizedString(
                        en: "Enhances 5-HT2A selectivity via hydrogen bonding. Cleaner serotonergic profile than DMT's broader sigma-1/TAAR engagement.",
                        fr: "Ameliore la selectivite 5-HT2A par liaison hydrogene. Profil serotoninergique plus propre que l'engagement sigma-1/TAAR plus large du DMT."
                    )
                ),
                EvolutionStep(
                    fromSubstanceId: "psilocin",
                    toSubstanceId: "psilocybin",
                    modification: LocalizedString(
                        en: "4-phosphorylation (prodrug)",
                        fr: "4-phosphorylation (prodrogue)"
                    ),
                    pharmacologicalEffect: LocalizedString(
                        en: "Nature's prodrug strategy: phosphate ester adds water solubility and metabolic stability for oral dosing. Cleaved to active psilocin by alkaline phosphatase in vivo.",
                        fr: "Strategie de prodrogue de la nature: l'ester phosphate ajoute la solubilite dans l'eau et la stabilite metabolique pour le dosage oral. Clive en psilocine active par la phosphatase alcaline in vivo."
                    )
                ),
            ]
        ),

        // MARK: Tryptamine → Ergoline branch (ring fusion)

        EvolutionChain(
            scaffold: .ergoline,
            name: LocalizedString(en: "Ergoline Branch (Ring Fusion)", fr: "Branche ergoline (fusion d'anneaux)"),
            steps: [
                EvolutionStep(
                    fromSubstanceId: "tryptamine",
                    toSubstanceId: "lsd",
                    modification: LocalizedString(
                        en: "Tetracyclic ring fusion + diethylamide",
                        fr: "Fusion tetracyclique + diethylamide"
                    ),
                    pharmacologicalEffect: LocalizedString(
                        en: "Constrains tryptamine into optimal binding conformation. 100-1000x potency increase: LSD active at 20-100 ug vs psilocybin 10-30 mg. EL2 lid traps LSD for 8-12 hours.",
                        fr: "Contraint la tryptamine dans sa conformation de liaison optimale. Augmentation de puissance de 100-1000x: LSD actif a 20-100 ug vs psilocybine 10-30 mg. Le couvercle EL2 piege le LSD pendant 8-12 heures."
                    )
                ),
            ]
        ),

        // MARK: Morphinan line: Morphine → Codeine, Morphine → Heroin

        EvolutionChain(
            scaffold: .morphinan,
            name: LocalizedString(en: "Morphinan Main Line", fr: "Ligne principale morphinane"),
            steps: [
                EvolutionStep(
                    fromSubstanceId: "morphine",
                    toSubstanceId: "codeine",
                    modification: LocalizedString(
                        en: "3-O-methylation",
                        fr: "3-O-methylation"
                    ),
                    pharmacologicalEffect: LocalizedString(
                        en: "Masks critical phenol pharmacophore, reducing MOR affinity ~10-fold. Converts to prodrug dependent on CYP2D6 O-demethylation.",
                        fr: "Masque le pharmacophore phenol critique, reduisant l'affinite MOR d'environ 10 fois. Convertit en prodrogue dependante de la O-demethylation par CYP2D6."
                    )
                ),
            ]
        ),

        // MARK: Morphinan N-substituent branch: agonist → antagonist

        EvolutionChain(
            scaffold: .morphinan,
            name: LocalizedString(en: "Morphinan N-Substituent Switch", fr: "Commutation N-substituant morphinane"),
            steps: [
                EvolutionStep(
                    fromSubstanceId: "morphine",
                    toSubstanceId: "naltrexone",
                    modification: LocalizedString(
                        en: "N-methyl → N-cyclopropylmethyl",
                        fr: "N-methyle → N-cyclopropylmethyle"
                    ),
                    pharmacologicalEffect: LocalizedString(
                        en: "Bulky N-substituent sterically prevents receptor conformational change for G-protein coupling. Converts full agonist to pure antagonist.",
                        fr: "Le substituant N volumineux empeche steriquement le changement conformationnel du recepteur pour le couplage de la proteine G. Convertit un agoniste complet en antagoniste pur."
                    )
                ),
            ]
        ),

        // MARK: Phenethylamine line: PEA → Amphetamine → Methamphetamine

        EvolutionChain(
            scaffold: .phenethylamine,
            name: LocalizedString(en: "Phenethylamine Stimulant Line", fr: "Ligne stimulante phenethylamine"),
            steps: [
                EvolutionStep(
                    fromSubstanceId: "phenethylamine",
                    toSubstanceId: "amphetamine",
                    modification: LocalizedString(
                        en: "Alpha-methylation",
                        fr: "Alpha-methylation"
                    ),
                    pharmacologicalEffect: LocalizedString(
                        en: "Blocks MAO metabolism (half-life: seconds → 10-13 hours), introduces chirality (S > R), enables reverse transport at DAT/NET.",
                        fr: "Bloque le metabolisme MAO (demi-vie: secondes → 10-13 heures), introduit la chiralite (S > R), permet le transport inverse au DAT/NET."
                    )
                ),
                EvolutionStep(
                    fromSubstanceId: "amphetamine",
                    toSubstanceId: "methamphetamine",
                    modification: LocalizedString(
                        en: "N-methylation",
                        fr: "N-methylation"
                    ),
                    pharmacologicalEffect: LocalizedString(
                        en: "Further increases lipophilicity and CNS penetration, boosting stimulant potency 3-5x. Narrows safety margin.",
                        fr: "Augmente encore la lipophilie et la penetration du SNC, augmentant la puissance stimulante de 3-5x. Reduit la marge de securite."
                    )
                ),
            ]
        ),

        // MARK: Phenethylamine → Mescaline branch (type change to Serotonin)

        EvolutionChain(
            scaffold: .phenethylamine,
            name: LocalizedString(en: "Phenethylamine Psychedelic Branch", fr: "Branche psychedelique phenethylamine"),
            steps: [
                EvolutionStep(
                    fromSubstanceId: "phenethylamine",
                    toSubstanceId: "mescaline",
                    modification: LocalizedString(
                        en: "3,4,5-trimethoxylation",
                        fr: "3,4,5-trimethoxylation"
                    ),
                    pharmacologicalEffect: LocalizedString(
                        en: "Complete type change from Dopamine to Serotonin. Redirects binding to 5-HT2A agonism (Ki ~3600-6400 nM, compensated by high dosing at 200-400 mg).",
                        fr: "Changement de type complet de Dopamine a Serotonine. Redirige la liaison vers l'agonisme 5-HT2A (Ki ~3600-6400 nM, compense par un dosage eleve a 200-400 mg)."
                    )
                ),
            ]
        ),

        // MARK: Benzodioxole line: PEA → MDA → MDMA

        EvolutionChain(
            scaffold: .benzodioxole,
            name: LocalizedString(en: "Benzodioxole Empathogen Line", fr: "Ligne empathogene benzodioxole"),
            steps: [
                EvolutionStep(
                    fromSubstanceId: "phenethylamine",
                    toSubstanceId: "mda",
                    modification: LocalizedString(
                        en: "3,4-methylenedioxy + alpha-methyl",
                        fr: "3,4-methylenedioxy + alpha-methyle"
                    ),
                    pharmacologicalEffect: LocalizedString(
                        en: "Methylenedioxy shifts SERT selectivity. MDA has stronger 5-HT2A agonism and more hallucinogenic character (Serotonin/Empathogen dual-type).",
                        fr: "Le methylenedioxy deplace la selectivite SERT. Le MDA a un agonisme 5-HT2A plus fort et un caractere plus hallucinogene (double type Serotonine/Empathogene)."
                    )
                ),
                EvolutionStep(
                    fromSubstanceId: "mda",
                    toSubstanceId: "mdma",
                    modification: LocalizedString(
                        en: "N-methylation",
                        fr: "N-methylation"
                    ),
                    pharmacologicalEffect: LocalizedString(
                        en: "Shifts to Empathogen type: SERT/DAT release ratio ~10:1, prosocial warmth, oxytocin release rather than hallucinogenic activity.",
                        fr: "Passe au type Empathogene: ratio de liberation SERT/DAT ~10:1, chaleur prosociale, liberation d'ocytocine plutot qu'activite hallucinogene."
                    )
                ),
            ]
        ),
    ]

    /// Look up evolution chains involving a given substance ID.
    public static func chains(involving substanceId: String) -> [EvolutionChain] {
        let id = substanceId.lowercased()
        return knownChains.filter { chain in
            chain.steps.contains { step in
                step.fromSubstanceId == id || step.toSubstanceId == id
            }
        }
    }
}
