import SwiftUI

/// Persistent text equivalent of the illustration, independent of animation timing.
public struct PoseGuideDetails: View {
    public let pose: Pose

    public init(pose: Pose) { self.pose = pose }

    public var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(LocalizedString(en: "Pose guide", fr: "Guide de la posture").localized)
                .font(.headline)
                .accessibilityAddTraits(.isHeader)
            Text(pose.description.localized)
                .font(.body)
            ForEach(Array(pose.kinematics.setupSteps.enumerated()), id: \.offset) { index, step in
                HStack(alignment: .top, spacing: 10) {
                    Text("\(index + 1).")
                        .monospacedDigit().foregroundStyle(.secondary)
                    Text(step.localized).frame(maxWidth: .infinity, alignment: .leading)
                }
                .accessibilityElement(children: .combine)
            }
            if !pose.breathingPattern.localized.isEmpty {
                Label(pose.breathingPattern.localized, systemImage: "wind")
            }
            if !pose.modifications.localized.isEmpty {
                DisclosureGroup(LocalizedString(en: "Make it comfortable", fr: "Adaptez la posture").localized) {
                    VStack(alignment: .leading, spacing: 8) {
                        ForEach(Array(pose.modifications.localized.enumerated()), id: \.offset) { _, modification in
                            Text(modification)
                        }
                    }.padding(.top, 8)
                }
            }
            if !pose.contraindications.localized.isEmpty {
                Text(LocalizedString(en: "Before you begin", fr: "Avant de commencer").localized)
                    .font(.subheadline.weight(.semibold)).accessibilityAddTraits(.isHeader)
                ForEach(Array(pose.contraindications.localized.enumerated()), id: \.offset) { _, caution in
                    Text(caution).font(.callout)
                }
            }
            Text(LocalizedString(
                en: "The illustration is a guide, not an assessment of your movement. Follow the steps within a comfortable range; stop if a movement hurts.",
                fr: "L’illustration est un guide, pas une évaluation de vos mouvements. Suivez les étapes dans une amplitude confortable ; arrêtez si un mouvement fait mal."
            ).localized)
            .font(.caption).foregroundStyle(.secondary)
        }
        .fixedSize(horizontal: false, vertical: true)
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}
