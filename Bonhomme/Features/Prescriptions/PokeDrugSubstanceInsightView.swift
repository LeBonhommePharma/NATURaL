import SwiftUI
import BonhommeCore

/// Deep-link destination from Prescriptions when a medication resolves to a
/// PokeDrug species / PK / BindingEntropyProfile entry.
///
/// Surfaces:
/// - Species (type, scaffold, stats, flavor)
/// - Matchup (scaffold effectiveness vs primary types)
/// - Drug-response expectations (PK ΔH, onset, mechanism)
/// - Binding entropy + cross-domain hint when available
///
/// Not medical advice. Requires clinical consent at the call site.
struct PokeDrugSubstanceInsightView: View {
    let match: PrescriptionPokeDrugMatch
    /// Original free-text medication name from the prescription list.
    let medicationDisplayName: String

    private var species: PokeDrugSpecies? { match.species }
    private var pk: PharmacokineticProfile? { match.pharmacokineticProfile }
    private var binding: BindingEntropyProfile? { match.bindingEntropyProfile }

    var body: some View {
        List {
            headerSection
            if let species {
                speciesSection(species)
                matchupSection(species)
            }
            if let pk {
                drugResponseSection(pk)
            }
            if let binding {
                bindingEntropySection(binding)
            }
            if species == nil && pk == nil && binding == nil {
                ContentUnavailableView {
                    Label(
                        LocalizedString(en: "No insights", fr: "Aucun aperçu").localized,
                        systemImage: "questionmark.circle"
                    )
                } description: {
                    Text(LocalizedString(
                        en: "This name matched a catalog key but no PokeDrug surfaces are populated yet.",
                        fr: "Ce nom correspond à une clé du catalogue, mais aucune surface PokeDrug n'est encore renseignée."
                    ).localized)
                }
            }
            disclaimerSection
        }
        .navigationTitle(match.catalogName.localized)
        .navigationBarTitleDisplayMode(.inline)
    }

    // MARK: - Header

    private var headerSection: some View {
        Section {
            VStack(alignment: .leading, spacing: 8) {
                if medicationDisplayName.localizedCaseInsensitiveCompare(match.catalogName.localized) != .orderedSame {
                    LabeledContent(
                        LocalizedString(en: "Prescription", fr: "Ordonnance").localized
                    ) {
                        Text(medicationDisplayName)
                            .foregroundStyle(.secondary)
                    }
                }

                LabeledContent(
                    LocalizedString(en: "Substance ID", fr: "ID substance").localized
                ) {
                    Text(match.substanceId)
                        .font(.system(.body, design: .monospaced))
                        .foregroundStyle(.secondary)
                }

                LabeledContent(
                    LocalizedString(en: "Match", fr: "Correspondance").localized
                ) {
                    Text(matchLabel)
                        .foregroundStyle(.secondary)
                }
            }
        } header: {
            Label(
                LocalizedString(en: "PokeDrug Link", fr: "Lien PokeDrug").localized,
                systemImage: "link"
            )
        }
    }

    private var matchLabel: String {
        let pct = Int((match.confidence * 100).rounded())
        let kind: String
        switch match.matchKind {
        case .substanceId:
            kind = LocalizedString(en: "ID", fr: "ID").localized
        case .exactName:
            kind = LocalizedString(en: "Exact name", fr: "Nom exact").localized
        case .containsName:
            kind = LocalizedString(en: "Name contains", fr: "Nom contenu").localized
        case .tokenOverlap:
            kind = LocalizedString(en: "Token match", fr: "Jetons").localized
        }
        return "\(kind) · \(pct)%"
    }

    // MARK: - Species

    private func speciesSection(_ species: PokeDrugSpecies) -> some View {
        Section {
            Text(species.flavorText.localized)
                .font(.system(size: 14))
                .foregroundStyle(.secondary)

            HStack(spacing: 8) {
                typeChip(species.primaryType)
                if let secondary = species.secondaryType {
                    typeChip(secondary)
                }
            }

            LabeledContent(
                LocalizedString(en: "Scaffold", fr: "Échafaudage").localized
            ) {
                Text(species.scaffold.displayName.localized)
                    .foregroundStyle(.secondary)
            }

            if let habitat = species.habitat {
                LabeledContent(
                    LocalizedString(en: "Habitat", fr: "Habitat").localized
                ) {
                    Text(habitat.displayName.localized)
                        .foregroundStyle(.secondary)
                }
            }

            LabeledContent("#") {
                Text(String(format: "%03d", species.dexNumber))
                    .font(.system(.body, design: .monospaced))
                    .foregroundStyle(.secondary)
            }

            statsRow(species.stats)
        } header: {
            Label(
                LocalizedString(en: "Species", fr: "Espèce").localized,
                systemImage: "leaf.fill"
            )
        }
    }

    private func typeChip(_ type: PokeDrugType) -> some View {
        Text(type.rawValue.capitalized)
            .font(.system(size: 12, weight: .semibold))
            .padding(.horizontal, 10)
            .padding(.vertical, 4)
            .background(Color(hex: type.color).opacity(0.22), in: Capsule())
            .foregroundStyle(Color(hex: type.color))
    }

    private func statsRow(_ stats: PokeDrugStats) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(LocalizedString(en: "Base stats", fr: "Stats de base").localized)
                .font(.system(size: 13, weight: .medium))
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())], spacing: 8) {
                statCell("HP", stats.hp)
                statCell("Atk", stats.attack)
                statCell("Def", stats.defense)
                statCell("SpA", stats.specialAttack)
                statCell("SpD", stats.specialDefense)
                statCell("Spe", stats.speed)
            }
        }
        .padding(.vertical, 4)
    }

    private func statCell(_ label: String, _ value: Int) -> some View {
        VStack(spacing: 2) {
            Text(label)
                .font(.system(size: 11))
                .foregroundStyle(.secondary)
            Text(String(repeating: "★", count: value) + String(repeating: "☆", count: max(0, 5 - value)))
                .font(.system(size: 11))
                .foregroundStyle(.orange)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 6)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 8))
    }

    // MARK: - Matchup

    private func matchupSection(_ species: PokeDrugSpecies) -> some View {
        let targets = Array(Set(species.types + species.scaffold.primaryTypes))
            .sorted { $0.rawValue < $1.rawValue }

        return Section {
            if targets.isEmpty {
                Text(LocalizedString(en: "No type targets.", fr: "Aucune cible de type.").localized)
                    .foregroundStyle(.secondary)
            } else {
                ForEach(targets, id: \.self) { target in
                    let effectiveness = PokeDrugMatchup.effectiveness(
                        scaffold: species.scaffold,
                        against: target
                    )
                    HStack {
                        typeChip(target)
                        Spacer()
                        Text(effectiveness.starRating)
                            .font(.system(size: 13, weight: .medium, design: .monospaced))
                            .foregroundStyle(effectivenessColor(effectiveness))
                    }
                }
            }

            Text(LocalizedString(
                en: "Matchups reflect structural complementarity (published Ki / crystal data), not clinical recommendations.",
                fr: "Les affrontements reflètent la complémentarité structurelle (Ki / structures publiées), pas des recommandations cliniques."
            ).localized)
            .font(.system(size: 12))
            .foregroundStyle(.tertiary)
        } header: {
            Label(
                LocalizedString(en: "Type Matchup", fr: "Affrontement de types").localized,
                systemImage: "arrow.left.arrow.right"
            )
        }
    }

    private func effectivenessColor(_ e: TypeEffectiveness) -> Color {
        switch e {
        case .superEffective: return .green
        case .effective: return .mint
        case .weaklyEffective: return .orange
        case .notEffective, .immune: return .secondary
        }
    }

    // MARK: - Drug response (PK expectations)

    private func drugResponseSection(_ pk: PharmacokineticProfile) -> some View {
        Section {
            LabeledContent(
                LocalizedString(en: "Mechanism", fr: "Mécanisme").localized
            ) {
                Text(mechanismLabel(pk.mechanism))
                    .foregroundStyle(.secondary)
            }

            LabeledContent(
                LocalizedString(en: "Expected ΔH", fr: "ΔH attendu").localized
            ) {
                Text(String(
                    format: "%+.2f … %+.2f bits",
                    pk.expectedDeltaHRange.lowerBound,
                    pk.expectedDeltaHRange.upperBound
                ))
                .font(.system(.body, design: .monospaced))
                .foregroundStyle(.secondary)
            }

            LabeledContent(
                LocalizedString(en: "Onset", fr: "Début d'effet").localized
            ) {
                Text(String(format: "%.0f min", pk.onsetMinutes))
                    .foregroundStyle(.secondary)
            }

            LabeledContent(
                LocalizedString(en: "Tmax", fr: "Tmax").localized
            ) {
                Text(String(format: "%.0f min", pk.tmaxMinutes))
                    .foregroundStyle(.secondary)
            }

            LabeledContent(
                LocalizedString(en: "Half-life", fr: "Demi-vie").localized
            ) {
                Text(String(format: "%.0f min", pk.halfLifeMinutes))
                    .foregroundStyle(.secondary)
            }

            LabeledContent(
                LocalizedString(en: "Class", fr: "Classe").localized
            ) {
                Text(pk.therapeuticClass.rawValue)
                    .foregroundStyle(.secondary)
            }

            Text(LocalizedString(
                en: "DrugResponseAnalyzer compares post-dose HRV entropy to this profile after you log a dose during a session — not from the prescription list alone.",
                fr: "DrugResponseAnalyzer compare l'entropie HRV post-dose à ce profil après un enregistrement de dose en séance — pas à partir de la seule liste d'ordonnances."
            ).localized)
            .font(.system(size: 12))
            .foregroundStyle(.tertiary)
        } header: {
            Label(
                LocalizedString(en: "Drug Response", fr: "Réponse médicamenteuse").localized,
                systemImage: "waveform.path.ecg"
            )
        }
    }

    private func mechanismLabel(_ m: AutonomicMechanism) -> String {
        switch m {
        case .sympathomimetic:
            return LocalizedString(en: "Sympathomimetic (collapse)", fr: "Sympathomimétique (collapse)").localized
        case .parasympathomimetic:
            return LocalizedString(en: "Parasympathomimetic (expansion)", fr: "Parasympathomimétique (expansion)").localized
        case .mixed:
            return LocalizedString(en: "Mixed / biphasic", fr: "Mixte / biphasique").localized
        case .unknown:
            return LocalizedString(en: "Unknown", fr: "Inconnu").localized
        }
    }

    // MARK: - Binding entropy + cross-domain

    private func bindingEntropySection(_ binding: BindingEntropyProfile) -> some View {
        Section {
            LabeledContent(
                LocalizedString(en: "ΔS_config", fr: "ΔS_config").localized
            ) {
                Text(String(format: "%+.2f bits", binding.expectedDeltaSBits))
                    .font(.system(.body, design: .monospaced))
                    .foregroundStyle(.secondary)
            }

            LabeledContent(
                LocalizedString(en: "−TΔS (298 K)", fr: "−TΔS (298 K)").localized
            ) {
                Text(String(format: "%.2f kcal/mol", binding.expectedEntropyPenaltyKcal))
                    .font(.system(.body, design: .monospaced))
                    .foregroundStyle(.secondary)
            }

            LabeledContent(
                LocalizedString(en: "Rotatable bonds", fr: "Liaisons rotatives").localized
            ) {
                Text("\(binding.rotatableBondCount)")
                    .foregroundStyle(.secondary)
            }

            Text(binding.reference)
                .font(.system(size: 12))
                .foregroundStyle(.secondary)

            // Cross-domain hint (FlexAID ΔS ↔ HRV ΔH)
            VStack(alignment: .leading, spacing: 6) {
                Label(
                    LocalizedString(
                        en: "Cross-domain hint",
                        fr: "Indice interdomaines"
                    ).localized,
                    systemImage: "arrow.triangle.branch"
                )
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(.cyan)

                Text(crossDomainHint(binding))
                    .font(.system(size: 13))
                    .foregroundStyle(.secondary)
            }
            .padding(.vertical, 4)
        } header: {
            Label(
                LocalizedString(en: "Binding Entropy", fr: "Entropie de liaison").localized,
                systemImage: "atom"
            )
        }
    }

    private func crossDomainHint(_ binding: BindingEntropyProfile) -> String {
        let ds = String(format: "%.1f", abs(binding.expectedDeltaSBits))
        let penalty = String(format: "%.1f", binding.expectedEntropyPenaltyKcal)
        return LocalizedString(
            en: "Molecular |ΔS_config| ≈ \(ds) bits (−TΔS ≈ \(penalty) kcal/mol). Larger configurational penalties are hypothesized to pair with larger |ΔH_hrv| collapses/expansions when CrossDomainValidator has ≥5 paired observations (p < 0.05).",
            fr: "|ΔS_config| moléculaire ≈ \(ds) bits (−TΔS ≈ \(penalty) kcal/mol). Les pénalités conformationnelles plus grandes devraient corréler avec de plus grands |ΔH_hrv| lorsque CrossDomainValidator dispose de ≥5 paires (p < 0,05)."
        ).localized
    }

    // MARK: - Disclaimer

    private var disclaimerSection: some View {
        Section {
            Text(LocalizedString(
                en: "Educational / research framing only — not medical advice, not a dosing guide, and not a substitute for your clinician or pharmacist.",
                fr: "Cadre éducatif / recherche uniquement — pas un avis médical, pas un guide de posologie, et ne remplace pas votre clinicien ou pharmacien."
            ).localized)
            .font(.system(size: 12))
            .foregroundStyle(.secondary)
        } header: {
            Label(
                LocalizedString(en: "Safety", fr: "Sécurité").localized,
                systemImage: "exclamationmark.shield"
            )
        }
    }
}

// MARK: - Color hex

private extension Color {
    init(hex: String) {
        let cleaned = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: cleaned).scanHexInt64(&int)
        let r, g, b: Double
        switch cleaned.count {
        case 6:
            r = Double((int >> 16) & 0xFF) / 255
            g = Double((int >> 8) & 0xFF) / 255
            b = Double(int & 0xFF) / 255
        default:
            r = 0.5; g = 0.5; b = 0.5
        }
        self.init(red: r, green: g, blue: b)
    }
}
