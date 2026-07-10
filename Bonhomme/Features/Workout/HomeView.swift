import SwiftUI
import SwiftData
import BonhommeCore

/// Main home screen showing available workout plans and activity summary.
/// Adapts to iPad with a NavigationSplitView when horizontal size class is regular.
struct HomeView: View {
    @Environment(AppState.self) private var appState
    @Environment(\.horizontalSizeClass) private var sizeClass
    @AppStorage("natural.motionCoachHeroDismissed") private var motionCoachHeroDismissed = false
    @State private var showingHealthKitAuth = false
    @State private var selectedPlan: WorkoutPlan?
    @State private var selectedStyle: YogaStyle?

    var body: some View {
        if sizeClass == .regular {
            iPadLayout
        } else {
            phoneLayout
        }
    }

    // MARK: - iPad Layout (NavigationSplitView)

    private var iPadLayout: some View {
        NavigationSplitView {
            List(selection: $selectedStyle) {
                // CareKit prescribed section
                if appState.careKitBridge.hasPrescriptions {
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
            if let style = selectedStyle {
                StyleDetailView(style: style)
            } else {
                ScrollView {
                    VStack(spacing: 24) {
                        coachHeroCard(compact: true, dismissible: false)
                            .padding(.horizontal, 32)
                            .padding(.top, 24)

                        if appState.persistenceSync.needsAttention {
                            cloudKitSyncStatusCard
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
        .onAppear { requestHealthKitIfNeeded() }
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
                    Text(LocalizedString(en: "Yoga & Wellness", fr: "Yoga et bien-être").localized)
                        .font(.system(size: 20, weight: .medium))
                        .foregroundStyle(.secondary)
                }
                .padding(.horizontal)

                if !motionCoachHeroDismissed {
                    coachHeroCard(compact: false, dismissible: true)
                        .padding(.horizontal)
                }

                // CareKit prescribed section
                if appState.careKitBridge.hasPrescriptions {
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

                // Style card grid
                styleCardGrid

                // Prescriptions / clinical medication consent entry
                prescriptionsEntryCard

                // iCloud / CloudKit sync status (local-only or ephemeral fallback)
                if appState.persistenceSync.needsAttention {
                    cloudKitSyncStatusCard
                }

                // TV connection status
                tvStatusSection
            }
            .padding(.vertical)
        }
        .onAppear { requestHealthKitIfNeeded() }
        .task { await loadCareKitPrescriptions() }
    }

    // MARK: - CloudKit / persistence status

    /// Settings-style card when storage is local-only or ephemeral.
    /// Mirrors banner messaging; keeps Retry available after the banner is dismissed.
    @ViewBuilder
    private var cloudKitSyncStatusCard: some View {
        @Bindable var sync = appState.persistenceSync
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 14) {
                Image(systemName: sync.systemImageName)
                    .font(.system(size: 24))
                    .foregroundStyle(sync.accentColor)
                    .frame(width: 40)

                VStack(alignment: .leading, spacing: 4) {
                    Text(LocalizedString(
                        en: "Data & iCloud Sync",
                        fr: "Données et sync iCloud"
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
                Task { await sync.retryCloudKitConnection() }
            } label: {
                if sync.isRetrying {
                    ProgressView()
                        .frame(maxWidth: .infinity)
                } else {
                    Text(LocalizedString(en: "Retry iCloud Sync", fr: "Réessayer la sync iCloud").localized)
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
            en: "Data and iCloud sync status",
            fr: "État des données et de la sync iCloud"
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
        let previewPose = PoseCatalog.seatedCatCow
        let previewPlan = PoseCatalog.beginnerFlow
        let accent = Color(hue: previewPose.category.accentHue, saturation: 0.62, brightness: 0.88)

        return VStack(alignment: .leading, spacing: 16) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 8) {
                    HStack(spacing: 8) {
                        Image(systemName: "video.slash")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundStyle(accent)
                        Text(LocalizedString(en: "Clean-room visual coach", fr: "Coach visuel clean-room").localized)
                            .font(.system(size: 12, weight: .bold, design: .rounded))
                            .foregroundStyle(accent)
                    }

                    Text(LocalizedString(
                        en: "Guided motion without trainer footage",
                        fr: "Guidage animé sans vidéo de coach"
                    ).localized)
                    .font(.system(size: compact ? 22 : 24, weight: .bold, design: .rounded))
                    .foregroundStyle(.primary)
                    .multilineTextAlignment(.leading)

                    Text(LocalizedString(
                        en: "Procedural symbol animation, breathing cues, and pose pacing inspired by the pattern class — not by copied code, assets, or video.",
                        fr: "Animation symbolique procédurale, repères respiratoires et rythme des postures inspirés de la classe de produit — sans code, actifs ni vidéo copiés."
                    ).localized)
                    .font(.system(size: 14))
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
                }

                Spacer(minLength: 12)

                if dismissible {
                    Button {
                        motionCoachHeroDismissed = true
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 20))
                            .foregroundStyle(.secondary)
                    }
                    .buttonStyle(.plain)
                }
            }

            MotionCoachView(pose: previewPose, phase: .preview, cornerRadius: 24)
                .frame(height: compact ? 250 : 220)

            VStack(alignment: .leading, spacing: 10) {
                coachPoint(
                    systemName: "sparkles.rectangle.stack",
                    text: LocalizedString(en: "Symbolic motion instead of trainer video", fr: "Mouvement symbolique au lieu d'une vidéo de coach").localized,
                    color: accent
                )
                coachPoint(
                    systemName: "wind",
                    text: LocalizedString(en: "Breathing and pacing cues embedded in the animation", fr: "Repères respiratoires et de rythme intégrés à l'animation").localized,
                    color: accent
                )
                coachPoint(
                    systemName: "figure.walk.motion",
                    text: LocalizedString(en: "Ready to wire into every guided workout phase", fr: "Prêt à être branché dans chaque phase guidée").localized,
                    color: accent
                )
            }

            NavigationLink {
                WorkoutFlowView(plan: previewPlan, feedbackEngine: appState.feedbackEngine)
            } label: {
                HStack {
                    Text(LocalizedString(en: "Try guided preview", fr: "Essayer l'aperçu guidé").localized)
                        .font(.system(size: 16, weight: .semibold))
                    Spacer()
                    Image(systemName: "arrow.right")
                        .font(.system(size: 14, weight: .bold))
                }
                .foregroundStyle(.black)
                .padding(.horizontal, 16)
                .padding(.vertical, 14)
                .background(accent, in: RoundedRectangle(cornerRadius: 14))
            }
            .buttonStyle(.plain)
        }
        .padding(compact ? 24 : 20)
        .background(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(Color(hue: previewPose.category.accentHue, saturation: 0.10, brightness: 0.97))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .strokeBorder(accent.opacity(0.28), lineWidth: 1)
        )
    }

    private func coachPoint(systemName: String, text: String, color: Color) -> some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: systemName)
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(color)
                .frame(width: 18, height: 18)
                .padding(.top, 1)

            Text(text)
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(.primary)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    // MARK: - Style Card Grid

    private var styleCardGrid: some View {
        let columns = [
            GridItem(.flexible(), spacing: 12),
            GridItem(.flexible(), spacing: 12)
        ]

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
            ForEach(appState.careKitBridge.prescribedTasks, id: \.id) { task in
                if let plan = appState.careKitBridge.resolveWorkoutPlan(for: task) {
                    planRow(plan: plan, isPremium: false)
                        .badge(Text(LocalizedString(
                            en: "Prescribed",
                            fr: "Prescrit"
                        ).localized))
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
            }
            .padding(.horizontal)

            ForEach(appState.careKitBridge.prescribedTasks, id: \.id) { task in
                if let plan = appState.careKitBridge.resolveWorkoutPlan(for: task) {
                    NavigationLink {
                        WorkoutFlowView(plan: plan, feedbackEngine: appState.feedbackEngine)
                    } label: {
                        HStack {
                            Image(systemName: "figure.yoga")
                                .font(.system(size: 24))
                                .foregroundStyle(.blue)

                            VStack(alignment: .leading) {
                                Text(plan.name.localized)
                                    .font(.system(size: 17, weight: .semibold))
                                    .foregroundStyle(.primary)
                                if let instructions = task.instructions {
                                    Text(instructions)
                                        .font(.system(size: 13))
                                        .foregroundStyle(.secondary)
                                        .lineLimit(2)
                                }
                            }

                            Spacer()

                            Image(systemName: "chevron.right")
                                .foregroundStyle(.secondary)
                        }
                        .padding()
                        .background(.blue.opacity(0.08), in: RoundedRectangle(cornerRadius: 16))
                    }
                    .buttonStyle(.plain)
                    .padding(.horizontal)
                }
            }
        }
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
                NavigationLink {
                    if !appState.isPremium || plan.isFree {
                        WorkoutFlowView(plan: plan, feedbackEngine: appState.feedbackEngine)
                    } else {
                        PaywallView()
                    }
                } label: {
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

    private func planRow(plan: WorkoutPlan, isPremium: Bool) -> some View {
        NavigationLink(value: plan) {
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

                if isPremium {
                    Image(systemName: "lock.fill")
                        .foregroundStyle(.orange)
                        .font(.system(size: 13))
                }
            }
        }
    }

    // MARK: - Phone Workout Card

    private func workoutCard(plan: WorkoutPlan, isPremium: Bool) -> some View {
        NavigationLink {
            if isPremium {
                PaywallView()
            } else {
                WorkoutFlowView(plan: plan, feedbackEngine: appState.feedbackEngine)
            }
        } label: {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Image(systemName: "figure.yoga")
                        .font(.system(size: 28))
                        .foregroundStyle(.cyan)

                    VStack(alignment: .leading) {
                        Text(plan.name.localized)
                            .font(.system(size: 20, weight: .semibold))
                            .foregroundStyle(.primary)

                        Text(plan.description.localized)
                            .font(.system(size: 14))
                            .foregroundStyle(.secondary)
                            .lineLimit(2)
                    }

                    Spacer()

                    if isPremium {
                        Image(systemName: "lock.fill")
                            .foregroundStyle(.orange)
                    } else {
                        Image(systemName: "chevron.right")
                            .foregroundStyle(.secondary)
                    }
                }

                HStack(spacing: 16) {
                    Label("\(plan.poseCount) poses", systemImage: "list.number")
                    Label(formattedDuration(plan.totalDuration), systemImage: "clock")
                }
                .font(.system(size: 13))
                .foregroundStyle(.secondary)
            }
            .padding()
            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16))
        }
        .buttonStyle(.plain)
        .padding(.horizontal)
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

    private func requestHealthKitIfNeeded() {
        if HealthKitManager.isAvailable && !appState.healthKitAuthorized {
            showingHealthKitAuth = true
            Task {
                try? await appState.healthKitManager.requestAuthorization()
                appState.healthKitAuthorized = true
            }
        }
    }

    private func loadCareKitPrescriptions() async {
        await appState.careKitBridge.refreshPrescribedTasks()
    }

    private func formattedDuration(_ duration: TimeInterval) -> String {
        let minutes = Int(duration) / 60
        return "\(minutes) min"
    }
}
