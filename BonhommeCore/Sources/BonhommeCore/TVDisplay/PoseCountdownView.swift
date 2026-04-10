import SwiftUI

/// Displays the current pose name, illustration placeholder, and a circular countdown timer.
/// Used on the TV display (left 60% panel) to show the active pose and time remaining.
public struct PoseCountdownView: View {
    public let pose: Pose
    public let remaining: TimeInterval
    public let total: TimeInterval

    public init(pose: Pose, remaining: TimeInterval, total: TimeInterval) {
        self.pose = pose
        self.remaining = remaining
        self.total = total
    }

    public var body: some View {
        VStack(spacing: 24) {
            Spacer()

            // Pose icon — uses SF Symbol fallback when asset not available on tvOS
            Image(systemName: "figure.yoga")
                .font(.system(size: 120))
                .foregroundStyle(.cyan.opacity(0.8))
                .shadow(color: .cyan.opacity(0.3), radius: 16)

            // Pose name
            Text(pose.name.localized)
                .font(.system(size: 32, weight: .bold, design: .rounded))
                .foregroundStyle(.white)
                .multilineTextAlignment(.center)
                .padding(.horizontal)

            // Countdown ring
            ZStack {
                Circle()
                    .stroke(Color.white.opacity(0.1), lineWidth: 8)

                Circle()
                    .trim(from: 0, to: total > 0 ? remaining / total : 0)
                    .stroke(
                        Color.cyan,
                        style: StrokeStyle(lineWidth: 8, lineCap: .round)
                    )
                    .rotationEffect(.degrees(-90))
                    .animation(.linear(duration: 1), value: remaining)

                Text(timeString)
                    .font(.system(size: 48, weight: .bold, design: .rounded))
                    .monospacedDigit()
                    .foregroundStyle(.white)
                    .contentTransition(.numericText())
            }
            .frame(width: 140, height: 140)

            Spacer()
        }
    }

    private var timeString: String {
        let seconds = Int(remaining)
        if seconds >= 60 {
            return String(format: "%d:%02d", seconds / 60, seconds % 60)
        }
        return "\(seconds)"
    }
}
