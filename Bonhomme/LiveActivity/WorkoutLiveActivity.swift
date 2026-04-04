import ActivityKit
import WidgetKit
import SwiftUI

/// Live Activity widget for Dynamic Island and Lock Screen during active workouts.
/// Shows current pose, time remaining, heart rate, and calories.
struct WorkoutLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: WorkoutActivityAttributes.self) { context in
            // Lock Screen banner
            lockScreenView(context: context)
        } dynamicIsland: { context in
            DynamicIsland {
                // Expanded region
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
                    // Progress bar
                    ProgressView(
                        value: Double(context.state.poseIndex + 1),
                        total: Double(context.attributes.totalPoses)
                    )
                    .tint(Color(hue: context.attributes.accentHue, saturation: 0.6, brightness: 0.9))
                }

                DynamicIslandExpandedRegion(.bottom) {
                    HStack {
                        if let hr = context.state.heartRate {
                            Label("\(hr)", systemImage: "heart.fill")
                                .font(.system(size: 13))
                                .foregroundStyle(.red)
                        }
                        Spacer()
                        Label("\(context.state.calories)", systemImage: "flame.fill")
                            .font(.system(size: 13))
                            .foregroundStyle(.orange)
                        Spacer()
                        Text("\(context.state.poseIndex + 1)/\(context.attributes.totalPoses)")
                            .font(.system(size: 13, weight: .medium))
                            .foregroundStyle(.secondary)
                    }
                }
            } compactLeading: {
                Image(systemName: context.attributes.styleSymbol)
                    .font(.system(size: 12))
                    .foregroundStyle(Color(hue: context.attributes.accentHue, saturation: 0.6, brightness: 0.9))
            } compactTrailing: {
                Text(formatTime(context.state.poseTimeRemaining))
                    .font(.system(size: 12, weight: .bold, design: .rounded))
                    .monospacedDigit()
            } minimal: {
                Image(systemName: context.attributes.styleSymbol)
                    .font(.system(size: 12))
                    .foregroundStyle(Color(hue: context.attributes.accentHue, saturation: 0.6, brightness: 0.9))
            }
        }
    }

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

            // Current pose with time
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

            // Progress
            ProgressView(
                value: Double(context.state.poseIndex + 1),
                total: Double(context.attributes.totalPoses)
            )
            .tint(Color(hue: context.attributes.accentHue, saturation: 0.6, brightness: 0.7))

            // Stats
            HStack {
                if let hr = context.state.heartRate {
                    Label("\(hr) bpm", systemImage: "heart.fill")
                        .font(.system(size: 12))
                        .foregroundStyle(.red)
                }
                Spacer()
                Label("\(context.state.calories) cal", systemImage: "flame.fill")
                    .font(.system(size: 12))
                    .foregroundStyle(.orange)
                Spacer()
                Text("Pose \(context.state.poseIndex + 1) of \(context.attributes.totalPoses)")
                    .font(.system(size: 12))
                    .foregroundStyle(.secondary)
            }
        }
        .padding()
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
}
