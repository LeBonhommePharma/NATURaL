import ActivityKit
import SwiftUI
import WidgetKit

/// Live Activity presentation for the NATURaLLiveActivity extension.
/// Attributes type must match the app’s `WorkoutActivityAttributes` (shared source file).
struct WorkoutLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: WorkoutActivityAttributes.self) { context in
            lockScreenView(context: context)
        } dynamicIsland: { context in
            DynamicIsland {
                DynamicIslandExpandedRegion(.leading) {
                    HStack(spacing: 6) {
                        Image(systemName: context.attributes.styleSymbol)
                            .font(.system(size: 14))
                        Text(context.state.currentPoseName)
                            .font(.system(size: 14, weight: .semibold))
                            .lineLimit(1)
                    }
                }

                DynamicIslandExpandedRegion(.trailing) {
                    Text(formatTime(context.state.poseTimeRemaining))
                        .font(.system(size: 16, weight: .bold, design: .rounded))
                        .monospacedDigit()
                        .foregroundStyle(Color(hue: context.attributes.accentHue, saturation: 0.6, brightness: 0.9))
                }

                DynamicIslandExpandedRegion(.center) {
                    ProgressView(
                        value: Double(context.state.poseIndex + 1),
                        total: Double(max(1, context.attributes.totalPoses))
                    )
                    .tint(Color(hue: context.attributes.accentHue, saturation: 0.6, brightness: 0.9))
                }

                DynamicIslandExpandedRegion(.bottom) {
                    HStack(spacing: 10) {
                        if let hr = context.state.heartRate {
                            Label("\(hr)", systemImage: "heart.fill")
                                .font(.system(size: 12))
                                .foregroundStyle(.red)
                        }
                        if let sci = context.state.sciScore {
                            Label(formatSCI(sci), systemImage: "waveform.path.ecg")
                                .font(.system(size: 12))
                                .foregroundStyle(.cyan)
                        }
                        if let breath = context.state.breathsPerMinute {
                            Label(formatBreath(breath), systemImage: "wind")
                                .font(.system(size: 12))
                                .foregroundStyle(.mint)
                        }
                        Spacer(minLength: 0)
                        Label("\(context.state.calories)", systemImage: "flame.fill")
                            .font(.system(size: 12))
                            .foregroundStyle(.orange)
                        Text("\(context.state.poseIndex + 1)/\(context.attributes.totalPoses)")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundStyle(.secondary)
                    }
                }
            } compactLeading: {
                Image(systemName: context.attributes.styleSymbol)
                    .font(.system(size: 12))
                    .foregroundStyle(Color(hue: context.attributes.accentHue, saturation: 0.6, brightness: 0.9))
            } compactTrailing: {
                if let sci = context.state.sciScore {
                    Text(formatSCI(sci))
                        .font(.system(size: 11, weight: .bold, design: .rounded))
                        .monospacedDigit()
                        .foregroundStyle(.cyan)
                } else {
                    Text(formatTime(context.state.poseTimeRemaining))
                        .font(.system(size: 12, weight: .bold, design: .rounded))
                        .monospacedDigit()
                }
            } minimal: {
                Image(systemName: context.attributes.styleSymbol)
                    .font(.system(size: 12))
                    .foregroundStyle(Color(hue: context.attributes.accentHue, saturation: 0.6, brightness: 0.9))
            }
        }
    }

    @ViewBuilder
    private func lockScreenView(context: ActivityViewContext<WorkoutActivityAttributes>) -> some View {
        VStack(spacing: 8) {
            HStack {
                Image(systemName: context.attributes.styleSymbol)
                Text(context.attributes.planName)
                    .font(.system(size: 15, weight: .semibold))
                Spacer()
                Text(formatElapsed(context.state.elapsedTime))
                    .font(.system(size: 13, design: .rounded))
                    .foregroundStyle(.secondary)
            }

            HStack {
                Text(context.state.currentPoseName)
                    .font(.system(size: 17, weight: .bold))
                    .lineLimit(1)
                Spacer()
                Text(formatTime(context.state.poseTimeRemaining))
                    .font(.system(size: 20, weight: .bold, design: .rounded))
                    .monospacedDigit()
                    .foregroundStyle(Color(hue: context.attributes.accentHue, saturation: 0.6, brightness: 0.7))
            }

            ProgressView(
                value: Double(context.state.poseIndex + 1),
                total: Double(max(1, context.attributes.totalPoses))
            )
            .tint(Color(hue: context.attributes.accentHue, saturation: 0.6, brightness: 0.7))

            HStack(spacing: 12) {
                if let hr = context.state.heartRate {
                    Label("\(hr) bpm", systemImage: "heart.fill")
                        .font(.system(size: 12))
                        .foregroundStyle(.red)
                }
                if let sci = context.state.sciScore {
                    Label("SCI \(formatSCI(sci))", systemImage: "waveform.path.ecg")
                        .font(.system(size: 12))
                        .foregroundStyle(.cyan)
                }
                if let breath = context.state.breathsPerMinute {
                    Label("\(formatBreath(breath))/min", systemImage: "wind")
                        .font(.system(size: 12))
                        .foregroundStyle(.mint)
                }
                Spacer(minLength: 0)
                Label("\(context.state.calories) cal", systemImage: "flame.fill")
                    .font(.system(size: 12))
                    .foregroundStyle(.orange)
            }
        }
        .padding()
        .activityBackgroundTint(Color.black.opacity(0.35))
    }

    private func formatTime(_ seconds: Int) -> String {
        let m = seconds / 60
        let s = seconds % 60
        return m > 0 ? String(format: "%d:%02d", m, s) : "\(s)s"
    }

    private func formatElapsed(_ interval: TimeInterval) -> String {
        let m = Int(interval) / 60
        let s = Int(interval) % 60
        return String(format: "%d:%02d", m, s)
    }

    private func formatSCI(_ score: Double) -> String {
        "\(Int((score * 100).rounded()))%"
    }

    private func formatBreath(_ bpm: Double) -> String {
        String(format: "%.0f", bpm)
    }
}
