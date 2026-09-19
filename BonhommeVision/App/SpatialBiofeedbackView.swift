import SwiftUI
import BonhommeCore

/// Spatial ornament: actual session progress and elapsed time. Vision has no
/// health-data source; SCI remains explicitly unavailable.
struct SpatialBiofeedbackView: View {
    let viewModel: SpatialWorkoutViewModel

    var body: some View {
        let metrics = viewModel.hudMetrics
        VStack(spacing: SessionSpacing.md) {
            CompactSCIMeter(
                score: metrics.sciScore,
                trend: metrics.sciTrend,
                size: 72
            )

            SessionStatusChip(
                title: metrics.entropyState.label.localized,
                systemImage: metrics.entropyState.symbolName,
                tint: SessionPalette.entropy(metrics.entropyState)
            )

            Text(LocalizedString(en: "Health data unavailable on this device",
                                 fr: "Données de santé indisponibles sur cet appareil").localized)
                .font(.caption).foregroundStyle(.secondary)
                .multilineTextAlignment(.center)

            Divider()
                .overlay(BrandColor.hairline)

            VStack(spacing: SessionSpacing.xxs) {
                Text(LocalizedString(en: "Progress", fr: "Progrès").localized)
                    .font(.caption2.weight(.medium))
                    .foregroundStyle(BrandColor.fgMuted)
                if let fraction = metrics.poseProgressFraction {
                    ProgressView(value: fraction)
                        .tint(SessionPalette.accent)
                        .accessibilityLabel(Text("Pose \(metrics.poseProgressText)"))
                } else {
                    Capsule()
                        .fill(BrandColor.magnesium.opacity(0.2))
                        .frame(height: 4)
                        .accessibilityLabel(Text("Pose —"))
                }
                Text(metrics.poseProgressText)
                    .font(SessionType.metric(.body))
                    .foregroundStyle(BrandColor.fg)
            }

            VStack(spacing: SessionSpacing.xxs) {
                Text(LocalizedString(en: "Time", fr: "Temps").localized)
                    .font(.caption2.weight(.medium))
                    .foregroundStyle(BrandColor.fgMuted)
                Text(metrics.elapsedText)
                    .font(SessionType.metric(.title3))
                    .foregroundStyle(BrandColor.fg)
            }
        }
        .padding(SessionSpacing.md)
        .frame(width: 180)
        .glassBackgroundEffect()
        .accessibilityElement(children: .contain)
        .accessibilityLabel(Text(metrics.accessibilitySummary))
    }
}
