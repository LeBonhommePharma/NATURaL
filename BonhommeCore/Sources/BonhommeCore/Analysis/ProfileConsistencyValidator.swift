import Foundation

/// Severity of a consistency issue.
public enum IssueSeverity: String, Sendable, Comparable {
    case info
    case warning
    case error

    public static func < (lhs: IssueSeverity, rhs: IssueSeverity) -> Bool {
        let order: [IssueSeverity] = [.info, .warning, .error]
        let li = order.firstIndex(of: lhs) ?? 0
        let ri = order.firstIndex(of: rhs) ?? 0
        return li < ri
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

/// Substances called out by the science audit as missing published thermodynamic
/// binding profiles in-registry. Values are **not** invented here — fill only with
/// sourced ITC/ΔH/−TΔS literature entries in `ThermodynamicBindingProfile`.
///
/// Tests assert this list is non-empty and stable so gaps stay visible.
public enum KnownThermoProfileGaps {
    /// Audit list (2026-07): missing primary-target thermodynamic decompositions.
    public static let substanceIds: [String] = [
        "diazepam",
        "psilocin",
        "mda",
        "scopolamine",
        "muscimol",
        "ephedrine",
        "mitragynine",
        "cbd",
        "harmine"
    ]
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
            fr: "Vérification de cohérence : \(substancesChecked) substances, \(issues.count) problèmes (\(errorCount) erreurs, \(warningCount) avertissements).",
            es: "Verificación de consistencia: \(substancesChecked) sustancias, \(issues.count) problemas (\(errorCount) errores, \(warningCount) advertencias).",
            ja: "整合性チェック: \(substancesChecked)物質、\(issues.count)件の問題（\(errorCount)件のエラー、\(warningCount)件の警告）。",
            zh: "一致性检查：\(substancesChecked)种物质，\(issues.count)个问题（\(errorCount)个错误，\(warningCount)个警告）。",
            ko: "일관성 검사: \(substancesChecked)개 물질, \(issues.count)개 문제 (\(errorCount)개 오류, \(warningCount)개 경고).",
            ru: "Проверка согласованности: \(substancesChecked) веществ, \(issues.count) проблем (\(errorCount) ошибок, \(warningCount) предупреждений).",
            de: "Konsistenzprüfung: \(substancesChecked) Substanzen, \(issues.count) Probleme (\(errorCount) Fehler, \(warningCount) Warnungen).",
            ar: "فحص الاتساق: \(substancesChecked) مادة، \(issues.count) مشكلة (\(errorCount) أخطاء، \(warningCount) تحذيرات)."
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
                    fr: "\(id) n'a pas de PharmacokineticProfile",
                    es: "\(id) no tiene PharmacokineticProfile",
                    ja: "\(id)にPharmacokineticProfileがありません",
                    zh: "\(id)没有PharmacokineticProfile",
                    ko: "\(id)에 PharmacokineticProfile이 없습니다",
                    ru: "\(id) не имеет PharmacokineticProfile",
                    de: "\(id) hat kein PharmacokineticProfile",
                    ar: "\(id) لا يملك PharmacokineticProfile"
                )
            ))
        }

        if BindingEntropyProfile.profile(for: id) == nil {
            issues.append(ConsistencyIssue(
                substanceId: id, issueType: .missingBindingEntropyProfile, severity: .warning,
                detail: LocalizedString(
                    en: "\(id) has no BindingEntropyProfile",
                    fr: "\(id) n'a pas de BindingEntropyProfile",
                    es: "\(id) no tiene BindingEntropyProfile",
                    ja: "\(id)にBindingEntropyProfileがありません",
                    zh: "\(id)没有BindingEntropyProfile",
                    ko: "\(id)에 BindingEntropyProfile이 없습니다",
                    ru: "\(id) не имеет BindingEntropyProfile",
                    de: "\(id) hat kein BindingEntropyProfile",
                    ar: "\(id) لا يملك BindingEntropyProfile"
                )
            ))
        }

        let thermoProfiles = ThermodynamicBindingProfile.profiles(for: id)
        if thermoProfiles.isEmpty {
            issues.append(ConsistencyIssue(
                substanceId: id, issueType: .missingThermodynamicProfile, severity: .warning,
                detail: LocalizedString(
                    en: "\(id) has no ThermodynamicBindingProfile",
                    fr: "\(id) n'a pas de ThermodynamicBindingProfile",
                    es: "\(id) no tiene ThermodynamicBindingProfile",
                    ja: "\(id)にThermodynamicBindingProfileがありません",
                    zh: "\(id)没有ThermodynamicBindingProfile",
                    ko: "\(id)에 ThermodynamicBindingProfile이 없습니다",
                    ru: "\(id) не имеет ThermodynamicBindingProfile",
                    de: "\(id) hat kein ThermodynamicBindingProfile",
                    ar: "\(id) لا يملك ThermodynamicBindingProfile"
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
                        fr: "\(id) Défense : curé=\(species.stats.defense), dérivé=\(derivedDefense) (de t½=\(pk.halfLifeMinutes) min)",
                        es: "\(id) Defensa: curado=\(species.stats.defense), derivado=\(derivedDefense) (de t½=\(pk.halfLifeMinutes) min)",
                        ja: "\(id) 防御: 管理値=\(species.stats.defense), 導出値=\(derivedDefense) (t½=\(pk.halfLifeMinutes)分より)",
                        zh: "\(id) 防御：策划值=\(species.stats.defense)，推导值=\(derivedDefense)（来自t½=\(pk.halfLifeMinutes)分钟）",
                        ko: "\(id) 방어: 큐레이션=\(species.stats.defense), 도출=\(derivedDefense) (t½=\(pk.halfLifeMinutes)분에서)",
                        ru: "\(id) Защита: курированное=\(species.stats.defense), расчётное=\(derivedDefense) (из t½=\(pk.halfLifeMinutes) мин)",
                        de: "\(id) Verteidigung: kuratiert=\(species.stats.defense), abgeleitet=\(derivedDefense) (aus t½=\(pk.halfLifeMinutes) Min)",
                        ar: "\(id) الدفاع: منسق=\(species.stats.defense)، مشتق=\(derivedDefense) (من t½=\(pk.halfLifeMinutes) دقيقة)"
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
                        fr: "\(id) Vitesse : curé=\(species.stats.speed), dérivé=\(derivedSpeed) (de début=\(pk.onsetMinutes) min)",
                        es: "\(id) Velocidad: curado=\(species.stats.speed), derivado=\(derivedSpeed) (de inicio=\(pk.onsetMinutes) min)",
                        ja: "\(id) 速度: 管理値=\(species.stats.speed), 導出値=\(derivedSpeed) (発現=\(pk.onsetMinutes)分より)",
                        zh: "\(id) 速度：策划值=\(species.stats.speed)，推导值=\(derivedSpeed)（来自起效=\(pk.onsetMinutes)分钟）",
                        ko: "\(id) 속도: 큐레이션=\(species.stats.speed), 도출=\(derivedSpeed) (발현=\(pk.onsetMinutes)분에서)",
                        ru: "\(id) Скорость: курированное=\(species.stats.speed), расчётное=\(derivedSpeed) (из начала=\(pk.onsetMinutes) мин)",
                        de: "\(id) Geschwindigkeit: kuratiert=\(species.stats.speed), abgeleitet=\(derivedSpeed) (aus Onset=\(pk.onsetMinutes) Min)",
                        ar: "\(id) السرعة: منسق=\(species.stats.speed)، مشتق=\(derivedSpeed) (من بداية التأثير=\(pk.onsetMinutes) دقيقة)"
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
                        fr: "\(id) Attaque : curé=\(species.stats.attack), dérivé=\(derivedAttack) (de Ki=\(ki) nM)",
                        es: "\(id) Ataque: curado=\(species.stats.attack), derivado=\(derivedAttack) (de Ki=\(ki) nM)",
                        ja: "\(id) 攻撃: 管理値=\(species.stats.attack), 導出値=\(derivedAttack) (Ki=\(ki) nMより)",
                        zh: "\(id) 攻击：策划值=\(species.stats.attack)，推导值=\(derivedAttack)（来自Ki=\(ki) nM）",
                        ko: "\(id) 공격: 큐레이션=\(species.stats.attack), 도출=\(derivedAttack) (Ki=\(ki) nM에서)",
                        ru: "\(id) Атака: курированное=\(species.stats.attack), расчётное=\(derivedAttack) (из Ki=\(ki) нМ)",
                        de: "\(id) Angriff: kuratiert=\(species.stats.attack), abgeleitet=\(derivedAttack) (aus Ki=\(ki) nM)",
                        ar: "\(id) الهجوم: منسق=\(species.stats.attack)، مشتق=\(derivedAttack) (من Ki=\(ki) نانومول)"
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
                        fr: "\(id) Att.Sp. : curé=\(species.stats.specialAttack), dérivé=\(derivedSpAtk)",
                        es: "\(id) At.Esp.: curado=\(species.stats.specialAttack), derivado=\(derivedSpAtk)",
                        ja: "\(id) 特攻: 管理値=\(species.stats.specialAttack), 導出値=\(derivedSpAtk)",
                        zh: "\(id) 特攻：策划值=\(species.stats.specialAttack)，推导值=\(derivedSpAtk)",
                        ko: "\(id) 특수공격: 큐레이션=\(species.stats.specialAttack), 도출=\(derivedSpAtk)",
                        ru: "\(id) Спец.Атака: курированное=\(species.stats.specialAttack), расчётное=\(derivedSpAtk)",
                        de: "\(id) Sp.Angr.: kuratiert=\(species.stats.specialAttack), abgeleitet=\(derivedSpAtk)",
                        ar: "\(id) هجوم خاص: منسق=\(species.stats.specialAttack)، مشتق=\(derivedSpAtk)"
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
                        fr: "\(id):\(profile.targetId) ITC incohérent : ΔG=\(thermo.deltaGKcal), ΔH=\(thermo.deltaHKcal), -TΔS=\(thermo.minusTDeltaSKcal)",
                        es: "\(id):\(profile.targetId) ITC inconsistente: ΔG=\(thermo.deltaGKcal), ΔH=\(thermo.deltaHKcal), -TΔS=\(thermo.minusTDeltaSKcal)",
                        ja: "\(id):\(profile.targetId) ITC不整合: ΔG=\(thermo.deltaGKcal), ΔH=\(thermo.deltaHKcal), -TΔS=\(thermo.minusTDeltaSKcal)",
                        zh: "\(id):\(profile.targetId) ITC不一致：ΔG=\(thermo.deltaGKcal)，ΔH=\(thermo.deltaHKcal)，-TΔS=\(thermo.minusTDeltaSKcal)",
                        ko: "\(id):\(profile.targetId) ITC 불일치: ΔG=\(thermo.deltaGKcal), ΔH=\(thermo.deltaHKcal), -TΔS=\(thermo.minusTDeltaSKcal)",
                        ru: "\(id):\(profile.targetId) ITC несогласованность: ΔG=\(thermo.deltaGKcal), ΔH=\(thermo.deltaHKcal), -TΔS=\(thermo.minusTDeltaSKcal)",
                        de: "\(id):\(profile.targetId) ITC inkonsistent: ΔG=\(thermo.deltaGKcal), ΔH=\(thermo.deltaHKcal), -TΔS=\(thermo.minusTDeltaSKcal)",
                        ar: "\(id):\(profile.targetId) ITC غير متسق: ΔG=\(thermo.deltaGKcal)، ΔH=\(thermo.deltaHKcal)، -TΔS=\(thermo.minusTDeltaSKcal)"
                    )
                ))
            }
        }

        return issues
    }
}
