import SwiftUI
import BonhommeCore

/// Plan selection screen for the watchOS companion app.
/// Shows available workout plans with pose count and duration,
/// and links to WatchSessionView for workout execution.
struct WatchHomeView: View {
    @Environment(WatchWorkoutManager.self) private var manager

    var body: some View {
        NavigationStack {
            List {
                // Free plan first
                planRow(plan: PoseCatalog.beginnerFlow)

                // All other plans
                ForEach(PoseCatalog.allPlans.filter { !$0.isFree }) { plan in
                    planRow(plan: plan)
                }
            }
            .navigationTitle("NATURaL")
        }
    }

    private func planRow(plan: WorkoutPlan) -> some View {
        NavigationLink {
            WatchSessionView(plan: plan)
        } label: {
            VStack(alignment: .leading, spacing: 4) {
                Text(plan.name.localized)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(.white)
                    .lineLimit(1)

                HStack(spacing: 8) {
                    Label("\(plan.poseCount)", systemImage: "figure.yoga")
                    Label(formattedDuration(plan.totalDuration), systemImage: "clock")
                }
                .font(.system(size: 12))
                .foregroundStyle(.secondary)
            }
            .padding(.vertical, 4)
        }
    }

    private func formattedDuration(_ duration: TimeInterval) -> String {
        let minutes = Int(duration) / 60
        return "\(minutes)m"
    }
}
