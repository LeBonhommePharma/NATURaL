import SwiftUI
import BonhommeCore

/// Spatial ornament view displaying real-time biofeedback gauges
/// alongside the visionOS workout window.
///
/// Positioned as a floating panel on the trailing edge of the main window,
/// showing heart rate, SCI focus score, session progress, and calories.
struct SpatialBiofeedbackView: View {
    let viewModel: SpatialWorkoutViewModel

    var body: some View {
        VStack(spacing: 20) {
            // SCI Focus Score
            sciGauge

            Divider()
                .background(.white.opacity(0.2))

            // Session Progress
            progressSection

            Divider()
                .background(.white.opacity(0.2))

            // Elapsed Time
            timeSection
        }
        .padding(20)
        .frame(width: 180)
        .glassBackgroundEffect()
    }

    // MARK: - SCI Gauge

    private var sciGauge: some View {
        VStack(spacing: 8) {
            Text(LocalizedString(en: "Focus", fr: "Concentration").localized)
                .font(.system(size: 12))
                .foregroundStyle(.secondary)

            let insight = viewModel.feedbackEngine.latestInsight(for: .heartRateVariability)

            ZStack {
                // Background ring
                Circle()
                    .stroke(Color.white.opacity(0.1), lineWidth: 6)
                    .frame(width: 80, height: 80)

                // Score ring
                Circle()
                    .trim(from: 0, to: CGFloat(insight?.score ?? 0))
                    .stroke(
                        sciColor(for: insight?.score),
                        style: StrokeStyle(lineWidth: 6, lineCap: .round)
                    )
                    .frame(width: 80, height: 80)
                    .rotationEffect(.degrees(-90))

                // Score text
                VStack(spacing: 2) {
                    if let score = insight?.score {
                        Text("\(Int(score * 100))")
                            .font(.system(size: 24, weight: .bold, design: .rounded))
                            .monospacedDigit()
                        Text("%")
                            .font(.system(size: 11))
                            .foregroundStyle(.secondary)
                    } else {
                        Text("--")
                            .font(.system(size: 24, weight: .bold, design: .rounded))
                            .foregroundStyle(.secondary)
                    }
                }
            }

            // Trend indicator
            if let trend = insight?.trend {
                HStack(spacing: 4) {
                    Image(systemName: trendIcon(trend))
                        .font(.system(size: 11))
                    Text(trendLabel(trend))
                        .font(.system(size: 11))
                }
                .foregroundStyle(trendColor(trend))
            }
        }
    }

    // MARK: - Progress

    private var progressSection: some View {
        VStack(spacing: 8) {
            Text(LocalizedString(en: "Progress", fr: "Progrès").localized)
                .font(.system(size: 12))
                .foregroundStyle(.secondary)

            // Pose progress dots
            let totalPoses = viewModel.plan.poseCount
            let currentIndex = viewModel.currentPoseIndex

            HStack(spacing: 4) {
                ForEach(0..<min(totalPoses, 10), id: \.self) { i in
                    Circle()
                        .fill(i <= currentIndex ? Color.cyan : Color.white.opacity(0.15))
                        .frame(width: 8, height: 8)
                }
                if totalPoses > 10 {
                    Text("+\(totalPoses - 10)")
                        .font(.system(size: 10))
                        .foregroundStyle(.secondary)
                }
            }

            Text("\(currentIndex + 1)/\(totalPoses)")
                .font(.system(size: 16, weight: .semibold, design: .rounded))
                .monospacedDigit()
        }
    }

    // MARK: - Time

    private var timeSection: some View {
        VStack(spacing: 4) {
            Text(LocalizedString(en: "Time", fr: "Temps").localized)
                .font(.system(size: 12))
                .foregroundStyle(.secondary)

            let minutes = Int(viewModel.elapsedTime) / 60
            let seconds = Int(viewModel.elapsedTime) % 60
            Text(String(format: "%d:%02d", minutes, seconds))
                .font(.system(size: 20, weight: .semibold, design: .rounded))
                .monospacedDigit()
        }
    }

    // MARK: - Helpers

    private func sciColor(for score: Double?) -> Color {
        guard let score else { return .white.opacity(0.2) }
        switch score {
        case 0.8...: return .green
        case 0.6...: return .cyan
        case 0.3...: return .orange
        default: return .red
        }
    }

    private func trendIcon(_ trend: InsightTrend) -> String {
        switch trend {
        case .improving: return "arrow.up.right"
        case .stable: return "arrow.right"
        case .declining: return "arrow.down.right"
        }
    }

    private func trendLabel(_ trend: InsightTrend) -> String {
        switch trend {
        case .improving: return LocalizedString(en: "Improving", fr: "En hausse").localized
        case .stable: return LocalizedString(en: "Stable", fr: "Stable").localized
        case .declining: return LocalizedString(en: "Declining", fr: "En baisse").localized
        }
    }

    private func trendColor(_ trend: InsightTrend) -> Color {
        switch trend {
        case .improving: return .green
        case .stable: return .white.opacity(0.5)
        case .declining: return .orange
        }
    }
}
