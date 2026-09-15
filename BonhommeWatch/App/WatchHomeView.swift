import SwiftUI
import BonhommeCore

/// A wrist-first library: one gentle starting point, followed by every available plan.
struct WatchHomeView: View {
    var body: some View {
        NavigationStack {
            List {
                VStack(alignment: .leading, spacing: 6) {
                    Image("Bloom").resizable().scaledToFit()
                        .frame(maxWidth: .infinity).frame(height: 80)
                        .accessibilityHidden(true)
                    Text(LocalizedString(en: "A moment for you.", fr: "Un moment pour vous.").localized)
                        .font(.title3.bold())
                    Text(LocalizedString(en: "Take a seat. Find your breath.", fr: "Asseyez-vous. Retrouvez votre souffle.").localized)
                        .font(.footnote).foregroundStyle(.secondary)
                }
                .listRowBackground(Color.clear)
                Section(LocalizedString(en: "Start gently", fr: "Commencez en douceur").localized) {
                    planRow(PoseCatalog.beginnerFlow)
                }
                Section(LocalizedString(en: "Explore your practice", fr: "Explorez votre pratique").localized) {
                    ForEach(PoseCatalog.allPlans.filter { $0.id != PoseCatalog.beginnerFlow.id }) { plan in
                        planRow(plan)
                    }
                }
            }
            .navigationTitle("NATURaL")
            .tint(.mint)
        }
    }

    private func planRow(_ plan: WorkoutPlan) -> some View {
        NavigationLink {
            WatchSessionView(plan: plan)
        } label: {
            VStack(alignment: .leading, spacing: 6) {
                Text(plan.name.localized)
                    .font(.headline).foregroundStyle(.primary)
                    .fixedSize(horizontal: false, vertical: true)
                HStack(spacing: 8) {
                    Label("\(plan.poseCount)", systemImage: "figure.yoga")
                    Label("\(Int(plan.totalDuration) / 60) min", systemImage: "clock")
                }
                .font(.caption).foregroundStyle(.mint)
            }
            .padding(.vertical, 6)
        }
    }
}
