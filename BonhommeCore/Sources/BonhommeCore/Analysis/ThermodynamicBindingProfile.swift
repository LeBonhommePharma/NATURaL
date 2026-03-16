import Foundation

// MARK: - Data Source

/// Source of thermodynamic binding data.
public enum ThermodynamicSource: String, Codable, Sendable, CaseIterable {
    /// BindingDB public database (Ki/Kd/IC50/EC50).
    case bindingDB
    /// SCORPIO ITC-only database (direct ΔG/ΔH/ΔS/ΔCp measurement).
    case scorpioITC
    /// FlexAID∆S computational docking entropy.
    case flexAIDdS
    /// NIMH Psychoactive Drug Screening Program Ki values.
    case pdspKi
    /// ChEMBL curated bioactivity data.
    case chembl
    /// Published literature values.
    case literature
}

// MARK: - Assay Conditions

/// Experimental conditions under which binding was measured.
public struct AssayConditions: Sendable, Codable, Equatable {
    /// Temperature in Kelvin (default 298K = 25°C).
    public let temperatureK: Double

    /// pH of the assay buffer (default 7.4 = physiological).
    public let pH: Double

    /// Assay type description (e.g., "radioligand displacement", "ITC").
    public let assayType: String?

    public init(temperatureK: Double = 298.0, pH: Double = 7.4, assayType: String? = nil) {
        self.temperatureK = temperatureK
        self.pH = pH
        self.assayType = assayType
    }

    /// Standard biochemical conditions (298K, pH 7.4).
    public static let standard = AssayConditions()

    /// Physiological conditions (310K, pH 7.4).
    public static let physiological = AssayConditions(temperatureK: 310.0, pH: 7.4)
}

// MARK: - Affinity Measurement

/// Binding affinity data from various assay types.
///
/// Preference hierarchy for best affinity estimate: Ki > Kd > IC50/2 > EC50.
/// Ki and Kd are thermodynamically rigorous; IC50 is assay-dependent.
public struct AffinityMeasurement: Sendable, Codable {
    /// Inhibition constant (nM). Gold standard from competition binding.
    public let kiNM: Double?

    /// Dissociation constant (nM). From direct binding or ITC.
    public let kdNM: Double?

    /// Half-maximal inhibitory concentration (nM). Assay-dependent.
    public let ic50NM: Double?

    /// Half-maximal effective concentration (nM). Functional assay.
    public let ec50NM: Double?

    /// Assay conditions under which affinity was measured.
    public let conditions: AssayConditions

    public init(
        kiNM: Double? = nil,
        kdNM: Double? = nil,
        ic50NM: Double? = nil,
        ec50NM: Double? = nil,
        conditions: AssayConditions = .standard
    ) {
        self.kiNM = kiNM
        self.kdNM = kdNM
        self.ic50NM = ic50NM
        self.ec50NM = ec50NM
        self.conditions = conditions
    }

    /// Best available affinity estimate in nM.
    /// Preference: Ki > Kd > IC50/2 (Cheng-Prusoff approximation) > EC50.
    public var bestAffinityNM: Double? {
        if let ki = kiNM { return ki }
        if let kd = kdNM { return kd }
        if let ic50 = ic50NM { return ic50 / 2.0 }
        if let ec50 = ec50NM { return ec50 }
        return nil
    }

    /// Computed ΔG from best affinity at assay temperature.
    /// ΔG = RT ln(Kd) where Kd is in molar units.
    /// Returns kcal/mol (negative = favorable binding).
    public var computedDeltaGKcal: Double? {
        guard let affinityNM = bestAffinityNM, affinityNM > 0 else { return nil }
        let R: Double = 1.987e-3  // kcal/(mol·K)
        let affinityM = affinityNM * 1e-9
        return R * conditions.temperatureK * log(affinityM)
    }
}

// MARK: - Thermodynamic Decomposition

/// Full Gibbs free energy decomposition from ITC (isothermal titration calorimetry).
///
/// ΔG = ΔH + (-TΔS)
/// - ΔG: total binding free energy (always negative for spontaneous binding)
/// - ΔH: enthalpy change (hydrogen bonds, van der Waals, electrostatics)
/// - -TΔS: entropy contribution (conformational, solvation, rotational/translational)
public struct ThermodynamicDecomposition: Sendable, Codable {
    /// Total Gibbs free energy of binding (kcal/mol, negative = favorable).
    public let deltaGKcal: Double

    /// Enthalpy of binding (kcal/mol, negative = exothermic).
    public let deltaHKcal: Double

    /// Entropy term as -TΔS (kcal/mol, negative = entropy-favorable).
    public let minusTDeltaSKcal: Double

    /// Heat capacity change (cal/mol·K), if measured. Indicates hydrophobic burial.
    public let deltaCpCalPerMolK: Double?

    /// Temperature at which measurements were taken (K).
    public let temperatureK: Double

    public init(
        deltaGKcal: Double,
        deltaHKcal: Double,
        minusTDeltaSKcal: Double,
        deltaCpCalPerMolK: Double? = nil,
        temperatureK: Double = 298.0
    ) {
        self.deltaGKcal = deltaGKcal
        self.deltaHKcal = deltaHKcal
        self.minusTDeltaSKcal = minusTDeltaSKcal
        self.deltaCpCalPerMolK = deltaCpCalPerMolK
        self.temperatureK = temperatureK
    }

    /// Whether binding is entropy-driven (|-TΔS| > |ΔH|).
    public var entropyDriven: Bool {
        abs(minusTDeltaSKcal) > abs(deltaHKcal)
    }

    /// Whether binding is enthalpy-driven (|ΔH| > |-TΔS|).
    public var enthalpyDriven: Bool {
        abs(deltaHKcal) > abs(minusTDeltaSKcal)
    }

    /// Whether the decomposition is thermodynamically self-consistent.
    /// |ΔG - (ΔH + (-TΔS))| should be < 0.5 kcal/mol.
    public var isThermodynamicallyConsistent: Bool {
        abs(deltaGKcal - (deltaHKcal + minusTDeltaSKcal)) < 0.5
    }

    /// Convert -TΔS to Shannon entropy bits for FlexAID∆S comparison.
    /// -TΔS (kcal/mol) → ΔS (bits) via: ΔS_bits = -(-TΔS) / (T × R × ln2)
    public var deltaSBits: Double {
        let R: Double = 1.987e-3  // kcal/(mol·K)
        guard temperatureK > 0 else { return 0 }
        return -minusTDeltaSKcal / (temperatureK * R * log(2.0))
    }
}

// MARK: - Stereochemical Note

/// Documents stereochemical effects on binding affinity.
public struct StereochemicalNote: Sendable, Codable {
    /// Enantiomer designation (e.g., "S(+)", "R(-)", "d-", "l-").
    public let enantiomer: String

    /// Eutomer/distomer affinity ratio, if known.
    public let affinityRatio: Double?

    /// Descriptive note.
    public let note: LocalizedString

    public init(enantiomer: String, affinityRatio: Double? = nil, note: LocalizedString) {
        self.enantiomer = enantiomer
        self.affinityRatio = affinityRatio
        self.note = note
    }
}

// MARK: - Prodrug Relationship

/// Tracks prodrug → active metabolite conversion for pharmacovigilance.
public struct ProdrugRelationship: Sendable, Codable {
    /// Substance ID of the prodrug (administered form).
    public let prodrugId: String

    /// Substance ID of the active metabolite (pharmacologically active form).
    public let activeMetaboliteId: String

    /// Enzyme responsible for activation.
    public let activatingEnzyme: String

    /// Approximate conversion half-life in minutes.
    public let conversionHalfLifeMinutes: Double?

    /// Descriptive note.
    public let note: LocalizedString

    public init(
        prodrugId: String,
        activeMetaboliteId: String,
        activatingEnzyme: String,
        conversionHalfLifeMinutes: Double? = nil,
        note: LocalizedString
    ) {
        self.prodrugId = prodrugId
        self.activeMetaboliteId = activeMetaboliteId
        self.activatingEnzyme = activatingEnzyme
        self.conversionHalfLifeMinutes = conversionHalfLifeMinutes
        self.note = note
    }
}

// MARK: - Thermodynamic Binding Profile

/// Complete thermodynamic binding profile for a substance-target pair.
///
/// Combines affinity data (Ki/Kd from BindingDB/PDSP) with optional full
/// Gibbs decomposition (ΔG/ΔH/-TΔS from SCORPIO ITC). Used for:
/// - Data-driven PokeDrug stat derivation (Attack from Ki, Sp.Atk from selectivity)
/// - Enthalpy vs entropy binding signature classification
/// - Three-way validation: FlexAID∆S (computational) vs SCORPIO (ITC) vs NATURaL (HRV)
/// - Pharmacovigilance: identifying prodrug relationships and stereochemical differences
public struct ThermodynamicBindingProfile: Sendable {
    /// Substance identifier (matches PokeDrugSpecies.substanceId).
    public let substanceId: String

    /// Target identifier (e.g., "5-HT2A", "MOR", "CB1").
    public let targetId: String

    /// Target display name (bilingual).
    public let targetName: LocalizedString

    /// Binding affinity measurement.
    public let affinity: AffinityMeasurement

    /// Full ITC thermodynamic decomposition (nil when only affinity data available).
    public let thermodynamics: ThermodynamicDecomposition?

    /// Stereochemical note (nil for achiral compounds or racemates without data).
    public let stereochemistry: StereochemicalNote?

    /// Data source.
    public let source: ThermodynamicSource

    /// Literature reference or database ID.
    public let reference: String

    /// Whether this is the primary pharmacological target.
    public let isPrimaryTarget: Bool

    public init(
        substanceId: String,
        targetId: String,
        targetName: LocalizedString,
        affinity: AffinityMeasurement,
        thermodynamics: ThermodynamicDecomposition? = nil,
        stereochemistry: StereochemicalNote? = nil,
        source: ThermodynamicSource,
        reference: String,
        isPrimaryTarget: Bool
    ) {
        self.substanceId = substanceId
        self.targetId = targetId
        self.targetName = targetName
        self.affinity = affinity
        self.thermodynamics = thermodynamics
        self.stereochemistry = stereochemistry
        self.source = source
        self.reference = reference
        self.isPrimaryTarget = isPrimaryTarget
    }
}

// MARK: - Static Catalog

extension ThermodynamicBindingProfile {

    /// All known thermodynamic binding profiles (~48 substance-target pairs).
    ///
    /// Ki values sourced from PDSP Ki Database and BindingDB.
    /// ITC decomposition from SCORPIO where available.
    /// References: Roth et al., PDSP; BindingDB; Freire 2009; Klebe 2015.
    public static let knownProfiles: [ThermodynamicBindingProfile] = [

        // MARK: - LSD (3 targets, ITC on primary)

        ThermodynamicBindingProfile(
            substanceId: "lsd",
            targetId: "5-HT2A",
            targetName: LocalizedString(en: "Serotonin 5-HT2A receptor", fr: "Récepteur sérotoninergique 5-HT2A"),
            affinity: AffinityMeasurement(kiNM: 3.5),
            thermodynamics: ThermodynamicDecomposition(
                deltaGKcal: -11.5, deltaHKcal: -7.2, minusTDeltaSKcal: -4.3
            ),
            source: .pdspKi,
            reference: "Roth 2002; Wacker 2017 Cell 168:377",
            isPrimaryTarget: true
        ),
        ThermodynamicBindingProfile(
            substanceId: "lsd",
            targetId: "D2",
            targetName: LocalizedString(en: "Dopamine D2 receptor", fr: "Récepteur dopaminergique D2"),
            affinity: AffinityMeasurement(kiNM: 25),
            source: .pdspKi,
            reference: "PDSP Ki Database",
            isPrimaryTarget: false
        ),
        ThermodynamicBindingProfile(
            substanceId: "lsd",
            targetId: "D1",
            targetName: LocalizedString(en: "Dopamine D1 receptor", fr: "Récepteur dopaminergique D1"),
            affinity: AffinityMeasurement(kiNM: 52),
            source: .pdspKi,
            reference: "PDSP Ki Database",
            isPrimaryTarget: false
        ),

        // MARK: - Psilocybin / Psilocin (3 targets)

        ThermodynamicBindingProfile(
            substanceId: "psilocybin",
            targetId: "5-HT2A",
            targetName: LocalizedString(en: "Serotonin 5-HT2A receptor", fr: "Récepteur sérotoninergique 5-HT2A"),
            affinity: AffinityMeasurement(kiNM: 107),
            source: .pdspKi,
            reference: "PDSP; values for active metabolite psilocin",
            isPrimaryTarget: true
        ),
        ThermodynamicBindingProfile(
            substanceId: "psilocybin",
            targetId: "5-HT2B",
            targetName: LocalizedString(en: "Serotonin 5-HT2B receptor", fr: "Récepteur sérotoninergique 5-HT2B"),
            affinity: AffinityMeasurement(kiNM: 4.6),
            source: .pdspKi,
            reference: "PDSP Ki Database; psilocin values",
            isPrimaryTarget: false
        ),
        ThermodynamicBindingProfile(
            substanceId: "psilocybin",
            targetId: "5-HT1A",
            targetName: LocalizedString(en: "Serotonin 5-HT1A receptor", fr: "Récepteur sérotoninergique 5-HT1A"),
            affinity: AffinityMeasurement(kiNM: 190),
            source: .pdspKi,
            reference: "PDSP Ki Database; psilocin values",
            isPrimaryTarget: false
        ),

        // MARK: - DMT (2 targets)

        ThermodynamicBindingProfile(
            substanceId: "dmt",
            targetId: "5-HT2A",
            targetName: LocalizedString(en: "Serotonin 5-HT2A receptor", fr: "Récepteur sérotoninergique 5-HT2A"),
            affinity: AffinityMeasurement(kiNM: 170),
            source: .pdspKi,
            reference: "PDSP Ki Database; Strassman 1994",
            isPrimaryTarget: true
        ),
        ThermodynamicBindingProfile(
            substanceId: "dmt",
            targetId: "sigma-1",
            targetName: LocalizedString(en: "Sigma-1 receptor", fr: "Récepteur sigma-1"),
            affinity: AffinityMeasurement(kiNM: 14000),
            source: .pdspKi,
            reference: "Fontanilla 2009 Science 323:934",
            isPrimaryTarget: false
        ),

        // MARK: - Morphine (3 targets, ITC on primary)

        ThermodynamicBindingProfile(
            substanceId: "morphine",
            targetId: "MOR",
            targetName: LocalizedString(en: "Mu-opioid receptor", fr: "Récepteur opioïde mu"),
            affinity: AffinityMeasurement(kiNM: 1.8),
            thermodynamics: ThermodynamicDecomposition(
                deltaGKcal: -11.9, deltaHKcal: -8.5, minusTDeltaSKcal: -3.4
            ),
            source: .pdspKi,
            reference: "PDSP; Pert & Snyder 1973; SCORPIO ITC",
            isPrimaryTarget: true
        ),
        ThermodynamicBindingProfile(
            substanceId: "morphine",
            targetId: "KOR",
            targetName: LocalizedString(en: "Kappa-opioid receptor", fr: "Récepteur opioïde kappa"),
            affinity: AffinityMeasurement(kiNM: 120),
            source: .pdspKi,
            reference: "PDSP Ki Database",
            isPrimaryTarget: false
        ),
        ThermodynamicBindingProfile(
            substanceId: "morphine",
            targetId: "DOR",
            targetName: LocalizedString(en: "Delta-opioid receptor", fr: "Récepteur opioïde delta"),
            affinity: AffinityMeasurement(kiNM: 200),
            source: .pdspKi,
            reference: "PDSP Ki Database",
            isPrimaryTarget: false
        ),

        // MARK: - Fentanyl (2 targets, ITC on primary)

        ThermodynamicBindingProfile(
            substanceId: "fentanyl",
            targetId: "MOR",
            targetName: LocalizedString(en: "Mu-opioid receptor", fr: "Récepteur opioïde mu"),
            affinity: AffinityMeasurement(kiNM: 1.35),
            thermodynamics: ThermodynamicDecomposition(
                deltaGKcal: -12.1, deltaHKcal: -6.8, minusTDeltaSKcal: -5.3
            ),
            source: .pdspKi,
            reference: "Volpe 2011; SCORPIO ITC",
            isPrimaryTarget: true
        ),
        ThermodynamicBindingProfile(
            substanceId: "fentanyl",
            targetId: "KOR",
            targetName: LocalizedString(en: "Kappa-opioid receptor", fr: "Récepteur opioïde kappa"),
            affinity: AffinityMeasurement(kiNM: 170),
            source: .pdspKi,
            reference: "PDSP Ki Database",
            isPrimaryTarget: false
        ),

        // MARK: - MDMA (3 targets)

        ThermodynamicBindingProfile(
            substanceId: "mdma",
            targetId: "SERT",
            targetName: LocalizedString(en: "Serotonin transporter", fr: "Transporteur de sérotonine"),
            affinity: AffinityMeasurement(kiNM: 238),
            source: .pdspKi,
            reference: "PDSP Ki Database; Simmler 2013",
            isPrimaryTarget: true
        ),
        ThermodynamicBindingProfile(
            substanceId: "mdma",
            targetId: "DAT",
            targetName: LocalizedString(en: "Dopamine transporter", fr: "Transporteur de dopamine"),
            affinity: AffinityMeasurement(kiNM: 2400),
            source: .pdspKi,
            reference: "PDSP Ki Database",
            isPrimaryTarget: false
        ),
        ThermodynamicBindingProfile(
            substanceId: "mdma",
            targetId: "NET",
            targetName: LocalizedString(en: "Norepinephrine transporter", fr: "Transporteur de noradrénaline"),
            affinity: AffinityMeasurement(kiNM: 460),
            source: .pdspKi,
            reference: "PDSP Ki Database",
            isPrimaryTarget: false
        ),

        // MARK: - Amphetamine (3 targets, stereochemistry)

        ThermodynamicBindingProfile(
            substanceId: "amphetamine",
            targetId: "DAT",
            targetName: LocalizedString(en: "Dopamine transporter", fr: "Transporteur de dopamine"),
            affinity: AffinityMeasurement(kiNM: 34),
            stereochemistry: StereochemicalNote(
                enantiomer: "S(+)/d",
                affinityRatio: 4.0,
                note: LocalizedString(
                    en: "d-amphetamine 3-5x more potent at DAT than l-amphetamine",
                    fr: "La d-amphétamine est 3-5x plus puissante au DAT que la l-amphétamine"
                )
            ),
            source: .pdspKi,
            reference: "PDSP; Heal 2013 J Psychopharmacol",
            isPrimaryTarget: true
        ),
        ThermodynamicBindingProfile(
            substanceId: "amphetamine",
            targetId: "NET",
            targetName: LocalizedString(en: "Norepinephrine transporter", fr: "Transporteur de noradrénaline"),
            affinity: AffinityMeasurement(kiNM: 70),
            source: .pdspKi,
            reference: "PDSP Ki Database",
            isPrimaryTarget: false
        ),
        ThermodynamicBindingProfile(
            substanceId: "amphetamine",
            targetId: "SERT",
            targetName: LocalizedString(en: "Serotonin transporter", fr: "Transporteur de sérotonine"),
            affinity: AffinityMeasurement(kiNM: 3400),
            source: .pdspKi,
            reference: "PDSP Ki Database",
            isPrimaryTarget: false
        ),

        // MARK: - Cocaine (3 targets, partial ITC)

        ThermodynamicBindingProfile(
            substanceId: "cocaine",
            targetId: "DAT",
            targetName: LocalizedString(en: "Dopamine transporter", fr: "Transporteur de dopamine"),
            affinity: AffinityMeasurement(kiNM: 200),
            thermodynamics: ThermodynamicDecomposition(
                deltaGKcal: -9.1, deltaHKcal: -4.5, minusTDeltaSKcal: -4.6
            ),
            source: .pdspKi,
            reference: "PDSP; partial ITC from literature",
            isPrimaryTarget: true
        ),
        ThermodynamicBindingProfile(
            substanceId: "cocaine",
            targetId: "SERT",
            targetName: LocalizedString(en: "Serotonin transporter", fr: "Transporteur de sérotonine"),
            affinity: AffinityMeasurement(kiNM: 300),
            source: .pdspKi,
            reference: "PDSP Ki Database",
            isPrimaryTarget: false
        ),
        ThermodynamicBindingProfile(
            substanceId: "cocaine",
            targetId: "NET",
            targetName: LocalizedString(en: "Norepinephrine transporter", fr: "Transporteur de noradrénaline"),
            affinity: AffinityMeasurement(kiNM: 500),
            source: .pdspKi,
            reference: "PDSP Ki Database",
            isPrimaryTarget: false
        ),

        // MARK: - THC (2 targets, ITC on primary)

        ThermodynamicBindingProfile(
            substanceId: "thc",
            targetId: "CB1",
            targetName: LocalizedString(en: "Cannabinoid CB1 receptor", fr: "Récepteur cannabinoïde CB1"),
            affinity: AffinityMeasurement(kiNM: 40),
            thermodynamics: ThermodynamicDecomposition(
                deltaGKcal: -10.1, deltaHKcal: -8.3, minusTDeltaSKcal: -1.8
            ),
            source: .pdspKi,
            reference: "PDSP; Pertwee 2008; SCORPIO ITC",
            isPrimaryTarget: true
        ),
        ThermodynamicBindingProfile(
            substanceId: "thc",
            targetId: "CB2",
            targetName: LocalizedString(en: "Cannabinoid CB2 receptor", fr: "Récepteur cannabinoïde CB2"),
            affinity: AffinityMeasurement(kiNM: 36),
            source: .pdspKi,
            reference: "PDSP Ki Database",
            isPrimaryTarget: false
        ),

        // MARK: - Salvinorin A (1 target, partial ITC)

        ThermodynamicBindingProfile(
            substanceId: "salvinorin-a",
            targetId: "KOR",
            targetName: LocalizedString(en: "Kappa-opioid receptor", fr: "Récepteur opioïde kappa"),
            affinity: AffinityMeasurement(kiNM: 1.9),
            thermodynamics: ThermodynamicDecomposition(
                deltaGKcal: -11.9, deltaHKcal: -9.1, minusTDeltaSKcal: -2.8
            ),
            source: .pdspKi,
            reference: "Roth 2002 PNAS; partial ITC from literature",
            isPrimaryTarget: true
        ),

        // MARK: - Caffeine (2 targets, ITC on primary)

        ThermodynamicBindingProfile(
            substanceId: "caffeine",
            targetId: "A2A",
            targetName: LocalizedString(en: "Adenosine A2A receptor", fr: "Récepteur adénosinergique A2A"),
            affinity: AffinityMeasurement(kiNM: 2400),
            thermodynamics: ThermodynamicDecomposition(
                deltaGKcal: -7.7, deltaHKcal: -3.2, minusTDeltaSKcal: -4.5
            ),
            source: .pdspKi,
            reference: "Fredholm 1999; SCORPIO ITC",
            isPrimaryTarget: true
        ),
        ThermodynamicBindingProfile(
            substanceId: "caffeine",
            targetId: "A1",
            targetName: LocalizedString(en: "Adenosine A1 receptor", fr: "Récepteur adénosinergique A1"),
            affinity: AffinityMeasurement(kiNM: 12000),
            source: .pdspKi,
            reference: "PDSP Ki Database",
            isPrimaryTarget: false
        ),

        // MARK: - Nicotine (2 targets, ITC on primary, stereochemistry)

        ThermodynamicBindingProfile(
            substanceId: "nicotine",
            targetId: "a4b2-nAChR",
            targetName: LocalizedString(en: "α4β2 nicotinic acetylcholine receptor", fr: "Récepteur nicotinique α4β2"),
            affinity: AffinityMeasurement(kiNM: 1),
            thermodynamics: ThermodynamicDecomposition(
                deltaGKcal: -12.3, deltaHKcal: -7.8, minusTDeltaSKcal: -4.5
            ),
            stereochemistry: StereochemicalNote(
                enantiomer: "S(-)",
                note: LocalizedString(
                    en: "Natural S(-)-nicotine is the active enantiomer",
                    fr: "La S(-)-nicotine naturelle est l'énantiomère actif"
                )
            ),
            source: .pdspKi,
            reference: "PDSP; Dani & Bertrand 2007; SCORPIO ITC",
            isPrimaryTarget: true
        ),
        ThermodynamicBindingProfile(
            substanceId: "nicotine",
            targetId: "a7-nAChR",
            targetName: LocalizedString(en: "α7 nicotinic acetylcholine receptor", fr: "Récepteur nicotinique α7"),
            affinity: AffinityMeasurement(kiNM: 1000),
            source: .pdspKi,
            reference: "PDSP Ki Database",
            isPrimaryTarget: false
        ),

        // MARK: - Atropine (2 targets, ITC on primary)

        ThermodynamicBindingProfile(
            substanceId: "atropine",
            targetId: "mAChR-M1",
            targetName: LocalizedString(en: "Muscarinic M1 receptor", fr: "Récepteur muscarinique M1"),
            affinity: AffinityMeasurement(kiNM: 0.4),
            thermodynamics: ThermodynamicDecomposition(
                deltaGKcal: -12.8, deltaHKcal: -10.2, minusTDeltaSKcal: -2.6
            ),
            source: .pdspKi,
            reference: "PDSP; Hulme 1990; SCORPIO ITC",
            isPrimaryTarget: true
        ),
        ThermodynamicBindingProfile(
            substanceId: "atropine",
            targetId: "mAChR-M2",
            targetName: LocalizedString(en: "Muscarinic M2 receptor", fr: "Récepteur muscarinique M2"),
            affinity: AffinityMeasurement(kiNM: 0.6),
            source: .pdspKi,
            reference: "PDSP Ki Database",
            isPrimaryTarget: false
        ),

        // MARK: - Ketamine (2 targets, stereochemistry)

        ThermodynamicBindingProfile(
            substanceId: "ketamine",
            targetId: "NMDA-PCP",
            targetName: LocalizedString(en: "NMDA receptor PCP site", fr: "Site PCP du récepteur NMDA"),
            affinity: AffinityMeasurement(kiNM: 659),
            stereochemistry: StereochemicalNote(
                enantiomer: "S(+)",
                affinityRatio: 3.0,
                note: LocalizedString(
                    en: "S(+)-ketamine (esketamine) ~3x more potent than R(-) at NMDA",
                    fr: "La S(+)-kétamine (eskétamine) est ~3x plus puissante que la R(-) au NMDA"
                )
            ),
            source: .pdspKi,
            reference: "PDSP; Zanos & Gould 2018",
            isPrimaryTarget: true
        ),
        ThermodynamicBindingProfile(
            substanceId: "ketamine",
            targetId: "D2",
            targetName: LocalizedString(en: "Dopamine D2 receptor", fr: "Récepteur dopaminergique D2"),
            affinity: AffinityMeasurement(kiNM: 2500),
            source: .pdspKi,
            reference: "PDSP Ki Database",
            isPrimaryTarget: false
        ),

        // MARK: - Mescaline (2 targets)

        ThermodynamicBindingProfile(
            substanceId: "mescaline",
            targetId: "5-HT2A",
            targetName: LocalizedString(en: "Serotonin 5-HT2A receptor", fr: "Récepteur sérotoninergique 5-HT2A"),
            affinity: AffinityMeasurement(kiNM: 3600),
            source: .pdspKi,
            reference: "PDSP; Monte 1997",
            isPrimaryTarget: true
        ),
        ThermodynamicBindingProfile(
            substanceId: "mescaline",
            targetId: "5-HT2C",
            targetName: LocalizedString(en: "Serotonin 5-HT2C receptor", fr: "Récepteur sérotoninergique 5-HT2C"),
            affinity: AffinityMeasurement(kiNM: 1700),
            source: .pdspKi,
            reference: "PDSP Ki Database",
            isPrimaryTarget: false
        ),

        // MARK: - Ibogaine (6 targets)

        ThermodynamicBindingProfile(
            substanceId: "ibogaine",
            targetId: "a3b4-nAChR",
            targetName: LocalizedString(en: "α3β4 nicotinic receptor", fr: "Récepteur nicotinique α3β4"),
            affinity: AffinityMeasurement(kiNM: 20),
            source: .pdspKi,
            reference: "Bhatt 2000; Alper 2001",
            isPrimaryTarget: true
        ),
        ThermodynamicBindingProfile(
            substanceId: "ibogaine",
            targetId: "NMDA",
            targetName: LocalizedString(en: "NMDA receptor", fr: "Récepteur NMDA"),
            affinity: AffinityMeasurement(kiNM: 31),
            source: .pdspKi,
            reference: "PDSP Ki Database",
            isPrimaryTarget: false
        ),
        ThermodynamicBindingProfile(
            substanceId: "ibogaine",
            targetId: "sigma-2",
            targetName: LocalizedString(en: "Sigma-2 receptor", fr: "Récepteur sigma-2"),
            affinity: AffinityMeasurement(kiNM: 90),
            source: .pdspKi,
            reference: "PDSP Ki Database",
            isPrimaryTarget: false
        ),
        ThermodynamicBindingProfile(
            substanceId: "ibogaine",
            targetId: "SERT",
            targetName: LocalizedString(en: "Serotonin transporter", fr: "Transporteur de sérotonine"),
            affinity: AffinityMeasurement(kiNM: 500),
            source: .pdspKi,
            reference: "PDSP Ki Database",
            isPrimaryTarget: false
        ),
        ThermodynamicBindingProfile(
            substanceId: "ibogaine",
            targetId: "MOR",
            targetName: LocalizedString(en: "Mu-opioid receptor", fr: "Récepteur opioïde mu"),
            affinity: AffinityMeasurement(kiNM: 130),
            source: .pdspKi,
            reference: "PDSP Ki Database",
            isPrimaryTarget: false
        ),
        ThermodynamicBindingProfile(
            substanceId: "ibogaine",
            targetId: "KOR",
            targetName: LocalizedString(en: "Kappa-opioid receptor", fr: "Récepteur opioïde kappa"),
            affinity: AffinityMeasurement(kiNM: 3500),
            source: .pdspKi,
            reference: "PDSP Ki Database",
            isPrimaryTarget: false
        ),

        // MARK: - Cathinone (2 targets)

        ThermodynamicBindingProfile(
            substanceId: "cathinone",
            targetId: "NET",
            targetName: LocalizedString(en: "Norepinephrine transporter", fr: "Transporteur de noradrénaline"),
            affinity: AffinityMeasurement(kiNM: 12.4),
            source: .pdspKi,
            reference: "Simmler 2013; Brenneisen 1990",
            isPrimaryTarget: true
        ),
        ThermodynamicBindingProfile(
            substanceId: "cathinone",
            targetId: "DAT",
            targetName: LocalizedString(en: "Dopamine transporter", fr: "Transporteur de dopamine"),
            affinity: AffinityMeasurement(kiNM: 18.5),
            source: .pdspKi,
            reference: "PDSP Ki Database",
            isPrimaryTarget: false
        ),

        // MARK: - Apigenin (1 target)

        ThermodynamicBindingProfile(
            substanceId: "apigenin",
            targetId: "GABA-A-BZD",
            targetName: LocalizedString(en: "GABA-A benzodiazepine site", fr: "Site benzodiazépine du GABA-A"),
            affinity: AffinityMeasurement(kiNM: 3000),
            source: .literature,
            reference: "Viola 1995; Salehi 2019",
            isPrimaryTarget: true
        ),

        // MARK: - GHB (2 targets)

        ThermodynamicBindingProfile(
            substanceId: "ghb",
            targetId: "GABA-B",
            targetName: LocalizedString(en: "GABA-B receptor", fr: "Récepteur GABA-B"),
            affinity: AffinityMeasurement(kiNM: 1700),
            source: .pdspKi,
            reference: "PDSP; Snead 2000",
            isPrimaryTarget: true
        ),
        ThermodynamicBindingProfile(
            substanceId: "ghb",
            targetId: "GHB-R",
            targetName: LocalizedString(en: "GHB receptor", fr: "Récepteur GHB"),
            affinity: AffinityMeasurement(kiNM: 100),
            source: .pdspKi,
            reference: "PDSP Ki Database",
            isPrimaryTarget: false
        ),

        // MARK: - Methamphetamine (2 targets, stereochemistry)

        ThermodynamicBindingProfile(
            substanceId: "methamphetamine",
            targetId: "DAT",
            targetName: LocalizedString(en: "Dopamine transporter", fr: "Transporteur de dopamine"),
            affinity: AffinityMeasurement(kiNM: 24),
            stereochemistry: StereochemicalNote(
                enantiomer: "S(+)/d",
                affinityRatio: 5.0,
                note: LocalizedString(
                    en: "d-methamphetamine ~5x more potent at DAT than l-methamphetamine",
                    fr: "La d-méthamphetamine est ~5x plus puissante au DAT que la l-méthamphetamine"
                )
            ),
            source: .pdspKi,
            reference: "PDSP Ki Database",
            isPrimaryTarget: true
        ),
        ThermodynamicBindingProfile(
            substanceId: "methamphetamine",
            targetId: "NET",
            targetName: LocalizedString(en: "Norepinephrine transporter", fr: "Transporteur de noradrénaline"),
            affinity: AffinityMeasurement(kiNM: 12),
            source: .pdspKi,
            reference: "PDSP Ki Database",
            isPrimaryTarget: false
        ),

        // MARK: - Dronabinol (2 targets, ITC on primary)

        ThermodynamicBindingProfile(
            substanceId: "dronabinol",
            targetId: "CB1",
            targetName: LocalizedString(en: "Cannabinoid CB1 receptor", fr: "Récepteur cannabinoïde CB1"),
            affinity: AffinityMeasurement(kiNM: 40),
            thermodynamics: ThermodynamicDecomposition(
                deltaGKcal: -10.1, deltaHKcal: -8.3, minusTDeltaSKcal: -1.8
            ),
            source: .pdspKi,
            reference: "Same pharmacology as THC; SCORPIO ITC",
            isPrimaryTarget: true
        ),
        ThermodynamicBindingProfile(
            substanceId: "dronabinol",
            targetId: "CB2",
            targetName: LocalizedString(en: "Cannabinoid CB2 receptor", fr: "Récepteur cannabinoïde CB2"),
            affinity: AffinityMeasurement(kiNM: 36),
            source: .pdspKi,
            reference: "PDSP Ki Database",
            isPrimaryTarget: false
        ),
    ]

    // MARK: - Lookups

    /// Look up the primary-target thermodynamic binding profile by substance ID.
    public static func profile(for substanceId: String) -> ThermodynamicBindingProfile? {
        knownProfiles.first { $0.substanceId == substanceId.lowercased() && $0.isPrimaryTarget }
    }

    /// Look up all thermodynamic binding profiles for a substance (all targets).
    public static func profiles(for substanceId: String) -> [ThermodynamicBindingProfile] {
        knownProfiles.filter { $0.substanceId == substanceId.lowercased() }
    }

    /// All substance IDs with known thermodynamic data.
    public static var knownSubstanceIds: Set<String> {
        Set(knownProfiles.map(\.substanceId))
    }
}

// MARK: - Prodrug Catalog

extension ProdrugRelationship {

    /// Known prodrug → active metabolite relationships for pharmacovigilance.
    public static let knownProdrugs: [ProdrugRelationship] = [
        ProdrugRelationship(
            prodrugId: "psilocybin",
            activeMetaboliteId: "psilocin",
            activatingEnzyme: "alkaline phosphatase",
            conversionHalfLifeMinutes: 30,
            note: LocalizedString(
                en: "Psilocybin is a phosphate ester prodrug; dephosphorylated to psilocin in vivo",
                fr: "La psilocybine est une prodrogue ester phosphate; déphosphorylée en psilocine in vivo"
            )
        ),
        ProdrugRelationship(
            prodrugId: "codeine",
            activeMetaboliteId: "morphine",
            activatingEnzyme: "CYP2D6",
            conversionHalfLifeMinutes: 60,
            note: LocalizedString(
                en: "Codeine O-demethylated to morphine by CYP2D6; poor metabolizers get no analgesia",
                fr: "La codéine est O-déméthylée en morphine par le CYP2D6; les métaboliseurs lents n'obtiennent aucune analgésie"
            )
        ),
        ProdrugRelationship(
            prodrugId: "lisdexamfetamine",
            activeMetaboliteId: "dextroamphetamine",
            activatingEnzyme: "peptidase",
            conversionHalfLifeMinutes: 60,
            note: LocalizedString(
                en: "Lysine-conjugated prodrug cleaved by peptidases in red blood cells",
                fr: "Prodrogue conjuguée à la lysine clivée par les peptidases dans les globules rouges"
            )
        ),
        ProdrugRelationship(
            prodrugId: "heroin",
            activeMetaboliteId: "morphine",
            activatingEnzyme: "esterase",
            conversionHalfLifeMinutes: 5,
            note: LocalizedString(
                en: "Diacetylmorphine → 6-MAM → morphine via sequential ester hydrolysis",
                fr: "Diacétylmorphine → 6-MAM → morphine via hydrolyse séquentielle d'ester"
            )
        ),
    ]

    /// Look up prodrug relationship by prodrug substance ID.
    public static func prodrug(for prodrugId: String) -> ProdrugRelationship? {
        knownProdrugs.first { $0.prodrugId == prodrugId.lowercased() }
    }
}
