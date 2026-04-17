import SwiftUI

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
            let kinematics = pose.kinematics
            let catColor = Color(hue: pose.category.accentHue, saturation: 0.7, brightness: 0.9)

            VStack(spacing: 24) {
                Spacer()

                ZStack {
                    Circle()
                        .fill(
                            RadialGradient(
                                colors: [catColor.opacity(0.12 + pulse * 0.06), .clear],
                                center: .center, startRadius: 10, endRadius: 80
                            )
                        )
                        .frame(width: 160, height: 160)

                    MotionCoachView(pose: pose, phase: .active, cornerRadius: 20)
                        .frame(width: 120, height: 120)
                        .scaleEffect(0.97 + pulse * 0.04)
                        .shadow(color: catColor.opacity(0.4), radius: 8)
                        .shadow(color: catColor.opacity(0.15), radius: 20)
                }

                if !kinematics.setupSteps.isEmpty {
                    Text(kinematics.setupSteps.first?.localized ?? "")
                        .font(.system(size: 18, weight: .medium, design: .rounded))
                        .foregroundStyle(.white.opacity(0.6))
                        .lineLimit(2)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 32)
                }

                Text(pose.name.localized)
                    .font(.system(size: 32, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
                    .shadow(color: catColor.opacity(0.3), radius: 8)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)

                // Volumetric countdown ring
                ZStack {
                    Circle()
                        .fill(
                            RadialGradient(
                                colors: [catColor.opacity(0.05), .clear],
                                center: .center, startRadius: 50, endRadius: 90
                            )
                        )
                        .frame(width: 180, height: 180)

                    Circle()
                        .trim(from: 0, to: total > 0 ? remaining / total : 0)
                        .stroke(catColor.opacity(0.3), style: StrokeStyle(lineWidth: 14, lineCap: .round))
                        .rotationEffect(.degrees(-90))
                        .blur(radius: 6)
                        .animation(.spring(response: 0.5, dampingFraction: 0.8), value: remaining)

                    Circle()
                        .stroke(Color.white.opacity(0.08), lineWidth: 8)

                    Circle()
                        .trim(from: 0, to: total > 0 ? remaining / total : 0)
                        .stroke(catColor, style: StrokeStyle(lineWidth: 8, lineCap: .round))
                        .rotationEffect(.degrees(-90))
                        .shadow(color: catColor.opacity(0.6), radius: 10)
                        .shadow(color: catColor.opacity(0.3), radius: 3)
                        .animation(.spring(response: 0.5, dampingFraction: 0.8), value: remaining)

                    Circle()
                        .trim(from: 0, to: total > 0 ? remaining / total : 0)
                        .stroke(Color.white.opacity(0.35), style: StrokeStyle(lineWidth: 2, lineCap: .round))
                        .rotationEffect(.degrees(-90))
                        .animation(.spring(response: 0.5, dampingFraction: 0.8), value: remaining)

                    Text(timeString)
                        .font(.system(size: 48, weight: .bold, design: .rounded))
                        .monospacedDigit()
                        .foregroundStyle(.white)
                        .shadow(color: catColor.opacity(0.3), radius: 6)
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
