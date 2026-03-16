import Foundation

/// A complete PokeDrug "Pokedex entry" combining type, scaffold, stats,
/// habitat, and flavor text for a psychoactive natural product or derivative.
///
/// Links to existing PharmacokineticProfile and BindingEntropyProfile
/// via the shared substanceId key.
public struct PokeDrugSpecies: Sendable {
    /// Links to PharmacokineticProfile.substanceId and BindingEntropyProfile.substanceId.
    public let substanceId: String

    /// Display name (bilingual).
    public let name: LocalizedString

    /// Primary PokeDrug type.
    public let primaryType: PokeDrugType

    /// Optional secondary type (e.g., LSD is Serotonin/Dopamine).
    public let secondaryType: PokeDrugType?

    /// Molecular scaffold ("species").
    public let scaffold: MolecularScaffold

    /// Six base stats (1-5 star ratings).
    public let stats: PokeDrugStats

    /// Natural habitat. Nil for fully synthetic compounds.
    public let habitat: PokeDrugHabitat?

    /// Pokedex-style flavor text.
    public let flavorText: LocalizedString

    /// Dex number for catalog ordering.
    public let dexNumber: Int

    public init(
        substanceId: String,
        name: LocalizedString,
        primaryType: PokeDrugType,
        secondaryType: PokeDrugType? = nil,
        scaffold: MolecularScaffold,
        stats: PokeDrugStats,
        habitat: PokeDrugHabitat? = nil,
        flavorText: LocalizedString,
        dexNumber: Int
    ) {
        self.substanceId = substanceId
        self.name = name
        self.primaryType = primaryType
        self.secondaryType = secondaryType
        self.scaffold = scaffold
        self.stats = stats
        self.habitat = habitat
        self.flavorText = flavorText
        self.dexNumber = dexNumber
    }
}

// MARK: - Cross-Reference Convenience

extension PokeDrugSpecies {

    /// Corresponding pharmacokinetic profile, if available.
    public var pharmacokineticProfile: PharmacokineticProfile? {
        PharmacokineticProfile.profile(for: substanceId)
    }

    /// Corresponding binding entropy profile, if available.
    public var bindingEntropyProfile: BindingEntropyProfile? {
        BindingEntropyProfile.profile(for: substanceId)
    }

    /// All types this species expresses (primary + secondary).
    public var types: [PokeDrugType] {
        if let secondary = secondaryType {
            return [primaryType, secondary]
        }
        return [primaryType]
    }

    /// All thermodynamic binding profiles for this species (all targets).
    public var thermodynamicProfiles: [ThermodynamicBindingProfile] {
        ThermodynamicBindingProfile.profiles(for: substanceId)
    }

    /// Primary-target thermodynamic binding profile, if available.
    public var primaryThermodynamicProfile: ThermodynamicBindingProfile? {
        ThermodynamicBindingProfile.profile(for: substanceId)
    }

    /// Attack stat derived from primary target Ki (nM) via thermodynamic data.
    /// Returns nil if no thermodynamic profile or affinity data is available.
    public var derivedAttack: Int? {
        guard let profile = primaryThermodynamicProfile,
              let ki = profile.affinity.bestAffinityNM else { return nil }
        return PokeDrugStats.deriveAttack(kiNM: ki)
    }

    /// Sp. Atk stat derived from selectivity ratio (best off-target Ki / primary Ki).
    /// Returns nil if fewer than 2 targets or no affinity data.
    public var derivedSpecialAttack: Int? {
        let profiles = thermodynamicProfiles
        guard let primary = profiles.first(where: { $0.isPrimaryTarget }),
              let primaryKi = primary.affinity.bestAffinityNM else { return nil }
        let offTargets = profiles.filter { !$0.isPrimaryTarget }
        guard let bestOffTarget = offTargets.compactMap({ $0.affinity.bestAffinityNM }).min() else {
            // Single target — maximum selectivity
            return 5
        }
        guard primaryKi > 0 else { return 1 }
        let ratio = bestOffTarget / primaryKi
        return PokeDrugStats.deriveSpecialAttack(selectivityRatio: ratio)
    }
}

// MARK: - New PharmacokineticProfile Entries for PokeDrug Substances

extension PharmacokineticProfile {

    /// N,N-Dimethyltryptamine (DMT). 5-HT2A + sigma-1 agonist.
    /// Smoked onset < 30 sec, t1/2 ~15-20 min. No oral activity without MAOIs.
    /// Strassman 1994, Barker 2018.
    public static let dmt = PharmacokineticProfile(
        substanceId: "dmt",
        name: LocalizedString(en: "DMT", fr: "DMT"),
        therapeuticClass: .psychedelic,
        onsetMinutes: 0.5,
        tmaxMinutes: 5,
        halfLifeMinutes: 20,
        expectedDeltaHRange: -0.5...0.4,
        mechanism: .mixed,
        fdaApproved: false,
        scheduled: true,
        bindingEntropyKcal: 1.0
    )

    /// Mescaline (3,4,5-trimethoxyphenethylamine). 5-HT2A agonist.
    /// Oral onset 45-90 min, dose 200-400 mg, t1/2 ~6h.
    /// Shulgin & Shulgin, PiHKAL; Chagas-Paula 2019.
    public static let mescaline = PharmacokineticProfile(
        substanceId: "mescaline",
        name: LocalizedString(en: "Mescaline", fr: "Mescaline"),
        therapeuticClass: .psychedelic,
        onsetMinutes: 45,
        tmaxMinutes: 120,
        halfLifeMinutes: 360,
        expectedDeltaHRange: -0.4...0.3,
        mechanism: .mixed,
        fdaApproved: false,
        scheduled: true,
        bindingEntropyKcal: 2.0
    )

    /// Salvinorin A. Selective KOR agonist from Salvia divinorum.
    /// Smoked onset < 30 sec, duration ~8 min. Ki 1.9 nM at KOR.
    /// Roth et al. 2002, Butelman et al. 2004.
    public static let salvinorinA = PharmacokineticProfile(
        substanceId: "salvinorin-a",
        name: LocalizedString(en: "Salvinorin A", fr: "Salvinorine A"),
        therapeuticClass: .psychedelic,
        onsetMinutes: 0.5,
        tmaxMinutes: 2,
        halfLifeMinutes: 8,
        expectedDeltaHRange: -0.3...0.2,
        mechanism: .unknown,
        fdaApproved: false,
        scheduled: false,
        bindingEntropyKcal: 2.5
    )

    /// Ibogaine. Multi-target alkaloid from Tabernanthe iboga.
    /// Oral onset 1-3h, t1/2 ~4-7h (ibogaine), metabolite noribogaine t1/2 24-48h.
    /// Mash et al. 2001, Glue et al. 2015.
    public static let ibogaine = PharmacokineticProfile(
        substanceId: "ibogaine",
        name: LocalizedString(en: "Ibogaine", fr: "Ibogaine"),
        therapeuticClass: .psychedelic,
        onsetMinutes: 60,
        tmaxMinutes: 180,
        halfLifeMinutes: 300,
        expectedDeltaHRange: -0.8...0.5,
        mechanism: .mixed,
        fdaApproved: false,
        scheduled: true,
        bindingEntropyKcal: 2.8
    )

    /// Cathinone. Natural beta-keto amphetamine from Catha edulis (khat).
    /// Oral onset ~30 min, t1/2 ~1.5h. NET/DAT releaser.
    /// Brenneisen et al. 1990, Toennes et al. 2003.
    public static let cathinone = PharmacokineticProfile(
        substanceId: "cathinone",
        name: LocalizedString(en: "Cathinone", fr: "Cathinone"),
        therapeuticClass: .stimulant,
        onsetMinutes: 30,
        tmaxMinutes: 90,
        halfLifeMinutes: 90,
        expectedDeltaHRange: -1.2...(-0.4),
        mechanism: .sympathomimetic,
        fdaApproved: false,
        scheduled: true,
        bindingEntropyKcal: 1.3
    )

    /// Apigenin. Flavonoid from chamomile. Weak GABA-A PAM at BZD site.
    /// Oral onset ~30-60 min, t1/2 ~12h. Ki ~1-10 uM at BZD site.
    /// Viola et al. 1995, Salehi et al. 2019.
    public static let apigenin = PharmacokineticProfile(
        substanceId: "apigenin",
        name: LocalizedString(en: "Apigenin", fr: "Apigenine"),
        therapeuticClass: .sedativeHypnotic,
        onsetMinutes: 30,
        tmaxMinutes: 90,
        halfLifeMinutes: 720,
        expectedDeltaHRange: 0.1...0.5,
        mechanism: .parasympathomimetic,
        fdaApproved: false,
        scheduled: false,
        bindingEntropyKcal: 1.0
    )
}


// MARK: - Species Catalog

extension PokeDrugSpecies {

    /// The complete PokeDrug Pokedex: all known species with their types,
    /// scaffolds, stats, habitats, and descriptions.
    ///
    /// Stats derived from published Ki values (PDSP, ChEMBL), crystal structures
    /// (Roth/Kobilka labs), safety ratios (Gable, Nutt et al. 2010 Lancet).
    public static let knownSpecies: [PokeDrugSpecies] = [

        // MARK: #001 - LSD (Ergoline)

        PokeDrugSpecies(
            substanceId: "lsd",
            name: LocalizedString(en: "LSD", fr: "LSD"),
            primaryType: .serotonin,
            secondaryType: .dopamine,
            scaffold: .ergoline,
            stats: PokeDrugStats(
                hp: 5,      // TI ~1000; no confirmed direct deaths
                attack: 5,  // Ki 3-7 nM at 5-HT2A
                defense: 4, // t1/2 3.6h + EL2 lid = 12h effect
                specialAttack: 2, // Pan-aminergic (all 13 5-HT subtypes + D1/D2/D3)
                specialDefense: 2, // Full tolerance in 3 days
                speed: 3    // 30-45 min oral onset
            ),
            habitat: .fungalForest,
            flavorText: LocalizedString(
                en: "The rigid ergoline tetracycle traps in the 5-HT2A pocket for hours via an extracellular loop 2 lid. Active at 20-100 micrograms — the most potent psychoactive compound by weight.",
                fr: "Le tetracycle ergoline rigide se piege dans la poche 5-HT2A pendant des heures via un couvercle de boucle extracellulaire 2. Actif a 20-100 microgrammes — le compose psychoactif le plus puissant au poids."
            ),
            dexNumber: 1
        ),

        // MARK: #002 - Psilocybin (Tryptamine)

        PokeDrugSpecies(
            substanceId: "psilocybin",
            name: LocalizedString(en: "Psilocybin", fr: "Psilocybine"),
            primaryType: .serotonin,
            scaffold: .tryptamine,
            stats: PokeDrugStats(
                hp: 5,      // TI ~1000; Nutt 2010: 5/100 harm score
                attack: 4,  // Psilocin Ki 25-107 nM
                defense: 3, // t1/2 ~3h
                specialAttack: 3, // 5-HT2A/2B/1A selective
                specialDefense: 2, // Full tolerance in 3 days
                speed: 3    // 20-40 min oral
            ),
            habitat: .fungalForest,
            flavorText: LocalizedString(
                en: "Nature's prodrug: the phosphate ester ensures oral stability, then alkaline phosphatase frees active psilocin in vivo. Produced by 200+ Psilocybe species via a 65-million-year-old enzyme cluster.",
                fr: "La prodrogue de la nature: l'ester phosphate assure la stabilite orale, puis la phosphatase alcaline libere la psilocine active in vivo. Produit par plus de 200 especes de Psilocybe via un cluster enzymatique vieux de 65 millions d'annees."
            ),
            dexNumber: 2
        ),

        // MARK: #003 - DMT (Tryptamine)

        PokeDrugSpecies(
            substanceId: "dmt",
            name: LocalizedString(en: "DMT", fr: "DMT"),
            primaryType: .serotonin,
            secondaryType: .sigma,
            scaffold: .tryptamine,
            stats: PokeDrugStats(
                hp: 4,      // TI ~20 (ayahuasca context)
                attack: 3,  // Ki 77-360 nM at 5-HT2A
                defense: 1, // t1/2 ~15 min smoked
                specialAttack: 3, // 5-HT2A + sigma-1
                specialDefense: 5, // NO tolerance — unique among serotonergics
                speed: 5    // <30 sec smoked
            ),
            habitat: .tropicalJungle,
            flavorText: LocalizedString(
                en: "The only serotonergic psychedelic that produces zero measurable tolerance. Smoked, it reaches peak brain concentration in under 30 seconds — a glass cannon with maximum Speed.",
                fr: "Le seul psychedelique serotoninergique qui ne produit aucune tolerance mesurable. Fume, il atteint la concentration cerebrale maximale en moins de 30 secondes — un canon de verre avec une Vitesse maximale."
            ),
            dexNumber: 3
        ),

        // MARK: #004 - Morphine (Morphinan)

        PokeDrugSpecies(
            substanceId: "morphine",
            name: LocalizedString(en: "Morphine", fr: "Morphine"),
            primaryType: .opioid,
            scaffold: .morphinan,
            stats: PokeDrugStats(
                hp: 2,      // TI ~15
                attack: 5,  // Ki 1.2-14 nM at MOR
                defense: 3, // t1/2 2-3h
                specialAttack: 4, // MOR/KOR 20-100x selectivity
                specialDefense: 1, // Rapid tolerance
                speed: 3    // 15-30 min oral
            ),
            habitat: .asianHighlands,
            flavorText: LocalizedString(
                en: "The pentacyclic morphinan locks phenol and nitrogen into the exact geometry of enkephalin Tyr1. The 17-enzyme biosynthetic pathway in Papaver somniferum is one of nature's most complex.",
                fr: "Le morphinane pentacyclique verrouille le phenol et l'azote dans la geometrie exacte de la Tyr1 de l'enkephaline. La voie biosynthetique a 17 enzymes chez Papaver somniferum est l'une des plus complexes de la nature."
            ),
            dexNumber: 4
        ),

        // MARK: #005 - Fentanyl (Synthetic Opioid)

        PokeDrugSpecies(
            substanceId: "fentanyl",
            name: LocalizedString(en: "Fentanyl", fr: "Fentanyl"),
            primaryType: .opioid,
            scaffold: .morphinan, // Synthetic but targets same pocket
            stats: PokeDrugStats(
                hp: 1,      // TI ~2-3, razor-thin margin
                attack: 5,  // Ki 1.35 nM
                defense: 4, // t1/2 3-7h
                specialAttack: 4, // MOR/KOR ~120x
                specialDefense: 1, // Rapid tolerance
                speed: 5    // Seconds IV
            ),
            habitat: nil, // Fully synthetic
            flavorText: LocalizedString(
                en: "A synthetic phenethyl piperidine with the lowest HP stat in the PokeDrug system. The difference between effective dose and lethal dose is razor-thin — TI of 2-3.",
                fr: "Une piperidine phenethylique synthetique avec la plus faible stat HP du systeme PokeDrug. La difference entre dose efficace et dose letale est infime — IT de 2-3."
            ),
            dexNumber: 5
        ),

        // MARK: #006 - MDMA (Benzodioxole)

        PokeDrugSpecies(
            substanceId: "mdma",
            name: LocalizedString(en: "MDMA", fr: "MDMA"),
            primaryType: .empathogen,
            secondaryType: .stimulant,
            scaffold: .benzodioxole,
            stats: PokeDrugStats(
                hp: 3,      // TI ~16
                attack: 3,  // SERT Ki 238-740 nM
                defense: 4, // t1/2 6-9h
                specialAttack: 3, // SERT/DAT ~10:1
                specialDefense: 2, // "Loss of magic"
                speed: 3    // 30-60 min
            ),
            habitat: nil, // Semi-synthetic (safrole precursor from tropical plants)
            flavorText: LocalizedString(
                en: "The methylenedioxy ring shifts the phenethylamine backbone toward SERT release: 10:1 serotonin-over-dopamine flooding creates prosocial warmth rather than stimulant rush. Breakthrough therapy for PTSD.",
                fr: "L'anneau methylenedioxy deplace le squelette phenethylamine vers la liberation de SERT: l'inondation de serotonine 10:1 par rapport a la dopamine cree une chaleur prosociale plutot qu'un rush stimulant. Therapie de rupture pour le TSPT."
            ),
            dexNumber: 6
        ),

        // MARK: #007 - Amphetamine (Phenethylamine)

        PokeDrugSpecies(
            substanceId: "amphetamine",
            name: LocalizedString(en: "Amphetamine", fr: "Amphetamine"),
            primaryType: .dopamine,
            secondaryType: .stimulant,
            scaffold: .phenethylamine,
            stats: PokeDrugStats(
                hp: 2,      // TI ~5-10
                attack: 4,  // NET Ki 70-100 nM
                defense: 5, // t1/2 10-13h
                specialAttack: 3, // NET/DAT preferring
                specialDefense: 2, // Euphoria tolerance
                speed: 3    // 20-60 min
            ),
            habitat: nil, // Synthetic
            flavorText: LocalizedString(
                en: "Alpha-methylation of phenethylamine — the single most consequential modification in stimulant pharmacology. Blocks MAO, enables reverse transport, extends half-life from seconds to 10-13 hours.",
                fr: "Alpha-methylation de la phenethylamine — la modification la plus consequente de la pharmacologie des stimulants. Bloque la MAO, permet le transport inverse, prolonge la demi-vie de secondes a 10-13 heures."
            ),
            dexNumber: 7
        ),

        // MARK: #008 - Cocaine (Tropane)

        PokeDrugSpecies(
            substanceId: "cocaine",
            name: LocalizedString(en: "Cocaine", fr: "Cocaine"),
            primaryType: .dopamine,
            scaffold: .tropane,
            stats: PokeDrugStats(
                hp: 2,      // TI ~15
                attack: 3,  // DAT Ki 200-700 nM
                defense: 1, // t1/2 ~1h
                specialAttack: 1, // Non-selective DAT/SERT/NET
                specialDefense: 2, // Sensitization paradox
                speed: 5    // Seconds smoked/IV
            ),
            habitat: .tropicalJungle,
            flavorText: LocalizedString(
                en: "The rigid tropane bicycle positions its 3-beta-benzoyloxy group into the DAT binding pocket. The stereochemistry at a single carbon determines whether a tropane is a stimulant or a deliriant.",
                fr: "Le bicycle tropane rigide positionne son groupe 3-beta-benzoyloxy dans la poche de liaison du DAT. La stereochimie a un seul carbone determine si un tropane est un stimulant ou un delirant."
            ),
            dexNumber: 8
        ),

        // MARK: #009 - THC (Terpenoid)

        PokeDrugSpecies(
            substanceId: "thc",
            name: LocalizedString(en: "THC", fr: "THC"),
            primaryType: .cannabinoid,
            scaffold: .terpenoid,
            stats: PokeDrugStats(
                hp: 5,      // TI >1000; no confirmed direct deaths
                attack: 4,  // CB1 Ki 5-80 nM
                defense: 5, // t1/2 25-36h terminal
                specialAttack: 3, // CB1/CB2 dual
                specialDefense: 3, // Slow tolerance, 1-2 weeks
                speed: 4    // Seconds-minutes smoked
            ),
            habitat: .centralAsianSteppe,
            flavorText: LocalizedString(
                en: "A single pyran ring closure separates psychoactive THC from non-psychoactive CBD. The Phe200/Trp356 twin toggle switch in CB1 activates only when the closed ring engages.",
                fr: "Une seule fermeture d'anneau pyrane separe le THC psychoactif du CBD non psychoactif. Le commutateur double Phe200/Trp356 dans CB1 ne s'active que lorsque l'anneau ferme s'engage."
            ),
            dexNumber: 9
        ),

        // MARK: #010 - Salvinorin A (Terpenoid)

        PokeDrugSpecies(
            substanceId: "salvinorin-a",
            name: LocalizedString(en: "Salvinorin A", fr: "Salvinorine A"),
            primaryType: .kappa,
            scaffold: .terpenoid,
            stats: PokeDrugStats(
                hp: 4,      // No deaths reported
                attack: 5,  // Ki 1.9 nM at KOR
                defense: 1, // 8 min brain clearance
                specialAttack: 5, // >5000x KOR selective — highest in PokeDrug
                specialDefense: 4, // Minimal tolerance
                speed: 5    // <30 sec smoked
            ),
            habitat: .tropicalJungle,
            flavorText: LocalizedString(
                en: "The most selective naturally occurring psychoactive compound: >5,000-fold KOR preference. The first non-nitrogenous opioid ligand, binding via a non-canonical epitope in TM II/VII. A glass cannon.",
                fr: "Le compose psychoactif naturel le plus selectif: preference KOR >5000 fois. Le premier ligand opioide non azote, se liant via un epitope non canonique dans TM II/VII. Un canon de verre."
            ),
            dexNumber: 10
        ),

        // MARK: #011 - Caffeine (Xanthine)

        PokeDrugSpecies(
            substanceId: "caffeine",
            name: LocalizedString(en: "Caffeine", fr: "Cafeine"),
            primaryType: .adenosine,
            scaffold: .xanthine,
            stats: PokeDrugStats(
                hp: 4,      // TI ~100
                attack: 1,  // A1 Ki ~12 uM (weak)
                defense: 4, // t1/2 3-7h
                specialAttack: 2, // Non-selective A1/A2A
                specialDefense: 3, // Days-weeks tolerance
                speed: 4    // 15-45 min
            ),
            habitat: .tropicalPlantations,
            flavorText: LocalizedString(
                en: "Evolved independently at least five times in unrelated plant families. Normal coffee yields 20-60 uM plasma concentration — enough for 30-50% adenosine receptor occupancy despite weak Ki.",
                fr: "A evolue independamment au moins cinq fois dans des familles vegetales non apparentees. Le cafe normal produit 20-60 uM de concentration plasmatique — suffisant pour 30-50% d'occupation des recepteurs malgre un Ki faible."
            ),
            dexNumber: 11
        ),

        // MARK: #012 - Nicotine (Cholinergic)

        PokeDrugSpecies(
            substanceId: "nicotine",
            name: LocalizedString(en: "Nicotine", fr: "Nicotine"),
            primaryType: .cholinergic,
            scaffold: .tropane, // Pyridine-pyrrolidine, closest scaffold family
            stats: PokeDrugStats(
                hp: 2,      // TI ~10-15 (narrow for pure compound)
                attack: 4,  // nAChR agonist, moderate affinity
                defense: 2, // t1/2 ~2h
                specialAttack: 3, // Selective for nAChR subtypes
                specialDefense: 1, // Rapid tolerance + dependence
                speed: 5    // ~10 min inhaled, seconds IV
            ),
            habitat: .tropicalJungle,
            flavorText: LocalizedString(
                en: "A pyridine-pyrrolidine that mimics acetylcholine at nicotinic receptors. One rotatable bond between its two rings. Extreme Speed but poor Sp. Def — the archetype of addictive pharmacokinetics.",
                fr: "Une pyridine-pyrrolidine qui mime l'acetylcholine aux recepteurs nicotiniques. Une liaison rotative entre ses deux cycles. Vitesse extreme mais mauvaise Def. Sp. — l'archetype de la pharmacocinetique addictive."
            ),
            dexNumber: 12
        ),

        // MARK: #013 - Atropine (Tropane)

        PokeDrugSpecies(
            substanceId: "atropine",
            name: LocalizedString(en: "Atropine", fr: "Atropine"),
            primaryType: .cholinergic,
            scaffold: .tropane,
            stats: PokeDrugStats(
                hp: 2,      // Narrow TI, especially in children
                attack: 4,  // Potent mAChR antagonist
                defense: 3, // t1/2 ~4h
                specialAttack: 3, // Selective mAChR antagonist
                specialDefense: 3,
                speed: 3    // 15-60 min oral
            ),
            habitat: .asianHighlands,
            flavorText: LocalizedString(
                en: "The 3-alpha-tropic acid ester on the tropane ring fits muscarinic receptors instead of DAT. Same scaffold as cocaine, completely different pharmacology — stereochemistry at C-3 is the switch.",
                fr: "L'ester d'acide tropique 3-alpha sur le cycle tropane s'adapte aux recepteurs muscariniques au lieu du DAT. Meme squelette que la cocaine, pharmacologie completement differente — la stereochimie au C-3 est le commutateur."
            ),
            dexNumber: 13
        ),

        // MARK: #014 - Ketamine (Dissociative)

        PokeDrugSpecies(
            substanceId: "ketamine",
            name: LocalizedString(en: "Ketamine", fr: "Ketamine"),
            primaryType: .dissociative,
            scaffold: .phenethylamine, // Arylcyclohexylamine class
            stats: PokeDrugStats(
                hp: 3,      // Moderate TI; anesthetic doses well-characterized
                attack: 4,  // NMDA channel blocker, effective at clinical doses
                defense: 2, // t1/2 ~2.5h
                specialAttack: 3, // Primarily NMDA but hits opioid, DA
                specialDefense: 2, // Tolerance develops over weeks
                speed: 4    // 5-20 min intranasal
            ),
            habitat: nil, // Fully synthetic
            flavorText: LocalizedString(
                en: "An arylcyclohexylamine that blocks the NMDA ion channel pore. FDA-approved as Spravato (esketamine) for treatment-resistant depression. Rapid antidepressant onset within hours.",
                fr: "Une arylcyclohexylamine qui bloque le pore du canal ionique NMDA. Approuve par la FDA comme Spravato (esketamine) pour la depression resistante au traitement. Action antidepressive rapide en quelques heures."
            ),
            dexNumber: 14
        ),

        // MARK: #015 - Mescaline (Phenethylamine)

        PokeDrugSpecies(
            substanceId: "mescaline",
            name: LocalizedString(en: "Mescaline", fr: "Mescaline"),
            primaryType: .serotonin,
            scaffold: .phenethylamine,
            stats: PokeDrugStats(
                hp: 4,      // High safety ratio
                attack: 2,  // Ki ~3600-6400 nM (weak, compensated by high dose)
                defense: 3, // t1/2 ~6h
                specialAttack: 3, // 5-HT2A selective at psychedelic doses
                specialDefense: 2, // Tolerance similar to other psychedelics
                speed: 2    // 45-90 min oral
            ),
            habitat: .desertMesa,
            flavorText: LocalizedString(
                en: "3,4,5-Trimethoxylation transforms the stimulant phenethylamine into a psychedelic — a complete type change from Dopamine to Serotonin. 5,700+ years of ceremonial use in peyote cacti.",
                fr: "La 3,4,5-trimethoxylation transforme la phenethylamine stimulante en psychedelique — un changement de type complet de Dopamine a Serotonine. Plus de 5 700 ans d'utilisation ceremonielle dans les cactus peyotl."
            ),
            dexNumber: 15
        ),

        // MARK: #016 - Ibogaine (Iboga)

        PokeDrugSpecies(
            substanceId: "ibogaine",
            name: LocalizedString(en: "Ibogaine", fr: "Ibogaine"),
            primaryType: .opioid,
            secondaryType: .dissociative,
            scaffold: .iboga,
            stats: PokeDrugStats(
                hp: 1,      // Narrow TI (hERG cardiac risk)
                attack: 5,  // nAChR Ki ~20 nM
                defense: 5, // Noribogaine t1/2 24-48h
                specialAttack: 1, // Hits 6+ targets — lowest selectivity
                specialDefense: 5, // Single dose; non-repeated
                speed: 2    // 1-3h oral
            ),
            habitat: .africanRainforest,
            flavorText: LocalizedString(
                en: "The only triple-type natural compound: Opioid/Dissociative/Empathogen. Engages 6+ pharmacologically distinct targets simultaneously. Noribogaine sustains effects for days. Narrow HP from hERG block.",
                fr: "Le seul compose naturel a triple type: Opioide/Dissociatif/Empathogene. Engage 6+ cibles pharmacologiquement distinctes simultanement. La noribogaine maintient les effets pendant des jours. HP etroit du blocage hERG."
            ),
            dexNumber: 16
        ),

        // MARK: #017 - Cathinone (Phenethylamine)

        PokeDrugSpecies(
            substanceId: "cathinone",
            name: LocalizedString(en: "Cathinone", fr: "Cathinone"),
            primaryType: .stimulant,
            scaffold: .phenethylamine,
            stats: PokeDrugStats(
                hp: 2,      // Similar to amphetamine
                attack: 3,  // Moderate NET/DAT release
                defense: 2, // t1/2 ~1.5h
                specialAttack: 2, // Non-selective monoamine releaser
                specialDefense: 2,
                speed: 3    // 30 min oral (khat chewing)
            ),
            habitat: .africanRainforest,
            flavorText: LocalizedString(
                en: "Nature's amphetamine: a beta-keto phenethylamine from Catha edulis. The keto group makes it less potent than amphetamine but still an effective NET/DAT releaser. Chewed fresh in the Horn of Africa.",
                fr: "L'amphetamine de la nature: une beta-keto phenethylamine de Catha edulis. Le groupe keto la rend moins puissante que l'amphetamine mais reste un liberateur NET/DAT efficace. Machee fraiche dans la Corne de l'Afrique."
            ),
            dexNumber: 17
        ),

        // MARK: #018 - Apigenin (Flavonoid/Sedative)

        PokeDrugSpecies(
            substanceId: "apigenin",
            name: LocalizedString(en: "Apigenin", fr: "Apigenine"),
            primaryType: .sedative,
            scaffold: .isoquinoline, // Flavonoid — closest phenolic scaffold
            stats: PokeDrugStats(
                hp: 5,      // Extremely safe; natural flavonoid
                attack: 1,  // BZD-site affinity ~uM (very weak)
                defense: 4, // t1/2 ~12h
                specialAttack: 2, // GABA-A PAM, some other targets
                specialDefense: 3,
                speed: 2    // 30-60 min oral
            ),
            habitat: .tropicalPlantations,
            flavorText: LocalizedString(
                en: "A flavonoid from chamomile that acts as a weak GABA-A PAM at the benzodiazepine site. Maximum HP and minimum Attack — the gentlest sedative in the PokeDrug system.",
                fr: "Un flavonoide de la camomille qui agit comme un faible MAP du GABA-A au site des benzodiazepines. HP maximal et Attaque minimale — le sedatif le plus doux du systeme PokeDrug."
            ),
            dexNumber: 18
        ),

        // MARK: #019 - GHB (Sedative)

        PokeDrugSpecies(
            substanceId: "ghb",
            name: LocalizedString(en: "GHB", fr: "GHB"),
            primaryType: .sedative,
            scaffold: .isoquinoline, // Simple GABA analog, closest functional match
            stats: PokeDrugStats(
                hp: 2,      // Narrow TI; steep dose-response
                attack: 3,  // GABA-B agonist at therapeutic doses
                defense: 1, // t1/2 30-60 min
                specialAttack: 2,
                specialDefense: 2,
                speed: 3    // 15-45 min oral
            ),
            habitat: nil, // Endogenous neurotransmitter / synthetic
            flavorText: LocalizedString(
                en: "An endogenous neurotransmitter and GABA-B agonist. FDA-approved as Xyrem for narcolepsy. The steep dose-response curve creates a dangerously narrow therapeutic window.",
                fr: "Un neurotransmetteur endogene et agoniste GABA-B. Approuve par la FDA comme Xyrem pour la narcolepsie. La courbe dose-reponse abrupte cree une fenetre therapeutique dangereusement etroite."
            ),
            dexNumber: 19
        ),

        // MARK: #020 - Methamphetamine (Phenethylamine)

        PokeDrugSpecies(
            substanceId: "methamphetamine",
            name: LocalizedString(en: "Methamphetamine", fr: "Methamphetamine"),
            primaryType: .dopamine,
            secondaryType: .stimulant,
            scaffold: .phenethylamine,
            stats: PokeDrugStats(
                hp: 1,      // Very narrow safety margin
                attack: 4,  // Potent DA/NE releaser
                defense: 5, // t1/2 10-12h
                specialAttack: 2, // Non-selective monoamine
                specialDefense: 1, // Rapid euphoria tolerance
                speed: 4    // Fast depending on route
            ),
            habitat: nil, // Synthetic
            flavorText: LocalizedString(
                en: "N-methylation of amphetamine: further increases lipophilicity and CNS penetration, boosting potency 3-5x while narrowing the safety margin. Each evolution step increases Attack while decreasing HP.",
                fr: "N-methylation de l'amphetamine: augmente encore la lipophilie et la penetration du SNC, augmentant la puissance de 3-5x tout en retrecissant la marge de securite. Chaque etape d'evolution augmente l'Attaque tout en diminuant les HP."
            ),
            dexNumber: 20
        ),

        // MARK: #021 - Dronabinol (Terpenoid)

        PokeDrugSpecies(
            substanceId: "dronabinol",
            name: LocalizedString(en: "Dronabinol", fr: "Dronabinol"),
            primaryType: .cannabinoid,
            scaffold: .terpenoid,
            stats: PokeDrugStats(
                hp: 5,      // Same as THC
                attack: 4,  // Same pharmacology
                defense: 5, // Same t1/2
                specialAttack: 3,
                specialDefense: 3,
                speed: 2    // Oral: slower than smoked THC
            ),
            habitat: nil, // Synthetic THC
            flavorText: LocalizedString(
                en: "Synthetic THC (Marinol). Identical pharmacodynamics to plant-derived THC but oral-only formulation reduces Speed stat. FDA-approved, Schedule III.",
                fr: "THC synthetique (Marinol). Pharmacodynamique identique au THC derive de plantes mais la formulation orale uniquement reduit la stat Vitesse. Approuve par la FDA, Annexe III."
            ),
            dexNumber: 21
        ),
    ]

    /// Look up a species by substance ID (case-insensitive).
    public static func species(for substanceId: String) -> PokeDrugSpecies? {
        knownSpecies.first { $0.substanceId == substanceId.lowercased() }
    }

    /// All species of a given PokeDrug type (primary or secondary).
    public static func species(ofType type: PokeDrugType) -> [PokeDrugSpecies] {
        knownSpecies.filter { $0.primaryType == type || $0.secondaryType == type }
    }

    /// All species built on a given molecular scaffold.
    public static func species(withScaffold scaffold: MolecularScaffold) -> [PokeDrugSpecies] {
        knownSpecies.filter { $0.scaffold == scaffold }
    }

    /// All species from a given habitat.
    public static func species(inHabitat habitat: PokeDrugHabitat) -> [PokeDrugSpecies] {
        knownSpecies.filter { $0.habitat == habitat }
    }
}
