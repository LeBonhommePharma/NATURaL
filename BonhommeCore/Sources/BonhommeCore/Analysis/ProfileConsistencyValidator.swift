import Foundation

/// Severity of a consistency issue.
public enum IssueSeverity: String, Sendable, Comparable {
    case info
    case warning
    case error

    public static func < (lhs: IssueSeverity, rhs: IssueSeverity) -> Bool {
        let order: [IssueSeverity] = [.info, .warning, .error]
        return order.firstIndex(of: lhs)! < order.firstIndex(of: rhs)!
    }
}

/// Type of consistency issue detected.
public enum ConsistencyIssueType: String, Sendable, CaseIterable {
    case missingPKProfile
    case missingBindingEntropyProfile
    case missingThermodynamicProfile
    case attackMismatch
    case defenseMismatch
    case speedMismatch
    case specialAttackMismatch
    case rotatableBondCountMismatch
    case thermodynamicInconsistency
}

/// A single consistency issue found during validation.
public struct ConsistencyIssue: Sendable {
    public let substanceId: String
    public let issueType: ConsistencyIssueType
    public let severity: IssueSeverity
    public let detail: LocalizedString

    public init(substanceId: String, issueType: ConsistencyIssueType, severity: IssueSeverity, detail: LocalizedString) {
        self.substanceId = substanceId
        self.issueType = issueType
        self.severity = severity
        self.detail = detail
    }
}

/// Report from cross-validating the three profile registries + PokeDrug stats.
public struct ConsistencyReport: Sendable {
    public let issues: [ConsistencyIssue]
    public let substancesChecked: Int

    public var issuesByType: [ConsistencyIssueType: [ConsistencyIssue]] {
        Dictionary(grouping: issues, by: \.issueType)
    }

    public var issuesBySeverity: [IssueSeverity: [ConsistencyIssue]] {
        Dictionary(grouping: issues, by: \.severity)
    }

    public var isFullyConsistent: Bool {
        !issues.contains { $0.severity == .error }
    }

    public var errorCount: Int { issues.filter { $0.severity == .error }.count }
    public var warningCount: Int { issues.filter { $0.severity == .warning }.count }

    public var summary: LocalizedString {
        LocalizedString(
            en: "Consistency check: \(substancesChecked) substances, \(issues.count) issues (\(errorCount) errors, \(warningCount) warnings).",
            fr: "Vérification de cohérence : \(substancesChecked) substances, \(issues.count) problèmes (\(errorCount) erreurs, \(warningCount) avertissements)."
        )
    }

    public init(issues: [ConsistencyIssue], substancesChecked: Int) {
        self.issues = issues
        self.substancesChecked = substancesChecked
    }
}

// MARK: - Validator

/// Cross-validates the three profile registries (PharmacokineticProfile,
/// BindingEntropyProfile, ThermodynamicBindingProfile) against PokeDrug
/// species stats for internal consistency.
///
/// Checks:
/// 1. All PokeDrug species have matching PK, BindingEntropy, and Thermodynamic profiles
/// 2. Derived stats (Attack from Ki, Defense from half-life, Speed from onset) match curated stats
/// 3. ITC decomposition is thermodynamically consistent where available
public struct ProfileConsistencyValidator: Sendable {

    public init() {}

    /// Validate all PokeDrug species.
    public static func validate() -> ConsistencyReport {
        var issues: [ConsistencyIssue] = []
        for species in PokeDrugSpecies.knownSpecies {
            issues.append(contentsOf: validate(substanceId: species.substanceId))
        }
        return ConsistencyReport(issues: issues, substancesChecked: PokeDrugSpecies.knownSpecies.count)
    }

    /// Validate a single substance.
    public static func validate(substanceId: String) -> [ConsistencyIssue] {
        var issues: [ConsistencyIssue] = []
        let id = substanceId.lowercased()

        let species = PokeDrugSpecies.species(for: id)

        // 1. Profile existence checks
        if PharmacokineticProfile.profile(for: id) == nil {
            issues.append(ConsistencyIssue(
                substanceId: id, issueType: .missingPKProfile, severity: .warning,
                detail: LocalizedString(
                    en: "\(id) has no PharmacokineticProfile",
                    fr: "\(id) n'a pas de PharmacokineticProfile"
                )
            ))
        }

        if BindingEntropyProfile.profile(for: id) == nil {
            issues.append(ConsistencyIssue(
                substanceId: id, issueType: .missingBindingEntropyProfile, severity: .warning,
                detail: LocalizedString(
                    en: "\(id) has no BindingEntropyProfile",
                    fr: "\(id) n'a pas de BindingEntropyProfile"
                )
            ))
        }

        let thermoProfiles = ThermodynamicBindingProfile.profiles(for: id)
        if thermoProfiles.isEmpty {
            issues.append(ConsistencyIssue(
                substanceId: id, issueType: .missingThermodynamicProfile, severity: .warning,
                detail: LocalizedString(
                    en: "\(id) has no ThermodynamicBindingProfile",
                    fr: "\(id) n'a pas de ThermodynamicBindingProfile"
                )
            ))
        }

        guard let species = species else { return issues }

        // 2. Stat derivation checks
        if let pk = PharmacokineticProfile.profile(for: id) {
            let derivedDefense = PokeDrugStats.deriveDefense(halfLifeMinutes: pk.halfLifeMinutes)
            let delta = abs(derivedDefense - species.stats.defense)
            if delta > 0 {
                issues.append(ConsistencyIssue(
                    substanceId: id, issueType: .defenseMismatch,
                    severity: delta >= 2 ? .error : .warning,
                    detail: LocalizedString(
                        en: "\(id) Defense: curated=\(species.stats.defense), derived=\(derivedDefense) (from t½=\(pk.halfLifeMinutes) min)",
                        fr: "\(id) Défense : curé=\(species.stats.defense), dérivé=\(derivedDefense) (de t½=\(pk.halfLifeMinutes) min)"
                    )
                ))
            }

            let derivedSpeed = PokeDrugStats.deriveSpeed(onsetMinutes: pk.onsetMinutes)
            let speedDelta = abs(derivedSpeed - species.stats.speed)
            if speedDelta > 0 {
                issues.append(ConsistencyIssue(
                    substanceId: id, issueType: .speedMismatch,
                    severity: speedDelta >= 2 ? .error : .warning,
                    detail: LocalizedString(
                        en: "\(id) Speed: curated=\(species.stats.speed), derived=\(derivedSpeed) (from onset=\(pk.onsetMinutes) min)",
                        fr: "\(id) Vitesse : curé=\(species.stats.speed), dérivé=\(derivedSpeed) (de début=\(pk.onsetMinutes) min)"
                    )
                ))
            }
        }

        if let primary = thermoProfiles.first(where: { $0.isPrimaryTarget }),
           let ki = primary.affinity.bestAffinityNM {
            let derivedAttack = PokeDrugStats.deriveAttack(kiNM: ki)
            let delta = abs(derivedAttack - species.stats.attack)
            if delta > 0 {
                issues.append(ConsistencyIssue(
                    substanceId: id, issueType: .attackMismatch,
                    severity: delta >= 2 ? .error : .warning,
                    detail: LocalizedString(
                        en: "\(id) Attack: curated=\(species.stats.attack), derived=\(derivedAttack) (from Ki=\(ki) nM)",
                        fr: "\(id) Attaque : curé=\(species.stats.attack), dérivé=\(derivedAttack) (de Ki=\(ki) nM)"
                    )
                ))
            }
        }

        // Sp.Atk from selectivity ratio
        if let derivedSpAtk = species.derivedSpecialAttack {
            let delta = abs(derivedSpAtk - species.stats.specialAttack)
            if delta > 0 {
                issues.append(ConsistencyIssue(
                    substanceId: id, issueType: .specialAttackMismatch,
                    severity: delta >= 2 ? .error : .warning,
                    detail: LocalizedString(
                        en: "\(id) Sp.Atk: curated=\(species.stats.specialAttack), derived=\(derivedSpAtk)",
                        fr: "\(id) Att.Sp. : curé=\(species.stats.specialAttack), dérivé=\(derivedSpAtk)"
                    )
                ))
            }
        }

        // 3. ITC thermodynamic consistency
        for profile in thermoProfiles {
            if let thermo = profile.thermodynamics, !thermo.isThermodynamicallyConsistent {
                issues.append(ConsistencyIssue(
                    substanceId: id, issueType: .thermodynamicInconsistency, severity: .error,
                    detail: LocalizedString(
                        en: "\(id):\(profile.targetId) ITC inconsistent: ΔG=\(thermo.deltaGKcal), ΔH=\(thermo.deltaHKcal), -TΔS=\(thermo.minusTDeltaSKcal)",
                        fr: "\(id):\(profile.targetId) ITC incohérent : ΔG=\(thermo.deltaGKcal), ΔH=\(thermo.deltaHKcal), -TΔS=\(thermo.minusTDeltaSKcal)"
                    )
                ))
            }
        }

        return issues
    }
}
