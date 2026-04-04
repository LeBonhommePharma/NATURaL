import Foundation

// MARK: - Interaction Result

/// Result of analyzing the pharmacological interaction between two PokeDrug species.
public struct InteractionResult: Sendable {
    /// The two species being analyzed.
    public let species1: PokeDrugSpecies
    public let species2: PokeDrugSpecies

    /// Overall interaction classification.
    public let classification: InteractionClassification

    /// Numeric synergy score: positive = synergy, negative = antagonism, ~0 = neutral.
    /// Range roughly -4.0 to +4.0.
    public let synergyScore: Double

    /// Half-life overlap ratio (0-1). Higher means more temporal interaction potential.
    public let temporalOverlap: Double

    /// Type-based effectiveness of species1's scaffold against species2's types.
    public let forwardEffectiveness: TypeEffectiveness

    /// Type-based effectiveness of species2's scaffold against species1's types.
    public let reverseEffectiveness: TypeEffectiveness
}

/// Classification of a drug-drug interaction.
public enum InteractionClassification: String, Sendable, Codable {
    /// Same-pathway potentiation (e.g., two serotonergics).
    case synergy
    /// Opposing mechanisms cancel effects.
    case antagonism
    /// Minimal pharmacological overlap.
    case neutral
    /// Same receptor competition — unpredictable displacement.
    case competition
}

// MARK: - Polypharmacology Analyzer

/// Analyzes cross-reactivity and polypharmacology risk between PokeDrug species
/// using the type matchup chart, scaffold effectiveness, and PK temporal overlap.
public struct PolypharmacologyAnalyzer: Sendable {

    public init() {}

    // MARK: - Pairwise Interaction

    /// Analyze the pharmacological interaction between two species.
    public func analyzeInteraction(
        _ species1: PokeDrugSpecies,
        _ species2: PokeDrugSpecies
    ) -> InteractionResult {
        let forward = PokeDrugMatchup.effectiveness(
            scaffold: species1.scaffold,
            against: species2.primaryType
        )
        let reverse = PokeDrugMatchup.effectiveness(
            scaffold: species2.scaffold,
            against: species1.primaryType
        )

        let temporalOverlap = computeTemporalOverlap(species1, species2)
        let typeOverlap = computeTypeOverlap(species1, species2)
        let synergyScore = computeSynergyScore(
            forward: forward,
            reverse: reverse,
            typeOverlap: typeOverlap,
            temporalOverlap: temporalOverlap
        )

        let classification = classify(
            synergyScore: synergyScore,
            forward: forward,
            reverse: reverse,
            typeOverlap: typeOverlap
        )

        return InteractionResult(
            species1: species1,
            species2: species2,
            classification: classification,
            synergyScore: synergyScore,
            temporalOverlap: temporalOverlap,
            forwardEffectiveness: forward,
            reverseEffectiveness: reverse
        )
    }

    // MARK: - Batch Analysis

    /// Find all synergy pairs in a set of species, ranked by synergy score (descending).
    public func findSynergyPairs(
        in species: [PokeDrugSpecies]
    ) -> [(PokeDrugSpecies, PokeDrugSpecies, Double)] {
        var pairs: [(PokeDrugSpecies, PokeDrugSpecies, Double)] = []

        for i in 0..<species.count {
            for j in (i + 1)..<species.count {
                let result = analyzeInteraction(species[i], species[j])
                if result.classification == .synergy {
                    pairs.append((species[i], species[j], result.synergyScore))
                }
            }
        }

        return pairs.sorted { $0.2 > $1.2 }
    }

    /// Compute polypharmacy risk score for a combination of species.
    /// Returns 0.0 (safe) to 1.0 (maximum risk).
    public func riskScore(for combination: [PokeDrugSpecies]) -> Double {
        guard combination.count >= 2 else { return 0.0 }

        var totalRisk = 0.0
        var pairCount = 0

        for i in 0..<combination.count {
            for j in (i + 1)..<combination.count {
                let result = analyzeInteraction(combination[i], combination[j])

                // Synergy on dangerous pathways increases risk
                if result.classification == .synergy {
                    let safetyPenalty = safetyInteractionPenalty(combination[i], combination[j])
                    totalRisk += result.synergyScore * safetyPenalty * result.temporalOverlap
                }
                // Competition also adds risk (unpredictable displacement)
                if result.classification == .competition {
                    totalRisk += 0.5 * result.temporalOverlap
                }

                pairCount += 1
            }
        }

        guard pairCount > 0 else { return 0.0 }

        // Normalize to 0-1 range
        let rawScore = totalRisk / Double(pairCount)
        return min(1.0, max(0.0, rawScore / 4.0))
    }

    // MARK: - Private Helpers

    /// Compute temporal overlap based on half-life similarity.
    private func computeTemporalOverlap(
        _ s1: PokeDrugSpecies,
        _ s2: PokeDrugSpecies
    ) -> Double {
        guard let pk1 = s1.pharmacokineticProfile,
              let pk2 = s2.pharmacokineticProfile else {
            return 0.5 // Default when PK data unavailable
        }

        let h1 = Double(pk1.halfLifeMinutes)
        let h2 = Double(pk2.halfLifeMinutes)
        let shorter = min(h1, h2)
        let longer = max(h1, h2)

        guard longer > 0 else { return 0.0 }

        // Overlap ratio: 1.0 when identical, decreasing as difference grows
        return shorter / longer
    }

    /// Compute type overlap score (shared types = higher interaction potential).
    private func computeTypeOverlap(
        _ s1: PokeDrugSpecies,
        _ s2: PokeDrugSpecies
    ) -> Double {
        let types1 = Set(s1.types)
        let types2 = Set(s2.types)
        let shared = types1.intersection(types2).count
        let total = types1.union(types2).count

        guard total > 0 else { return 0.0 }
        return Double(shared) / Double(total)
    }

    /// Compute synergy score from effectiveness and overlap metrics.
    private func computeSynergyScore(
        forward: TypeEffectiveness,
        reverse: TypeEffectiveness,
        typeOverlap: Double,
        temporalOverlap: Double
    ) -> Double {
        let effectivenessScore = Double(forward.rawValue + reverse.rawValue) / 2.0
        let overlapBonus = typeOverlap * 2.0
        let temporalWeight = 0.5 + temporalOverlap * 0.5

        return (effectivenessScore + overlapBonus) * temporalWeight
    }

    /// Classify the interaction based on scores and effectiveness.
    private func classify(
        synergyScore: Double,
        forward: TypeEffectiveness,
        reverse: TypeEffectiveness,
        typeOverlap: Double
    ) -> InteractionClassification {
        // Same scaffold hitting same type = competition
        if typeOverlap > 0.5 && forward >= .effective && reverse >= .effective {
            return .competition
        }

        // Both scaffolds effective against each other's types = synergy
        if forward >= .effective && reverse >= .effective {
            return .synergy
        }

        // One effective, one immune/not effective = antagonism
        if (forward <= .notEffective && reverse >= .effective) ||
           (reverse <= .notEffective && forward >= .effective) {
            return .antagonism
        }

        // High type overlap = synergy (same pathway potentiation)
        if typeOverlap > 0.3 {
            return .synergy
        }

        return .neutral
    }

    /// Safety interaction penalty: higher when both species have low HP (narrow TI).
    private func safetyInteractionPenalty(
        _ s1: PokeDrugSpecies,
        _ s2: PokeDrugSpecies
    ) -> Double {
        let avgHP = Double(s1.stats.hp + s2.stats.hp) / 2.0
        // Lower HP = higher penalty (inverse relationship)
        return (6.0 - avgHP) / 5.0
    }
}
