import SwiftUI

/// Displays the current pose name, illustration placeholder, and a circular countdown timer.
/// Volumetric ring glow, radial ambient light, spring interpolation.
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
        TimelineView(.animation(minimumInterval: 1.0 / 30.0, paused: false)) { context in
            let t = context.date.timeIntervalSinceReferenceDate
            let pulse = (sin(t * .pi * 2.0 / 4.0) + 1.0) * 0.5

            VStack(spacing: 24) {
                Spacer()

                ZStack {
                    // Ambient glow behind icon
                    Circle()
                        .fill(
                            RadialGradient(
                                colors: [Color.cyan.opacity(0.12 + pulse * 0.06), .clear],
                                center: .center, startRadius: 10, endRadius: 80
                            )
                        )
                        .frame(width: 160, height: 160)

                    Image(systemName: "figure.yoga")
                        .font(.system(size: 120))
                        .foregroundStyle(.cyan.opacity(0.8))
                        .scaleEffect(0.97 + pulse * 0.04)
                        .shadow(color: .cyan.opacity(0.4), radius: 8)
                        .shadow(color: .cyan.opacity(0.15), radius: 20)
                }

                Text(pose.name.localized)
                    .font(.system(size: 32, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
                    .shadow(color: .cyan.opacity(0.3), radius: 8)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)

                // Volumetric countdown ring
                ZStack {
                    // Ambient ring glow
                    Circle()
                        .fill(
                            RadialGradient(
                                colors: [Color.cyan.opacity(0.05), .clear],
                                center: .center, startRadius: 50, endRadius: 90
                            )
                        )
                        .frame(width: 180, height: 180)

                    // Outer blurred glow ring
                    Circle()
                        .trim(from: 0, to: total > 0 ? remaining / total : 0)
                        .stroke(Color.cyan.opacity(0.3), style: StrokeStyle(lineWidth: 14, lineCap: .round))
                        .rotationEffect(.degrees(-90))
                        .blur(radius: 6)
                        .animation(.spring(response: 0.5, dampingFraction: 0.8), value: remaining)

                    // Background track
                    Circle()
                        .stroke(Color.white.opacity(0.08), lineWidth: 8)

                    // Main ring
                    Circle()
                        .trim(from: 0, to: total > 0 ? remaining / total : 0)
                        .stroke(Color.cyan, style: StrokeStyle(lineWidth: 8, lineCap: .round))
                        .rotationEffect(.degrees(-90))
                        .shadow(color: .cyan.opacity(0.6), radius: 10)
                        .shadow(color: .cyan.opacity(0.3), radius: 3)
                        .animation(.spring(response: 0.5, dampingFraction: 0.8), value: remaining)

                    // Inner highlight ring
                    Circle()
                        .trim(from: 0, to: total > 0 ? remaining / total : 0)
                        .stroke(Color.white.opacity(0.35), style: StrokeStyle(lineWidth: 2, lineCap: .round))
                        .rotationEffect(.degrees(-90))
                        .animation(.spring(response: 0.5, dampingFraction: 0.8), value: remaining)

                    Text(timeString)
                        .font(.system(size: 48, weight: .bold, design: .rounded))
                        .monospacedDigit()
                        .foregroundStyle(.white)
                        .shadow(color: .cyan.opacity(0.3), radius: 6)
                        .contentTransition(.numericText())
                }
                .frame(width: 140, height: 140)

                Spacer()
            }
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
