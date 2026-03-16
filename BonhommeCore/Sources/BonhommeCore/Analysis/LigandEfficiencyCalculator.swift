import Foundation

// MARK: - Molecular Descriptor

/// Molecular descriptor data for a substance (from PubChem).
///
/// Used to compute ligand efficiency metrics (LE, BEI, LipE) and
/// drug-likeness compliance (Lipinski Rule of 5, Veber rules).
public struct MolecularDescriptor: Sendable {
    public let substanceId: String
    public let molecularWeightDa: Double
    public let heavyAtomCount: Int
    public let cLogP: Double
    public let hBondDonors: Int
    public let hBondAcceptors: Int
    public let polarSurfaceArea: Double
    public let rotatableBondCount: Int

    public var molecularWeightKDa: Double { molecularWeightDa / 1000.0 }

    public init(substanceId: String, molecularWeightDa: Double, heavyAtomCount: Int,
                cLogP: Double, hBondDonors: Int, hBondAcceptors: Int,
                polarSurfaceArea: Double, rotatableBondCount: Int) {
        self.substanceId = substanceId
        self.molecularWeightDa = molecularWeightDa
        self.heavyAtomCount = heavyAtomCount
        self.cLogP = cLogP
        self.hBondDonors = hBondDonors
        self.hBondAcceptors = hBondAcceptors
        self.polarSurfaceArea = polarSurfaceArea
        self.rotatableBondCount = rotatableBondCount
    }
}

// MARK: - Drug-Likeness

/// Violations of Lipinski's Rule of 5 and Veber's rules.
public enum DrugLikenessViolation: String, Sendable, CaseIterable {
    case molecularWeightExceeds500
    case cLogPExceeds5
    case hBondDonorsExceed5
    case hBondAcceptorsExceed10
    case psaExceeds140
    case rotatableBondsExceed10
}

extension MolecularDescriptor {

    /// Lipinski Rule of 5 compliance (MW ≤ 500, cLogP ≤ 5, HBD ≤ 5, HBA ≤ 10).
    public var isLipinskiCompliant: Bool {
        molecularWeightDa <= 500 && cLogP <= 5.0 && hBondDonors <= 5 && hBondAcceptors <= 10
    }

    /// Veber rule compliance (PSA ≤ 140 Å², rotatable bonds ≤ 10).
    public var isVeberCompliant: Bool {
        polarSurfaceArea <= 140.0 && rotatableBondCount <= 10
    }

    /// All drug-likeness violations for this substance.
    public var drugLikenessViolations: [DrugLikenessViolation] {
        var violations: [DrugLikenessViolation] = []
        if molecularWeightDa > 500 { violations.append(.molecularWeightExceeds500) }
        if cLogP > 5.0 { violations.append(.cLogPExceeds5) }
        if hBondDonors > 5 { violations.append(.hBondDonorsExceed5) }
        if hBondAcceptors > 10 { violations.append(.hBondAcceptorsExceed10) }
        if polarSurfaceArea > 140.0 { violations.append(.psaExceeds140) }
        if rotatableBondCount > 10 { violations.append(.rotatableBondsExceed10) }
        return violations
    }
}

// MARK: - Ligand Efficiency Result

/// Result of ligand efficiency calculations for a substance-target pair.
public struct LigandEfficiencyResult: Sendable {
    /// Substance identifier.
    public let substanceId: String
    /// Target identifier.
    public let targetId: String
    /// Ligand Efficiency: LE = -ΔG / heavyAtomCount (kcal/mol per heavy atom).
    /// Values > 0.3 are generally considered good.
    public let le: Double?
    /// Binding Efficiency Index: BEI = pKi / MW(kDa).
    public let bei: Double?
    /// Lipophilic Ligand Efficiency: LipE = pKi - cLogP.
    /// Higher = better (potency not driven by lipophilicity).
    public let lipE: Double?
    /// pKi = 9 - log10(Ki_nM).
    public let pKi: Double?
    /// Bilingual summary.
    public let summary: LocalizedString

    public init(substanceId: String, targetId: String, le: Double?, bei: Double?,
                lipE: Double?, pKi: Double?, summary: LocalizedString) {
        self.substanceId = substanceId
        self.targetId = targetId
        self.le = le
        self.bei = bei
        self.lipE = lipE
        self.pKi = pKi
        self.summary = summary
    }
}

// MARK: - Calculator

/// Computes standard medicinal chemistry ligand efficiency metrics from
/// existing Ki affinity data and molecular descriptors.
///
/// Metrics:
/// - **LE** (Ligand Efficiency) = -ΔG / heavyAtomCount. Good drug leads have LE > 0.3.
/// - **BEI** (Binding Efficiency Index) = pKi / MW(kDa). Size-normalized potency.
/// - **LipE** (Lipophilic Ligand Efficiency) = pKi - cLogP. Potency not from lipophilicity.
///
/// All computed from ThermodynamicBindingProfile affinities + MolecularDescriptor data.
public struct LigandEfficiencyCalculator: Sendable {

    public init() {}

    /// Calculate ligand efficiency for a specific substance-target pair.
    public static func calculate(substanceId: String, targetId: String) -> LigandEfficiencyResult? {
        let id = substanceId.lowercased()
        guard let descriptor = MolecularDescriptor.descriptor(for: id) else { return nil }

        let profiles = ThermodynamicBindingProfile.profiles(for: id)
        guard let profile = profiles.first(where: { $0.targetId == targetId }) else { return nil }

        return buildResult(profile: profile, descriptor: descriptor)
    }

    /// Calculate ligand efficiency for all targets of a substance.
    public static func calculateAll(for substanceId: String) -> [LigandEfficiencyResult] {
        let id = substanceId.lowercased()
        guard let descriptor = MolecularDescriptor.descriptor(for: id) else { return [] }

        return ThermodynamicBindingProfile.profiles(for: id).compactMap {
            buildResult(profile: $0, descriptor: descriptor)
        }
    }

    /// Rank all substances by ligand efficiency (primary target), highest LE first.
    public static func rankByLE() -> [LigandEfficiencyResult] {
        var results: [LigandEfficiencyResult] = []
        for id in ThermodynamicBindingProfile.knownSubstanceIds {
            guard let descriptor = MolecularDescriptor.descriptor(for: id),
                  let profile = ThermodynamicBindingProfile.profile(for: id) else { continue }
            if let result = buildResult(profile: profile, descriptor: descriptor) {
                results.append(result)
            }
        }
        return results.sorted { ($0.le ?? 0) > ($1.le ?? 0) }
    }

    // MARK: - Private

    private static func buildResult(profile: ThermodynamicBindingProfile,
                                     descriptor: MolecularDescriptor) -> LigandEfficiencyResult? {
        guard let kiNM = profile.affinity.bestAffinityNM, kiNM > 0 else { return nil }

        let pKi = 9.0 - log10(kiNM)
        let deltaG = profile.affinity.computedDeltaGKcal

        let le = deltaG.map { -$0 / Double(descriptor.heavyAtomCount) }
        let bei = descriptor.molecularWeightKDa > 0 ? pKi / descriptor.molecularWeightKDa : nil
        let lipE = pKi - descriptor.cLogP

        let leText = le.map { String(format: "%.2f", $0) } ?? "N/A"
        let beiText = bei.map { String(format: "%.1f", $0) } ?? "N/A"
        let lipEText = String(format: "%.1f", lipE)

        return LigandEfficiencyResult(
            substanceId: descriptor.substanceId,
            targetId: profile.targetId,
            le: le,
            bei: bei,
            lipE: lipE,
            pKi: pKi,
            summary: LocalizedString(
                en: "\(descriptor.substanceId):\(profile.targetId) — LE=\(leText), BEI=\(beiText), LipE=\(lipEText) (pKi=\(String(format: "%.2f", pKi)))",
                fr: "\(descriptor.substanceId):\(profile.targetId) — LE=\(leText), BEI=\(beiText), LipE=\(lipEText) (pKi=\(String(format: "%.2f", pKi)))"
            )
        )
    }
}

// MARK: - Static Catalog

extension MolecularDescriptor {

    /// Look up descriptor for a substance.
    public static func descriptor(for substanceId: String) -> MolecularDescriptor? {
        knownDescriptors.first { $0.substanceId == substanceId.lowercased() }
    }

    /// Molecular descriptors for all PharmacokineticProfile substances (PubChem data).
    public static let knownDescriptors: [MolecularDescriptor] = [
        // ── Stimulants ──
        MolecularDescriptor(substanceId: "amphetamine", molecularWeightDa: 135.2, heavyAtomCount: 10, cLogP: 1.76, hBondDonors: 1, hBondAcceptors: 1, polarSurfaceArea: 26.0, rotatableBondCount: 2),
        MolecularDescriptor(substanceId: "lisdexamfetamine", molecularWeightDa: 263.4, heavyAtomCount: 19, cLogP: 0.58, hBondDonors: 3, hBondAcceptors: 4, polarSurfaceArea: 75.3, rotatableBondCount: 8),
        MolecularDescriptor(substanceId: "methylphenidate", molecularWeightDa: 233.3, heavyAtomCount: 17, cLogP: 2.15, hBondDonors: 1, hBondAcceptors: 3, polarSurfaceArea: 38.3, rotatableBondCount: 3),
        MolecularDescriptor(substanceId: "dextroamphetamine", molecularWeightDa: 135.2, heavyAtomCount: 10, cLogP: 1.76, hBondDonors: 1, hBondAcceptors: 1, polarSurfaceArea: 26.0, rotatableBondCount: 2),
        MolecularDescriptor(substanceId: "methamphetamine", molecularWeightDa: 149.2, heavyAtomCount: 11, cLogP: 2.07, hBondDonors: 1, hBondAcceptors: 1, polarSurfaceArea: 12.0, rotatableBondCount: 2),
        MolecularDescriptor(substanceId: "modafinil", molecularWeightDa: 273.4, heavyAtomCount: 19, cLogP: 0.69, hBondDonors: 1, hBondAcceptors: 3, polarSurfaceArea: 79.4, rotatableBondCount: 4),
        MolecularDescriptor(substanceId: "armodafinil", molecularWeightDa: 273.4, heavyAtomCount: 19, cLogP: 0.69, hBondDonors: 1, hBondAcceptors: 3, polarSurfaceArea: 79.4, rotatableBondCount: 4),
        MolecularDescriptor(substanceId: "atomoxetine", molecularWeightDa: 255.4, heavyAtomCount: 19, cLogP: 3.51, hBondDonors: 1, hBondAcceptors: 2, polarSurfaceArea: 21.3, rotatableBondCount: 5),
        MolecularDescriptor(substanceId: "caffeine", molecularWeightDa: 194.2, heavyAtomCount: 14, cLogP: -0.07, hBondDonors: 0, hBondAcceptors: 6, polarSurfaceArea: 58.4, rotatableBondCount: 0),
        MolecularDescriptor(substanceId: "theophylline", molecularWeightDa: 180.2, heavyAtomCount: 13, cLogP: -0.02, hBondDonors: 1, hBondAcceptors: 6, polarSurfaceArea: 69.3, rotatableBondCount: 0),

        // ── Beta Blockers / Cardiovascular ──
        MolecularDescriptor(substanceId: "propranolol", molecularWeightDa: 259.3, heavyAtomCount: 19, cLogP: 3.48, hBondDonors: 2, hBondAcceptors: 3, polarSurfaceArea: 41.5, rotatableBondCount: 6),
        MolecularDescriptor(substanceId: "metoprolol", molecularWeightDa: 267.4, heavyAtomCount: 19, cLogP: 1.88, hBondDonors: 2, hBondAcceptors: 4, polarSurfaceArea: 50.7, rotatableBondCount: 9),
        MolecularDescriptor(substanceId: "atenolol", molecularWeightDa: 266.3, heavyAtomCount: 19, cLogP: 0.16, hBondDonors: 3, hBondAcceptors: 4, polarSurfaceArea: 84.6, rotatableBondCount: 8),
        MolecularDescriptor(substanceId: "bisoprolol", molecularWeightDa: 325.4, heavyAtomCount: 23, cLogP: 1.87, hBondDonors: 2, hBondAcceptors: 5, polarSurfaceArea: 60.0, rotatableBondCount: 10),
        MolecularDescriptor(substanceId: "carvedilol", molecularWeightDa: 406.5, heavyAtomCount: 30, cLogP: 4.19, hBondDonors: 2, hBondAcceptors: 5, polarSurfaceArea: 75.7, rotatableBondCount: 10),
        MolecularDescriptor(substanceId: "clonidine", molecularWeightDa: 230.1, heavyAtomCount: 14, cLogP: 1.59, hBondDonors: 1, hBondAcceptors: 1, polarSurfaceArea: 36.4, rotatableBondCount: 1),
        MolecularDescriptor(substanceId: "guanfacine", molecularWeightDa: 246.1, heavyAtomCount: 16, cLogP: 1.52, hBondDonors: 2, hBondAcceptors: 2, polarSurfaceArea: 58.3, rotatableBondCount: 3),
        MolecularDescriptor(substanceId: "digoxin", molecularWeightDa: 780.9, heavyAtomCount: 54, cLogP: 1.26, hBondDonors: 5, hBondAcceptors: 14, polarSurfaceArea: 203.1, rotatableBondCount: 7),
        MolecularDescriptor(substanceId: "ivabradine", molecularWeightDa: 468.6, heavyAtomCount: 34, cLogP: 2.96, hBondDonors: 0, hBondAcceptors: 5, polarSurfaceArea: 60.8, rotatableBondCount: 7),

        // ── SSRIs / Antidepressants ──
        MolecularDescriptor(substanceId: "sertraline", molecularWeightDa: 306.2, heavyAtomCount: 20, cLogP: 5.29, hBondDonors: 1, hBondAcceptors: 1, polarSurfaceArea: 12.0, rotatableBondCount: 2),
        MolecularDescriptor(substanceId: "fluoxetine", molecularWeightDa: 309.3, heavyAtomCount: 22, cLogP: 4.05, hBondDonors: 1, hBondAcceptors: 2, polarSurfaceArea: 21.3, rotatableBondCount: 6),
        MolecularDescriptor(substanceId: "escitalopram", molecularWeightDa: 324.4, heavyAtomCount: 24, cLogP: 3.50, hBondDonors: 1, hBondAcceptors: 3, polarSurfaceArea: 36.3, rotatableBondCount: 5),
        MolecularDescriptor(substanceId: "paroxetine", molecularWeightDa: 329.4, heavyAtomCount: 23, cLogP: 3.60, hBondDonors: 1, hBondAcceptors: 4, polarSurfaceArea: 39.7, rotatableBondCount: 4),
        MolecularDescriptor(substanceId: "venlafaxine", molecularWeightDa: 277.4, heavyAtomCount: 20, cLogP: 3.20, hBondDonors: 1, hBondAcceptors: 3, polarSurfaceArea: 32.7, rotatableBondCount: 5),
        MolecularDescriptor(substanceId: "duloxetine", molecularWeightDa: 297.4, heavyAtomCount: 22, cLogP: 4.21, hBondDonors: 1, hBondAcceptors: 3, polarSurfaceArea: 21.3, rotatableBondCount: 6),
        MolecularDescriptor(substanceId: "bupropion", molecularWeightDa: 239.7, heavyAtomCount: 16, cLogP: 3.21, hBondDonors: 1, hBondAcceptors: 2, polarSurfaceArea: 29.1, rotatableBondCount: 4),
        MolecularDescriptor(substanceId: "mirtazapine", molecularWeightDa: 265.4, heavyAtomCount: 20, cLogP: 2.90, hBondDonors: 0, hBondAcceptors: 3, polarSurfaceArea: 19.4, rotatableBondCount: 0),
        MolecularDescriptor(substanceId: "trazodone", molecularWeightDa: 371.9, heavyAtomCount: 26, cLogP: 2.68, hBondDonors: 0, hBondAcceptors: 5, polarSurfaceArea: 42.4, rotatableBondCount: 5),
        MolecularDescriptor(substanceId: "amitriptyline", molecularWeightDa: 277.4, heavyAtomCount: 21, cLogP: 4.92, hBondDonors: 0, hBondAcceptors: 1, polarSurfaceArea: 3.2, rotatableBondCount: 2),
        MolecularDescriptor(substanceId: "nortriptyline", molecularWeightDa: 263.4, heavyAtomCount: 20, cLogP: 4.51, hBondDonors: 1, hBondAcceptors: 1, polarSurfaceArea: 12.0, rotatableBondCount: 2),
        MolecularDescriptor(substanceId: "phenelzine", molecularWeightDa: 136.2, heavyAtomCount: 10, cLogP: 0.91, hBondDonors: 2, hBondAcceptors: 2, polarSurfaceArea: 38.1, rotatableBondCount: 3),
        MolecularDescriptor(substanceId: "tranylcypromine", molecularWeightDa: 133.2, heavyAtomCount: 10, cLogP: 1.42, hBondDonors: 1, hBondAcceptors: 1, polarSurfaceArea: 26.0, rotatableBondCount: 1),

        // ── Antipsychotics ──
        MolecularDescriptor(substanceId: "quetiapine", molecularWeightDa: 383.5, heavyAtomCount: 27, cLogP: 2.81, hBondDonors: 1, hBondAcceptors: 4, polarSurfaceArea: 48.8, rotatableBondCount: 6),
        MolecularDescriptor(substanceId: "olanzapine", molecularWeightDa: 312.4, heavyAtomCount: 23, cLogP: 2.10, hBondDonors: 1, hBondAcceptors: 4, polarSurfaceArea: 30.9, rotatableBondCount: 1),
        MolecularDescriptor(substanceId: "risperidone", molecularWeightDa: 410.5, heavyAtomCount: 30, cLogP: 3.04, hBondDonors: 0, hBondAcceptors: 5, polarSurfaceArea: 61.9, rotatableBondCount: 4),
        MolecularDescriptor(substanceId: "aripiprazole", molecularWeightDa: 448.4, heavyAtomCount: 31, cLogP: 4.49, hBondDonors: 1, hBondAcceptors: 4, polarSurfaceArea: 44.8, rotatableBondCount: 7),
        MolecularDescriptor(substanceId: "haloperidol", molecularWeightDa: 375.9, heavyAtomCount: 26, cLogP: 3.23, hBondDonors: 1, hBondAcceptors: 3, polarSurfaceArea: 40.5, rotatableBondCount: 6),
        MolecularDescriptor(substanceId: "chlorpromazine", molecularWeightDa: 318.9, heavyAtomCount: 21, cLogP: 5.18, hBondDonors: 0, hBondAcceptors: 2, polarSurfaceArea: 6.5, rotatableBondCount: 4),
        MolecularDescriptor(substanceId: "clozapine", molecularWeightDa: 326.8, heavyAtomCount: 23, cLogP: 3.23, hBondDonors: 1, hBondAcceptors: 4, polarSurfaceArea: 30.9, rotatableBondCount: 1),

        // ── Anxiolytics / Sedatives ──
        MolecularDescriptor(substanceId: "alprazolam", molecularWeightDa: 308.8, heavyAtomCount: 22, cLogP: 2.12, hBondDonors: 0, hBondAcceptors: 3, polarSurfaceArea: 43.1, rotatableBondCount: 1),
        MolecularDescriptor(substanceId: "diazepam", molecularWeightDa: 284.7, heavyAtomCount: 20, cLogP: 2.82, hBondDonors: 0, hBondAcceptors: 2, polarSurfaceArea: 32.7, rotatableBondCount: 1),
        MolecularDescriptor(substanceId: "lorazepam", molecularWeightDa: 321.2, heavyAtomCount: 22, cLogP: 2.39, hBondDonors: 2, hBondAcceptors: 3, polarSurfaceArea: 61.7, rotatableBondCount: 1),
        MolecularDescriptor(substanceId: "clonazepam", molecularWeightDa: 315.7, heavyAtomCount: 23, cLogP: 2.41, hBondDonors: 1, hBondAcceptors: 4, polarSurfaceArea: 87.0, rotatableBondCount: 1),
        MolecularDescriptor(substanceId: "buspirone", molecularWeightDa: 385.5, heavyAtomCount: 28, cLogP: 2.67, hBondDonors: 0, hBondAcceptors: 5, polarSurfaceArea: 69.6, rotatableBondCount: 6),
        MolecularDescriptor(substanceId: "hydroxyzine", molecularWeightDa: 374.9, heavyAtomCount: 26, cLogP: 2.36, hBondDonors: 1, hBondAcceptors: 4, polarSurfaceArea: 35.9, rotatableBondCount: 8),
        MolecularDescriptor(substanceId: "zolpidem", molecularWeightDa: 307.4, heavyAtomCount: 23, cLogP: 2.47, hBondDonors: 0, hBondAcceptors: 3, polarSurfaceArea: 37.6, rotatableBondCount: 3),
        MolecularDescriptor(substanceId: "suvorexant", molecularWeightDa: 450.9, heavyAtomCount: 31, cLogP: 3.61, hBondDonors: 0, hBondAcceptors: 5, polarSurfaceArea: 72.4, rotatableBondCount: 5),

        // ── Opioids / Analgesics ──
        MolecularDescriptor(substanceId: "morphine", molecularWeightDa: 285.3, heavyAtomCount: 21, cLogP: 0.89, hBondDonors: 2, hBondAcceptors: 4, polarSurfaceArea: 52.9, rotatableBondCount: 1),
        MolecularDescriptor(substanceId: "oxycodone", molecularWeightDa: 315.4, heavyAtomCount: 23, cLogP: 0.70, hBondDonors: 1, hBondAcceptors: 5, polarSurfaceArea: 59.7, rotatableBondCount: 1),
        MolecularDescriptor(substanceId: "hydrocodone", molecularWeightDa: 299.4, heavyAtomCount: 22, cLogP: 1.52, hBondDonors: 1, hBondAcceptors: 4, polarSurfaceArea: 49.8, rotatableBondCount: 1),
        MolecularDescriptor(substanceId: "fentanyl", molecularWeightDa: 336.5, heavyAtomCount: 25, cLogP: 3.89, hBondDonors: 0, hBondAcceptors: 3, polarSurfaceArea: 23.6, rotatableBondCount: 7),
        MolecularDescriptor(substanceId: "methadone", molecularWeightDa: 309.4, heavyAtomCount: 23, cLogP: 3.93, hBondDonors: 0, hBondAcceptors: 2, polarSurfaceArea: 20.3, rotatableBondCount: 7),
        MolecularDescriptor(substanceId: "buprenorphine", molecularWeightDa: 467.6, heavyAtomCount: 34, cLogP: 4.98, hBondDonors: 2, hBondAcceptors: 5, polarSurfaceArea: 62.2, rotatableBondCount: 5),
        MolecularDescriptor(substanceId: "tramadol", molecularWeightDa: 263.4, heavyAtomCount: 19, cLogP: 2.51, hBondDonors: 1, hBondAcceptors: 3, polarSurfaceArea: 32.7, rotatableBondCount: 4),
        MolecularDescriptor(substanceId: "naltrexone", molecularWeightDa: 341.4, heavyAtomCount: 25, cLogP: 1.91, hBondDonors: 2, hBondAcceptors: 5, polarSurfaceArea: 70.0, rotatableBondCount: 2),

        // ── Anticonvulsants / Mood Stabilizers ──
        MolecularDescriptor(substanceId: "gabapentin", molecularWeightDa: 171.2, heavyAtomCount: 12, cLogP: -1.10, hBondDonors: 2, hBondAcceptors: 3, polarSurfaceArea: 63.3, rotatableBondCount: 3),
        MolecularDescriptor(substanceId: "pregabalin", molecularWeightDa: 159.2, heavyAtomCount: 11, cLogP: -1.35, hBondDonors: 2, hBondAcceptors: 3, polarSurfaceArea: 63.3, rotatableBondCount: 4),
        MolecularDescriptor(substanceId: "lamotrigine", molecularWeightDa: 256.1, heavyAtomCount: 16, cLogP: 2.57, hBondDonors: 2, hBondAcceptors: 4, polarSurfaceArea: 90.7, rotatableBondCount: 1),
        MolecularDescriptor(substanceId: "valproate", molecularWeightDa: 144.2, heavyAtomCount: 10, cLogP: 2.75, hBondDonors: 1, hBondAcceptors: 2, polarSurfaceArea: 37.3, rotatableBondCount: 4),
        MolecularDescriptor(substanceId: "lithium", molecularWeightDa: 6.9, heavyAtomCount: 1, cLogP: -0.77, hBondDonors: 0, hBondAcceptors: 0, polarSurfaceArea: 0.0, rotatableBondCount: 0),
        MolecularDescriptor(substanceId: "carbamazepine", molecularWeightDa: 236.3, heavyAtomCount: 18, cLogP: 2.45, hBondDonors: 1, hBondAcceptors: 2, polarSurfaceArea: 46.3, rotatableBondCount: 0),
        MolecularDescriptor(substanceId: "topiramate", molecularWeightDa: 339.4, heavyAtomCount: 22, cLogP: -0.77, hBondDonors: 1, hBondAcceptors: 9, polarSurfaceArea: 115.5, rotatableBondCount: 3),

        // ── Recreational / Research ──
        MolecularDescriptor(substanceId: "ethanol", molecularWeightDa: 46.1, heavyAtomCount: 3, cLogP: -0.31, hBondDonors: 1, hBondAcceptors: 1, polarSurfaceArea: 20.2, rotatableBondCount: 0),
        MolecularDescriptor(substanceId: "nicotine", molecularWeightDa: 162.2, heavyAtomCount: 12, cLogP: 1.17, hBondDonors: 0, hBondAcceptors: 2, polarSurfaceArea: 16.1, rotatableBondCount: 1),
        MolecularDescriptor(substanceId: "thc", molecularWeightDa: 314.5, heavyAtomCount: 23, cLogP: 6.97, hBondDonors: 1, hBondAcceptors: 2, polarSurfaceArea: 29.5, rotatableBondCount: 4),
        MolecularDescriptor(substanceId: "dronabinol", molecularWeightDa: 314.5, heavyAtomCount: 23, cLogP: 6.97, hBondDonors: 1, hBondAcceptors: 2, polarSurfaceArea: 29.5, rotatableBondCount: 4),
        MolecularDescriptor(substanceId: "cocaine", molecularWeightDa: 303.4, heavyAtomCount: 22, cLogP: 2.28, hBondDonors: 0, hBondAcceptors: 5, polarSurfaceArea: 55.8, rotatableBondCount: 4),
        MolecularDescriptor(substanceId: "mdma", molecularWeightDa: 193.2, heavyAtomCount: 14, cLogP: 1.67, hBondDonors: 1, hBondAcceptors: 3, polarSurfaceArea: 30.5, rotatableBondCount: 3),
        MolecularDescriptor(substanceId: "psilocybin", molecularWeightDa: 284.3, heavyAtomCount: 20, cLogP: 0.22, hBondDonors: 3, hBondAcceptors: 6, polarSurfaceArea: 90.8, rotatableBondCount: 3),
        MolecularDescriptor(substanceId: "lsd", molecularWeightDa: 323.4, heavyAtomCount: 24, cLogP: 2.95, hBondDonors: 1, hBondAcceptors: 4, polarSurfaceArea: 43.1, rotatableBondCount: 1),
        MolecularDescriptor(substanceId: "ketamine", molecularWeightDa: 237.7, heavyAtomCount: 16, cLogP: 2.18, hBondDonors: 1, hBondAcceptors: 2, polarSurfaceArea: 29.1, rotatableBondCount: 1),
        MolecularDescriptor(substanceId: "ghb", molecularWeightDa: 104.1, heavyAtomCount: 7, cLogP: -0.53, hBondDonors: 2, hBondAcceptors: 3, polarSurfaceArea: 57.5, rotatableBondCount: 2),

        // ── Psychedelics / Entheogens ──
        MolecularDescriptor(substanceId: "dmt", molecularWeightDa: 188.3, heavyAtomCount: 14, cLogP: 1.54, hBondDonors: 1, hBondAcceptors: 2, polarSurfaceArea: 16.0, rotatableBondCount: 2),
        MolecularDescriptor(substanceId: "mescaline", molecularWeightDa: 211.3, heavyAtomCount: 15, cLogP: 0.68, hBondDonors: 1, hBondAcceptors: 4, polarSurfaceArea: 41.9, rotatableBondCount: 5),
        MolecularDescriptor(substanceId: "ibogaine", molecularWeightDa: 310.4, heavyAtomCount: 23, cLogP: 2.69, hBondDonors: 1, hBondAcceptors: 3, polarSurfaceArea: 32.3, rotatableBondCount: 4),
        MolecularDescriptor(substanceId: "salvinorin-a", molecularWeightDa: 432.5, heavyAtomCount: 31, cLogP: 2.38, hBondDonors: 0, hBondAcceptors: 9, polarSurfaceArea: 113.4, rotatableBondCount: 5),
        MolecularDescriptor(substanceId: "cathinone", molecularWeightDa: 149.2, heavyAtomCount: 11, cLogP: 1.12, hBondDonors: 1, hBondAcceptors: 2, polarSurfaceArea: 43.1, rotatableBondCount: 2),
        MolecularDescriptor(substanceId: "apigenin", molecularWeightDa: 270.2, heavyAtomCount: 20, cLogP: 1.77, hBondDonors: 3, hBondAcceptors: 5, polarSurfaceArea: 90.9, rotatableBondCount: 1),
        MolecularDescriptor(substanceId: "atropine", molecularWeightDa: 289.4, heavyAtomCount: 21, cLogP: 1.83, hBondDonors: 1, hBondAcceptors: 4, polarSurfaceArea: 49.8, rotatableBondCount: 4),

        // ── Miscellaneous ──
        MolecularDescriptor(substanceId: "diphenhydramine", molecularWeightDa: 255.4, heavyAtomCount: 19, cLogP: 3.27, hBondDonors: 0, hBondAcceptors: 2, polarSurfaceArea: 12.5, rotatableBondCount: 6),
        MolecularDescriptor(substanceId: "promethazine", molecularWeightDa: 284.4, heavyAtomCount: 20, cLogP: 4.20, hBondDonors: 0, hBondAcceptors: 2, polarSurfaceArea: 31.8, rotatableBondCount: 3),
        MolecularDescriptor(substanceId: "scopolamine", molecularWeightDa: 303.4, heavyAtomCount: 22, cLogP: 0.98, hBondDonors: 1, hBondAcceptors: 5, polarSurfaceArea: 62.3, rotatableBondCount: 4),
        MolecularDescriptor(substanceId: "ibuprofen", molecularWeightDa: 206.3, heavyAtomCount: 15, cLogP: 3.97, hBondDonors: 1, hBondAcceptors: 2, polarSurfaceArea: 37.3, rotatableBondCount: 4),
        MolecularDescriptor(substanceId: "prednisone", molecularWeightDa: 358.4, heavyAtomCount: 26, cLogP: 1.46, hBondDonors: 2, hBondAcceptors: 5, polarSurfaceArea: 91.7, rotatableBondCount: 2),
        MolecularDescriptor(substanceId: "dexamethasone", molecularWeightDa: 392.5, heavyAtomCount: 28, cLogP: 1.83, hBondDonors: 3, hBondAcceptors: 5, polarSurfaceArea: 94.8, rotatableBondCount: 2),
        MolecularDescriptor(substanceId: "metoclopramide", molecularWeightDa: 299.8, heavyAtomCount: 21, cLogP: 2.62, hBondDonors: 2, hBondAcceptors: 4, polarSurfaceArea: 67.6, rotatableBondCount: 6),
        MolecularDescriptor(substanceId: "levothyroxine", molecularWeightDa: 776.9, heavyAtomCount: 33, cLogP: 2.43, hBondDonors: 3, hBondAcceptors: 4, polarSurfaceArea: 96.8, rotatableBondCount: 5),
        MolecularDescriptor(substanceId: "cyclobenzaprine", molecularWeightDa: 275.4, heavyAtomCount: 21, cLogP: 4.77, hBondDonors: 0, hBondAcceptors: 1, polarSurfaceArea: 3.2, rotatableBondCount: 2),
        MolecularDescriptor(substanceId: "baclofen", molecularWeightDa: 213.7, heavyAtomCount: 14, cLogP: 1.27, hBondDonors: 2, hBondAcceptors: 3, polarSurfaceArea: 63.3, rotatableBondCount: 4),
        MolecularDescriptor(substanceId: "tizanidine", molecularWeightDa: 253.7, heavyAtomCount: 16, cLogP: 1.42, hBondDonors: 1, hBondAcceptors: 3, polarSurfaceArea: 64.7, rotatableBondCount: 1),

        // ── Insulin (peptide, non-standard MW) ──
        MolecularDescriptor(substanceId: "insulin-rapid", molecularWeightDa: 5808.0, heavyAtomCount: 408, cLogP: -12.0, hBondDonors: 55, hBondAcceptors: 80, polarSurfaceArea: 2290.0, rotatableBondCount: 50),
    ]
}
