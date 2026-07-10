import SwiftUI
import SwiftData
import BonhommeCore

/// User-managed prescriptions with **explicit consent** for HealthKit clinical import.
///
/// Legal/safety: not medical advice; confirm with a clinician. No pharmacy website scraping.
struct PrescriptionsView: View {
    @Environment(AppState.self) private var appState
    @Environment(\.modelContext) private var modelContext

    @Query(filter: #Predicate<MedicationSchedule> { $0.isActive }, sort: \MedicationSchedule.createdAt)
    private var schedules: [MedicationSchedule]

    @State private var showingManualEntry = false
    @State private var showRevokeConfirm = false

    // Manual entry fields
    @State private var manualName = ""
    @State private var manualDose = ""
    @State private var manualUnit = "mg"
    @State private var manualHour = 8
    @State private var manualPharmacyNotes = ""

    private var service: MedicationPrescriptionService {
        appState.prescriptionService
    }

    var body: some View {
        List {
            consentSection
            privacySection
            if service.consent.isValidForCurrentPolicy {
                syncSection
                medicationsSection
                schedulesSection
            } else {
                lockedSection
            }
            auditSection
        }
        .navigationTitle(LocalizedString(en: "Prescriptions", fr: "Ordonnances").localized)
        .sheet(isPresented: $showingManualEntry) {
            manualEntrySheet
        }
        .confirmationDialog(
            LocalizedString(
                en: "Revoke medication data access?",
                fr: "Révoquer l'accès aux données de médicaments?"
            ).localized,
            isPresented: $showRevokeConfirm,
            titleVisibility: .visible
        ) {
            Button(LocalizedString(en: "Revoke", fr: "Révoquer").localized, role: .destructive) {
                service.revokeConsent()
                mirrorPreferences()
            }
            Button(LocalizedString(en: "Cancel", fr: "Annuler").localized, role: .cancel) {}
        }
        .onAppear {
            service.refreshConsentState()
        }
    }

    // MARK: - Consent

    private var consentSection: some View {
        Section {
            Toggle(isOn: Binding(
                get: { service.consent.isValidForCurrentPolicy },
                set: { newValue in
                    if newValue {
                        Task {
                            await service.grantConsent(requestHealthKit: true)
                            mirrorPreferences()
                        }
                    } else {
                        showRevokeConfirm = true
                    }
                }
            )) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(LocalizedString(
                        en: "Allow medication data access",
                        fr: "Autoriser l'accès aux données de médicaments"
                    ).localized)
                    .font(.system(size: 16, weight: .medium))

                    Text(LocalizedString(
                        en: "Required before reading Health clinical medication records or syncing meds to CareKit.",
                        fr: "Requis avant de lire les dossiers cliniques Santé ou de synchroniser les médicaments avec CareKit."
                    ).localized)
                    .font(.system(size: 13))
                    .foregroundStyle(.secondary)
                }
            }
            .tint(.cyan)

            if let grantedAt = service.consent.grantedAt, service.consent.isGranted {
                LabeledContent(
                    LocalizedString(en: "Consent granted", fr: "Consentement accordé").localized
                ) {
                    Text(grantedAt, style: .date)
                        .foregroundStyle(.secondary)
                }
                if let version = service.consent.policyVersion {
                    LabeledContent(
                        LocalizedString(en: "Policy version", fr: "Version de la politique").localized
                    ) {
                        Text(version)
                            .foregroundStyle(.secondary)
                    }
                }
            }
        } header: {
            Label(
                LocalizedString(en: "Explicit Consent", fr: "Consentement explicite").localized,
                systemImage: "hand.raised.fill"
            )
        }
    }

    // MARK: - Privacy copy

    private var privacySection: some View {
        Section {
            VStack(alignment: .leading, spacing: 8) {
                Text(LocalizedString(
                    en: "This is not medical advice. Medications you import or enter are user-managed — always confirm with your clinician or pharmacist.",
                    fr: "Ceci n'est pas un avis médical. Les médicaments importés ou saisis sont gérés par vous — confirmez toujours avec votre clinicien ou pharmacien."
                ).localized)
                .font(.system(size: 13))

                Text(LocalizedString(
                    en: "NATURaL only uses Apple Health clinical records (when you connect a health institution) and what you type yourself. We never log into pharmacy accounts or scrape pharmacy websites.",
                    fr: "NATURaL utilise uniquement les dossiers cliniques Apple Santé (si vous connectez un établissement) et ce que vous saisissez. Nous ne nous connectons jamais aux comptes de pharmacie ni ne collectons leurs sites."
                ).localized)
                .font(.system(size: 13))
                .foregroundStyle(.secondary)
            }
            .padding(.vertical, 4)
        } header: {
            Label(
                LocalizedString(en: "Privacy & Safety", fr: "Confidentialité et sécurité").localized,
                systemImage: "lock.shield"
            )
        }
    }

    // MARK: - Locked (no consent)

    private var lockedSection: some View {
        Section {
            ContentUnavailableView {
                Label(
                    LocalizedString(en: "Consent required", fr: "Consentement requis").localized,
                    systemImage: "cross.case"
                )
            } description: {
                Text(LocalizedString(
                    en: "Turn on medication data access above to import clinical records or manage prescriptions here. Manual entry becomes available after consent so all clinical workflows share one gate.",
                    fr: "Activez l'accès aux données de médicaments ci-dessus pour importer les dossiers cliniques ou gérer les ordonnances. La saisie manuelle est disponible après consentement afin qu'un seul consentement couvre ce flux."
                ).localized)
            }
        }
    }

    // MARK: - Sync

    private var syncSection: some View {
        Section {
            Button {
                Task {
                    await service.syncPrescriptions(modelContext: modelContext)
                    mirrorPreferences()
                }
            } label: {
                HStack {
                    if service.isSyncing {
                        ProgressView()
                            .padding(.trailing, 8)
                    }
                    Text(LocalizedString(
                        en: "Sync from Health / CareKit",
                        fr: "Synchroniser depuis Santé / CareKit"
                    ).localized)
                }
            }
            .disabled(service.isSyncing)

            if let last = service.lastSyncDate {
                LabeledContent(
                    LocalizedString(en: "Last sync", fr: "Dernière sync").localized
                ) {
                    Text(last, style: .relative)
                        .foregroundStyle(.secondary)
                }
            }

            if let msg = service.importStatusMessage {
                Text(msg)
                    .font(.system(size: 12))
                    .foregroundStyle(.secondary)
            }

            if let err = service.lastSyncError {
                Text(err)
                    .font(.system(size: 12))
                    .foregroundStyle(.red)
            }

            LabeledContent(
                LocalizedString(en: "Clinical HK type", fr: "Type clinique HK").localized
            ) {
                Text(HealthKitManager.isClinicalMedicationTypeAvailable
                     ? LocalizedString(en: "Available", fr: "Disponible").localized
                     : LocalizedString(en: "Unavailable", fr: "Indisponible").localized)
                    .foregroundStyle(.secondary)
            }
        } header: {
            Label(
                LocalizedString(en: "Import", fr: "Importation").localized,
                systemImage: "arrow.triangle.2.circlepath"
            )
        } footer: {
            Text(LocalizedString(
                en: "OS limits: clinical medication records need Health Records entitlement, a connected health institution in the Health app, and may be empty outside supported regions. Manual entry always works as fallback.",
                fr: "Limites OS : les dossiers cliniques de médicaments nécessitent l'entitlement Health Records, un établissement connecté dans Santé, et peuvent être vides hors des régions prises en charge. La saisie manuelle reste le secours."
            ).localized)
        }
    }

    // MARK: - Medications list

    private var medicationsSection: some View {
        Section {
            let meds = service.trackedMedications
            if meds.isEmpty && schedules.isEmpty {
                Text(LocalizedString(
                    en: "No medications yet. Sync clinical records or add one manually.",
                    fr: "Aucun médicament pour l'instant. Synchronisez les dossiers cliniques ou ajoutez-en un manuellement."
                ).localized)
                .foregroundStyle(.secondary)
            } else {
                ForEach(meds) { med in
                    // Consent already gates this section; only link when PokeDrug can match.
                    medicationRow(med)
                }
            }

            Button {
                showingManualEntry = true
            } label: {
                Label(
                    LocalizedString(en: "Add medication manually", fr: "Ajouter un médicament manuellement").localized,
                    systemImage: "plus.circle"
                )
            }
        } header: {
            Label(
                LocalizedString(en: "Medications", fr: "Médicaments").localized,
                systemImage: "pills"
            )
        } footer: {
            Text(LocalizedString(
                en: "When a name matches the PokeDrug catalog, open it for species, type matchup, expected drug-response, and binding-entropy hints.",
                fr: "Si un nom correspond au catalogue PokeDrug, ouvrez-le pour l'espèce, l'affrontement de types, la réponse médicamenteuse attendue et les indices d'entropie de liaison."
            ).localized)
        }
    }

    @ViewBuilder
    private func medicationRow(_ med: MedicationProfile) -> some View {
        let pokeMatch = PrescriptionPokeDrugBridge.match(
            medicationId: med.id,
            localizedName: med.name
        ) ?? PrescriptionPokeDrugBridge.match(name: med.name.localized, medicationId: med.id)

        let row = VStack(alignment: .leading, spacing: 4) {
            HStack(alignment: .firstTextBaseline) {
                Text(med.name.localized)
                    .font(.system(size: 16, weight: .semibold))
                if pokeMatch != nil {
                    Image(systemName: "atom")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(.purple)
                        .accessibilityLabel(LocalizedString(
                            en: "PokeDrug insights available",
                            fr: "Aperçus PokeDrug disponibles"
                        ).localized)
                }
            }
            HStack {
                Text(med.formattedDose)
                    .font(.system(size: 13))
                    .foregroundStyle(.secondary)
                Spacer()
                Text(med.source == .clinicalRecord
                     ? LocalizedString(en: "Clinical", fr: "Clinique").localized
                     : LocalizedString(en: "Manual", fr: "Manuel").localized)
                    .font(.system(size: 12, weight: .medium))
                    .padding(.horizontal, 8)
                    .padding(.vertical, 2)
                    .background(
                        (med.source == .clinicalRecord ? Color.blue : Color.green)
                            .opacity(0.15),
                        in: Capsule()
                    )
                    .foregroundStyle(med.source == .clinicalRecord ? .blue : .green)
            }
            if let pokeMatch {
                pokeDrugHintBar(pokeMatch)
            }
        }
        .padding(.vertical, 2)

        if let pokeMatch, service.consent.isValidForCurrentPolicy {
            NavigationLink {
                PokeDrugSubstanceInsightView(
                    match: pokeMatch,
                    medicationDisplayName: med.name.localized
                )
            } label: {
                row
            }
        } else {
            row
        }
    }

    /// Compact BindingEntropy / species teaser on the list row.
    private func pokeDrugHintBar(_ match: PrescriptionPokeDrugMatch) -> some View {
        HStack(spacing: 6) {
            if let species = match.species {
                Text(species.primaryType.rawValue.capitalized)
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(.purple)
            } else if match.pharmacokineticProfile != nil {
                Text(LocalizedString(en: "PK profile", fr: "Profil PK").localized)
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(.purple)
            }
            if let binding = match.bindingEntropyProfile {
                Text("·")
                    .foregroundStyle(.tertiary)
                Text(String(format: "ΔS %+.1f bit", binding.expectedDeltaSBits))
                    .font(.system(size: 11, design: .monospaced))
                    .foregroundStyle(.secondary)
            }
            Spacer(minLength: 0)
            Text(LocalizedString(en: "Insights", fr: "Aperçus").localized)
                .font(.system(size: 11, weight: .medium))
                .foregroundStyle(.purple.opacity(0.9))
        }
        .padding(.top, 2)
        .accessibilityElement(children: .combine)
        .accessibilityHint(LocalizedString(
            en: "Opens PokeDrug species, matchup, and drug-response insights",
            fr: "Ouvre l'espèce PokeDrug, l'affrontement et la réponse médicamenteuse"
        ).localized)
    }

    // MARK: - Schedules (SwiftData)

    private var schedulesSection: some View {
        Section {
            if schedules.isEmpty {
                Text(LocalizedString(
                    en: "No reminder schedules.",
                    fr: "Aucun horaire de rappel."
                ).localized)
                .foregroundStyle(.secondary)
            } else {
                ForEach(schedules) { schedule in
                    scheduleRow(schedule)
                }
            }
        } header: {
            Label(
                LocalizedString(en: "Schedules", fr: "Horaires").localized,
                systemImage: "clock"
            )
        }
    }

    @ViewBuilder
    private func scheduleRow(_ schedule: MedicationSchedule) -> some View {
        let pokeMatch = PrescriptionPokeDrugBridge.match(
            name: schedule.name,
            medicationId: schedule.medicationId
        )

        let row = VStack(alignment: .leading, spacing: 4) {
            HStack(alignment: .firstTextBaseline) {
                Text(schedule.name)
                    .font(.system(size: 15, weight: .medium))
                if pokeMatch != nil {
                    Image(systemName: "atom")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundStyle(.purple)
                }
            }
            Text("\(schedule.formattedDose) · \(schedule.formattedSchedule.isEmpty ? "—" : schedule.formattedSchedule)")
                .font(.system(size: 13))
                .foregroundStyle(.secondary)
            if let notes = schedule.notes, !notes.isEmpty {
                Text(notes)
                    .font(.system(size: 12))
                    .foregroundStyle(.tertiary)
                    .lineLimit(2)
            }
            if let pokeMatch {
                pokeDrugHintBar(pokeMatch)
            }
        }

        if let pokeMatch, service.consent.isValidForCurrentPolicy {
            NavigationLink {
                PokeDrugSubstanceInsightView(
                    match: pokeMatch,
                    medicationDisplayName: schedule.name
                )
            } label: {
                row
            }
        } else {
            row
        }
    }

    // MARK: - Audit (grant/revoke strings)

    private var auditSection: some View {
        Section {
            let log = service.consentStore.auditLog.suffix(8).reversed()
            if log.isEmpty {
                Text(LocalizedString(en: "No consent events yet.", fr: "Aucun événement de consentement.").localized)
                    .foregroundStyle(.secondary)
            } else {
                ForEach(Array(log)) { entry in
                    Text(entry.auditString)
                        .font(.system(size: 11, design: .monospaced))
                        .foregroundStyle(.secondary)
                }
            }
        } header: {
            Label(
                LocalizedString(en: "Consent audit", fr: "Journal de consentement").localized,
                systemImage: "list.bullet.rectangle"
            )
        }
    }

    // MARK: - Manual entry sheet

    private var manualEntrySheet: some View {
        NavigationStack {
            Form {
                Section {
                    TextField(
                        LocalizedString(en: "Medication name", fr: "Nom du médicament").localized,
                        text: $manualName
                    )
                    HStack {
                        TextField(
                            LocalizedString(en: "Dose", fr: "Dose").localized,
                            text: $manualDose
                        )
                        .keyboardType(.decimalPad)
                        TextField(
                            LocalizedString(en: "Unit", fr: "Unité").localized,
                            text: $manualUnit
                        )
                        .frame(width: 80)
                    }
                    Stepper(
                        value: $manualHour,
                        in: 0...23
                    ) {
                        Text(LocalizedString(
                            en: "Reminder hour: \(manualHour):00",
                            fr: "Heure de rappel : \(manualHour):00"
                        ).localized)
                    }
                } header: {
                    Text(LocalizedString(en: "Medication", fr: "Médicament").localized)
                }

                Section {
                    TextField(
                        LocalizedString(
                            en: "Pharmacy / clinician notes (optional)",
                            fr: "Notes pharmacie / clinicien (optionnel)"
                        ).localized,
                        text: $manualPharmacyNotes,
                        axis: .vertical
                    )
                    .lineLimit(2...4)
                } footer: {
                    Text(LocalizedString(
                        en: "Free-text notes only — never enter pharmacy passwords. Not medical advice.",
                        fr: "Notes en texte libre seulement — n'entrez jamais de mots de passe de pharmacie. Ce n'est pas un avis médical."
                    ).localized)
                }
            }
            .navigationTitle(LocalizedString(en: "Manual entry", fr: "Saisie manuelle").localized)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(LocalizedString(en: "Cancel", fr: "Annuler").localized) {
                        showingManualEntry = false
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(LocalizedString(en: "Save", fr: "Enregistrer").localized) {
                        saveManual()
                    }
                    .disabled(manualName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
        }
        .presentationDetents([.medium, .large])
    }

    private func saveManual() {
        let dose = Double(manualDose.replacingOccurrences(of: ",", with: ".")) ?? 0
        _ = service.addManualMedication(
            name: manualName.trimmingCharacters(in: .whitespacesAndNewlines),
            doseValue: dose,
            doseUnit: manualUnit.trimmingCharacters(in: .whitespacesAndNewlines),
            scheduledHours: [manualHour],
            pharmacyNotes: manualPharmacyNotes.isEmpty ? nil : manualPharmacyNotes,
            modelContext: modelContext
        )
        manualName = ""
        manualDose = ""
        manualUnit = "mg"
        manualHour = 8
        manualPharmacyNotes = ""
        showingManualEntry = false

        Task {
            // Best-effort CareKit sync after manual add (still consent-gated inside service)
            await service.syncPrescriptions(modelContext: modelContext)
        }
    }

    private func mirrorPreferences() {
        let descriptor = FetchDescriptor<UserPreferences>()
        if let prefs = try? modelContext.fetch(descriptor).first {
            prefs.applyClinicalConsent(service.consent)
            try? modelContext.save()
        } else {
            let prefs = UserPreferences()
            prefs.applyClinicalConsent(service.consent)
            modelContext.insert(prefs)
            try? modelContext.save()
        }
    }
}
