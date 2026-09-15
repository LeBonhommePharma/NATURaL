import SwiftUI
import SwiftData
import BonhommeCore

/// Main home screen showing available workout plans and activity summary.
/// Adapts to iPad with a NavigationSplitView when horizontal size class is regular.
struct HomeView: View {
    @Environment(AppState.self) private var appState
    @Environment(\.horizontalSizeClass) private var sizeClass
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @AppStorage("natural.motionCoachHeroDismissed") private var motionCoachHeroDismissed = false
    @State private var selectedPlan: WorkoutPlan?
    @State private var selectedStyle: YogaStyle?

    var body: some View {
        Group {
            if sizeClass == .regular {
                iPadLayout
            } else {
                phoneLayout
            }
        }
        .fullScreenCover(item: $selectedPlan) { plan in
            NavigationStack {
                WorkoutFlowView(plan: plan, feedbackEngine: appState.feedbackEngine)
            }
            .interactiveDismissDisabled()
        }
        .toolbar {
            ToolbarItemGroup(placement: .topBarTrailing) {
                NavigationLink { HistoryView() } label: {
                    Label(LocalizedString(en: "History", fr: "Historique").localized, systemImage: "clock.arrow.circlepath")
                }
                .accessibilityIdentifier("home.history")
                NavigationLink { AppInformationView() } label: {
                    Label(LocalizedString(en: "About & Privacy", fr: "À propos et confidentialité").localized, systemImage: "info.circle")
                }
                .accessibilityIdentifier("home.about")
            }
        }
    }

    // MARK: - iPad Layout (NavigationSplitView)

    private var iPadLayout: some View {
        NavigationSplitView {
            List(selection: $selectedStyle) {
                // CareKit prescribed yoga workouts (meds surface in Prescriptions)
                if appState.careKitBridge.hasYogaPrescriptions {
                    prescribedSection
                }

                // Style sections
                ForEach(YogaStyle.allCases, id: \.self) { style in
                    NavigationLink(value: style) {
                        HStack {
                            Image(systemName: style.symbolName)
                                .font(.system(size: 20))
                                .foregroundStyle(Color(hue: style.accentHue, saturation: 0.6, brightness: 0.8))
                                .frame(width: 32)

                            VStack(alignment: .leading) {
                                Text(style.localizedName.localized)
                                    .font(.system(size: 16, weight: .medium))
                                Text("\(PoseCatalog.planCount(for: style)) \(LocalizedString(en: "plans", fr: "programmes").localized)")
                                    .font(.system(size: 13))
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                }
            }
            .navigationTitle("NATURaL")
            .listStyle(.sidebar)
        } detail: {
            NavigationStack {
            if let style = selectedStyle {
                StyleDetailView(style: style)
            } else {
                ScrollView {
                    VStack(spacing: 24) {
                        coachHeroCard(compact: true, dismissible: false)
                            .padding(.horizontal, 32)
                            .padding(.top, 24)

                        if appState.persistenceSync.needsAttention {
                            storageStatusCard
                        }

                        VStack(spacing: 16) {
                            Image(systemName: "figure.yoga")
                                .font(.system(size: 52))
                                .foregroundStyle(.cyan.opacity(0.55))
                            Text(LocalizedString(
                                en: "Select a yoga style",
                                fr: "Sélectionnez un style de yoga"
                            ).localized)
                                .font(.system(size: 20, weight: .medium))
                                .foregroundStyle(.secondary)
                        }
                        .padding(.bottom, 32)
                    }
                }
            }
            }
            .id(selectedStyle)
        }
        .task { await loadCareKitPrescriptions() }
    }

    // MARK: - Phone Layout (ScrollView)

    private var phoneLayout: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                // Header
                VStack(alignment: .leading, spacing: 4) {
                    Text("NATURaL")
                        .font(.system(size: 34, weight: .bold, design: .rounded))
                    Text(LocalizedString(en: "A little movement. A little more you.", fr: "Un peu de mouvement. Du temps pour vous.").localized)
                        .font(.system(size: 20, weight: .medium))
                        .foregroundStyle(.secondary)
                }
                .padding(.horizontal)

                if !motionCoachHeroDismissed {
                    coachHeroCard(compact: false, dismissible: true)
                        .padding(.horizontal)
                }

                // CareKit prescribed yoga workouts (meds surface in Prescriptions)
                if appState.careKitBridge.hasYogaPrescriptions {
                    prescribedCardsSection
                }

                // Secondary re-entry / discard affordance when restored session is pending
                // (primary path auto-loads on launch/active; banner is not the sole load gate).
                if let restoredVM = appState.pendingRestoredWorkout {
                    HStack(spacing: 12) {
                        NavigationLink {
                            WorkoutFlowView(restoredViewModel: restoredVM)
                        } label: {
                            resumeBanner(plan: restoredVM.plan)
                        }
                        .buttonStyle(.plain)

                        Button {
                            appState.dismissRestoredWorkout()
                        } label: {
                            Image(systemName: "xmark.circle.fill")
                                .font(.system(size: 28))
                                .foregroundStyle(.secondary)
                        }
                        .buttonStyle(.plain)
                        .accessibilityLabel(LocalizedString(en: "Discard", fr: "Annuler").localized)
                    }
                    .padding(.horizontal)
                }

                Text(LocalizedString(en: "Move in your own way", fr: "Bougez à votre façon").localized)
                    .font(.title2.bold())
                    .padding(.horizontal)
                styleCardGrid

                // Prescriptions / clinical medication consent entry
                prescriptionsEntryCard

                if appState.persistenceSync.needsAttention {
                    storageStatusCard
                }

                // TV connection status
                tvStatusSection
            }
            .padding(.vertical)
        }
        .task { await loadCareKitPrescriptions() }
    }

    // MARK: - On-device storage status

    /// Shown only when durable local storage is unavailable.
    @ViewBuilder
    private var storageStatusCard: some View {
        @Bindable var sync = appState.persistenceSync
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 14) {
                Image(systemName: sync.systemImageName)
                    .font(.system(size: 24))
                    .foregroundStyle(sync.accentColor)
                    .frame(width: 40)

                VStack(alignment: .leading, spacing: 4) {
                    Text(LocalizedString(
                        en: "Data & Storage",
                        fr: "Données et stockage"
                    ).localized)
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundStyle(.primary)

                    Text(sync.settingsDetail)
                        .font(.system(size: 13))
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }

                Spacer(minLength: 0)
            }

            if let feedback = sync.retryFeedback {
                Text(feedback)
                    .font(.system(size: 12))
                    .foregroundStyle(sync.restartRecommended ? Color.green.opacity(0.9) : .secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Button {
                Task { await sync.retryLocalStorage() }
            } label: {
                if sync.isRetrying {
                    ProgressView()
                        .frame(maxWidth: .infinity)
                } else {
                    Text(LocalizedString(en: "Retry storage", fr: "Réessayer le stockage").localized)
                        .frame(maxWidth: .infinity)
                }
            }
            .buttonStyle(.bordered)
            .tint(sync.accentColor)
            .disabled(sync.isRetrying)
        }
        .padding()
        .background(sync.accentColor.opacity(0.08), in: RoundedRectangle(cornerRadius: 16))
        .padding(.horizontal)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(LocalizedString(
            en: "On-device storage status",
            fr: "État du stockage sur cet appareil"
        ).localized)
    }

    // MARK: - Prescriptions entry

    private var prescriptionsEntryCard: some View {
        NavigationLink {
            PrescriptionsView()
        } label: {
            HStack(spacing: 14) {
                Image(systemName: "pills.fill")
                    .font(.system(size: 24))
                    .foregroundStyle(.teal)
                    .frame(width: 40)

                VStack(alignment: .leading, spacing: 4) {
                    Text(LocalizedString(
                        en: "Prescriptions & Consent",
                        fr: "Ordonnances et consentement"
                    ).localized)
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundStyle(.primary)

                    Text(
                        appState.prescriptionService.consent.isValidForCurrentPolicy
                        ? LocalizedString(
                            en: "Medication access on · manage meds & sync",
                            fr: "Accès médicaments activé · gérer et synchroniser"
                        ).localized
                        : LocalizedString(
                            en: "Explicit consent required before clinical reads",
                            fr: "Consentement explicite requis avant lecture clinique"
                        ).localized
                    )
                    .font(.system(size: 13))
                    .foregroundStyle(.secondary)
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .foregroundStyle(.secondary)
            }
            .padding()
            .background(.teal.opacity(0.08), in: RoundedRectangle(cornerRadius: 16))
        }
        .buttonStyle(.plain)
        .padding(.horizontal)
        .accessibilityHint(LocalizedString(
            en: "Opens prescription consent and medication list",
            fr: "Ouvre le consentement et la liste des médicaments"
        ).localized)
    }

    // MARK: - Coach Hero

    private func coachHeroCard(compact: Bool, dismissible: Bool) -> some View {
        let plan = PoseCatalog.beginnerFlow
        return VStack(alignment: .leading, spacing: 18) {
            HStack(alignment: .top) {
                Label(LocalizedString(en: "YOUR DAILY EXHALE", fr: "VOTRE PAUSE RESPIRATION").localized, systemImage: "sun.max")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(Color(red: 1, green: 0.81, blue: 0.48))
                Spacer()
                if dismissible {
                    Button { motionCoachHeroDismissed = true } label: {
                        Image(systemName: "xmark").frame(width: 44, height: 44)
                    }
                    .accessibilityLabel(LocalizedString(en: "Hide featured session", fr: "Masquer la séance en vedette").localized)
                    .foregroundStyle(.white.opacity(0.8))
                }
            }
            Image("Bloom")
                .resizable()
                .scaledToFit()
                .frame(maxWidth: .infinity)
                .frame(height: compact ? 190 : 155)
                .accessibilityHidden(true)
            Text(LocalizedString(en: "Come back to yourself.", fr: "Revenez à vous.").localized)
                .font(.largeTitle.bold())
                .fixedSize(horizontal: false, vertical: true)
            Text(LocalizedString(
                en: "A chair. A breath. A moment to move. Follow a gentle seated practice, at your own pace.",
                fr: "Une chaise. Un souffle. Un moment pour bouger. Suivez une pratique douce, à votre rythme."
            ).localized)
            .font(.body)
            .foregroundStyle(.white.opacity(0.85))
            .fixedSize(horizontal: false, vertical: true)
            Label(formattedDuration(plan.totalDuration), systemImage: "clock")
                .font(.subheadline)
                .foregroundStyle(.white.opacity(0.8))
            Button { selectedPlan = plan } label: {
                HStack {
                    Text(LocalizedString(en: "Begin a gentle session", fr: "Commencer en douceur").localized)
                        .font(.headline)
                    Spacer(minLength: 8)
                    Image(systemName: "arrow.right")
                }
                .foregroundStyle(Color(red: 0.12, green: 0.04, blue: 0.17))
                .padding(18)
                .background(Color(red: 0.52, green: 0.95, blue: 0.79), in: RoundedRectangle(cornerRadius: 18))
            }
            .buttonStyle(.plain)
            .accessibilityIdentifier("home.start")
        }
        .foregroundStyle(.white)
        .padding(compact ? 28 : 24)
        .background(Color(red: 0.11, green: 0.01, blue: 0.15), in: RoundedRectangle(cornerRadius: 28))
    }

    // MARK: - Style Card Grid

    private var styleCardGrid: some View {
        let columns = [GridItem(.adaptive(minimum: dynamicTypeSize.isAccessibilitySize ? 280 : 155), spacing: 12)]

        return LazyVGrid(columns: columns, spacing: 12) {
            ForEach(YogaStyle.allCases, id: \.self) { style in
                NavigationLink {
                    StyleDetailView(style: style)
                } label: {
                    styleCard(style: style)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal)
    }

    private func styleCard(style: YogaStyle) -> some View {
        let planCount = PoseCatalog.planCount(for: style)
        let accentColor = Color(hue: style.accentHue, saturation: 0.6, brightness: 0.85)

        return VStack(spacing: 12) {
            Image(systemName: style.symbolName)
                .font(.system(size: 32))
                .foregroundStyle(accentColor)

            Text(style.localizedName.localized)
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(.primary)
                .multilineTextAlignment(.center)
                .lineLimit(2)
                .minimumScaleFactor(0.8)

            Text("\(planCount) \(LocalizedString(en: "plans", fr: "programmes").localized)")
                .font(.system(size: 13))
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 20)
        .background(
            Color(hue: style.accentHue, saturation: 0.1, brightness: 0.95),
            in: RoundedRectangle(cornerRadius: 16)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .strokeBorder(accentColor.opacity(0.3), lineWidth: 1)
        )
    }

    // MARK: - CareKit Prescribed Section

    private var prescribedSection: some View {
        Section {
            ForEach(appState.careKitBridge.yogaPrescribedTasks, id: \.id) { task in
                if let plan = appState.careKitBridge.resolveWorkoutPlan(for: task) {
                    planRow(plan: plan)
                        .badge(Text(LocalizedString(
                            en: "Prescribed",
                            fr: "Prescrit"
                        ).localized))
                } else {
                    // Orphan CareKit yoga task (plan not in local catalog) — still surface it
                    Label(
                        task.title ?? YogaTaskBuilder.planId(from: task.id),
                        systemImage: "stethoscope"
                    )
                    .foregroundStyle(.secondary)
                }
            }
        } header: {
            Label(
                LocalizedString(en: "Prescribed", fr: "Prescrits").localized,
                systemImage: "stethoscope"
            )
        }
    }

    private var prescribedCardsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "stethoscope")
                    .foregroundStyle(.blue)
                Text(LocalizedString(en: "Prescribed Workouts", fr: "Entraînements prescrits").localized)
                    .font(.system(size: 16, weight: .semibold))
                Spacer()
                Text("\(appState.careKitBridge.yogaPrescribedTasks.count)")
                    .font(.system(size: 13, weight: .semibold, design: .rounded))
                    .foregroundStyle(.blue)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 2)
                    .background(.blue.opacity(0.12), in: Capsule())
            }
            .padding(.horizontal)

            ForEach(appState.careKitBridge.yogaPrescribedTasks, id: \.id) { task in
                if let plan = appState.careKitBridge.resolveWorkoutPlan(for: task) {
                    Button { selectedPlan = plan } label: {
                        prescribedTaskCard(
                            title: plan.name.localized,
                            subtitle: task.instructions,
                            isTappable: true
                        )
                    }
                    .buttonStyle(.plain)
                    .padding(.horizontal)
                } else {
                    // Show prescribed task even when catalog resolve fails
                    prescribedTaskCard(
                        title: task.title ?? YogaTaskBuilder.planId(from: task.id),
                        subtitle: task.instructions
                            ?? LocalizedString(
                                en: "Prescribed plan — open when available in catalog",
                                fr: "Programme prescrit — disponible quand présent au catalogue"
                            ).localized,
                        isTappable: false
                    )
                    .padding(.horizontal)
                }
            }
        }
    }

    private func prescribedTaskCard(
        title: String,
        subtitle: String?,
        isTappable: Bool
    ) -> some View {
        HStack {
            Image(systemName: "figure.yoga")
                .font(.system(size: 24))
                .foregroundStyle(.blue)

            VStack(alignment: .leading) {
                HStack(spacing: 6) {
                    Text(title)
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundStyle(.primary)
                    Text(LocalizedString(en: "Prescribed", fr: "Prescrit").localized)
                        .font(.system(size: 11, weight: .semibold))
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(.blue.opacity(0.15), in: Capsule())
                        .foregroundStyle(.blue)
                }
                if let subtitle, !subtitle.isEmpty {
                    Text(subtitle)
                        .font(.system(size: 13))
                        .foregroundStyle(.secondary)
                        .lineLimit(2)
                }
            }

            Spacer()

            if isTappable {
                Image(systemName: "chevron.right")
                    .foregroundStyle(.secondary)
            }
        }
        .padding()
        .background(.blue.opacity(0.08), in: RoundedRectangle(cornerRadius: 16))
    }

    // MARK: - Resume Banner

    private func resumeBanner(plan: WorkoutPlan) -> some View {
        HStack {
            Image(systemName: "arrow.clockwise.circle.fill")
                .font(.system(size: 28))
                .foregroundStyle(.orange)

            VStack(alignment: .leading) {
                Text(LocalizedString(en: "Continuing session", fr: "Séance en cours").localized)
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundStyle(.primary)
                Text(plan.name.localized)
                    .font(.system(size: 14))
                    .foregroundStyle(.secondary)
            }

            Spacer()

            Image(systemName: "chevron.right")
                .foregroundStyle(.secondary)
        }
        .padding()
        .background(.orange.opacity(0.1), in: RoundedRectangle(cornerRadius: 16))
    }

    // MARK: - iPad Plan Detail

    private func planDetailView(plan: WorkoutPlan) -> some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                // Plan header
                VStack(alignment: .leading, spacing: 8) {
                    Text(plan.name.localized)
                        .font(.system(size: 28, weight: .bold, design: .rounded))

                    Text(plan.description.localized)
                        .font(.system(size: 16))
                        .foregroundStyle(.secondary)

                    HStack(spacing: 16) {
                        Label("\(plan.poseCount) poses", systemImage: "list.number")
                        Label(formattedDuration(plan.totalDuration), systemImage: "clock")
                    }
                    .font(.system(size: 14))
                    .foregroundStyle(.secondary)
                }
                .padding(.horizontal)

                // Pose list
                ForEach(Array(plan.poses.enumerated()), id: \.element.id) { index, pose in
                    HStack(spacing: 12) {
                        Text("\(index + 1)")
                            .font(.system(size: 14, weight: .bold, design: .rounded))
                            .foregroundStyle(.white)
                            .frame(width: 28, height: 28)
                            .background(.cyan, in: Circle())

                        VStack(alignment: .leading) {
                            Text(pose.name.localized)
                                .font(.system(size: 16, weight: .medium))
                            Text("\(Int(pose.durationSeconds))s · \(pose.category.localizedName.localized)")
                                .font(.system(size: 13))
                                .foregroundStyle(.secondary)
                        }

                        Spacer()

                        // Difficulty dots
                        HStack(spacing: 3) {
                            ForEach(0..<pose.difficulty.dotCount, id: \.self) { _ in
                                Circle()
                                    .fill(.cyan)
                                    .frame(width: 6, height: 6)
                            }
                        }
                    }
                    .padding(.horizontal)
                }

                // Start button
                Button { selectedPlan = plan } label: {
                    Text(LocalizedString(en: "Start Workout", fr: "Commencer").localized)
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundStyle(.black)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(.cyan, in: RoundedRectangle(cornerRadius: 14))
                }
                .padding(.horizontal, 40)

                // TV status
                tvStatusSection
            }
            .padding(.vertical)
        }
    }

    // MARK: - Sidebar Plan Row

    private func planRow(plan: WorkoutPlan) -> some View {
        Button { selectedPlan = plan } label: {
            HStack {
                Image(systemName: plan.poses.first?.category.symbolName ?? "figure.yoga")
                    .font(.system(size: 20))
                    .foregroundStyle(.cyan)
                    .frame(width: 32)

                VStack(alignment: .leading) {
                    Text(plan.name.localized)
                        .font(.system(size: 16, weight: .medium))
                    Text("\(plan.poseCount) poses · \(formattedDuration(plan.totalDuration))")
                        .font(.system(size: 13))
                        .foregroundStyle(.secondary)
                }

                Spacer()

            }
        }
    }

    private var tvStatusSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(LocalizedString(en: "TV Display", fr: "Affichage TV").localized)
                .font(.system(size: 16, weight: .semibold))

            HStack {
                Image(systemName: "tv")
                    .foregroundStyle(.cyan)
                Text(LocalizedString(
                    en: "Connect during a workout to display poses on your TV",
                    fr: "Connectez-vous pendant un entraînement pour afficher les postures sur votre télé"
                ).localized)
                    .font(.system(size: 14))
                    .foregroundStyle(.secondary)
            }
        }
        .padding()
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16))
        .padding(.horizontal)
    }

    // MARK: - Helpers

    private func loadCareKitPrescriptions() async {
        await appState.careKitBridge.refreshPrescribedTasks()
    }

    private func formattedDuration(_ duration: TimeInterval) -> String {
        let minutes = Int(duration) / 60
        return "\(minutes) min"
    }
}
