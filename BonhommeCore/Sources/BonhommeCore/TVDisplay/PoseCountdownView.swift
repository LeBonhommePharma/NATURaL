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

    private var categoryColor: Color {
        Color(hue: pose.category.accentHue, saturation: 0.7, brightness: 0.9)
    }

    public var body: some View {
        VStack(spacing: 20) {
            // Category icon
            Image(systemName: pose.category.symbolName)
                .font(.system(size: 36))
                .foregroundStyle(categoryColor.opacity(0.6))
                .padding(.bottom, -8)

            // Pose name
            Text(pose.name.localized)
                .font(.system(size: 36, weight: .semibold, design: .rounded))
                .foregroundStyle(.white)

            // Difficulty dots
            HStack(spacing: 6) {
                ForEach(0..<3, id: \.self) { i in
                    Circle()
                        .fill(i < pose.difficulty.dotCount ? categoryColor : Color.white.opacity(0.15))
                        .frame(width: 8, height: 8)
                }
            }

            // Countdown ring
            ZStack {
                // Outer ambient glow
                Circle()
                    .stroke(categoryColor.opacity(0.08), lineWidth: 24)

                // Background ring
                Circle()
                    .stroke(Color.white.opacity(0.12), lineWidth: 12)

                // Progress ring
                Circle()
                    .trim(from: 0, to: progress)
                    .stroke(
                        progressGradient,
                        style: StrokeStyle(lineWidth: 12, lineCap: .round)
                    )
                    .rotationEffect(.degrees(-90))
                    .shadow(color: categoryColor.opacity(0.4), radius: 6)
                    .animation(.linear(duration: 0.5), value: progress)

                // Countdown number
                Text("\(Int(remaining))")
                    .font(.system(size: 96, weight: .bold, design: .rounded))
                    .monospacedDigit()
                    .foregroundStyle(.white)
                    .contentTransition(.numericText())
            }
            .frame(width: 280, height: 280)

            // Breathing pattern
            if !pose.breathingPattern.localized.isEmpty {
                HStack(spacing: 6) {
                    Image(systemName: "wind")
                        .font(.system(size: 14))
                        .foregroundStyle(categoryColor.opacity(0.7))
                    Text(pose.breathingPattern.localized)
                        .font(.system(size: 15, weight: .medium, design: .rounded))
                        .foregroundStyle(.white.opacity(0.5))
                }
                .lineLimit(1)
                .padding(.horizontal, 32)
            }

            // Voice cue
            Text(pose.voiceCueText.localized)
                .font(.system(size: 18, weight: .regular, design: .rounded))
                .foregroundStyle(.white.opacity(0.7))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
                .lineLimit(2)
        }
    }

    private var progressGradient: AngularGradient {
        AngularGradient(
            colors: [categoryColor, .blue, .purple, categoryColor],
            center: .center,
            startAngle: .degrees(0),
            endAngle: .degrees(360)
        )
    }
}
