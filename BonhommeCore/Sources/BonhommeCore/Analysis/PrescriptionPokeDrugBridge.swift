import Foundation

/// Result of matching a free-text prescription / medication name to the
/// PokeDrug knowledge base (species, PK, BindingEntropyProfile).
///
/// Used to deep-link Prescriptions UI into substance insights when a match exists.
public struct PrescriptionPokeDrugMatch: Sendable, Identifiable, Equatable {
    public var id: String { substanceId }

    /// Canonical substance key shared by PK / BindingEntropy / PokeDrugSpecies.
    public let substanceId: String

    /// Display name used for the match (usually the catalog EN name).
    public let catalogName: LocalizedString

    /// How the free-text name was resolved.
    public let matchKind: MatchKind

    /// 0…1 confidence (exact id/name = 1.0; token / contains = lower).
    public let confidence: Double

    public enum MatchKind: String, Sendable, Equatable {
        /// Exact substanceId (e.g. "propranolol").
        case substanceId
        /// Exact catalog display name (any supported language).
        case exactName
        /// Medication string contains catalog name (or vice versa).
        case containsName
        /// Significant token overlap (e.g. "Propranolol HCl 40 mg").
        case tokenOverlap
    }

    public init(
        substanceId: String,
        catalogName: LocalizedString,
        matchKind: MatchKind,
        confidence: Double
    ) {
        self.substanceId = substanceId
        self.catalogName = catalogName
        self.matchKind = matchKind
        self.confidence = confidence
    }

    // MARK: - Cross-reference convenience

    public var species: PokeDrugSpecies? {
        PokeDrugSpecies.species(for: substanceId)
    }

    public var pharmacokineticProfile: PharmacokineticProfile? {
        PharmacokineticProfile.profile(for: substanceId)
    }

    public var bindingEntropyProfile: BindingEntropyProfile? {
        BindingEntropyProfile.profile(for: substanceId)
    }

    /// True when at least one insight surface is available.
    public var hasAnyInsight: Bool {
        species != nil || pharmacokineticProfile != nil || bindingEntropyProfile != nil
    }

    /// Whether a BindingEntropyProfile cross-domain hint can be shown.
    public var hasCrossDomainHint: Bool {
        bindingEntropyProfile != nil
    }

    public static func == (lhs: PrescriptionPokeDrugMatch, rhs: PrescriptionPokeDrugMatch) -> Bool {
        lhs.substanceId == rhs.substanceId
            && lhs.matchKind == rhs.matchKind
            && lhs.confidence == rhs.confidence
    }
}

// MARK: - Bridge

/// Maps prescription / MedicationProfile free-text names onto PokeDrug substance insights.
///
/// Pure, side-effect free, and safe to call without clinical consent — **UI must still
/// gate navigation behind `ConsentStore.hasValidClinicalConsent`** so clinical workflows
/// share one consent surface.
public enum PrescriptionPokeDrugBridge: Sendable {

    /// Resolve a medication display name (and optional id) to a PokeDrug match.
    ///
    /// - Parameters:
    ///   - name: User-visible medication name (clinical FHIR display or manual entry).
    ///   - medicationId: Optional id that may already be a substanceId.
    /// - Returns: Best match with any insight surface, or nil if unmatched / no insights.
    public static func match(
        name: String,
        medicationId: String? = nil
    ) -> PrescriptionPokeDrugMatch? {
        // Prefer explicit substance id when callers already store a catalog key.
        if let medicationId {
            let id = medicationId.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
            if !id.isEmpty, let hit = matchBySubstanceId(id) {
                return hit
            }
        }

        let normalized = normalize(name)
        guard !normalized.isEmpty else { return nil }

        // Exact substanceId on full normalized string (spaces → hyphens / stripped).
        if let hit = matchBySubstanceId(normalized.replacingOccurrences(of: " ", with: "-"))
            ?? matchBySubstanceId(normalized.replacingOccurrences(of: " ", with: "")) {
            return hit
        }

        let candidates = catalogCandidates()
        var best: (PrescriptionPokeDrugMatch, Double)?

        for candidate in candidates {
            if let exact = exactNameMatch(query: normalized, candidate: candidate) {
                if best == nil || exact.confidence > best!.1 {
                    best = (exact, exact.confidence)
                }
                continue
            }
            if let contains = containsNameMatch(query: normalized, candidate: candidate) {
                if best == nil || contains.confidence > best!.1 {
                    best = (contains, contains.confidence)
                }
                continue
            }
            if let tokens = tokenOverlapMatch(query: normalized, candidate: candidate) {
                if best == nil || tokens.confidence > best!.1 {
                    best = (tokens, tokens.confidence)
                }
            }
        }

        guard let match = best?.0, match.hasAnyInsight, match.confidence >= 0.55 else {
            return nil
        }
        return match
    }

    /// Convenience for `MedicationProfile`-shaped inputs (id + localized name).
    public static func match(
        medicationId: String,
        localizedName: LocalizedString
    ) -> PrescriptionPokeDrugMatch? {
        // Try EN first (catalog primary), then localized fallback.
        match(name: localizedName.en, medicationId: medicationId)
            ?? match(name: localizedName.localized, medicationId: medicationId)
            ?? match(name: localizedName.fr, medicationId: medicationId)
    }

    // MARK: - Matching helpers

    private static func matchBySubstanceId(_ id: String) -> PrescriptionPokeDrugMatch? {
        let key = id.lowercased()
        guard !key.isEmpty else { return nil }

        if let species = PokeDrugSpecies.species(for: key) {
            return PrescriptionPokeDrugMatch(
                substanceId: species.substanceId,
                catalogName: species.name,
                matchKind: .substanceId,
                confidence: 1.0
            )
        }
        if let pk = PharmacokineticProfile.profile(for: key) {
            return PrescriptionPokeDrugMatch(
                substanceId: pk.substanceId,
                catalogName: pk.name,
                matchKind: .substanceId,
                confidence: 1.0
            )
        }
        if let binding = BindingEntropyProfile.profile(for: key) {
            // Binding-only entry: synthesize a display name from the id.
            return PrescriptionPokeDrugMatch(
                substanceId: binding.substanceId,
                catalogName: LocalizedString(
                    en: key.replacingOccurrences(of: "-", with: " ").capitalized,
                    fr: key.replacingOccurrences(of: "-", with: " ").capitalized
                ),
                matchKind: .substanceId,
                confidence: 1.0
            )
        }
        return nil
    }

    private struct CatalogCandidate: Sendable {
        let substanceId: String
        let name: LocalizedString
        let aliases: [String]
    }

    private static func catalogCandidates() -> [CatalogCandidate] {
        var byId: [String: CatalogCandidate] = [:]

        for species in PokeDrugSpecies.knownSpecies {
            byId[species.substanceId] = CatalogCandidate(
                substanceId: species.substanceId,
                name: species.name,
                aliases: nameAliases(species.name, substanceId: species.substanceId)
            )
        }
        for pk in PharmacokineticProfile.knownProfiles {
            if byId[pk.substanceId] == nil {
                byId[pk.substanceId] = CatalogCandidate(
                    substanceId: pk.substanceId,
                    name: pk.name,
                    aliases: nameAliases(pk.name, substanceId: pk.substanceId)
                )
            } else if var existing = byId[pk.substanceId] {
                // Merge PK aliases into species entry.
                let extra = nameAliases(pk.name, substanceId: pk.substanceId)
                existing = CatalogCandidate(
                    substanceId: existing.substanceId,
                    name: existing.name,
                    aliases: Array(Set(existing.aliases + extra))
                )
                byId[pk.substanceId] = existing
            }
        }
        return Array(byId.values)
    }

    private static func nameAliases(_ name: LocalizedString, substanceId: String) -> [String] {
        var raw = [
            name.en, name.fr, name.es, name.ja, name.zh,
            name.ko, name.ru, name.de, name.ar, name.it, name.pt,
            substanceId.replacingOccurrences(of: "-", with: " ")
        ]
        // Common salt / formulation suffixes stripped at match time; keep base forms only.
        raw = raw.filter { !$0.isEmpty }
        return raw.map { normalize($0) }.filter { !$0.isEmpty }
    }

    private static func exactNameMatch(
        query: String,
        candidate: CatalogCandidate
    ) -> PrescriptionPokeDrugMatch? {
        for alias in candidate.aliases where alias == query {
            return PrescriptionPokeDrugMatch(
                substanceId: candidate.substanceId,
                catalogName: candidate.name,
                matchKind: .exactName,
                confidence: 1.0
            )
        }
        return nil
    }

    private static func containsNameMatch(
        query: String,
        candidate: CatalogCandidate
    ) -> PrescriptionPokeDrugMatch? {
        // Prefer longer aliases to avoid short false positives (e.g. "thc" in "methyl...").
        let aliases = candidate.aliases.sorted { $0.count > $1.count }
        for alias in aliases {
            guard alias.count >= 4 else { continue }
            if query == alias { continue } // handled by exact
            if query.contains(alias) {
                // "propranolol hcl 40 mg" contains "propranolol"
                let ratio = Double(alias.count) / Double(max(query.count, 1))
                let confidence = min(0.95, 0.7 + 0.25 * ratio)
                return PrescriptionPokeDrugMatch(
                    substanceId: candidate.substanceId,
                    catalogName: candidate.name,
                    matchKind: .containsName,
                    confidence: confidence
                )
            }
            if alias.contains(query), query.count >= 5 {
                // User typed a short form of a longer catalog name
                let ratio = Double(query.count) / Double(max(alias.count, 1))
                let confidence = min(0.9, 0.65 + 0.25 * ratio)
                return PrescriptionPokeDrugMatch(
                    substanceId: candidate.substanceId,
                    catalogName: candidate.name,
                    matchKind: .containsName,
                    confidence: confidence
                )
            }
        }
        return nil
    }

    private static func tokenOverlapMatch(
        query: String,
        candidate: CatalogCandidate
    ) -> PrescriptionPokeDrugMatch? {
        let queryTokens = significantTokens(query)
        guard !queryTokens.isEmpty else { return nil }

        var bestOverlap = 0.0
        for alias in candidate.aliases {
            let aliasTokens = significantTokens(alias)
            guard !aliasTokens.isEmpty else { continue }
            let intersection = queryTokens.intersection(aliasTokens)
            guard !intersection.isEmpty else { continue }
            // Require at least one meaningful shared token ≥ 4 chars (or full alias token match).
            let meaningful = intersection.filter { $0.count >= 4 }
            guard !meaningful.isEmpty else { continue }
            let overlap = Double(meaningful.count)
                / Double(max(aliasTokens.count, queryTokens.count))
            bestOverlap = max(bestOverlap, overlap)
        }

        guard bestOverlap >= 0.4 else { return nil }
        return PrescriptionPokeDrugMatch(
            substanceId: candidate.substanceId,
            catalogName: candidate.name,
            matchKind: .tokenOverlap,
            confidence: min(0.85, 0.55 + bestOverlap * 0.35)
        )
    }

    // MARK: - Normalization

    /// Lowercase, strip diacritics, drop dose/unit noise, keep letters/digits/spaces/hyphens.
    public static func normalize(_ raw: String) -> String {
        let folded = raw
            .folding(options: [.diacriticInsensitive, .caseInsensitive], locale: .current)
            .lowercased()

        // Drop common dose patterns early: "40mg", "10 mg", "0.5 mg/ml"
        var s = folded.replacingOccurrences(
            of: #"\b\d+([.,]\d+)?\s*(mg|mcg|µg|ug|g|ml|%|iu|units?)\b"#,
            with: " ",
            options: .regularExpression
        )

        // Drop salt / formulation suffixes that rarely appear in catalog names.
        let noise: [String] = [
            "hcl", "hydrochloride", "hydrobromide", "sulfate", "sulphate",
            "sodium", "potassium", "maleate", "tartrate", "citrate",
            "er", "xr", "sr", "cr", "la", "tablet", "tablets", "capsule",
            "capsules", "oral", "solution", "injection", "extended", "release"
        ]
        for token in noise {
            s = s.replacingOccurrences(
                of: "\\b\(token)\\b",
                with: " ",
                options: .regularExpression
            )
        }

        let allowed = CharacterSet.alphanumerics.union(CharacterSet(charactersIn: " -"))
        let scalars = s.unicodeScalars.map { allowed.contains($0) ? Character($0) : " " }
        let cleaned = String(scalars)
            .replacingOccurrences(of: #"\s+"#, with: " ", options: .regularExpression)
            .trimmingCharacters(in: .whitespacesAndNewlines)
        return cleaned
    }

    private static func significantTokens(_ normalized: String) -> Set<String> {
        let stop: Set<String> = [
            "the", "and", "for", "with", "de", "la", "le", "les", "des", "du"
        ]
        return Set(
            normalized
                .split(separator: " ")
                .map(String.init)
                .filter { $0.count >= 3 && !stop.contains($0) }
        )
    }
}
