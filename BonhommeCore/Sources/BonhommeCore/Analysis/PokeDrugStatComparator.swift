import Foundation

// MARK: - Stat Comparison Result

/// Head-to-head comparison result between two PokeDrug species.
public struct StatComparison: Sendable {
    public let species1: PokeDrugSpecies
    public let species2: PokeDrugSpecies

    /// Per-stat differences (species1 - species2). Positive = species1 wins.
    public let hpDiff: Int
    public let attackDiff: Int
    public let defenseDiff: Int
    public let specialAttackDiff: Int
    public let specialDefenseDiff: Int
    public let speedDiff: Int

    /// Number of stats species1 wins (positive diff).
    public var species1Wins: Int {
        [hpDiff, attackDiff, defenseDiff, specialAttackDiff, specialDefenseDiff, speedDiff]
            .filter { $0 > 0 }.count
    }

    /// Number of stats species2 wins (negative diff).
    public var species2Wins: Int {
        [hpDiff, attackDiff, defenseDiff, specialAttackDiff, specialDefenseDiff, speedDiff]
            .filter { $0 < 0 }.count
    }

    /// Number of tied stats.
    public var ties: Int {
        6 - species1Wins - species2Wins
    }

    /// Total stat difference (species1.total - species2.total).
    public var totalDiff: Int {
        species1.stats.total - species2.stats.total
    }
}

// MARK: - Stat Key

/// Identifies one of the six PokeDrug base stats.
public enum PokeDrugStatKey: String, CaseIterable, Sendable, Codable {
    case hp
    case attack
    case defense
    case specialAttack
    case specialDefense
    case speed

    /// Human-readable display name.
    public var displayName: String {
        switch self {
        case .hp:             return "HP"
        case .attack:         return "Attack"
        case .defense:        return "Defense"
        case .specialAttack:  return "Sp. Atk"
        case .specialDefense: return "Sp. Def"
        case .speed:          return "Speed"
        }
    }

    /// Extract this stat's value from a PokeDrugStats struct.
    public func value(from stats: PokeDrugStats) -> Int {
        switch self {
        case .hp:             return stats.hp
        case .attack:         return stats.attack
        case .defense:        return stats.defense
        case .specialAttack:  return stats.specialAttack
        case .specialDefense: return stats.specialDefense
        case .speed:          return stats.speed
        }
    }
}

// MARK: - Stat Comparator

/// Comparative pharmacology engine using PokeDrug stat profiles.
/// Enables head-to-head comparison, ranking, radar chart data, and similarity search.
public struct PokeDrugStatComparator: Sendable {

    public init() {}

    // MARK: - Head-to-Head Comparison

    /// Compare two species stat-by-stat.
    public func compare(
        _ species1: PokeDrugSpecies,
        _ species2: PokeDrugSpecies
    ) -> StatComparison {
        let s1 = species1.stats
        let s2 = species2.stats

        return StatComparison(
            species1: species1,
            species2: species2,
            hpDiff: s1.hp - s2.hp,
            attackDiff: s1.attack - s2.attack,
            defenseDiff: s1.defense - s2.defense,
            specialAttackDiff: s1.specialAttack - s2.specialAttack,
            specialDefenseDiff: s1.specialDefense - s2.specialDefense,
            speedDiff: s1.speed - s2.speed
        )
    }

    // MARK: - Ranking

    /// Rank species by a specific stat (descending).
    public func rankBy(
        stat: PokeDrugStatKey,
        in species: [PokeDrugSpecies]
    ) -> [PokeDrugSpecies] {
        species.sorted { stat.value(from: $0.stats) > stat.value(from: $1.stats) }
    }

    /// Rank species by overall power score (descending).
    public func rankByOverallPower(
        in species: [PokeDrugSpecies]
    ) -> [PokeDrugSpecies] {
        species.sorted { overallPowerScore(for: $0) > overallPowerScore(for: $1) }
    }

    // MARK: - Radar Profile

    /// Generate a 6-axis radar chart profile for a species.
    /// Returns stat keys mapped to their integer values (1-5).
    public func radarProfile(for species: PokeDrugSpecies) -> [String: Int] {
        [
            "HP": species.stats.hp,
            "Attack": species.stats.attack,
            "Defense": species.stats.defense,
            "Sp. Atk": species.stats.specialAttack,
            "Sp. Def": species.stats.specialDefense,
            "Speed": species.stats.speed
        ]
    }

    // MARK: - Overall Power Score

    /// Compute a weighted composite power score.
    /// HP is weighted 2x (safety is paramount in pharmacology).
    /// Returns a value roughly in range 7-35.
    public func overallPowerScore(for species: PokeDrugSpecies) -> Double {
        let s = species.stats
        return Double(s.hp * 2 + s.attack + s.defense + s.specialAttack + s.specialDefense + s.speed)
    }

    // MARK: - Similarity Search

    /// Find the most similar species by Euclidean distance in 6D stat space.
    public func similarSpecies(
        to target: PokeDrugSpecies,
        in catalog: [PokeDrugSpecies],
        topN: Int = 5
    ) -> [PokeDrugSpecies] {
        let ranked = catalog
            .filter { $0.substanceId != target.substanceId }
            .map { species -> (PokeDrugSpecies, Double) in
                let distance = statDistance(target.stats, species.stats)
                return (species, distance)
            }
            .sorted { $0.1 < $1.1 }

        return Array(ranked.prefix(topN).map(\.0))
    }

    // MARK: - Archetype Classification

    /// Classify a species into a pharmacological archetype based on stat distribution.
    public func archetype(for species: PokeDrugSpecies) -> String {
        let s = species.stats
        let maxStat = max(s.hp, s.attack, s.defense, s.specialAttack, s.specialDefense, s.speed)

        if s.hp == maxStat && s.hp >= 4 {
            return "Tank" // High safety, e.g., CBD, psilocybin
        }
        if s.attack == maxStat && s.attack >= 4 {
            if s.defense <= 2 {
                return "Glass Cannon" // High potency, short duration, e.g., salvinorin A
            }
            return "Sweeper" // High potency + decent duration
        }
        if s.defense == maxStat && s.defense >= 4 {
            return "Wall" // Long-acting, e.g., diazepam, THC
        }
        if s.specialAttack == maxStat && s.specialAttack >= 4 {
            return "Specialist" // Highly selective, e.g., salvinorin A at KOR
        }
        if s.specialDefense == maxStat && s.specialDefense >= 4 {
            return "Endurance" // Tolerance-resistant, e.g., ibogaine, DMT
        }
        if s.speed == maxStat && s.speed >= 4 {
            return "Speedster" // Rapid onset, e.g., cocaine, DMT smoked
        }

        return "Balanced" // No single dominant stat
    }

    // MARK: - Private Helpers

    /// Euclidean distance between two stat vectors in 6D space.
    private func statDistance(_ a: PokeDrugStats, _ b: PokeDrugStats) -> Double {
        let diffs = [
            a.hp - b.hp,
            a.attack - b.attack,
            a.defense - b.defense,
            a.specialAttack - b.specialAttack,
            a.specialDefense - b.specialDefense,
            a.speed - b.speed
        ]
        let sumOfSquares = diffs.reduce(0.0) { $0 + Double($1 * $1) }
        return sumOfSquares.squareRoot()
    }
}
