import Foundation

/// Six base stats for every PokeDrug species, derived from real PK/PD data.
///
/// Mapped to Pokemon base stats:
/// - HP = Therapeutic index (LD50/ED50). Higher HP = safer.
/// - Attack = Binding affinity (inverse Ki). Lower Ki = higher Attack.
/// - Defense = Metabolic stability (half-life, first-pass resistance).
/// - Sp. Atk = Receptor selectivity (primary/off-target ratio).
/// - Sp. Def = Tolerance resistance (slower tolerance = higher).
/// - Speed = Onset of action / BBB penetration rate.
///
/// All stats are integer star ratings from 1 to 5.
public struct PokeDrugStats: Sendable, Codable, Equatable {
    /// Therapeutic index (safety ratio: LD50/ED50). 5 = very safe (~1000:1).
    public let hp: Int

    /// Binding affinity at primary target (inverse Ki). 5 = sub-10 nM.
    public let attack: Int

    /// Metabolic stability (half-life, resistance to first-pass). 5 = very long.
    public let defense: Int

    /// Receptor selectivity (ratio of primary to strongest off-target). 5 = highly selective.
    public let specialAttack: Int

    /// Tolerance resistance. 5 = no/minimal tolerance development.
    public let specialDefense: Int

    /// Onset of action / BBB penetration rate. 5 = seconds.
    public let speed: Int

    /// Sum of all six base stats.
    public var total: Int {
        hp + attack + defense + specialAttack + specialDefense + speed
    }

    public init(hp: Int, attack: Int, defense: Int, specialAttack: Int, specialDefense: Int, speed: Int) {
        self.hp = hp
        self.attack = attack
        self.defense = defense
        self.specialAttack = specialAttack
        self.specialDefense = specialDefense
        self.speed = speed
    }
}

// MARK: - Stat Derivation Helpers

extension PokeDrugStats {

    /// Derive Defense star rating from elimination half-life.
    ///
    /// Quartile binning:
    /// - ★: < 60 min (e.g., cocaine, DMT smoked)
    /// - ★★: 60-180 min (e.g., morphine)
    /// - ★★★: 180-480 min (e.g., psilocybin, LSD plasma)
    /// - ★★★★: 480-1200 min (e.g., MDMA, amphetamine)
    /// - ★★★★★: > 1200 min (e.g., THC terminal, ibogaine/noribogaine)
    public static func deriveDefense(halfLifeMinutes: Double) -> Int {
        switch halfLifeMinutes {
        case ..<60:     return 1
        case 60..<180:  return 2
        case 180..<480: return 3
        case 480..<1200: return 4
        default:        return 5
        }
    }

    /// Derive Speed star rating from onset of action.
    ///
    /// Inverse relationship (faster onset = higher Speed):
    /// - ★★★★★: < 5 min (smoked/IV routes)
    /// - ★★★★: 5-15 min
    /// - ★★★: 15-30 min
    /// - ★★: 30-60 min
    /// - ★: > 60 min
    public static func deriveSpeed(onsetMinutes: Double) -> Int {
        switch onsetMinutes {
        case ..<5:    return 5
        case 5..<15:  return 4
        case 15..<30: return 3
        case 30..<60: return 2
        default:      return 1
        }
    }

    /// Derive Attack star rating from primary target Ki (nM).
    ///
    /// Lower Ki = tighter binding = higher Attack:
    /// - ★★★★★: < 10 nM (e.g., LSD, fentanyl, morphine)
    /// - ★★★★: 10-100 nM (e.g., amphetamine, THC)
    /// - ★★★: 100-1,000 nM (e.g., MDMA, cocaine, DMT)
    /// - ★★: 1,000-10,000 nM (e.g., caffeine, mescaline)
    /// - ★: > 10,000 nM (e.g., apigenin)
    public static func deriveAttack(kiNM: Double) -> Int {
        switch kiNM {
        case ..<10:      return 5
        case 10..<100:   return 4
        case 100..<1000: return 3
        case 1000..<10000: return 2
        default:         return 1
        }
    }

    /// Derive Sp. Atk star rating from selectivity ratio.
    ///
    /// Selectivity ratio = best off-target Ki / primary target Ki.
    /// Higher ratio = more selective = higher Sp. Atk:
    /// - ★★★★★: > 1,000x (e.g., salvinorin A at KOR)
    /// - ★★★★: 100-1,000x
    /// - ★★★: 10-100x
    /// - ★★: 3-10x
    /// - ★: < 3x (e.g., ibogaine — hits everything)
    public static func deriveSpecialAttack(selectivityRatio: Double) -> Int {
        switch selectivityRatio {
        case _ where selectivityRatio > 1000: return 5
        case _ where selectivityRatio > 100:  return 4
        case _ where selectivityRatio > 10:   return 3
        case _ where selectivityRatio > 3:    return 2
        default:                              return 1
        }
    }

    /// Format a single stat as a star string (e.g., 3 → "★★★").
    public static func starString(for value: Int) -> String {
        String(repeating: "★", count: max(1, min(5, value)))
    }
}
