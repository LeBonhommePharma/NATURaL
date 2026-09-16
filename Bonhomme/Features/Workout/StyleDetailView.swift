import SwiftUI
import BonhommeCore

/// Drill-in view showing all workout plans for a specific yoga style.
/// Regular width uses a two-column card grid; compact stays a single readable column.
struct StyleDetailView: View {
    @Environment(AppState.self) private var appState
    @Environment(\.horizontalSizeClass) private var sizeClass
    let style: YogaStyle
    @State private var selectedPlan: WorkoutPlan?

    private var plans: [WorkoutPlan] {
        PoseCatalog.plans(for: style)
    }

    private var isRegular: Bool { sizeClass == .regular }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: SessionSpacing.lg) {
                styleHeader
                    .frame(maxWidth: isRegular ? 720 : .infinity)

                LazyVGrid(
                    columns: [GridItem(.adaptive(minimum: isRegular ? 320 : 280), spacing: SessionSpacing.md)],
                    spacing: SessionSpacing.md
                ) {
                    ForEach(plans) { plan in
                        planCard(plan: plan)
                    }
                }
            }
            .padding(SessionSpacing.md)
            .frame(maxWidth: 1100)
            .frame(maxWidth: .infinity)
        }
        .background(Color(.systemGroupedBackground))
        .fullScreenCover(item: $selectedPlan) { plan in
            NavigationStack {
                WorkoutFlowView(plan: plan, feedbackEngine: appState.feedbackEngine)
            }
            .interactiveDismissDisabled()
        }
        .navigationTitle(style.localizedName.localized)
        .navigationBarTitleDisplayMode(.inline)
    }

    private var styleHeader: some View {
        VStack(alignment: .leading, spacing: SessionSpacing.sm) {
            Label(style.localizedName.localized, systemImage: style.symbolName)
                .font(.title.weight(.bold))
                .foregroundStyle(Color(hue: style.accentHue, saturation: 0.55, brightness: 0.7))
                .symbolRenderingMode(.hierarchical)
            Text(style.localizedDescription.localized)
                .font(.body)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
            HStack(spacing: SessionSpacing.md) {
                Label(
                    "\(plans.count) \(LocalizedString(en: "plans", fr: "programmes").localized)",
                    systemImage: "list.bullet"
                )
                Label(
                    "\(plans.flatMap(\.poses).count) \(LocalizedString(en: "poses", fr: "postures").localized)",
                    systemImage: "figure.yoga"
                )
            }
            .font(.subheadline)
            .foregroundStyle(.secondary)
        }
        .padding(SessionSpacing.md)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.thinMaterial, in: SessionRadius.cardShape())
    }

    private func planCard(plan: WorkoutPlan) -> some View {
        VStack(alignment: .leading, spacing: SessionSpacing.sm) {
            Text(plan.name.localized)
                .font(.headline)
                .foregroundStyle(.primary)
            Text(plan.description.localized)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .lineLimit(3)
                .fixedSize(horizontal: false, vertical: true)

            HStack(spacing: SessionSpacing.md) {
                Label("\(plan.poseCount)", systemImage: "list.number")
                Label(formattedDuration(plan.totalDuration), systemImage: "clock")
                Spacer(minLength: 0)
            }
            .font(.caption)
            .foregroundStyle(.secondary)

            Button {
                selectedPlan = plan
            } label: {
                Text(LocalizedString(en: "Start", fr: "Commencer").localized)
                    .font(.headline)
                    .frame(maxWidth: .infinity, minHeight: SessionSpacing.minTapTarget)
            }
            .sessionProminentButtonStyle()
            .tint(Color(hue: style.accentHue, saturation: 0.55, brightness: 0.75))
            .accessibilityLabel(Text("\(SessionHUDCopy.beginSession.localized), \(plan.name.localized)"))
        }
        .padding(SessionSpacing.md)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.regularMaterial, in: SessionRadius.cardShape())
    }

    private func formattedDuration(_ duration: TimeInterval) -> String {
        let minutes = Int(duration) / 60
        return "\(minutes) min"
    }
}
