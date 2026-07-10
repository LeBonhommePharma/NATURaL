import SwiftUI
import BonhommeCore

/// Drill-in view showing all workout plans for a specific yoga style.
struct StyleDetailView: View {
    @Environment(AppState.self) private var appState
    let style: YogaStyle

    private var plans: [WorkoutPlan] {
        PoseCatalog.plans(for: style)
    }

    private var freePlans: [WorkoutPlan] {
        plans.filter(\.isFree)
    }

    private var premiumPlans: [WorkoutPlan] {
        plans.filter { !$0.isFree }
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                // Style header
                styleHeader

                // Free plans
                if !freePlans.isEmpty {
                    sectionHeader(
                        title: LocalizedString(en: "Free", fr: "Gratuit"),
                        systemImage: "gift"
                    )
                    ForEach(freePlans) { plan in
                        planCard(plan: plan, locked: false)
                    }
                }

                // Premium plans
                if !premiumPlans.isEmpty {
                    sectionHeader(
                        title: LocalizedString(en: "Premium", fr: "Premium"),
                        systemImage: "star.fill"
                    )
                    ForEach(premiumPlans) { plan in
                        planCard(plan: plan, locked: !appState.isPremium)
                    }
                }
            }
            .padding(.vertical)
        }
        .navigationTitle(style.localizedName.localized)
        .navigationBarTitleDisplayMode(.inline)
    }

    // MARK: - Style Header

    private var styleHeader: some View {
        VStack(spacing: 16) {
            Image(systemName: style.symbolName)
                .font(.system(size: 48))
                .foregroundStyle(Color(hue: style.accentHue, saturation: 0.6, brightness: 0.9))

            Text(style.localizedName.localized)
                .font(.system(size: 28, weight: .bold, design: .rounded))

            Text(style.localizedDescription.localized)
                .font(.system(size: 15))
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)

            HStack(spacing: 20) {
                Label(
                    "\(plans.count) \(LocalizedString(en: "plans", fr: "programmes").localized)",
                    systemImage: "list.bullet"
                )
                Label(
                    "\(PoseCatalog.plans(for: style).flatMap(\.poses).count) \(LocalizedString(en: "poses", fr: "postures").localized)",
                    systemImage: "figure.yoga"
                )
            }
            .font(.system(size: 14))
            .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(
            Color(hue: style.accentHue, saturation: 0.15, brightness: 0.95)
                .opacity(0.5),
            in: RoundedRectangle(cornerRadius: 20)
        )
        .padding(.horizontal)
    }

    // MARK: - Section Header

    private func sectionHeader(title: LocalizedString, systemImage: String) -> some View {
        HStack {
            Image(systemName: systemImage)
                .foregroundStyle(Color(hue: style.accentHue, saturation: 0.6, brightness: 0.8))
            Text(title.localized)
                .font(.system(size: 18, weight: .semibold))
        }
        .padding(.horizontal)
    }

    // MARK: - Plan Card

    private func planCard(plan: WorkoutPlan, locked: Bool) -> some View {
        NavigationLink {
            if locked {
                PaywallView()
            } else {
                WorkoutFlowView(plan: plan, feedbackEngine: appState.feedbackEngine)
            }
        } label: {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(plan.name.localized)
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundStyle(.primary)

                        Text(plan.description.localized)
                            .font(.system(size: 14))
                            .foregroundStyle(.secondary)
                            .lineLimit(2)
                    }

                    Spacer()

                    if locked {
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

                    if plan.isFree {
                        Text(LocalizedString(en: "FREE", fr: "GRATUIT").localized)
                            .font(.system(size: 11, weight: .bold))
                            .foregroundStyle(.green)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(.green.opacity(0.15), in: Capsule())
                    }
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

    // MARK: - Helpers

    private func formattedDuration(_ duration: TimeInterval) -> String {
        let minutes = Int(duration) / 60
        return "\(minutes) min"
    }
}
