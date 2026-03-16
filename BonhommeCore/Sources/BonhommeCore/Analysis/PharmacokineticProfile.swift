import Foundation

/// Autonomic mechanism of action for a substance.
///
/// Determines the expected direction of HRV entropy change:
/// - Sympathomimetics compress RR variability → entropy collapse (ΔH < 0)
/// - Parasympathomimetics expand RR variability → entropy increase (ΔH > 0)
/// - Mixed agents have biphasic or unpredictable effects
public enum AutonomicMechanism: String, Codable, Sendable {
    /// Increases sympathetic tone (e.g., amphetamine, cocaine, caffeine).
    /// Expected HRV effect: decreased RR interval variability → entropy collapse.
    case sympathomimetic

    /// Increases parasympathetic / decreases sympathetic tone (e.g., beta-blockers, clonidine).
    /// Expected HRV effect: increased RR interval variability → entropy expansion.
    case parasympathomimetic

    /// Affects both branches or has biphasic profile (e.g., alcohol, cannabis, SSRIs).
    case mixed

    /// Mechanism not well characterized for autonomic HRV effects.
    case unknown
}

/// Therapeutic class for substance categorization.
public enum TherapeuticClass: String, Codable, Sendable {
    case stimulant
    case antidepressant
    case antipsychotic
    case anxiolytic
    case opioidAnalgesic
    case betaBlocker
    case alphaAgonist
    case anticholinergic
    case anticonvulsant
    case sedativeHypnotic
    case dissociative
    case psychedelic
    case cannabinoid
    case alcohol
    case nicotinic
    case antihistamine
    case corticosteroid
    case nsaid
    case cardiovascular
    case gastrointestinal
    case endocrine
    case other
}

/// Pharmacokinetic and autonomic profile for a substance.
///
/// Models the expected time course and magnitude of HRV entropy change
/// following administration. Directly analogous to FlexAID∆S binding profiles
/// where each ligand has characteristic ΔS_config upon docking.
///
/// The isomorphism:
///   FlexAID∆S:  ΔS_config = S_bound - S_free  (torsional angles, kcal/mol·K)
///   NATURaL:    ΔH_hrv    = H_post  - H_pre   (RR intervals, bits)
public struct PharmacokineticProfile: Sendable {
    /// Stable identifier (lowercase, e.g., "amphetamine", "caffeine", "propranolol").
    public let substanceId: String

    /// Display name.
    public let name: LocalizedString

    /// Therapeutic class.
    public let therapeuticClass: TherapeuticClass

    /// Time from administration to first detectable autonomic effect (minutes).
    public let onsetMinutes: Double

    /// Time to peak plasma concentration / peak autonomic effect (minutes).
    public let tmaxMinutes: Double

    /// Elimination half-life (minutes).
    public let halfLifeMinutes: Double

    /// Expected ΔH range at Tmax (bits).
    /// Negative for sympathomimetics (entropy collapse), positive for parasympathomimetics.
    public let expectedDeltaHRange: ClosedRange<Double>

    /// Primary autonomic mechanism.
    public let mechanism: AutonomicMechanism

    /// FDA approval status.
    public let fdaApproved: Bool

    /// Whether this is a controlled/scheduled substance.
    public let scheduled: Bool

    /// Known configurational entropy penalty of binding (kcal/mol at 298K), if characterized.
    /// Computed as -TΔS_config from FlexAID∆S or published computational chemistry data.
    /// Positive values = entropy penalty (unfavorable contribution to binding free energy).
    /// nil = not yet characterized for this substance.
    public let bindingEntropyKcal: Double?

    /// Shannon entropy change (ΔS_config) in bits, derived from bindingEntropyKcal.
    /// Negative = binding constrains conformational freedom.
    /// Computed via: ΔS_bits = -penalty / (T × R × ln(2)) at 298K.
    public var bindingEntropySBits: Double? {
        guard let kcal = bindingEntropyKcal else { return nil }
        let R: Double = 1.987e-3  // kcal/(mol·K)
        let T: Double = 298.0
        return -kcal / (T * R * log(2.0))
    }

    /// Analysis windows (minutes post-dose) for entropy measurement.
    public var analysisWindows: [Double] {
        let windows = [
            onsetMinutes,
            (onsetMinutes + tmaxMinutes) / 2,
            tmaxMinutes,
            tmaxMinutes * 1.5,
            tmaxMinutes + halfLifeMinutes,
            tmaxMinutes + halfLifeMinutes * 2,
        ]
        return Array(Set(windows.map { ($0 * 10).rounded() / 10 })).sorted()
    }

    public init(
        substanceId: String,
        name: LocalizedString,
        therapeuticClass: TherapeuticClass,
        onsetMinutes: Double,
        tmaxMinutes: Double,
        halfLifeMinutes: Double,
        expectedDeltaHRange: ClosedRange<Double>,
        mechanism: AutonomicMechanism,
        fdaApproved: Bool = true,
        scheduled: Bool = false,
        bindingEntropyKcal: Double? = nil
    ) {
        self.substanceId = substanceId
        self.name = name
        self.therapeuticClass = therapeuticClass
        self.onsetMinutes = onsetMinutes
        self.tmaxMinutes = tmaxMinutes
        self.halfLifeMinutes = halfLifeMinutes
        self.expectedDeltaHRange = expectedDeltaHRange
        self.mechanism = mechanism
        self.fdaApproved = fdaApproved
        self.scheduled = scheduled
        self.bindingEntropyKcal = bindingEntropyKcal
    }
}

// MARK: - Known Profiles: Stimulants & ADHD Medications

extension PharmacokineticProfile {

    /// d-Amphetamine / mixed amphetamine salts (Adderall).
    /// NE/DA reuptake inhibition + vesicular release. Schedule II.
    /// Tmax ~3h oral IR, t½ ~10h. Pronounced HRV entropy collapse.
    public static let amphetamine = PharmacokineticProfile(
        substanceId: "amphetamine",
        name: LocalizedString(en: "Amphetamine", fr: "Amphétamine"),
        therapeuticClass: .stimulant,
        onsetMinutes: 30,
        tmaxMinutes: 180,
        halfLifeMinutes: 600,
        expectedDeltaHRange: -2.0...(-0.8),
        mechanism: .sympathomimetic,
        scheduled: true,
        bindingEntropyKcal: 1.2  // 2 rotatable bonds, small molecule
    )

    /// Lisdexamfetamine (Vyvanse). Prodrug of d-amphetamine.
    /// Slower onset, smoother PK curve. Schedule II.
    /// Tmax ~3.5h, t½ ~12h (includes prodrug conversion).
    public static let lisdexamfetamine = PharmacokineticProfile(
        substanceId: "lisdexamfetamine",
        name: LocalizedString(en: "Lisdexamfetamine", fr: "Lisdexamfétamine"),
        therapeuticClass: .stimulant,
        onsetMinutes: 60,
        tmaxMinutes: 210,
        halfLifeMinutes: 720,
        expectedDeltaHRange: -1.8...(-0.6),
        mechanism: .sympathomimetic,
        scheduled: true,
        bindingEntropyKcal: 1.8  // Lysine-conjugated amphetamine, 4 rotatable bonds
    )

    /// Methylphenidate (Ritalin/Concerta).
    /// DAT/NET reuptake inhibitor. Schedule II.
    /// Tmax ~2h IR, t½ ~3h.
    public static let methylphenidate = PharmacokineticProfile(
        substanceId: "methylphenidate",
        name: LocalizedString(en: "Methylphenidate", fr: "Méthylphénidate"),
        therapeuticClass: .stimulant,
        onsetMinutes: 20,
        tmaxMinutes: 120,
        halfLifeMinutes: 180,
        expectedDeltaHRange: -1.5...(-0.5),
        mechanism: .sympathomimetic,
        scheduled: true,
        bindingEntropyKcal: 2.8  // 3 rotatable bonds, moderate constraint
    )

    /// Dextroamphetamine (Dexedrine). Pure d-isomer.
    /// Tmax ~3h, t½ ~12h. Schedule II.
    public static let dextroamphetamine = PharmacokineticProfile(
        substanceId: "dextroamphetamine",
        name: LocalizedString(en: "Dextroamphetamine", fr: "Dextroamphétamine"),
        therapeuticClass: .stimulant,
        onsetMinutes: 30,
        tmaxMinutes: 180,
        halfLifeMinutes: 720,
        expectedDeltaHRange: -2.0...(-0.8),
        mechanism: .sympathomimetic,
        scheduled: true,
        bindingEntropyKcal: 1.2  // Same structure as amphetamine, 2 rotatable bonds
    )

    /// Methamphetamine (Desoxyn). FDA-approved for ADHD and obesity.
    /// Potent NE/DA releaser. Schedule II.
    /// Tmax ~3h, t½ ~10h. Strongest HRV entropy collapse in class.
    public static let methamphetamine = PharmacokineticProfile(
        substanceId: "methamphetamine",
        name: LocalizedString(en: "Methamphetamine", fr: "Méthamphétamine"),
        therapeuticClass: .stimulant,
        onsetMinutes: 20,
        tmaxMinutes: 180,
        halfLifeMinutes: 600,
        expectedDeltaHRange: -2.5...(-1.0),
        mechanism: .sympathomimetic,
        scheduled: true,
        bindingEntropyKcal: 1.3  // N-methyl phenethylamine, 2 rotatable bonds
    )

    /// Modafinil (Provigil). Wakefulness-promoting, atypical stimulant.
    /// Weak DAT inhibitor, orexin modulation. Schedule IV.
    /// Tmax ~2-4h, t½ ~15h. Mild sympathomimetic effect.
    public static let modafinil = PharmacokineticProfile(
        substanceId: "modafinil",
        name: LocalizedString(en: "Modafinil", fr: "Modafinil"),
        therapeuticClass: .stimulant,
        onsetMinutes: 60,
        tmaxMinutes: 180,
        halfLifeMinutes: 900,
        expectedDeltaHRange: -0.8...(-0.2),
        mechanism: .sympathomimetic,
        scheduled: true,
        bindingEntropyKcal: 2.2  // Diphenylmethyl sulfinyl, 4 rotatable bonds
    )

    /// Armodafinil (Nuvigil). R-enantiomer of modafinil.
    /// Tmax ~2h, t½ ~15h. Schedule IV.
    public static let armodafinil = PharmacokineticProfile(
        substanceId: "armodafinil",
        name: LocalizedString(en: "Armodafinil", fr: "Armodafinil"),
        therapeuticClass: .stimulant,
        onsetMinutes: 60,
        tmaxMinutes: 120,
        halfLifeMinutes: 900,
        expectedDeltaHRange: -0.8...(-0.2),
        mechanism: .sympathomimetic,
        scheduled: true,
        bindingEntropyKcal: 2.2  // R-enantiomer of modafinil, identical structure
    )

    /// Atomoxetine (Strattera). NE reuptake inhibitor (non-stimulant ADHD).
    /// FDA-approved, not scheduled.
    /// Tmax ~1-2h, t½ ~5h. Moderate sympathomimetic.
    public static let atomoxetine = PharmacokineticProfile(
        substanceId: "atomoxetine",
        name: LocalizedString(en: "Atomoxetine", fr: "Atomoxétine"),
        therapeuticClass: .stimulant,
        onsetMinutes: 60,
        tmaxMinutes: 90,
        halfLifeMinutes: 300,
        expectedDeltaHRange: -1.0...(-0.3),
        mechanism: .sympathomimetic,
        scheduled: false,
        bindingEntropyKcal: 2.5  // Phenoxypropylamine, 4 rotatable bonds
    )
}

// MARK: - Known Profiles: Caffeine & Xanthines

extension PharmacokineticProfile {

    /// Caffeine. Adenosine A1/A2A receptor antagonist.
    /// Mild sympathomimetic. Not scheduled.
    /// Tmax ~45min, t½ ~5h.
    public static let caffeine = PharmacokineticProfile(
        substanceId: "caffeine",
        name: LocalizedString(en: "Caffeine", fr: "Caféine"),
        therapeuticClass: .stimulant,
        onsetMinutes: 15,
        tmaxMinutes: 45,
        halfLifeMinutes: 300,
        expectedDeltaHRange: -0.8...(-0.2),
        mechanism: .sympathomimetic,
        fdaApproved: true,
        scheduled: false,
        bindingEntropyKcal: 0.4  // Rigid planar xanthine, minimal configurational penalty
    )

    /// Theophylline. Xanthine bronchodilator.
    /// Mild sympathomimetic + PDE inhibition. FDA-approved.
    /// Tmax ~1-2h, t½ ~8h.
    public static let theophylline = PharmacokineticProfile(
        substanceId: "theophylline",
        name: LocalizedString(en: "Theophylline", fr: "Théophylline"),
        therapeuticClass: .other,
        onsetMinutes: 30,
        tmaxMinutes: 90,
        halfLifeMinutes: 480,
        expectedDeltaHRange: -0.6...(-0.1),
        mechanism: .sympathomimetic,
        scheduled: false,
        bindingEntropyKcal: 0.3  // Rigid planar xanthine, similar to caffeine
    )
}

// MARK: - Known Profiles: Beta-Blockers & Cardiovascular

extension PharmacokineticProfile {

    /// Propranolol. Non-selective beta-blocker.
    /// Increases vagal tone → expanded HRV → entropy increase.
    /// Tmax ~1.5h, t½ ~4h.
    public static let propranolol = PharmacokineticProfile(
        substanceId: "propranolol",
        name: LocalizedString(en: "Propranolol", fr: "Propranolol"),
        therapeuticClass: .betaBlocker,
        onsetMinutes: 30,
        tmaxMinutes: 90,
        halfLifeMinutes: 240,
        expectedDeltaHRange: 0.3...1.5,
        mechanism: .parasympathomimetic,
        scheduled: false,
        bindingEntropyKcal: 3.5  // 5 rotatable bonds, flexible chain
    )

    /// Metoprolol. Selective β1-blocker.
    /// Tmax ~1.5h, t½ ~3-7h. Milder vagal effect than propranolol.
    public static let metoprolol = PharmacokineticProfile(
        substanceId: "metoprolol",
        name: LocalizedString(en: "Metoprolol", fr: "Métoprolol"),
        therapeuticClass: .betaBlocker,
        onsetMinutes: 30,
        tmaxMinutes: 90,
        halfLifeMinutes: 300,
        expectedDeltaHRange: 0.2...1.2,
        mechanism: .parasympathomimetic,
        scheduled: false,
        bindingEntropyKcal: 4.0  // Long flexible chain
    )

    /// Atenolol. Selective β1-blocker, hydrophilic.
    /// Tmax ~2-4h, t½ ~6-7h.
    public static let atenolol = PharmacokineticProfile(
        substanceId: "atenolol",
        name: LocalizedString(en: "Atenolol", fr: "Aténolol"),
        therapeuticClass: .betaBlocker,
        onsetMinutes: 60,
        tmaxMinutes: 180,
        halfLifeMinutes: 390,
        expectedDeltaHRange: 0.2...1.0,
        mechanism: .parasympathomimetic,
        scheduled: false,
        bindingEntropyKcal: 3.8  // Similar to metoprolol
    )

    /// Bisoprolol. Highly selective β1-blocker.
    /// Tmax ~2-3h, t½ ~10-12h.
    public static let bisoprolol = PharmacokineticProfile(
        substanceId: "bisoprolol",
        name: LocalizedString(en: "Bisoprolol", fr: "Bisoprolol"),
        therapeuticClass: .betaBlocker,
        onsetMinutes: 60,
        tmaxMinutes: 150,
        halfLifeMinutes: 660,
        expectedDeltaHRange: 0.2...1.0,
        mechanism: .parasympathomimetic,
        scheduled: false,
        bindingEntropyKcal: 4.0  // Isopropylamine ether chain, 7 rotatable bonds
    )

    /// Carvedilol. Non-selective β-blocker + α1-blocker.
    /// Tmax ~1.5h, t½ ~7-10h.
    public static let carvedilol = PharmacokineticProfile(
        substanceId: "carvedilol",
        name: LocalizedString(en: "Carvedilol", fr: "Carvédilol"),
        therapeuticClass: .betaBlocker,
        onsetMinutes: 30,
        tmaxMinutes: 90,
        halfLifeMinutes: 510,
        expectedDeltaHRange: 0.2...1.3,
        mechanism: .parasympathomimetic,
        scheduled: false,
        bindingEntropyKcal: 3.5  // Carbazole + propanolamine, 6 rotatable bonds
    )

    /// Clonidine. α2-adrenergic agonist (central sympatholytic).
    /// Reduces sympathetic outflow. Tmax ~1-3h, t½ ~12-16h.
    /// Also used for ADHD, opioid withdrawal.
    public static let clonidine = PharmacokineticProfile(
        substanceId: "clonidine",
        name: LocalizedString(en: "Clonidine", fr: "Clonidine"),
        therapeuticClass: .alphaAgonist,
        onsetMinutes: 30,
        tmaxMinutes: 120,
        halfLifeMinutes: 840,
        expectedDeltaHRange: 0.3...1.5,
        mechanism: .parasympathomimetic,
        scheduled: false,
        bindingEntropyKcal: 0.6  // Small, rigid imidazoline
    )

    /// Guanfacine (Intuniv). α2A-selective agonist.
    /// Tmax ~4h, t½ ~17h.
    public static let guanfacine = PharmacokineticProfile(
        substanceId: "guanfacine",
        name: LocalizedString(en: "Guanfacine", fr: "Guanfacine"),
        therapeuticClass: .alphaAgonist,
        onsetMinutes: 60,
        tmaxMinutes: 240,
        halfLifeMinutes: 1020,
        expectedDeltaHRange: 0.2...1.2,
        mechanism: .parasympathomimetic,
        scheduled: false,
        bindingEntropyKcal: 1.4  // Dichlorophenylacetylguanidine, 2 rotatable bonds
    )

    /// Digoxin. Cardiac glycoside.
    /// Enhances vagal tone. Tmax ~1-3h oral, t½ ~36-48h.
    public static let digoxin = PharmacokineticProfile(
        substanceId: "digoxin",
        name: LocalizedString(en: "Digoxin", fr: "Digoxine"),
        therapeuticClass: .cardiovascular,
        onsetMinutes: 60,
        tmaxMinutes: 120,
        halfLifeMinutes: 2520,
        expectedDeltaHRange: 0.2...0.8,
        mechanism: .parasympathomimetic,
        scheduled: false,
        bindingEntropyKcal: 5.0  // Large steroid glycoside, 8+ rotatable bonds in sugar chain
    )

    /// Ivabradine (Corlanor). If-channel blocker.
    /// Reduces HR without affecting HRV pattern. Tmax ~1h, t½ ~6h.
    public static let ivabradine = PharmacokineticProfile(
        substanceId: "ivabradine",
        name: LocalizedString(en: "Ivabradine", fr: "Ivabradine"),
        therapeuticClass: .cardiovascular,
        onsetMinutes: 30,
        tmaxMinutes: 60,
        halfLifeMinutes: 360,
        expectedDeltaHRange: -0.2...0.3,
        mechanism: .unknown,
        scheduled: false,
        bindingEntropyKcal: 3.0  // Benzazepinone, 5 rotatable bonds
    )
}

// MARK: - Known Profiles: Antidepressants

extension PharmacokineticProfile {

    /// Sertraline (Zoloft). SSRI.
    /// Mild sympathomimetic effect via serotonin-mediated NE modulation.
    /// Tmax ~4.5-8h, t½ ~26h.
    public static let sertraline = PharmacokineticProfile(
        substanceId: "sertraline",
        name: LocalizedString(en: "Sertraline", fr: "Sertraline"),
        therapeuticClass: .antidepressant,
        onsetMinutes: 120,
        tmaxMinutes: 390,
        halfLifeMinutes: 1560,
        expectedDeltaHRange: -0.5...0.1,
        mechanism: .mixed,
        scheduled: false,
        bindingEntropyKcal: 2.2  // 3 rotatable bonds
    )

    /// Fluoxetine (Prozac). SSRI. Long t½ including active metabolite.
    /// Tmax ~6-8h, t½ ~1-3 days (norfluoxetine: 4-16 days).
    public static let fluoxetine = PharmacokineticProfile(
        substanceId: "fluoxetine",
        name: LocalizedString(en: "Fluoxetine", fr: "Fluoxétine"),
        therapeuticClass: .antidepressant,
        onsetMinutes: 120,
        tmaxMinutes: 420,
        halfLifeMinutes: 2880,
        expectedDeltaHRange: -0.5...0.1,
        mechanism: .mixed,
        scheduled: false,
        bindingEntropyKcal: 3.0  // 5 rotatable bonds
    )

    /// Escitalopram (Lexapro). SSRI.
    /// Tmax ~5h, t½ ~27-32h.
    public static let escitalopram = PharmacokineticProfile(
        substanceId: "escitalopram",
        name: LocalizedString(en: "Escitalopram", fr: "Escitalopram"),
        therapeuticClass: .antidepressant,
        onsetMinutes: 120,
        tmaxMinutes: 300,
        halfLifeMinutes: 1800,
        expectedDeltaHRange: -0.4...0.1,
        mechanism: .mixed,
        scheduled: false,
        bindingEntropyKcal: 2.5  // Bicyclic phthalane + fluorophenyl, 4 rotatable bonds
    )

    /// Paroxetine (Paxil). SSRI + anticholinergic.
    /// Stronger autonomic effects due to muscarinic antagonism.
    /// Tmax ~5h, t½ ~21h.
    public static let paroxetine = PharmacokineticProfile(
        substanceId: "paroxetine",
        name: LocalizedString(en: "Paroxetine", fr: "Paroxétine"),
        therapeuticClass: .antidepressant,
        onsetMinutes: 120,
        tmaxMinutes: 300,
        halfLifeMinutes: 1260,
        expectedDeltaHRange: -0.6...0.0,
        mechanism: .mixed,
        scheduled: false,
        bindingEntropyKcal: 2.0  // Methylenedioxyphenyl piperidine, 3 rotatable bonds
    )

    /// Venlafaxine (Effexor). SNRI.
    /// NE reuptake at higher doses → sympathomimetic component.
    /// Tmax ~2h IR, t½ ~5h.
    public static let venlafaxine = PharmacokineticProfile(
        substanceId: "venlafaxine",
        name: LocalizedString(en: "Venlafaxine", fr: "Venlafaxine"),
        therapeuticClass: .antidepressant,
        onsetMinutes: 60,
        tmaxMinutes: 120,
        halfLifeMinutes: 300,
        expectedDeltaHRange: -0.8...(-0.1),
        mechanism: .sympathomimetic,
        scheduled: false,
        bindingEntropyKcal: 3.8  // 6 rotatable bonds
    )

    /// Duloxetine (Cymbalta). SNRI.
    /// Tmax ~6h, t½ ~12h.
    public static let duloxetine = PharmacokineticProfile(
        substanceId: "duloxetine",
        name: LocalizedString(en: "Duloxetine", fr: "Duloxétine"),
        therapeuticClass: .antidepressant,
        onsetMinutes: 120,
        tmaxMinutes: 360,
        halfLifeMinutes: 720,
        expectedDeltaHRange: -0.7...(-0.1),
        mechanism: .sympathomimetic,
        scheduled: false,
        bindingEntropyKcal: 2.3  // Naphthyl thioether + amine chain, 3 rotatable bonds
    )

    /// Bupropion (Wellbutrin). NDRI.
    /// Norepinephrine/dopamine reuptake inhibitor. Sympathomimetic.
    /// Tmax ~2h IR, t½ ~21h.
    public static let bupropion = PharmacokineticProfile(
        substanceId: "bupropion",
        name: LocalizedString(en: "Bupropion", fr: "Bupropion"),
        therapeuticClass: .antidepressant,
        onsetMinutes: 60,
        tmaxMinutes: 120,
        halfLifeMinutes: 1260,
        expectedDeltaHRange: -0.8...(-0.2),
        mechanism: .sympathomimetic,
        scheduled: false,
        bindingEntropyKcal: 1.8  // Aminoketone, 3 rotatable bonds, chlorophenyl
    )

    /// Mirtazapine (Remeron). NaSSA.
    /// α2-antagonist + antihistamine. Sedating, parasympathetic.
    /// Tmax ~2h, t½ ~20-40h.
    public static let mirtazapine = PharmacokineticProfile(
        substanceId: "mirtazapine",
        name: LocalizedString(en: "Mirtazapine", fr: "Mirtazapine"),
        therapeuticClass: .antidepressant,
        onsetMinutes: 60,
        tmaxMinutes: 120,
        halfLifeMinutes: 1800,
        expectedDeltaHRange: 0.1...0.6,
        mechanism: .parasympathomimetic,
        scheduled: false,
        bindingEntropyKcal: 1.2  // Tetracyclic, mostly rigid, 1 rotatable N-methyl piperazine
    )

    /// Trazodone. SARI. Serotonin antagonist + reuptake inhibitor.
    /// Sedating, α1-antagonist. Tmax ~1h, t½ ~5-9h.
    public static let trazodone = PharmacokineticProfile(
        substanceId: "trazodone",
        name: LocalizedString(en: "Trazodone", fr: "Trazodone"),
        therapeuticClass: .antidepressant,
        onsetMinutes: 30,
        tmaxMinutes: 60,
        halfLifeMinutes: 420,
        expectedDeltaHRange: 0.0...0.5,
        mechanism: .parasympathomimetic,
        scheduled: false,
        bindingEntropyKcal: 2.8  // Triazolopyridine + piperazine + chlorophenyl, 4 rotatable bonds
    )

    /// Amitriptyline. TCA. Strong anticholinergic + NE/5-HT reuptake.
    /// Tmax ~4h, t½ ~25h.
    public static let amitriptyline = PharmacokineticProfile(
        substanceId: "amitriptyline",
        name: LocalizedString(en: "Amitriptyline", fr: "Amitriptyline"),
        therapeuticClass: .antidepressant,
        onsetMinutes: 60,
        tmaxMinutes: 240,
        halfLifeMinutes: 1500,
        expectedDeltaHRange: -0.8...(-0.2),
        mechanism: .sympathomimetic,
        scheduled: false,
        bindingEntropyKcal: 2.0  // Tricyclic + dimethylaminopropylidene, 3 rotatable bonds
    )

    /// Nortriptyline. TCA (active metabolite of amitriptyline).
    /// Tmax ~4-6h, t½ ~28h.
    public static let nortriptyline = PharmacokineticProfile(
        substanceId: "nortriptyline",
        name: LocalizedString(en: "Nortriptyline", fr: "Nortriptyline"),
        therapeuticClass: .antidepressant,
        onsetMinutes: 60,
        tmaxMinutes: 300,
        halfLifeMinutes: 1680,
        expectedDeltaHRange: -0.7...(-0.1),
        mechanism: .sympathomimetic,
        scheduled: false,
        bindingEntropyKcal: 1.6  // Tricyclic + methylaminopropylidene, 2 rotatable bonds
    )

    /// Phenelzine (Nardil). MAOI.
    /// Irreversible MAO-A/B inhibitor. Significant sympathomimetic at higher doses.
    /// Tmax ~2h, t½ ~12h (but MAO regeneration takes weeks).
    public static let phenelzine = PharmacokineticProfile(
        substanceId: "phenelzine",
        name: LocalizedString(en: "Phenelzine", fr: "Phénelzine"),
        therapeuticClass: .antidepressant,
        onsetMinutes: 60,
        tmaxMinutes: 120,
        halfLifeMinutes: 720,
        expectedDeltaHRange: -0.6...0.0,
        mechanism: .mixed,
        scheduled: false,
        bindingEntropyKcal: 1.0  // Phenylethylhydrazine, 2 rotatable bonds
    )

    /// Tranylcypromine (Parnate). MAOI.
    /// Irreversible, amphetamine-like structure. Sympathomimetic.
    /// Tmax ~1-2h, t½ ~2.5h.
    public static let tranylcypromine = PharmacokineticProfile(
        substanceId: "tranylcypromine",
        name: LocalizedString(en: "Tranylcypromine", fr: "Tranylcypromine"),
        therapeuticClass: .antidepressant,
        onsetMinutes: 30,
        tmaxMinutes: 90,
        halfLifeMinutes: 150,
        expectedDeltaHRange: -1.0...(-0.3),
        mechanism: .sympathomimetic,
        scheduled: false,
        bindingEntropyKcal: 0.5  // Rigid cyclopropylamine, minimal flexibility
    )
}

// MARK: - Known Profiles: Antipsychotics

extension PharmacokineticProfile {

    /// Quetiapine (Seroquel). Atypical antipsychotic.
    /// Strong antihistamine + α1-antagonist at low dose. Sedating.
    /// Tmax ~1.5h, t½ ~7h.
    public static let quetiapine = PharmacokineticProfile(
        substanceId: "quetiapine",
        name: LocalizedString(en: "Quetiapine", fr: "Quétiapine"),
        therapeuticClass: .antipsychotic,
        onsetMinutes: 30,
        tmaxMinutes: 90,
        halfLifeMinutes: 420,
        expectedDeltaHRange: -0.3...0.4,
        mechanism: .mixed,
        scheduled: false,
        bindingEntropyKcal: 4.5  // 7 rotatable bonds, long chain
    )

    /// Olanzapine (Zyprexa). Atypical antipsychotic.
    /// Multi-receptor antagonist. Significant anticholinergic/antihistamine.
    /// Tmax ~5-8h, t½ ~30h.
    public static let olanzapine = PharmacokineticProfile(
        substanceId: "olanzapine",
        name: LocalizedString(en: "Olanzapine", fr: "Olanzapine"),
        therapeuticClass: .antipsychotic,
        onsetMinutes: 120,
        tmaxMinutes: 390,
        halfLifeMinutes: 1800,
        expectedDeltaHRange: -0.5...0.2,
        mechanism: .mixed,
        scheduled: false,
        bindingEntropyKcal: 1.8  // Thienobenzodiazepine, moderate flexibility
    )

    /// Risperidone (Risperdal). Atypical antipsychotic.
    /// D2/5-HT2A antagonist. Tmax ~1h, t½ ~3h (active metabolite ~21h).
    public static let risperidone = PharmacokineticProfile(
        substanceId: "risperidone",
        name: LocalizedString(en: "Risperidone", fr: "Rispéridone"),
        therapeuticClass: .antipsychotic,
        onsetMinutes: 30,
        tmaxMinutes: 60,
        halfLifeMinutes: 1260,
        expectedDeltaHRange: -0.4...0.2,
        mechanism: .mixed,
        scheduled: false,
        bindingEntropyKcal: 2.8  // Benzisoxazole-piperidine chain, 4 rotatable bonds
    )

    /// Aripiprazole (Abilify). Atypical antipsychotic / D2 partial agonist.
    /// Tmax ~3-5h, t½ ~75h.
    public static let aripiprazole = PharmacokineticProfile(
        substanceId: "aripiprazole",
        name: LocalizedString(en: "Aripiprazole", fr: "Aripiprazole"),
        therapeuticClass: .antipsychotic,
        onsetMinutes: 120,
        tmaxMinutes: 240,
        halfLifeMinutes: 4500,
        expectedDeltaHRange: -0.3...0.2,
        mechanism: .mixed,
        scheduled: false,
        bindingEntropyKcal: 3.5  // Dichlorophenyl piperazine + butoxy chain, 6 rotatable bonds
    )

    /// Haloperidol (Haldol). Typical antipsychotic.
    /// Potent D2 antagonist. Tmax ~2-6h oral, t½ ~12-36h.
    public static let haloperidol = PharmacokineticProfile(
        substanceId: "haloperidol",
        name: LocalizedString(en: "Haloperidol", fr: "Halopéridol"),
        therapeuticClass: .antipsychotic,
        onsetMinutes: 60,
        tmaxMinutes: 240,
        halfLifeMinutes: 1440,
        expectedDeltaHRange: -0.4...0.1,
        mechanism: .mixed,
        scheduled: false,
        bindingEntropyKcal: 3.6  // Long chain between ring systems
    )

    /// Chlorpromazine (Thorazine). Typical antipsychotic.
    /// Strong α1-antagonist + anticholinergic. Tmax ~2-4h, t½ ~30h.
    public static let chlorpromazine = PharmacokineticProfile(
        substanceId: "chlorpromazine",
        name: LocalizedString(en: "Chlorpromazine", fr: "Chlorpromazine"),
        therapeuticClass: .antipsychotic,
        onsetMinutes: 30,
        tmaxMinutes: 180,
        halfLifeMinutes: 1800,
        expectedDeltaHRange: -0.5...0.2,
        mechanism: .mixed,
        scheduled: false,
        bindingEntropyKcal: 2.0  // Phenothiazine + dimethylaminopropyl, 3 rotatable bonds
    )

    /// Clozapine (Clozaril). Atypical antipsychotic.
    /// Multi-receptor. Strong anticholinergic. Known for QTc and autonomic effects.
    /// Tmax ~2.5h, t½ ~12h.
    public static let clozapine = PharmacokineticProfile(
        substanceId: "clozapine",
        name: LocalizedString(en: "Clozapine", fr: "Clozapine"),
        therapeuticClass: .antipsychotic,
        onsetMinutes: 60,
        tmaxMinutes: 150,
        halfLifeMinutes: 720,
        expectedDeltaHRange: -0.6...0.1,
        mechanism: .mixed,
        scheduled: false,
        bindingEntropyKcal: 1.5  // Dibenzodiazepine, mostly rigid, 2 rotatable N-methyl piperazine
    )
}

// MARK: - Known Profiles: Anxiolytics & Sedatives

extension PharmacokineticProfile {

    /// Alprazolam (Xanax). Short-acting benzodiazepine.
    /// GABA-A positive allosteric modulator. Schedule IV.
    /// Tmax ~1-2h, t½ ~11h.
    public static let alprazolam = PharmacokineticProfile(
        substanceId: "alprazolam",
        name: LocalizedString(en: "Alprazolam", fr: "Alprazolam"),
        therapeuticClass: .anxiolytic,
        onsetMinutes: 15,
        tmaxMinutes: 90,
        halfLifeMinutes: 660,
        expectedDeltaHRange: 0.2...1.0,
        mechanism: .parasympathomimetic,
        scheduled: true,
        bindingEntropyKcal: 0.8  // Rigid fused ring system
    )

    /// Diazepam (Valium). Long-acting benzodiazepine.
    /// Tmax ~0.5-2h, t½ ~20-100h (with active metabolites).
    public static let diazepam = PharmacokineticProfile(
        substanceId: "diazepam",
        name: LocalizedString(en: "Diazepam", fr: "Diazépam"),
        therapeuticClass: .anxiolytic,
        onsetMinutes: 15,
        tmaxMinutes: 75,
        halfLifeMinutes: 3600,
        expectedDeltaHRange: 0.2...1.0,
        mechanism: .parasympathomimetic,
        scheduled: true,
        bindingEntropyKcal: 1.1  // Rigid benzodiazepine
    )

    /// Lorazepam (Ativan). Intermediate benzodiazepine.
    /// Tmax ~2h, t½ ~12h.
    public static let lorazepam = PharmacokineticProfile(
        substanceId: "lorazepam",
        name: LocalizedString(en: "Lorazepam", fr: "Lorazépam"),
        therapeuticClass: .anxiolytic,
        onsetMinutes: 20,
        tmaxMinutes: 120,
        halfLifeMinutes: 720,
        expectedDeltaHRange: 0.2...0.9,
        mechanism: .parasympathomimetic,
        scheduled: true,
        bindingEntropyKcal: 0.9  // Rigid benzodiazepine
    )

    /// Clonazepam (Klonopin). Long-acting benzodiazepine.
    /// Tmax ~1-4h, t½ ~30-40h.
    public static let clonazepam = PharmacokineticProfile(
        substanceId: "clonazepam",
        name: LocalizedString(en: "Clonazepam", fr: "Clonazépam"),
        therapeuticClass: .anxiolytic,
        onsetMinutes: 20,
        tmaxMinutes: 150,
        halfLifeMinutes: 2100,
        expectedDeltaHRange: 0.2...0.9,
        mechanism: .parasympathomimetic,
        scheduled: true,
        bindingEntropyKcal: 0.9  // Rigid nitrobenzodiazepine, 0 rotatable bonds
    )

    /// Buspirone. 5-HT1A partial agonist (non-benzodiazepine anxiolytic).
    /// Not scheduled. Tmax ~0.5-1.5h, t½ ~2-3h.
    public static let buspirone = PharmacokineticProfile(
        substanceId: "buspirone",
        name: LocalizedString(en: "Buspirone", fr: "Buspirone"),
        therapeuticClass: .anxiolytic,
        onsetMinutes: 30,
        tmaxMinutes: 60,
        halfLifeMinutes: 150,
        expectedDeltaHRange: -0.2...0.3,
        mechanism: .mixed,
        scheduled: false,
        bindingEntropyKcal: 3.0  // Azapirone + butyl piperazine chain, 5 rotatable bonds
    )

    /// Hydroxyzine (Vistaril). Antihistamine anxiolytic.
    /// H1-antagonist + anticholinergic. Not scheduled.
    /// Tmax ~2h, t½ ~20h.
    public static let hydroxyzine = PharmacokineticProfile(
        substanceId: "hydroxyzine",
        name: LocalizedString(en: "Hydroxyzine", fr: "Hydroxyzine"),
        therapeuticClass: .antihistamine,
        onsetMinutes: 30,
        tmaxMinutes: 120,
        halfLifeMinutes: 1200,
        expectedDeltaHRange: 0.0...0.5,
        mechanism: .parasympathomimetic,
        scheduled: false,
        bindingEntropyKcal: 3.2  // Diphenylmethyl piperazine + ethoxy chain, 5 rotatable bonds
    )

    /// Zolpidem (Ambien). Non-benzodiazepine hypnotic (Z-drug).
    /// GABA-A α1 subunit selective. Schedule IV.
    /// Tmax ~1.6h, t½ ~2.5h.
    public static let zolpidem = PharmacokineticProfile(
        substanceId: "zolpidem",
        name: LocalizedString(en: "Zolpidem", fr: "Zolpidem"),
        therapeuticClass: .sedativeHypnotic,
        onsetMinutes: 15,
        tmaxMinutes: 96,
        halfLifeMinutes: 150,
        expectedDeltaHRange: 0.1...0.6,
        mechanism: .parasympathomimetic,
        scheduled: true,
        bindingEntropyKcal: 1.4  // Imidazopyridine, 2 rotatable bonds
    )

    /// Suvorexant (Belsomra). Orexin receptor antagonist.
    /// Tmax ~2h, t½ ~12h.
    public static let suvorexant = PharmacokineticProfile(
        substanceId: "suvorexant",
        name: LocalizedString(en: "Suvorexant", fr: "Suvorexant"),
        therapeuticClass: .sedativeHypnotic,
        onsetMinutes: 30,
        tmaxMinutes: 120,
        halfLifeMinutes: 720,
        expectedDeltaHRange: 0.0...0.4,
        mechanism: .parasympathomimetic,
        scheduled: true,
        bindingEntropyKcal: 2.5  // Diazepane + chlorobenzoxazole, 4 rotatable bonds
    )
}

// MARK: - Known Profiles: Opioids

extension PharmacokineticProfile {

    /// Morphine. Mu-opioid agonist. Schedule II.
    /// Vagotonic (increases parasympathetic tone). Tmax ~1h oral, t½ ~2-3h.
    public static let morphine = PharmacokineticProfile(
        substanceId: "morphine",
        name: LocalizedString(en: "Morphine", fr: "Morphine"),
        therapeuticClass: .opioidAnalgesic,
        onsetMinutes: 30,
        tmaxMinutes: 60,
        halfLifeMinutes: 150,
        expectedDeltaHRange: 0.2...1.2,
        mechanism: .parasympathomimetic,
        scheduled: true,
        bindingEntropyKcal: 1.0  // Rigid polycyclic, few rotatable bonds
    )

    /// Oxycodone (OxyContin). Semi-synthetic mu-opioid agonist. Schedule II.
    /// Tmax ~1.5h IR, t½ ~3.5h.
    public static let oxycodone = PharmacokineticProfile(
        substanceId: "oxycodone",
        name: LocalizedString(en: "Oxycodone", fr: "Oxycodone"),
        therapeuticClass: .opioidAnalgesic,
        onsetMinutes: 15,
        tmaxMinutes: 90,
        halfLifeMinutes: 210,
        expectedDeltaHRange: 0.2...1.2,
        mechanism: .parasympathomimetic,
        scheduled: true,
        bindingEntropyKcal: 1.2  // Rigid polycyclic, similar to morphine
    )

    /// Hydrocodone (Vicodin component). Schedule II.
    /// Tmax ~1.3h, t½ ~4h.
    public static let hydrocodone = PharmacokineticProfile(
        substanceId: "hydrocodone",
        name: LocalizedString(en: "Hydrocodone", fr: "Hydrocodone"),
        therapeuticClass: .opioidAnalgesic,
        onsetMinutes: 20,
        tmaxMinutes: 78,
        halfLifeMinutes: 240,
        expectedDeltaHRange: 0.2...1.0,
        mechanism: .parasympathomimetic,
        scheduled: true,
        bindingEntropyKcal: 1.1  // Rigid polycyclic phenanthrene, similar to morphine
    )

    /// Fentanyl. Potent synthetic mu-agonist. Schedule II.
    /// Tmax varies by route. Oral transmucosal ~25min, t½ ~7h.
    public static let fentanyl = PharmacokineticProfile(
        substanceId: "fentanyl",
        name: LocalizedString(en: "Fentanyl", fr: "Fentanyl"),
        therapeuticClass: .opioidAnalgesic,
        onsetMinutes: 5,
        tmaxMinutes: 25,
        halfLifeMinutes: 420,
        expectedDeltaHRange: 0.3...1.5,
        mechanism: .parasympathomimetic,
        scheduled: true,
        bindingEntropyKcal: 4.2  // Multiple rotatable bonds, high flexibility
    )

    /// Methadone. Long-acting mu-agonist + NMDA antagonist. Schedule II.
    /// Tmax ~2.5-4h, t½ ~24-36h. Known for QTc prolongation.
    public static let methadone = PharmacokineticProfile(
        substanceId: "methadone",
        name: LocalizedString(en: "Methadone", fr: "Méthadone"),
        therapeuticClass: .opioidAnalgesic,
        onsetMinutes: 30,
        tmaxMinutes: 195,
        halfLifeMinutes: 1800,
        expectedDeltaHRange: 0.2...1.0,
        mechanism: .parasympathomimetic,
        scheduled: true,
        bindingEntropyKcal: 3.2  // Diphenylpropylamine, 5 rotatable bonds
    )

    /// Buprenorphine (Subutex/Suboxone). Partial mu-agonist.
    /// Schedule III. Tmax ~1h sublingual, t½ ~37h.
    public static let buprenorphine = PharmacokineticProfile(
        substanceId: "buprenorphine",
        name: LocalizedString(en: "Buprenorphine", fr: "Buprénorphine"),
        therapeuticClass: .opioidAnalgesic,
        onsetMinutes: 30,
        tmaxMinutes: 60,
        halfLifeMinutes: 2220,
        expectedDeltaHRange: 0.1...0.7,
        mechanism: .parasympathomimetic,
        scheduled: true,
        bindingEntropyKcal: 1.5  // Rigid polycyclic + cyclopropylmethyl, 2 rotatable bonds
    )

    /// Tramadol. Weak mu-agonist + SNRI. Schedule IV.
    /// Tmax ~2h, t½ ~6h.
    public static let tramadol = PharmacokineticProfile(
        substanceId: "tramadol",
        name: LocalizedString(en: "Tramadol", fr: "Tramadol"),
        therapeuticClass: .opioidAnalgesic,
        onsetMinutes: 30,
        tmaxMinutes: 120,
        halfLifeMinutes: 360,
        expectedDeltaHRange: -0.2...0.6,
        mechanism: .mixed,
        scheduled: true,
        bindingEntropyKcal: 2.0  // Cyclohexanol + dimethylaminomethyl, 3 rotatable bonds
    )

    /// Naltrexone. Opioid antagonist (used for alcohol/opioid dependence).
    /// Blocks mu-receptors → removes opioid-mediated vagal effects.
    /// Tmax ~1h, t½ ~4h (6β-naltrexol: ~12h).
    public static let naltrexone = PharmacokineticProfile(
        substanceId: "naltrexone",
        name: LocalizedString(en: "Naltrexone", fr: "Naltrexone"),
        therapeuticClass: .opioidAnalgesic,
        onsetMinutes: 15,
        tmaxMinutes: 60,
        halfLifeMinutes: 240,
        expectedDeltaHRange: -0.4...0.1,
        mechanism: .sympathomimetic,
        scheduled: false,
        bindingEntropyKcal: 1.3  // Rigid polycyclic + cyclopropyl, 2 rotatable bonds
    )
}

// MARK: - Known Profiles: Anticonvulsants / Mood Stabilizers

extension PharmacokineticProfile {

    /// Gabapentin (Neurontin). Calcium channel α2δ ligand.
    /// Anxiolytic / anticonvulsant. Tmax ~2-3h, t½ ~5-7h.
    public static let gabapentin = PharmacokineticProfile(
        substanceId: "gabapentin",
        name: LocalizedString(en: "Gabapentin", fr: "Gabapentine"),
        therapeuticClass: .anticonvulsant,
        onsetMinutes: 60,
        tmaxMinutes: 150,
        halfLifeMinutes: 360,
        expectedDeltaHRange: 0.0...0.5,
        mechanism: .parasympathomimetic,
        scheduled: false,
        bindingEntropyKcal: 1.5  // Cyclohexane ring with flexible tail
    )

    /// Pregabalin (Lyrica). Calcium channel α2δ ligand. Schedule V.
    /// Tmax ~1.5h, t½ ~6h.
    public static let pregabalin = PharmacokineticProfile(
        substanceId: "pregabalin",
        name: LocalizedString(en: "Pregabalin", fr: "Prégabaline"),
        therapeuticClass: .anticonvulsant,
        onsetMinutes: 30,
        tmaxMinutes: 90,
        halfLifeMinutes: 360,
        expectedDeltaHRange: 0.0...0.5,
        mechanism: .parasympathomimetic,
        scheduled: true,
        bindingEntropyKcal: 1.6  // Isobutyl amino acid, 3 rotatable bonds
    )

    /// Lamotrigine (Lamictal). Sodium channel blocker.
    /// Mood stabilizer. Tmax ~2.5h, t½ ~25h.
    public static let lamotrigine = PharmacokineticProfile(
        substanceId: "lamotrigine",
        name: LocalizedString(en: "Lamotrigine", fr: "Lamotrigine"),
        therapeuticClass: .anticonvulsant,
        onsetMinutes: 60,
        tmaxMinutes: 150,
        halfLifeMinutes: 1500,
        expectedDeltaHRange: -0.2...0.2,
        mechanism: .unknown,
        scheduled: false,
        bindingEntropyKcal: 0.7  // Rigid dichlorophenyl triazine, 1 rotatable bond
    )

    /// Valproate / Valproic acid (Depakote). GABA enhancer / HDAC inhibitor.
    /// Tmax ~4h, t½ ~9-16h.
    public static let valproate = PharmacokineticProfile(
        substanceId: "valproate",
        name: LocalizedString(en: "Valproate", fr: "Valproate"),
        therapeuticClass: .anticonvulsant,
        onsetMinutes: 60,
        tmaxMinutes: 240,
        halfLifeMinutes: 750,
        expectedDeltaHRange: -0.2...0.3,
        mechanism: .mixed,
        scheduled: false,
        bindingEntropyKcal: 1.8  // Branched alkanoic acid, 4 rotatable bonds
    )

    /// Lithium. Mood stabilizer.
    /// Tmax ~2-4h IR, t½ ~18-36h. Can affect sinus node.
    public static let lithium = PharmacokineticProfile(
        substanceId: "lithium",
        name: LocalizedString(en: "Lithium", fr: "Lithium"),
        therapeuticClass: .anticonvulsant,
        onsetMinutes: 60,
        tmaxMinutes: 180,
        halfLifeMinutes: 1620,
        expectedDeltaHRange: -0.3...0.2,
        mechanism: .mixed,
        scheduled: false,
        bindingEntropyKcal: 0.0  // Monatomic ion, no rotatable bonds
    )

    /// Carbamazepine (Tegretol). Sodium channel blocker.
    /// Tmax ~4-5h, t½ ~12-17h (auto-induction to ~8h).
    public static let carbamazepine = PharmacokineticProfile(
        substanceId: "carbamazepine",
        name: LocalizedString(en: "Carbamazepine", fr: "Carbamazépine"),
        therapeuticClass: .anticonvulsant,
        onsetMinutes: 60,
        tmaxMinutes: 270,
        halfLifeMinutes: 870,
        expectedDeltaHRange: -0.3...0.1,
        mechanism: .mixed,
        scheduled: false,
        bindingEntropyKcal: 0.8  // Rigid tricyclic iminostilbene, 1 rotatable carboxamide
    )

    /// Topiramate (Topamax). Multiple mechanisms (Na+, GABA, glutamate).
    /// Tmax ~2h, t½ ~21h.
    public static let topiramate = PharmacokineticProfile(
        substanceId: "topiramate",
        name: LocalizedString(en: "Topiramate", fr: "Topiramate"),
        therapeuticClass: .anticonvulsant,
        onsetMinutes: 60,
        tmaxMinutes: 120,
        halfLifeMinutes: 1260,
        expectedDeltaHRange: -0.2...0.2,
        mechanism: .unknown,
        scheduled: false,
        bindingEntropyKcal: 1.6  // Sugar-based sulfamate, partially rigid, 3 rotatable bonds
    )
}

// MARK: - Known Profiles: Psychoactive Substances (Non-FDA / Recreational)

extension PharmacokineticProfile {

    /// Ethanol (alcohol).
    /// Biphasic: initial sympathetic (absorption), then parasympathetic (elimination).
    /// Tmax ~60min empty stomach, t½ ~60-90min per standard drink.
    public static let ethanol = PharmacokineticProfile(
        substanceId: "ethanol",
        name: LocalizedString(en: "Alcohol (Ethanol)", fr: "Alcool (Éthanol)"),
        therapeuticClass: .alcohol,
        onsetMinutes: 15,
        tmaxMinutes: 60,
        halfLifeMinutes: 90,
        expectedDeltaHRange: -1.0...0.5,
        mechanism: .mixed,
        fdaApproved: false,
        scheduled: false,
        bindingEntropyKcal: 0.1  // Minimal, essentially no rotatable bonds
    )

    /// Nicotine. nAChR agonist. Sympathomimetic.
    /// Tmax ~10min (inhaled), t½ ~2h.
    public static let nicotine = PharmacokineticProfile(
        substanceId: "nicotine",
        name: LocalizedString(en: "Nicotine", fr: "Nicotine"),
        therapeuticClass: .nicotinic,
        onsetMinutes: 1,
        tmaxMinutes: 10,
        halfLifeMinutes: 120,
        expectedDeltaHRange: -1.0...(-0.3),
        mechanism: .sympathomimetic,
        fdaApproved: true, // NRT products are FDA-approved
        scheduled: false,
        bindingEntropyKcal: 0.9  // Small, 1 rotatable bond
    )

    /// Δ9-THC (Cannabis). CB1/CB2 agonist.
    /// Biphasic HRV: initial tachycardia (sympathetic), then parasympathetic.
    /// Tmax ~10min (inhaled) / ~2h (oral), t½ ~25-36h (lipophilic).
    public static let thc = PharmacokineticProfile(
        substanceId: "thc",
        name: LocalizedString(en: "THC (Cannabis)", fr: "THC (Cannabis)"),
        therapeuticClass: .cannabinoid,
        onsetMinutes: 5,
        tmaxMinutes: 10,
        halfLifeMinutes: 1800,
        expectedDeltaHRange: -0.8...0.3,
        mechanism: .mixed,
        fdaApproved: false,
        scheduled: true,
        bindingEntropyKcal: 2.2  // Tricyclic terpene + pentyl chain, 4 rotatable bonds
    )

    /// Dronabinol (Marinol). Synthetic THC. FDA-approved. Schedule III.
    /// Tmax ~2-4h oral, t½ ~25-36h.
    public static let dronabinol = PharmacokineticProfile(
        substanceId: "dronabinol",
        name: LocalizedString(en: "Dronabinol", fr: "Dronabinol"),
        therapeuticClass: .cannabinoid,
        onsetMinutes: 30,
        tmaxMinutes: 180,
        halfLifeMinutes: 1800,
        expectedDeltaHRange: -0.6...0.3,
        mechanism: .mixed,
        fdaApproved: true,
        scheduled: true,
        bindingEntropyKcal: 2.2  // Synthetic THC, identical structure
    )

    /// Cocaine. DAT/NET/SERT inhibitor. Potent sympathomimetic. Schedule II.
    /// Tmax ~30min (intranasal), t½ ~1h.
    public static let cocaine = PharmacokineticProfile(
        substanceId: "cocaine",
        name: LocalizedString(en: "Cocaine", fr: "Cocaïne"),
        therapeuticClass: .stimulant,
        onsetMinutes: 3,
        tmaxMinutes: 30,
        halfLifeMinutes: 60,
        expectedDeltaHRange: -2.5...(-1.0),
        mechanism: .sympathomimetic,
        fdaApproved: true, // Schedule II, rare clinical use as local anesthetic
        scheduled: true,
        bindingEntropyKcal: 2.0  // Moderate flexibility
    )

    /// MDMA (3,4-methylenedioxymethamphetamine).
    /// SERT/DAT/NET releaser. Mixed sympathomimetic + serotonergic.
    /// Tmax ~2h, t½ ~8h.
    public static let mdma = PharmacokineticProfile(
        substanceId: "mdma",
        name: LocalizedString(en: "MDMA", fr: "MDMA"),
        therapeuticClass: .stimulant,
        onsetMinutes: 30,
        tmaxMinutes: 120,
        halfLifeMinutes: 480,
        expectedDeltaHRange: -1.8...(-0.5),
        mechanism: .sympathomimetic,
        fdaApproved: false,
        scheduled: true,
        bindingEntropyKcal: 1.5  // Methylenedioxyphenethylamine, 3 rotatable bonds
    )

    /// Psilocybin. 5-HT2A agonist. Psychedelic.
    /// Mild sympathomimetic. Tmax ~1.5h, t½ ~3h.
    public static let psilocybin = PharmacokineticProfile(
        substanceId: "psilocybin",
        name: LocalizedString(en: "Psilocybin", fr: "Psilocybine"),
        therapeuticClass: .psychedelic,
        onsetMinutes: 20,
        tmaxMinutes: 90,
        halfLifeMinutes: 180,
        expectedDeltaHRange: -0.6...0.3,
        mechanism: .mixed,
        fdaApproved: false,
        scheduled: true,
        bindingEntropyKcal: 1.4  // Tryptamine + phosphate ester, 3 rotatable bonds
    )

    /// LSD (lysergic acid diethylamide). 5-HT2A agonist.
    /// Mild sympathomimetic. Tmax ~1.5-2.5h, t½ ~3.5h.
    public static let lsd = PharmacokineticProfile(
        substanceId: "lsd",
        name: LocalizedString(en: "LSD", fr: "LSD"),
        therapeuticClass: .psychedelic,
        onsetMinutes: 30,
        tmaxMinutes: 120,
        halfLifeMinutes: 210,
        expectedDeltaHRange: -0.5...0.2,
        mechanism: .mixed,
        fdaApproved: false,
        scheduled: true,
        bindingEntropyKcal: 1.0  // Rigid ergoline tetracycle, 1 rotatable diethylamide
    )

    /// Ketamine. NMDA antagonist. Dissociative anesthetic.
    /// FDA-approved (esketamine nasal as Spravato for TRD). Schedule III.
    /// Tmax ~20min (intranasal), t½ ~2.5h.
    public static let ketamine = PharmacokineticProfile(
        substanceId: "ketamine",
        name: LocalizedString(en: "Ketamine", fr: "Kétamine"),
        therapeuticClass: .dissociative,
        onsetMinutes: 5,
        tmaxMinutes: 20,
        halfLifeMinutes: 150,
        expectedDeltaHRange: -0.8...0.4,
        mechanism: .mixed,
        fdaApproved: true,
        scheduled: true,
        bindingEntropyKcal: 0.8  // Cyclohexanone + chloroamine, 1 rotatable bond
    )

    /// GHB (gamma-hydroxybutyrate / Xyrem). GABA-B agonist.
    /// FDA-approved for narcolepsy. Schedule I/III (Xyrem).
    /// Tmax ~25-45min, t½ ~30-60min.
    public static let ghb = PharmacokineticProfile(
        substanceId: "ghb",
        name: LocalizedString(en: "GHB (Sodium Oxybate)", fr: "GHB (Oxybate de sodium)"),
        therapeuticClass: .sedativeHypnotic,
        onsetMinutes: 15,
        tmaxMinutes: 35,
        halfLifeMinutes: 45,
        expectedDeltaHRange: 0.2...1.0,
        mechanism: .parasympathomimetic,
        fdaApproved: true,
        scheduled: true,
        bindingEntropyKcal: 0.6  // Tiny 4-carbon hydroxybutyrate, 2 rotatable bonds
    )
}

// MARK: - Known Profiles: Anticholinergics & Antihistamines

extension PharmacokineticProfile {

    /// Diphenhydramine (Benadryl). H1-antagonist + anticholinergic.
    /// Tmax ~2h, t½ ~4-8h.
    public static let diphenhydramine = PharmacokineticProfile(
        substanceId: "diphenhydramine",
        name: LocalizedString(en: "Diphenhydramine", fr: "Diphenhydramine"),
        therapeuticClass: .antihistamine,
        onsetMinutes: 30,
        tmaxMinutes: 120,
        halfLifeMinutes: 360,
        expectedDeltaHRange: -0.4...0.2,
        mechanism: .mixed,
        scheduled: false,
        bindingEntropyKcal: 2.8  // Diphenylmethoxy + dimethylaminoethyl, 4 rotatable bonds
    )

    /// Promethazine (Phenergan). H1-antagonist + anticholinergic + α1-blocker.
    /// Tmax ~2-3h, t½ ~10-14h.
    public static let promethazine = PharmacokineticProfile(
        substanceId: "promethazine",
        name: LocalizedString(en: "Promethazine", fr: "Prométhazine"),
        therapeuticClass: .antihistamine,
        onsetMinutes: 30,
        tmaxMinutes: 150,
        halfLifeMinutes: 720,
        expectedDeltaHRange: -0.3...0.3,
        mechanism: .mixed,
        scheduled: false,
        bindingEntropyKcal: 2.2  // Phenothiazine + dimethylaminopropyl, 3 rotatable bonds
    )

    /// Scopolamine. Muscarinic antagonist.
    /// Paradoxically reduces HRV at low doses (removes vagal brake),
    /// increases at high doses. Tmax ~1h oral, t½ ~4.5h.
    public static let scopolamine = PharmacokineticProfile(
        substanceId: "scopolamine",
        name: LocalizedString(en: "Scopolamine", fr: "Scopolamine"),
        therapeuticClass: .anticholinergic,
        onsetMinutes: 30,
        tmaxMinutes: 60,
        halfLifeMinutes: 270,
        expectedDeltaHRange: -0.6...0.0,
        mechanism: .sympathomimetic, // removes vagal brake → sympathetic dominance
        scheduled: false,
        bindingEntropyKcal: 2.8  // Tropane ester + epoxytropane, similar to atropine
    )

    /// Atropine. Muscarinic antagonist.
    /// Blocks vagal influence → HR increases, HRV collapses.
    /// Tmax ~1h oral, t½ ~4h.
    public static let atropine = PharmacokineticProfile(
        substanceId: "atropine",
        name: LocalizedString(en: "Atropine", fr: "Atropine"),
        therapeuticClass: .anticholinergic,
        onsetMinutes: 15,
        tmaxMinutes: 60,
        halfLifeMinutes: 240,
        expectedDeltaHRange: -1.2...(-0.4),
        mechanism: .sympathomimetic, // removes vagal brake
        scheduled: false,
        bindingEntropyKcal: 3.2  // Ester linkage + flexible chain
    )
}

// MARK: - Known Profiles: NSAIDs & Corticosteroids

extension PharmacokineticProfile {

    /// Ibuprofen (Advil/Motrin). COX-1/2 inhibitor.
    /// Minimal direct autonomic effect. Tmax ~1-2h, t½ ~2h.
    public static let ibuprofen = PharmacokineticProfile(
        substanceId: "ibuprofen",
        name: LocalizedString(en: "Ibuprofen", fr: "Ibuprofène"),
        therapeuticClass: .nsaid,
        onsetMinutes: 30,
        tmaxMinutes: 90,
        halfLifeMinutes: 120,
        expectedDeltaHRange: -0.2...0.2,
        mechanism: .unknown,
        scheduled: false,
        bindingEntropyKcal: 1.6  // Propionic acid + isobutyl phenyl, 3 rotatable bonds
    )

    /// Prednisone. Corticosteroid.
    /// Mild sympathomimetic at higher doses (cortisol surge).
    /// Tmax ~1-2h, t½ ~3.5h (but biologic t½ ~18-36h).
    public static let prednisone = PharmacokineticProfile(
        substanceId: "prednisone",
        name: LocalizedString(en: "Prednisone", fr: "Prednisone"),
        therapeuticClass: .corticosteroid,
        onsetMinutes: 60,
        tmaxMinutes: 120,
        halfLifeMinutes: 210,
        expectedDeltaHRange: -0.5...0.0,
        mechanism: .sympathomimetic,
        scheduled: false,
        bindingEntropyKcal: 1.2  // Rigid steroid skeleton, 2 rotatable side chain bonds
    )

    /// Dexamethasone. Potent corticosteroid.
    /// Tmax ~1-2h, t½ ~36-54h.
    public static let dexamethasone = PharmacokineticProfile(
        substanceId: "dexamethasone",
        name: LocalizedString(en: "Dexamethasone", fr: "Dexaméthasone"),
        therapeuticClass: .corticosteroid,
        onsetMinutes: 60,
        tmaxMinutes: 120,
        halfLifeMinutes: 2700,
        expectedDeltaHRange: -0.5...0.0,
        mechanism: .sympathomimetic,
        scheduled: false,
        bindingEntropyKcal: 1.5  // Rigid steroid + fluorine, 3 rotatable bonds on side chain
    )
}

// MARK: - Known Profiles: GI & Endocrine

extension PharmacokineticProfile {

    /// Metoclopramide (Reglan). D2 antagonist / 5-HT4 agonist.
    /// Prokinetic. Tmax ~1-2h, t½ ~5-6h.
    public static let metoclopramide = PharmacokineticProfile(
        substanceId: "metoclopramide",
        name: LocalizedString(en: "Metoclopramide", fr: "Métoclopramide"),
        therapeuticClass: .gastrointestinal,
        onsetMinutes: 30,
        tmaxMinutes: 90,
        halfLifeMinutes: 330,
        expectedDeltaHRange: -0.2...0.2,
        mechanism: .unknown,
        scheduled: false,
        bindingEntropyKcal: 2.5  // Benzamide + diethylaminoethyl, 4 rotatable bonds
    )

    /// Levothyroxine (Synthroid). Thyroid hormone replacement.
    /// Sympathomimetic when supratherapeutic. Tmax ~2-4h, t½ ~7 days.
    public static let levothyroxine = PharmacokineticProfile(
        substanceId: "levothyroxine",
        name: LocalizedString(en: "Levothyroxine", fr: "Lévothyroxine"),
        therapeuticClass: .endocrine,
        onsetMinutes: 120,
        tmaxMinutes: 180,
        halfLifeMinutes: 10080,
        expectedDeltaHRange: -0.3...0.1,
        mechanism: .sympathomimetic,
        scheduled: false,
        bindingEntropyKcal: 2.4  // Amino acid + diiodophenoxy ether, 4 rotatable bonds
    )

    /// Insulin (rapid-acting, e.g., lispro). Endocrine.
    /// Hypoglycemia triggers sympathetic activation.
    /// Tmax ~1h subcutaneous, duration ~3-5h.
    public static let insulinRapid = PharmacokineticProfile(
        substanceId: "insulin-rapid",
        name: LocalizedString(en: "Insulin (Rapid)", fr: "Insuline (rapide)"),
        therapeuticClass: .endocrine,
        onsetMinutes: 15,
        tmaxMinutes: 60,
        halfLifeMinutes: 60,
        expectedDeltaHRange: -0.6...0.2,
        mechanism: .mixed,
        scheduled: false
    )
}

// MARK: - Known Profiles: Muscle Relaxants & Other

extension PharmacokineticProfile {

    /// Cyclobenzaprine (Flexeril). Tricyclic muscle relaxant.
    /// Structurally similar to amitriptyline. Anticholinergic.
    /// Tmax ~3-8h, t½ ~18h.
    public static let cyclobenzaprine = PharmacokineticProfile(
        substanceId: "cyclobenzaprine",
        name: LocalizedString(en: "Cyclobenzaprine", fr: "Cyclobenzaprine"),
        therapeuticClass: .other,
        onsetMinutes: 60,
        tmaxMinutes: 330,
        halfLifeMinutes: 1080,
        expectedDeltaHRange: -0.4...0.1,
        mechanism: .mixed,
        scheduled: false,
        bindingEntropyKcal: 1.5  // TCA-like tricyclic + dimethylaminopropyl, 2 rotatable bonds
    )

    /// Baclofen. GABA-B agonist. Muscle relaxant.
    /// Tmax ~2-3h, t½ ~3-4h.
    public static let baclofen = PharmacokineticProfile(
        substanceId: "baclofen",
        name: LocalizedString(en: "Baclofen", fr: "Baclofène"),
        therapeuticClass: .other,
        onsetMinutes: 30,
        tmaxMinutes: 150,
        halfLifeMinutes: 210,
        expectedDeltaHRange: 0.0...0.4,
        mechanism: .parasympathomimetic,
        scheduled: false,
        bindingEntropyKcal: 1.2  // Chlorophenyl GABA analog, 2 rotatable bonds
    )

    /// Tizanidine (Zanaflex). α2-adrenergic agonist. Muscle relaxant.
    /// Reduces sympathetic tone. Tmax ~1h, t½ ~2.5h.
    public static let tizanidine = PharmacokineticProfile(
        substanceId: "tizanidine",
        name: LocalizedString(en: "Tizanidine", fr: "Tizanidine"),
        therapeuticClass: .other,
        onsetMinutes: 30,
        tmaxMinutes: 60,
        halfLifeMinutes: 150,
        expectedDeltaHRange: 0.2...0.8,
        mechanism: .parasympathomimetic,
        scheduled: false,
        bindingEntropyKcal: 0.7  // Rigid benzothiadiazine, 1 rotatable bond
    )
}

// MARK: - Profile Registry

extension PharmacokineticProfile {

    /// All built-in profiles for lookup.
    public static let knownProfiles: [PharmacokineticProfile] = [
        // Stimulants & ADHD
        .amphetamine, .lisdexamfetamine, .methylphenidate, .dextroamphetamine,
        .methamphetamine, .modafinil, .armodafinil, .atomoxetine,
        // Xanthines
        .caffeine, .theophylline,
        // Beta-blockers & Cardiovascular
        .propranolol, .metoprolol, .atenolol, .bisoprolol, .carvedilol,
        .clonidine, .guanfacine, .digoxin, .ivabradine,
        // Antidepressants
        .sertraline, .fluoxetine, .escitalopram, .paroxetine,
        .venlafaxine, .duloxetine, .bupropion,
        .mirtazapine, .trazodone, .amitriptyline, .nortriptyline,
        .phenelzine, .tranylcypromine,
        // Antipsychotics
        .quetiapine, .olanzapine, .risperidone, .aripiprazole,
        .haloperidol, .chlorpromazine, .clozapine,
        // Anxiolytics & Sedatives
        .alprazolam, .diazepam, .lorazepam, .clonazepam,
        .buspirone, .hydroxyzine, .zolpidem, .suvorexant,
        // Opioids
        .morphine, .oxycodone, .hydrocodone, .fentanyl,
        .methadone, .buprenorphine, .tramadol, .naltrexone,
        // Anticonvulsants / Mood Stabilizers
        .gabapentin, .pregabalin, .lamotrigine, .valproate,
        .lithium, .carbamazepine, .topiramate,
        // Psychoactive
        .ethanol, .nicotine, .thc, .dronabinol, .cocaine,
        .mdma, .psilocybin, .lsd, .ketamine, .ghb,
        // Anticholinergics & Antihistamines
        .diphenhydramine, .promethazine, .scopolamine, .atropine,
        // NSAIDs & Corticosteroids
        .ibuprofen, .prednisone, .dexamethasone,
        // GI & Endocrine
        .metoclopramide, .levothyroxine, .insulinRapid,
        // Muscle Relaxants & Other
        .cyclobenzaprine, .baclofen, .tizanidine,
    ]

    /// Look up a profile by substance ID (case-insensitive).
    public static func profile(for substanceId: String) -> PharmacokineticProfile? {
        knownProfiles.first { $0.substanceId == substanceId.lowercased() }
    }

    /// Look up profiles by therapeutic class.
    public static func profiles(for therapeuticClass: TherapeuticClass) -> [PharmacokineticProfile] {
        knownProfiles.filter { $0.therapeuticClass == therapeuticClass }
    }

    /// Look up profiles by mechanism.
    public static func profiles(for mechanism: AutonomicMechanism) -> [PharmacokineticProfile] {
        knownProfiles.filter { $0.mechanism == mechanism }
    }

    /// All FDA-approved profiles.
    public static var fdaApprovedProfiles: [PharmacokineticProfile] {
        knownProfiles.filter(\.fdaApproved)
    }

    /// All scheduled (controlled) substance profiles.
    public static var scheduledProfiles: [PharmacokineticProfile] {
        knownProfiles.filter(\.scheduled)
    }

    /// Profiles with characterized binding entropy (for FlexAID∆S cross-domain validation).
    public static var profilesWithBindingEntropy: [PharmacokineticProfile] {
        knownProfiles.filter { $0.bindingEntropyKcal != nil }
    }
}
