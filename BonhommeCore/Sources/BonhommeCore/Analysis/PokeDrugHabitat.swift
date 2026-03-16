import Foundation

/// Natural biogeographic origins of psychoactive molecular scaffolds.
///
/// Each habitat represents an ecosystem where specific scaffolds evolved
/// in nature, creating a natural pharmacogeography of psychoactive chemistry.
public enum PokeDrugHabitat: String, Codable, Sendable, CaseIterable {
    /// Temperate/subtropical mushroom habitats. Home of tryptamine and ergoline
    /// lineages. Over 200 Psilocybe species produce psilocybin via a four-enzyme
    /// cluster that arose ~65 million years ago.
    case fungalForest

    /// Amazon basin, equatorial forests. The most scaffold-diverse habitat.
    /// Psychotria viridis (DMT), Erythroxylum coca (cocaine),
    /// Banisteriopsis caapi (beta-carboline MAOIs).
    case tropicalJungle

    /// Chihuahuan Desert, Andean slopes. Domain of phenethylamine psychedelics.
    /// Lophophora williamsii (peyote/mescaline), Echinopsis pachanoi (San Pedro).
    /// 5,700+ years of documented ceremonial use.
    case desertMesa

    /// Fertile Crescent through East Asia. Origin of the morphinan scaffold.
    /// Papaver somniferum (morphine, 17-enzyme 19-step pathway),
    /// Ephedra sinica (ephedrine), Camellia sinensis (caffeine).
    case asianHighlands

    /// Equatorial West Africa. Home of the iboga alkaloid.
    /// Tabernanthe iboga (ibogaine), Catha edulis (cathinone/khat).
    /// Bwiti spiritual tradition in Gabon.
    case africanRainforest

    /// Hindu Kush / Altai region. Ancestral home of Cannabis sativa.
    /// Cannabinoids via olivetolic acid + geranyl pyrophosphate -> CBGA pathway.
    case centralAsianSteppe

    /// Pan-tropical. Caffeine evolved independently at least five times:
    /// Coffea (Ethiopia), Camellia (China), Theobroma (Amazon),
    /// Paullinia (Amazon), Ilex (South America).
    case tropicalPlantations
}

// MARK: - Metadata

extension PokeDrugHabitat {

    /// Display name.
    public var displayName: LocalizedString {
        switch self {
        case .fungalForest:
            return LocalizedString(en: "Fungal Forest", fr: "Foret fongique")
        case .tropicalJungle:
            return LocalizedString(en: "Tropical Jungle", fr: "Jungle tropicale")
        case .desertMesa:
            return LocalizedString(en: "Desert Mesa", fr: "Mesa desertique")
        case .asianHighlands:
            return LocalizedString(en: "Asian Highlands", fr: "Hauts plateaux asiatiques")
        case .africanRainforest:
            return LocalizedString(en: "African Rainforest", fr: "Foret pluviale africaine")
        case .centralAsianSteppe:
            return LocalizedString(en: "Central Asian Steppe", fr: "Steppe d'Asie centrale")
        case .tropicalPlantations:
            return LocalizedString(en: "Tropical Plantations", fr: "Plantations tropicales")
        }
    }

    /// Habitat description.
    public var description: LocalizedString {
        switch self {
        case .fungalForest:
            return LocalizedString(
                en: "Temperate and subtropical mushroom habitats producing tryptamine and ergoline alkaloids via L-tryptophan biosynthesis.",
                fr: "Habitats fongiques temperes et subtropicaux produisant des alcaloides tryptamine et ergoline via la biosynthese du L-tryptophane."
            )
        case .tropicalJungle:
            return LocalizedString(
                en: "The most scaffold-diverse habitat, hosting DMT (chacruna), cocaine (coca), and beta-carboline MAOIs (ayahuasca vine).",
                fr: "L'habitat le plus diversifie en structures, abritant le DMT (chacruna), la cocaine (coca) et les IMAO beta-carbolines (liane d'ayahuasca)."
            )
        case .desertMesa:
            return LocalizedString(
                en: "Arid landscapes where cacti synthesize mescaline from tyrosine. Peyote and San Pedro ceremonies span 5,700+ years.",
                fr: "Paysages arides ou les cactus synthetisent la mescaline a partir de la tyrosine. Les ceremonies du peyotl et de San Pedro s'etendent sur plus de 5 700 ans."
            )
        case .asianHighlands:
            return LocalizedString(
                en: "Origin of the morphinan scaffold via Papaver somniferum's 17-enzyme, 19-step biosynthetic pathway from tyrosine.",
                fr: "Origine du squelette morphinane via la voie biosynthetique a 17 enzymes et 19 etapes du Papaver somniferum a partir de la tyrosine."
            )
        case .africanRainforest:
            return LocalizedString(
                en: "Home of ibogaine (Tabernanthe iboga) and cathinone (Catha edulis). Bwiti spiritual tradition in Gabon.",
                fr: "Berceau de l'ibogaine (Tabernanthe iboga) et de la cathinone (Catha edulis). Tradition spirituelle Bwiti au Gabon."
            )
        case .centralAsianSteppe:
            return LocalizedString(
                en: "Ancestral home of Cannabis sativa. THCA- and CBDA-synthases compete for the CBGA precursor.",
                fr: "Berceau ancestral du Cannabis sativa. Les THCA- et CBDA-synthases rivalisent pour le precurseur CBGA."
            )
        case .tropicalPlantations:
            return LocalizedString(
                en: "Caffeine evolved independently at least five times in unrelated plant families — the most dramatic convergent evolution in psychoactive chemistry.",
                fr: "La cafeine a evolue independamment au moins cinq fois dans des familles vegetales non apparentees — l'evolution convergente la plus spectaculaire de la chimie psychoactive."
            )
        }
    }

    /// Molecular scaffolds found in this habitat.
    public var scaffoldsFound: [MolecularScaffold] {
        switch self {
        case .fungalForest:         return [.tryptamine, .ergoline]
        case .tropicalJungle:       return [.tryptamine, .tropane]
        case .desertMesa:           return [.phenethylamine]
        case .asianHighlands:       return [.morphinan, .isoquinoline, .xanthine, .phenethylamine]
        case .africanRainforest:    return [.iboga, .phenethylamine]
        case .centralAsianSteppe:   return [.terpenoid]
        case .tropicalPlantations:  return [.xanthine]
        }
    }
}
