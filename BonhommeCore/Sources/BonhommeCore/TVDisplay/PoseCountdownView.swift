import SwiftUI

/// Animated circular countdown timer for the current pose.
public struct PoseCountdownView: View {
    public let pose: Pose
    public let remaining: TimeInterval
    public let total: TimeInterval

    public init(pose: Pose, remaining: TimeInterval, total: TimeInterval) {
        self.pose = pose
        self.remaining = remaining
        self.total = total
    }

    private var progress: Double {
        guard total > 0 else { return 0 }
        return max(0, min(1, 1.0 - remaining / total))
    }

    public var body: some View {
        VStack(spacing: 24) {
            Text(pose.name)
                .font(.system(size: 36, weight: .semibold, design: .rounded))
                .foregroundStyle(.white)

            ZStack {
                // Background ring
                Circle()
                    .stroke(Color.white.opacity(0.15), lineWidth: 12)

                // Progress ring
                Circle()
                    .trim(from: 0, to: progress)
                    .stroke(
                        progressGradient,
                        style: StrokeStyle(lineWidth: 12, lineCap: .round)
                    )
                    .rotationEffect(.degrees(-90))
                    .animation(.linear(duration: 0.5), value: progress)

                // Countdown number
                Text("\(Int(remaining))")
                    .font(.system(size: 96, weight: .bold, design: .rounded))
                    .monospacedDigit()
                    .foregroundStyle(.white)
                    .contentTransition(.numericText())
            }
            .frame(width: 280, height: 280)

            Text(pose.voiceCueText)
                .font(.system(size: 18, weight: .regular, design: .rounded))
                .foregroundStyle(.white.opacity(0.7))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
                .lineLimit(2)
        }
    }

    private var progressGradient: AngularGradient {
        AngularGradient(
            colors: [.cyan, .blue, .purple, .cyan],
            center: .center,
            startAngle: .degrees(0),
            endAngle: .degrees(360)
        )
    }
}
