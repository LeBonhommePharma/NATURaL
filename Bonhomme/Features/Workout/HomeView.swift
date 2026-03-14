import SwiftUI
import BonhommeCore

/// Main home screen showing available workout plans and activity summary.
struct HomeView: View {
    @Environment(AppState.self) private var appState
    @State private var showingHealthKitAuth = false

    var body: some View {
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
        .onAppear {
            if HealthKitManager.isAvailable && !appState.healthKitAuthorized {
                showingHealthKitAuth = true
            }
        }
        .task {
            if showingHealthKitAuth {
                try? await appState.healthKitManager.requestAuthorization()
                appState.healthKitAuthorized = true
            }
        }
    }

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

    private func formattedDuration(_ duration: TimeInterval) -> String {
        let minutes = Int(duration) / 60
        return "\(minutes) min"
    }
}
