import SwiftUI
import BonhommeCore

/// Wrist-first library: one gentle start, then every other plan.
/// watchOS 26 kit: compact List, SF text styles, mint session accent — no hero art.
struct WatchHomeView: View {
    var body: some View {
        NavigationStack {
            List {
                Section {
                    VStack(alignment: .leading, spacing: SessionSpacing.xxs) {
                        Text(LocalizedString(en: "A moment for you.", fr: "Un moment pour vous.").localized)
                            .font(.headline)
                        Text(LocalizedString(en: "Take a seat. Find your breath.", fr: "Asseyez-vous. Retrouvez votre souffle.").localized)
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                    }
                    .accessibilityElement(children: .combine)
                    .listRowBackground(Color.clear)
                }

                Section(LocalizedString(en: "Start gently", fr: "Commencez en douceur").localized) {
                    planRow(PoseCatalog.beginnerFlow)
                }

                Section(LocalizedString(en: "Explore", fr: "Explorer").localized) {
                    ForEach(PoseCatalog.allPlans.filter { $0.id != PoseCatalog.beginnerFlow.id }) { plan in
                        planRow(plan)
                    }
                }
            }
            .navigationTitle("NATURaL")
            .tint(SessionPalette.accent)
        }
    }

    private func planRow(_ plan: WorkoutPlan) -> some View {
        NavigationLink {
            WatchSessionView(plan: plan)
        } label: {
            VStack(alignment: .leading, spacing: SessionSpacing.xxs) {
                Text(plan.name.localized)
                    .font(.headline)
                    .foregroundStyle(.primary)
                    .fixedSize(horizontal: false, vertical: true)
                HStack(spacing: SessionSpacing.xs) {
                    Label("\(plan.poseCount)", systemImage: "figure.yoga")
                    Label("\(Int(plan.totalDuration) / 60) min", systemImage: "clock")
                }
                .font(.caption2)
                .foregroundStyle(SessionPalette.accent)
            }
            .padding(.vertical, SessionSpacing.xxs)
            .frame(minHeight: SessionSpacing.minTapTarget, alignment: .leading)
        }
    }
}
