import ActivityKit
import SwiftUI
import WidgetKit

/// ActivityKit attributes for the workout Live Activity shown on
/// the lock screen and Dynamic Island during an active session.
struct WorkoutAttributes: ActivityAttributes {
    let workoutName: String

    struct ContentState: Codable, Hashable {
        var elapsedSeconds: Int
        var currentPoseName: String
        var heartRate: Int
        var caloriesBurned: Int
        var poseProgress: Double
    }
}

struct WorkoutLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: WorkoutAttributes.self) { context in
            // Lock screen presentation
            lockScreenView(context: context)
        } dynamicIsland: { context in
            DynamicIsland {
                DynamicIslandExpandedRegion(.leading) {
                    HStack(spacing: 4) {
                        Image(systemName: "heart.fill")
                            .foregroundStyle(.red)
                        Text("\(context.state.heartRate)")
                            .font(.system(size: 16, weight: .bold, design: .rounded))
                            .monospacedDigit()
                    }
                }
                DynamicIslandExpandedRegion(.trailing) {
                    HStack(spacing: 4) {
                        Image(systemName: "flame.fill")
                            .foregroundStyle(.orange)
                        Text("\(context.state.caloriesBurned)")
                            .font(.system(size: 16, weight: .bold, design: .rounded))
                            .monospacedDigit()
                    }
                }
                DynamicIslandExpandedRegion(.center) {
                    Text(context.state.currentPoseName)
                        .font(.system(size: 14, weight: .semibold))
                        .lineLimit(1)
                }
                DynamicIslandExpandedRegion(.bottom) {
                    ProgressView(value: context.state.poseProgress)
                        .tint(.cyan)
                }
            } compactLeading: {
                Image(systemName: "figure.yoga")
                    .foregroundStyle(.cyan)
            } compactTrailing: {
                Text(formatTime(context.state.elapsedSeconds))
                    .font(.system(size: 14, weight: .semibold, design: .rounded))
                    .monospacedDigit()
            } minimal: {
                Image(systemName: "figure.yoga")
                    .foregroundStyle(.cyan)
            }
        }
    }

    @ViewBuilder
    private func lockScreenView(context: ActivityViewContext<WorkoutAttributes>) -> some View {
        HStack(spacing: 16) {
            VStack(alignment: .leading, spacing: 4) {
                Text(context.attributes.workoutName)
                    .font(.system(size: 14, weight: .semibold))

                Text(context.state.currentPoseName)
                    .font(.system(size: 18, weight: .bold))

                ProgressView(value: context.state.poseProgress)
                    .tint(.cyan)
            }

            Spacer()

            VStack(spacing: 8) {
                HStack(spacing: 4) {
                    Image(systemName: "heart.fill")
                        .font(.system(size: 12))
                        .foregroundStyle(.red)
                    Text("\(context.state.heartRate)")
                        .font(.system(size: 16, weight: .bold, design: .rounded))
                        .monospacedDigit()
                }

                HStack(spacing: 4) {
                    Image(systemName: "flame.fill")
                        .font(.system(size: 12))
                        .foregroundStyle(.orange)
                    Text("\(context.state.caloriesBurned)")
                        .font(.system(size: 16, weight: .bold, design: .rounded))
                        .monospacedDigit()
                }

                Text(formatTime(context.state.elapsedSeconds))
                    .font(.system(size: 14, weight: .medium, design: .rounded))
                    .monospacedDigit()
                    .foregroundStyle(.secondary)
            }
        }
        .padding()
    }

    private func formatTime(_ seconds: Int) -> String {
        let m = seconds / 60
        let s = seconds % 60
        return String(format: "%d:%02d", m, s)
    }
}
