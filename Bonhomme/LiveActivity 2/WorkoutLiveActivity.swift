import ActivityKit
import WidgetKit
import SwiftUI

/// FlexAIDΔS v2 tokens for the in-app Live Activity widget (no BonhommeCore).
/// Source: https://thebonhomme.com/tokens.css
private enum BrandTokens {
    static let mint = Color(red: 69 / 255, green: 224 / 255, blue: 168 / 255)
    static let violet = Color(red: 139 / 255, green: 92 / 255, blue: 246 / 255)
    static let tangerine = Color(red: 1, green: 147 / 255, blue: 0)
    static let strawberry = Color(red: 1, green: 47 / 255, blue: 146 / 255)
    static let bg = Color(red: 8 / 255, green: 9 / 255, blue: 26 / 255)
}

/// Live Activity widget compiled into the Bonhomme iOS target.
/// Violet SCI, mint progress, strawberry pause — no cyan/orange SCI.
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
                        .foregroundStyle(context.state.isPaused ? BrandTokens.strawberry : BrandTokens.mint)
                }

                DynamicIslandExpandedRegion(.center) {
                    ProgressView(
                        value: Double(context.state.poseIndex + 1),
                        total: Double(max(1, context.attributes.totalPoses))
                    )
                    .tint(context.state.isPaused ? BrandTokens.strawberry : BrandTokens.mint)
                }

                DynamicIslandExpandedRegion(.bottom) {
                    HStack(spacing: 10) {
                        if context.state.isPaused {
                            Label("Paused", systemImage: "pause.fill")
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundStyle(BrandTokens.strawberry)
                        }
                        if let hr = context.state.heartRate {
                            Label("\(hr)", systemImage: "heart.fill")
                                .font(.system(size: 12))
                                .foregroundStyle(.red)
                        }
                        if let sci = context.state.sciScore {
                            Label(formatSCI(sci), systemImage: "waveform.path.ecg")
                                .font(.system(size: 12))
                                .foregroundStyle(BrandTokens.violet)
                        }
                        if let breath = context.state.breathsPerMinute {
                            Label(formatBreath(breath), systemImage: "wind")
                                .font(.system(size: 12))
                                .foregroundStyle(BrandTokens.mint)
                        }
                        Spacer(minLength: 0)
                        Label("\(context.state.calories)", systemImage: "flame.fill")
                            .font(.system(size: 12))
                            .foregroundStyle(BrandTokens.tangerine)
                        Text("\(context.state.poseIndex + 1)/\(context.attributes.totalPoses)")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundStyle(.secondary)
                    }
                }
            } compactLeading: {
                Image(systemName: context.state.isPaused ? "pause.fill" : context.attributes.styleSymbol)
                    .font(.system(size: 12))
                    .foregroundStyle(context.state.isPaused ? BrandTokens.strawberry : BrandTokens.mint)
            } compactTrailing: {
                if let sci = context.state.sciScore {
                    Text(formatSCI(sci))
                        .font(.system(size: 11, weight: .bold, design: .rounded))
                        .monospacedDigit()
                        .foregroundStyle(context.state.isPaused ? BrandTokens.strawberry : BrandTokens.violet)
                } else {
                    Text(formatTime(context.state.poseTimeRemaining))
                        .font(.system(size: 12, weight: .bold, design: .rounded))
                        .monospacedDigit()
                }
            } minimal: {
                Image(systemName: context.state.isPaused ? "pause.fill" : context.attributes.styleSymbol)
                    .font(.system(size: 12))
                    .foregroundStyle(context.state.isPaused ? BrandTokens.strawberry : BrandTokens.mint)
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
                if context.state.isPaused {
                    Label("Paused", systemImage: "pause.fill")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(BrandTokens.strawberry)
                }
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
                    .foregroundStyle(context.state.isPaused ? BrandTokens.strawberry : BrandTokens.mint)
            }

            ProgressView(
                value: Double(context.state.poseIndex + 1),
                total: Double(max(1, context.attributes.totalPoses))
            )
            .tint(context.state.isPaused ? BrandTokens.strawberry : BrandTokens.mint)

            HStack(spacing: 12) {
                if let hr = context.state.heartRate {
                    Label("\(hr) bpm", systemImage: "heart.fill")
                        .font(.system(size: 12))
                        .foregroundStyle(.red)
                }
                if let sci = context.state.sciScore {
                    Label("SCI \(formatSCI(sci))", systemImage: "waveform.path.ecg")
                        .font(.system(size: 12))
                        .foregroundStyle(BrandTokens.violet)
                }
                if let breath = context.state.breathsPerMinute {
                    Label("\(formatBreath(breath))/min", systemImage: "wind")
                        .font(.system(size: 12))
                        .foregroundStyle(BrandTokens.mint)
                }
                Spacer(minLength: 0)
                Label("\(context.state.calories) cal", systemImage: "flame.fill")
                    .font(.system(size: 12))
                    .foregroundStyle(BrandTokens.tangerine)
            }
        }
        .padding()
        .activityBackgroundTint(BrandTokens.bg.opacity(0.92))
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
