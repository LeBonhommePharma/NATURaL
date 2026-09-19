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
        return kind
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
            Text(LocalizedString(en: "Illustrative ratings", fr: "Évaluations illustratives").localized)
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
            HStack(spacing: 1) {
                ForEach(0..<5, id: \.self) { index in
                    Image(systemName: index < value ? "star.fill" : "star")
                        .font(.caption2)
                        .foregroundStyle(BrandColor.tangerine)
                }
            }
            .accessibilityElement(children: .ignore)
            .accessibilityLabel("\(label) \(value) of 5")
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
                        Text("\(effectiveness.rawValue) / 4")
                            .font(.system(size: 13, weight: .medium, design: .monospaced))
                            .foregroundStyle(effectivenessColor(effectiveness))
                    }
                }
            }

            Text(LocalizedString(
                en: "These are hand-authored scaffold categories, not measurements of this substance’s affinity, efficacy, or safety. A low rating does not establish absence of binding.",
                fr: "Ces catégories de structures sont définies manuellement, sans mesurer l’affinité, l’efficacité ou la sécurité de cette substance. Un score faible ne démontre pas une absence de liaison."
            ).localized)
            .font(.system(size: 12))
            .foregroundStyle(.tertiary)
        } header: {
            Label(
                LocalizedString(en: "Illustrative scaffold ratings", fr: "Évaluations illustratives des structures").localized,
                systemImage: "arrow.left.arrow.right"
            )
        }
    }

    private func effectivenessColor(_ e: TypeEffectiveness) -> Color {
        switch e {
        case .superEffective: return BrandColor.mint
        case .effective: return BrandColor.aqua
        case .weaklyEffective: return BrandColor.tangerine
        case .notEffective, .immune: return BrandColor.magnesium
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
                LocalizedString(en: "Model ΔH range", fr: "Plage ΔH du modèle").localized
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
                en: "These catalog timings and entropy ranges are model inputs, not your measured response or validated personal predictions. Dose, route, formulation, and individual factors can change timing. A logged dose alone does not establish a drug effect.",
                fr: "Ces durées et plages d’entropie du catalogue sont des entrées de modèle, pas votre réponse mesurée ni des prédictions personnelles validées. La dose, la voie, la formulation et les facteurs individuels peuvent modifier les durées. Une prise consignée ne démontre pas un effet médicamenteux."
            ).localized)
            .font(.system(size: 12))
            .foregroundStyle(.tertiary)
        } header: {
            Label(
                LocalizedString(en: "Catalog model inputs", fr: "Entrées du modèle du catalogue").localized,
                systemImage: "waveform.path.ecg"
            )
        }
    }

    private func mechanismLabel(_ m: AutonomicMechanism) -> String {
        switch m {
        case .sympathomimetic:
            return LocalizedString(en: "Sympathomimetic", fr: "Sympathomimétique").localized
        case .parasympathomimetic:
            return LocalizedString(en: "Parasympathomimetic", fr: "Parasympathomimétique").localized
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
                LocalizedString(en: "Catalog ΔS_config estimate", fr: "Estimation ΔS_config du catalogue").localized
            ) {
                Text(String(format: "%+.2f bits", binding.expectedDeltaSBits))
                    .font(.system(.body, design: .monospaced))
                    .foregroundStyle(.secondary)
            }

            LabeledContent(
                LocalizedString(en: "Catalog −TΔS estimate (298 K)", fr: "Estimation −TΔS du catalogue (298 K)").localized
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

            Text(LocalizedString(
                en: "Unverified catalog estimate. The source note below does not establish the exact value or a measured result for this substance.",
                fr: "Estimation du catalogue non vérifiée. La note source ci-dessous ne démontre ni cette valeur exacte ni une mesure pour cette substance."
            ).localized)
            .font(.footnote)
            .foregroundStyle(.secondary)

            Text(binding.reference)
                .font(.system(size: 12))
                .foregroundStyle(.secondary)

            // Cross-domain hint (FlexAID ΔS ↔ HRV ΔH)
            VStack(alignment: .leading, spacing: 6) {
                Label(
                    LocalizedString(
                        en: "Research hypothesis",
                        fr: "Hypothèse de recherche"
                    ).localized,
                    systemImage: "arrow.triangle.branch"
                )
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(BrandColor.aqua)

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
        return LocalizedString(
            en: "Molecular configurational entropy and HRV entropy describe different distributions. Their association is an exploratory hypothesis; shared units, five pairs, or a small p-value do not validate a drug effect or receptor binding. This page shows catalog inputs, not a paired analysis of your measurements.",
            fr: "L’entropie conformationnelle moléculaire et l’entropie VFC décrivent des distributions différentes. Leur association est une hypothèse exploratoire ; des unités communes, cinq paires ou une petite valeur p ne valident ni un effet médicamenteux ni une liaison aux récepteurs. Cette page présente le catalogue, pas une analyse appariée de vos mesures."
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
