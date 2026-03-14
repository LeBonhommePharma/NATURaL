import SwiftUI
import SwiftData
import BonhommeCore

/// Main home screen showing available workout plans and activity summary.
/// Adapts to iPad with a NavigationSplitView when horizontal size class is regular.
struct HomeView: View {
    @Environment(AppState.self) private var appState
    @Environment(\.horizontalSizeClass) private var sizeClass
    @State private var showingHealthKitAuth = false
    @State private var selectedPlan: WorkoutPlan?

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
            List(selection: $selectedPlan) {
                // CareKit prescribed section
                if appState.careKitBridge.hasPrescriptions {
                    prescribedSection
                }

                // Free session
                Section {
                    planRow(plan: PoseCatalog.beginnerFlow, isPremium: false)
                } header: {
                    Text(LocalizedString(en: "Free", fr: "Gratuit").localized)
                }

                // Premium plans
                Section {
                    ForEach(PoseCatalog.allPlans.filter { !$0.isFree }) { plan in
                        planRow(plan: plan, isPremium: !appState.isPremium)
                    }
                } header: {
                    Text(LocalizedString(en: "All Plans", fr: "Tous les programmes").localized)
                }
            }
            .navigationTitle("NATURaL")
            .listStyle(.sidebar)
        } detail: {
            if let plan = selectedPlan {
                planDetailView(plan: plan)
            } else {
                VStack(spacing: 16) {
                    Image(systemName: "figure.yoga")
                        .font(.system(size: 64))
                        .foregroundStyle(.cyan.opacity(0.5))
                    Text(LocalizedString(
                        en: "Select a workout plan",
                        fr: "Sélectionnez un programme"
                    ).localized)
                        .font(.system(size: 20, weight: .medium))
                        .foregroundStyle(.secondary)
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
                    Text(LocalizedString(en: "Chair Yoga", fr: "Yoga sur chaise").localized)
                        .font(.system(size: 20, weight: .medium))
                        .foregroundStyle(.secondary)
                }
                .padding(.horizontal)

                // CareKit prescribed section
                if appState.careKitBridge.hasPrescriptions {
                    prescribedCardsSection
                }

                // Restored workout banner
                if let restoredVM = appState.pendingRestoredWorkout {
                    NavigationLink {
                        WorkoutFlowView(restoredViewModel: restoredVM)
                    } label: {
                        resumeBanner(plan: restoredVM.plan)
                    }
                    .buttonStyle(.plain)
                    .padding(.horizontal)
                }

                // Free session
                workoutCard(
                    plan: PoseCatalog.beginnerFlow,
                    isPremium: false
                )

                // All plans
                ForEach(PoseCatalog.allPlans.filter { !$0.isFree }) { plan in
                    workoutCard(
                        plan: plan,
                        isPremium: !appState.isPremium
                    )
                }

                // TV connection status
                tvStatusSection
            }
            .padding(.vertical)
        }
        .onAppear { requestHealthKitIfNeeded() }
        .task { await loadCareKitPrescriptions() }
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
                        WorkoutFlowView(plan: plan)
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
                Text(LocalizedString(en: "Resume Workout", fr: "Reprendre l'entraînement").localized)
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
                        WorkoutFlowView(plan: plan)
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
                WorkoutFlowView(plan: plan)
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
