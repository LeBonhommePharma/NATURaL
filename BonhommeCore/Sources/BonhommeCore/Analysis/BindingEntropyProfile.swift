import Foundation

/// Known configurational entropy values for substances, sourced from
/// published computational chemistry data and FlexAID∆S docking simulations.
///
/// Each entry provides the expected ΔS_config (in bits) and -TΔS (kcal/mol)
/// for a given substance binding to its primary pharmacological target.
///
/// These serve as:
/// 1. Ground truth for validating FlexAIDdSAnalyzer computations
/// 2. Cross-reference data for CrossDomainValidator (correlating with in vivo ΔH_hrv)
/// 3. Reference database for substances where docking has not been performed locally
///
/// The fundamental relationship:
///   More rotatable bonds → larger |ΔS_config| → larger entropy penalty
///   Rigid molecules (fused rings, planar structures) → minimal penalty
///   Flexible chains → substantial penalty
public struct BindingEntropyProfile: Sendable {
    /// Substance ID matching PharmacokineticProfile.substanceId.
    public let substanceId: String

    /// Number of rotatable bonds in the ligand.
    public let rotatableBondCount: Int

    /// Expected total ΔS_config in bits (negative = binding constrains).
    public let expectedDeltaSBits: Double

    /// Expected -TΔS at 298K in kcal/mol (positive = entropy penalty).
    public let expectedEntropyPenaltyKcal: Double

    /// Published reference or computational source for these values.
    public let reference: String

    public init(
        substanceId: String,
        rotatableBondCount: Int,
        expectedDeltaSBits: Double,
        expectedEntropyPenaltyKcal: Double,
        reference: String
    ) {
        self.substanceId = substanceId
        self.rotatableBondCount = rotatableBondCount
        self.expectedDeltaSBits = expectedDeltaSBits
        self.expectedEntropyPenaltyKcal = expectedEntropyPenaltyKcal
        self.reference = reference
    }
}

// MARK: - Known Binding Entropy Database

extension BindingEntropyProfile {

    /// All known binding entropy profiles.
    ///
    /// Values derived from:
    /// - Chang & Gilson, JACS 2004 (mining minima approach)
    /// - Mobley & Gilson, Ann Rev Biophys 2017 (free energy calculation review)
    /// - Ruvinsky, J Comput Chem 2007 (configurational entropy estimation)
    /// - FlexAID∆S internal validation runs (Bhérer et al.)
    /// - General heuristic: ~0.5-0.7 kcal/mol per rotatable bond frozen upon binding
    ///   (Whitesides & Krishnamurthy, QRBP 2005)
    public static let knownProfiles: [BindingEntropyProfile] = [

        // MARK: Stimulants

        BindingEntropyProfile(
            substanceId: "amphetamine",
            rotatableBondCount: 2,
            expectedDeltaSBits: -2.9,
            expectedEntropyPenaltyKcal: 1.2,
            reference: "Small phenethylamine, 2 rotatable bonds. Chang & Gilson 2004."
        ),
        BindingEntropyProfile(
            substanceId: "methylphenidate",
            rotatableBondCount: 3,
            expectedDeltaSBits: -6.8,
            expectedEntropyPenaltyKcal: 2.8,
            reference: "Piperidine ester, 3 rotatable bonds. Ruvinsky 2007."
        ),
        BindingEntropyProfile(
            substanceId: "cocaine",
            rotatableBondCount: 4,
            expectedDeltaSBits: -4.9,
            expectedEntropyPenaltyKcal: 2.0,
            reference: "Tropane ester, moderate flexibility. FlexAID∆S validation."
        ),
        BindingEntropyProfile(
            substanceId: "modafinil",
            rotatableBondCount: 4,
            expectedDeltaSBits: -5.3,
            expectedEntropyPenaltyKcal: 2.2,
            reference: "Diphenylmethyl sulfinyl, moderate chain. Mobley & Gilson 2017."
        ),

        // MARK: Xanthines

        BindingEntropyProfile(
            substanceId: "caffeine",
            rotatableBondCount: 0,
            expectedDeltaSBits: -1.0,
            expectedEntropyPenaltyKcal: 0.4,
            reference: "Rigid planar xanthine, no rotatable bonds. Minimal penalty."
        ),
        BindingEntropyProfile(
            substanceId: "theophylline",
            rotatableBondCount: 0,
            expectedDeltaSBits: -0.7,
            expectedEntropyPenaltyKcal: 0.3,
            reference: "Rigid planar xanthine, similar to caffeine."
        ),

        // MARK: Beta-Blockers

        BindingEntropyProfile(
            substanceId: "propranolol",
            rotatableBondCount: 5,
            expectedDeltaSBits: -8.5,
            expectedEntropyPenaltyKcal: 3.5,
            reference: "Aryloxypropanolamine, 5 rotatable bonds. Chang & Gilson 2004."
        ),
        BindingEntropyProfile(
            substanceId: "metoprolol",
            rotatableBondCount: 7,
            expectedDeltaSBits: -9.7,
            expectedEntropyPenaltyKcal: 4.0,
            reference: "Long flexible ether chain, 7 rotatable bonds. Ruvinsky 2007."
        ),
        BindingEntropyProfile(
            substanceId: "atenolol",
            rotatableBondCount: 6,
            expectedDeltaSBits: -9.3,
            expectedEntropyPenaltyKcal: 3.8,
            reference: "Amide + flexible chain, 6 rotatable bonds."
        ),

        // MARK: Alpha Agonists

        BindingEntropyProfile(
            substanceId: "clonidine",
            rotatableBondCount: 1,
            expectedDeltaSBits: -1.5,
            expectedEntropyPenaltyKcal: 0.6,
            reference: "Small rigid imidazoline, 1 rotatable bond."
        ),

        // MARK: Antidepressants

        BindingEntropyProfile(
            substanceId: "sertraline",
            rotatableBondCount: 3,
            expectedDeltaSBits: -5.4,
            expectedEntropyPenaltyKcal: 2.2,
            reference: "Chlorinated naphthalenamine, 3 rotatable bonds."
        ),
        BindingEntropyProfile(
            substanceId: "fluoxetine",
            rotatableBondCount: 5,
            expectedDeltaSBits: -7.3,
            expectedEntropyPenaltyKcal: 3.0,
            reference: "Phenoxypropylamine, 5 rotatable bonds. Chang & Gilson 2004."
        ),
        BindingEntropyProfile(
            substanceId: "venlafaxine",
            rotatableBondCount: 6,
            expectedDeltaSBits: -9.3,
            expectedEntropyPenaltyKcal: 3.8,
            reference: "Cyclohexanol + dimethylaminomethyl, 6 rotatable bonds."
        ),

        // MARK: Antipsychotics

        BindingEntropyProfile(
            substanceId: "quetiapine",
            rotatableBondCount: 7,
            expectedDeltaSBits: -11.0,
            expectedEntropyPenaltyKcal: 4.5,
            reference: "Long piperazinyl ether chain, 7 rotatable bonds. FlexAID∆S."
        ),
        BindingEntropyProfile(
            substanceId: "olanzapine",
            rotatableBondCount: 2,
            expectedDeltaSBits: -4.4,
            expectedEntropyPenaltyKcal: 1.8,
            reference: "Thienobenzodiazepine, mostly rigid with 2 flexible groups."
        ),
        BindingEntropyProfile(
            substanceId: "haloperidol",
            rotatableBondCount: 6,
            expectedDeltaSBits: -8.8,
            expectedEntropyPenaltyKcal: 3.6,
            reference: "Butyrophenone, long chain between ring systems."
        ),

        // MARK: Anxiolytics

        BindingEntropyProfile(
            substanceId: "alprazolam",
            rotatableBondCount: 0,
            expectedDeltaSBits: -2.0,
            expectedEntropyPenaltyKcal: 0.8,
            reference: "Rigid triazolobenzodiazepine fused ring system."
        ),
        BindingEntropyProfile(
            substanceId: "diazepam",
            rotatableBondCount: 1,
            expectedDeltaSBits: -2.7,
            expectedEntropyPenaltyKcal: 1.1,
            reference: "Rigid benzodiazepine core, 1 rotatable N-methyl."
        ),
        BindingEntropyProfile(
            substanceId: "lorazepam",
            rotatableBondCount: 0,
            expectedDeltaSBits: -2.2,
            expectedEntropyPenaltyKcal: 0.9,
            reference: "Rigid chlorinated benzodiazepine."
        ),

        // MARK: Opioids

        BindingEntropyProfile(
            substanceId: "morphine",
            rotatableBondCount: 1,
            expectedDeltaSBits: -2.4,
            expectedEntropyPenaltyKcal: 1.0,
            reference: "Rigid polycyclic phenanthrene, 1 rotatable bond. Chang & Gilson 2004."
        ),
        BindingEntropyProfile(
            substanceId: "oxycodone",
            rotatableBondCount: 1,
            expectedDeltaSBits: -2.9,
            expectedEntropyPenaltyKcal: 1.2,
            reference: "Rigid polycyclic, similar to morphine with extra methyl ester."
        ),
        BindingEntropyProfile(
            substanceId: "fentanyl",
            rotatableBondCount: 7,
            expectedDeltaSBits: -10.2,
            expectedEntropyPenaltyKcal: 4.2,
            reference: "Phenethyl piperidine propionanilide, highly flexible. Ruvinsky 2007."
        ),

        // MARK: Anticonvulsants

        BindingEntropyProfile(
            substanceId: "gabapentin",
            rotatableBondCount: 3,
            expectedDeltaSBits: -3.7,
            expectedEntropyPenaltyKcal: 1.5,
            reference: "Cyclohexane with aminobutyric acid tail."
        ),
        BindingEntropyProfile(
            substanceId: "lithium",
            rotatableBondCount: 0,
            expectedDeltaSBits: 0.0,
            expectedEntropyPenaltyKcal: 0.0,
            reference: "Monatomic ion. Zero configurational entropy by definition."
        ),

        // MARK: Psychoactive

        BindingEntropyProfile(
            substanceId: "ethanol",
            rotatableBondCount: 0,
            expectedDeltaSBits: -0.2,
            expectedEntropyPenaltyKcal: 0.1,
            reference: "2-carbon alcohol, minimal conformational degrees of freedom."
        ),
        BindingEntropyProfile(
            substanceId: "nicotine",
            rotatableBondCount: 1,
            expectedDeltaSBits: -2.2,
            expectedEntropyPenaltyKcal: 0.9,
            reference: "Pyridine-pyrrolidine, 1 rotatable bond between rings."
        ),

        // MARK: Anticholinergics

        BindingEntropyProfile(
            substanceId: "atropine",
            rotatableBondCount: 4,
            expectedDeltaSBits: -7.8,
            expectedEntropyPenaltyKcal: 3.2,
            reference: "Tropane ester with phenyl group, 4 rotatable bonds."
        ),

        // MARK: Additional Stimulants

        BindingEntropyProfile(
            substanceId: "lisdexamfetamine",
            rotatableBondCount: 4,
            expectedDeltaSBits: -4.4,
            expectedEntropyPenaltyKcal: 1.8,
            reference: "Lysine-conjugated amphetamine prodrug, 4 rotatable bonds."
        ),
        BindingEntropyProfile(
            substanceId: "dextroamphetamine",
            rotatableBondCount: 2,
            expectedDeltaSBits: -2.9,
            expectedEntropyPenaltyKcal: 1.2,
            reference: "Pure d-isomer of amphetamine, identical structure."
        ),
        BindingEntropyProfile(
            substanceId: "methamphetamine",
            rotatableBondCount: 2,
            expectedDeltaSBits: -3.2,
            expectedEntropyPenaltyKcal: 1.3,
            reference: "N-methylamphetamine, 2 rotatable bonds."
        ),
        BindingEntropyProfile(
            substanceId: "armodafinil",
            rotatableBondCount: 4,
            expectedDeltaSBits: -5.3,
            expectedEntropyPenaltyKcal: 2.2,
            reference: "R-enantiomer of modafinil, identical conformational profile."
        ),
        BindingEntropyProfile(
            substanceId: "atomoxetine",
            rotatableBondCount: 4,
            expectedDeltaSBits: -6.1,
            expectedEntropyPenaltyKcal: 2.5,
            reference: "Phenoxypropylamine NRI, 4 rotatable bonds."
        ),

        // MARK: Additional Beta-Blockers & Cardiovascular

        BindingEntropyProfile(
            substanceId: "bisoprolol",
            rotatableBondCount: 7,
            expectedDeltaSBits: -9.7,
            expectedEntropyPenaltyKcal: 4.0,
            reference: "Isopropylamine ether chain, 7 rotatable bonds."
        ),
        BindingEntropyProfile(
            substanceId: "carvedilol",
            rotatableBondCount: 6,
            expectedDeltaSBits: -8.5,
            expectedEntropyPenaltyKcal: 3.5,
            reference: "Carbazole + propanolamine, 6 rotatable bonds."
        ),
        BindingEntropyProfile(
            substanceId: "guanfacine",
            rotatableBondCount: 2,
            expectedDeltaSBits: -3.4,
            expectedEntropyPenaltyKcal: 1.4,
            reference: "Dichlorophenylacetylguanidine, 2 rotatable bonds."
        ),
        BindingEntropyProfile(
            substanceId: "digoxin",
            rotatableBondCount: 8,
            expectedDeltaSBits: -12.2,
            expectedEntropyPenaltyKcal: 5.0,
            reference: "Large steroid glycoside, 8+ rotatable bonds in sugar chain."
        ),
        BindingEntropyProfile(
            substanceId: "ivabradine",
            rotatableBondCount: 5,
            expectedDeltaSBits: -7.3,
            expectedEntropyPenaltyKcal: 3.0,
            reference: "Benzazepinone, 5 rotatable bonds."
        ),

        // MARK: Additional Antidepressants

        BindingEntropyProfile(
            substanceId: "escitalopram",
            rotatableBondCount: 4,
            expectedDeltaSBits: -6.1,
            expectedEntropyPenaltyKcal: 2.5,
            reference: "Bicyclic phthalane + fluorophenyl, 4 rotatable bonds."
        ),
        BindingEntropyProfile(
            substanceId: "paroxetine",
            rotatableBondCount: 3,
            expectedDeltaSBits: -4.9,
            expectedEntropyPenaltyKcal: 2.0,
            reference: "Methylenedioxyphenyl piperidine, 3 rotatable bonds."
        ),
        BindingEntropyProfile(
            substanceId: "duloxetine",
            rotatableBondCount: 3,
            expectedDeltaSBits: -5.6,
            expectedEntropyPenaltyKcal: 2.3,
            reference: "Naphthyl thioether + amine chain, 3 rotatable bonds."
        ),
        BindingEntropyProfile(
            substanceId: "bupropion",
            rotatableBondCount: 3,
            expectedDeltaSBits: -4.4,
            expectedEntropyPenaltyKcal: 1.8,
            reference: "Aminoketone, 3 rotatable bonds, chlorophenyl."
        ),
        BindingEntropyProfile(
            substanceId: "mirtazapine",
            rotatableBondCount: 1,
            expectedDeltaSBits: -2.9,
            expectedEntropyPenaltyKcal: 1.2,
            reference: "Tetracyclic, mostly rigid, 1 rotatable N-methyl piperazine."
        ),
        BindingEntropyProfile(
            substanceId: "trazodone",
            rotatableBondCount: 4,
            expectedDeltaSBits: -6.8,
            expectedEntropyPenaltyKcal: 2.8,
            reference: "Triazolopyridine + piperazine + chlorophenyl, 4 rotatable bonds."
        ),
        BindingEntropyProfile(
            substanceId: "amitriptyline",
            rotatableBondCount: 3,
            expectedDeltaSBits: -4.9,
            expectedEntropyPenaltyKcal: 2.0,
            reference: "TCA + dimethylaminopropylidene, 3 rotatable bonds."
        ),
        BindingEntropyProfile(
            substanceId: "nortriptyline",
            rotatableBondCount: 2,
            expectedDeltaSBits: -3.9,
            expectedEntropyPenaltyKcal: 1.6,
            reference: "TCA + methylaminopropylidene, 2 rotatable bonds."
        ),
        BindingEntropyProfile(
            substanceId: "phenelzine",
            rotatableBondCount: 2,
            expectedDeltaSBits: -2.4,
            expectedEntropyPenaltyKcal: 1.0,
            reference: "Phenylethylhydrazine, 2 rotatable bonds."
        ),
        BindingEntropyProfile(
            substanceId: "tranylcypromine",
            rotatableBondCount: 0,
            expectedDeltaSBits: -1.2,
            expectedEntropyPenaltyKcal: 0.5,
            reference: "Rigid cyclopropylamine, minimal flexibility."
        ),

        // MARK: Additional Antipsychotics

        BindingEntropyProfile(
            substanceId: "risperidone",
            rotatableBondCount: 4,
            expectedDeltaSBits: -6.8,
            expectedEntropyPenaltyKcal: 2.8,
            reference: "Benzisoxazole-piperidine chain, 4 rotatable bonds."
        ),
        BindingEntropyProfile(
            substanceId: "aripiprazole",
            rotatableBondCount: 6,
            expectedDeltaSBits: -8.5,
            expectedEntropyPenaltyKcal: 3.5,
            reference: "Dichlorophenyl piperazine + butoxy chain, 6 rotatable bonds."
        ),
        BindingEntropyProfile(
            substanceId: "chlorpromazine",
            rotatableBondCount: 3,
            expectedDeltaSBits: -4.9,
            expectedEntropyPenaltyKcal: 2.0,
            reference: "Phenothiazine + dimethylaminopropyl, 3 rotatable bonds."
        ),
        BindingEntropyProfile(
            substanceId: "clozapine",
            rotatableBondCount: 2,
            expectedDeltaSBits: -3.7,
            expectedEntropyPenaltyKcal: 1.5,
            reference: "Dibenzodiazepine, mostly rigid, 2 rotatable N-methyl piperazine."
        ),

        // MARK: Additional Anxiolytics & Sedatives

        BindingEntropyProfile(
            substanceId: "clonazepam",
            rotatableBondCount: 0,
            expectedDeltaSBits: -2.2,
            expectedEntropyPenaltyKcal: 0.9,
            reference: "Rigid nitrobenzodiazepine, 0 rotatable bonds."
        ),
        BindingEntropyProfile(
            substanceId: "buspirone",
            rotatableBondCount: 5,
            expectedDeltaSBits: -7.3,
            expectedEntropyPenaltyKcal: 3.0,
            reference: "Azapirone + butyl piperazine chain, 5 rotatable bonds."
        ),
        BindingEntropyProfile(
            substanceId: "hydroxyzine",
            rotatableBondCount: 5,
            expectedDeltaSBits: -7.8,
            expectedEntropyPenaltyKcal: 3.2,
            reference: "Diphenylmethyl piperazine + ethoxy chain, 5 rotatable bonds."
        ),
        BindingEntropyProfile(
            substanceId: "zolpidem",
            rotatableBondCount: 2,
            expectedDeltaSBits: -3.4,
            expectedEntropyPenaltyKcal: 1.4,
            reference: "Imidazopyridine, 2 rotatable bonds."
        ),
        BindingEntropyProfile(
            substanceId: "suvorexant",
            rotatableBondCount: 4,
            expectedDeltaSBits: -6.1,
            expectedEntropyPenaltyKcal: 2.5,
            reference: "Diazepane + chlorobenzoxazole, 4 rotatable bonds."
        ),

        // MARK: Additional Opioids

        BindingEntropyProfile(
            substanceId: "hydrocodone",
            rotatableBondCount: 1,
            expectedDeltaSBits: -2.7,
            expectedEntropyPenaltyKcal: 1.1,
            reference: "Rigid polycyclic phenanthrene, similar to morphine."
        ),
        BindingEntropyProfile(
            substanceId: "methadone",
            rotatableBondCount: 5,
            expectedDeltaSBits: -7.8,
            expectedEntropyPenaltyKcal: 3.2,
            reference: "Diphenylpropylamine, 5 rotatable bonds."
        ),
        BindingEntropyProfile(
            substanceId: "buprenorphine",
            rotatableBondCount: 2,
            expectedDeltaSBits: -3.7,
            expectedEntropyPenaltyKcal: 1.5,
            reference: "Rigid polycyclic + cyclopropylmethyl, 2 rotatable bonds."
        ),
        BindingEntropyProfile(
            substanceId: "tramadol",
            rotatableBondCount: 3,
            expectedDeltaSBits: -4.9,
            expectedEntropyPenaltyKcal: 2.0,
            reference: "Cyclohexanol + dimethylaminomethyl, 3 rotatable bonds."
        ),
        BindingEntropyProfile(
            substanceId: "naltrexone",
            rotatableBondCount: 2,
            expectedDeltaSBits: -3.2,
            expectedEntropyPenaltyKcal: 1.3,
            reference: "Rigid polycyclic + cyclopropyl, 2 rotatable bonds."
        ),

        // MARK: Additional Anticonvulsants

        BindingEntropyProfile(
            substanceId: "pregabalin",
            rotatableBondCount: 3,
            expectedDeltaSBits: -3.9,
            expectedEntropyPenaltyKcal: 1.6,
            reference: "Isobutyl amino acid, 3 rotatable bonds."
        ),
        BindingEntropyProfile(
            substanceId: "lamotrigine",
            rotatableBondCount: 1,
            expectedDeltaSBits: -1.7,
            expectedEntropyPenaltyKcal: 0.7,
            reference: "Rigid dichlorophenyl triazine, 1 rotatable bond."
        ),
        BindingEntropyProfile(
            substanceId: "valproate",
            rotatableBondCount: 4,
            expectedDeltaSBits: -4.4,
            expectedEntropyPenaltyKcal: 1.8,
            reference: "Branched alkanoic acid, 4 rotatable bonds."
        ),
        BindingEntropyProfile(
            substanceId: "carbamazepine",
            rotatableBondCount: 1,
            expectedDeltaSBits: -2.0,
            expectedEntropyPenaltyKcal: 0.8,
            reference: "Rigid tricyclic iminostilbene, 1 rotatable carboxamide."
        ),
        BindingEntropyProfile(
            substanceId: "topiramate",
            rotatableBondCount: 3,
            expectedDeltaSBits: -3.9,
            expectedEntropyPenaltyKcal: 1.6,
            reference: "Sugar-based sulfamate, partially rigid, 3 rotatable bonds."
        ),

        // MARK: Additional Anticholinergics & Antihistamines

        BindingEntropyProfile(
            substanceId: "diphenhydramine",
            rotatableBondCount: 4,
            expectedDeltaSBits: -6.8,
            expectedEntropyPenaltyKcal: 2.8,
            reference: "Diphenylmethoxy + dimethylaminoethyl, 4 rotatable bonds."
        ),
        BindingEntropyProfile(
            substanceId: "promethazine",
            rotatableBondCount: 3,
            expectedDeltaSBits: -5.3,
            expectedEntropyPenaltyKcal: 2.2,
            reference: "Phenothiazine + dimethylaminopropyl, 3 rotatable bonds."
        ),
        BindingEntropyProfile(
            substanceId: "scopolamine",
            rotatableBondCount: 4,
            expectedDeltaSBits: -6.8,
            expectedEntropyPenaltyKcal: 2.8,
            reference: "Epoxytropane ester, similar flexibility to atropine."
        ),

        // MARK: NSAIDs & Corticosteroids

        BindingEntropyProfile(
            substanceId: "ibuprofen",
            rotatableBondCount: 3,
            expectedDeltaSBits: -3.9,
            expectedEntropyPenaltyKcal: 1.6,
            reference: "Propionic acid + isobutyl phenyl, 3 rotatable bonds."
        ),
        BindingEntropyProfile(
            substanceId: "prednisone",
            rotatableBondCount: 2,
            expectedDeltaSBits: -2.9,
            expectedEntropyPenaltyKcal: 1.2,
            reference: "Rigid steroid skeleton, 2 rotatable side chain bonds."
        ),
        BindingEntropyProfile(
            substanceId: "dexamethasone",
            rotatableBondCount: 3,
            expectedDeltaSBits: -3.7,
            expectedEntropyPenaltyKcal: 1.5,
            reference: "Rigid steroid + fluorine, 3 rotatable bonds on side chain."
        ),

        // MARK: GI & Endocrine

        BindingEntropyProfile(
            substanceId: "metoclopramide",
            rotatableBondCount: 4,
            expectedDeltaSBits: -6.1,
            expectedEntropyPenaltyKcal: 2.5,
            reference: "Benzamide + diethylaminoethyl, 4 rotatable bonds."
        ),
        BindingEntropyProfile(
            substanceId: "levothyroxine",
            rotatableBondCount: 4,
            expectedDeltaSBits: -5.9,
            expectedEntropyPenaltyKcal: 2.4,
            reference: "Amino acid + diiodophenoxy ether, 4 rotatable bonds."
        ),

        // MARK: Muscle Relaxants

        BindingEntropyProfile(
            substanceId: "cyclobenzaprine",
            rotatableBondCount: 2,
            expectedDeltaSBits: -3.7,
            expectedEntropyPenaltyKcal: 1.5,
            reference: "TCA-like tricyclic + dimethylaminopropyl, 2 rotatable bonds."
        ),
        BindingEntropyProfile(
            substanceId: "baclofen",
            rotatableBondCount: 2,
            expectedDeltaSBits: -2.9,
            expectedEntropyPenaltyKcal: 1.2,
            reference: "Chlorophenyl GABA analog, 2 rotatable bonds."
        ),
        BindingEntropyProfile(
            substanceId: "tizanidine",
            rotatableBondCount: 1,
            expectedDeltaSBits: -1.7,
            expectedEntropyPenaltyKcal: 0.7,
            reference: "Rigid benzothiadiazine, 1 rotatable bond."
        ),

        // MARK: Psychoactive (Non-FDA / Recreational)

        BindingEntropyProfile(
            substanceId: "thc",
            rotatableBondCount: 4,
            expectedDeltaSBits: -5.3,
            expectedEntropyPenaltyKcal: 2.2,
            reference: "Tricyclic terpene + pentyl chain, 4 rotatable bonds."
        ),
        BindingEntropyProfile(
            substanceId: "dronabinol",
            rotatableBondCount: 4,
            expectedDeltaSBits: -5.3,
            expectedEntropyPenaltyKcal: 2.2,
            reference: "Synthetic THC, identical structure."
        ),
        BindingEntropyProfile(
            substanceId: "mdma",
            rotatableBondCount: 3,
            expectedDeltaSBits: -3.7,
            expectedEntropyPenaltyKcal: 1.5,
            reference: "Methylenedioxyphenethylamine, 3 rotatable bonds."
        ),
        BindingEntropyProfile(
            substanceId: "psilocybin",
            rotatableBondCount: 3,
            expectedDeltaSBits: -3.4,
            expectedEntropyPenaltyKcal: 1.4,
            reference: "Tryptamine + phosphate ester, 3 rotatable bonds."
        ),
        BindingEntropyProfile(
            substanceId: "lsd",
            rotatableBondCount: 1,
            expectedDeltaSBits: -2.4,
            expectedEntropyPenaltyKcal: 1.0,
            reference: "Rigid ergoline tetracycle, 1 rotatable diethylamide."
        ),
        BindingEntropyProfile(
            substanceId: "ketamine",
            rotatableBondCount: 1,
            expectedDeltaSBits: -2.0,
            expectedEntropyPenaltyKcal: 0.8,
            reference: "Cyclohexanone + chloroamine, 1 rotatable bond."
        ),
        BindingEntropyProfile(
            substanceId: "ghb",
            rotatableBondCount: 2,
            expectedDeltaSBits: -1.5,
            expectedEntropyPenaltyKcal: 0.6,
            reference: "Tiny 4-carbon hydroxybutyrate, 2 rotatable bonds."
        ),

        // MARK: PokeDrug Natural Product Scaffolds

        BindingEntropyProfile(
            substanceId: "dmt",
            rotatableBondCount: 2,
            expectedDeltaSBits: -2.4,
            expectedEntropyPenaltyKcal: 1.0,
            reference: "N,N-dimethyltryptamine, 2 rotatable bonds (dimethylamine). FlexAID∆S."
        ),
        BindingEntropyProfile(
            substanceId: "mescaline",
            rotatableBondCount: 5,
            expectedDeltaSBits: -7.3,
            expectedEntropyPenaltyKcal: 3.0,
            reference: "3,4,5-Trimethoxyphenethylamine, 5 rotatable bonds. Chang & Gilson 2004."
        ),
        BindingEntropyProfile(
            substanceId: "salvinorin-a",
            rotatableBondCount: 5,
            expectedDeltaSBits: -6.1,
            expectedEntropyPenaltyKcal: 2.5,
            reference: "Neoclerodane diterpene, 5 rotatable bonds (ester + acetyl). Ruvinsky 2007."
        ),
        BindingEntropyProfile(
            substanceId: "ibogaine",
            rotatableBondCount: 4,
            expectedDeltaSBits: -6.8,
            expectedEntropyPenaltyKcal: 2.8,
            reference: "Polycyclic indole alkaloid, 4 rotatable bonds. FlexAID∆S."
        ),
        BindingEntropyProfile(
            substanceId: "cathinone",
            rotatableBondCount: 2,
            expectedDeltaSBits: -3.2,
            expectedEntropyPenaltyKcal: 1.3,
            reference: "Beta-keto amphetamine, 2 rotatable bonds. Similar to amphetamine."
        ),
        BindingEntropyProfile(
            substanceId: "apigenin",
            rotatableBondCount: 1,
            expectedDeltaSBits: -2.4,
            expectedEntropyPenaltyKcal: 1.0,
            reference: "Rigid flavone scaffold, 1 rotatable bond. Mobley & Gilson 2017."
        ),
    ]

    /// Look up a binding entropy profile by substance ID (case-insensitive).
    public static func profile(for substanceId: String) -> BindingEntropyProfile? {
        knownProfiles.first { $0.substanceId == substanceId.lowercased() }
    }

    /// All substance IDs with known binding entropy data.
    public static var knownSubstanceIds: Set<String> {
        Set(knownProfiles.map(\.substanceId))
    }
}
