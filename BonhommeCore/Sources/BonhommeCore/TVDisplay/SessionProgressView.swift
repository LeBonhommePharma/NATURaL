import SwiftUI

/// Shows the session progress: which pose in the sequence and total elapsed time.
/// Shimmering gradient fill with leading edge glow.
public struct SessionProgressView: View {
    public let index: Int
    public let total: Int
    public let elapsed: TimeInterval

    public init(index: Int, total: Int, elapsed: TimeInterval) {
        self.index = index
        self.total = total
        self.elapsed = elapsed
    }

    public var body: some View {
        VStack(spacing: 8) {
            Text("\(index + 1) / \(total)")
                .font(.system(size: 20, weight: .semibold, design: .rounded))
                .monospacedDigit()
                .foregroundStyle(.white)
                .shadow(color: .white.opacity(0.2), radius: 4)

            TimelineView(.animation(minimumInterval: 1.0 / 30.0, paused: false)) { context in
                let shimmer = CGFloat(fmod(context.date.timeIntervalSinceReferenceDate, 2.0) / 2.0)
                let fraction = total > 0 ? CGFloat(index + 1) / CGFloat(total) : 0

                GeometryReader { geo in
                    let fillWidth = geo.size.width * fraction

                    ZStack(alignment: .leading) {
                        // Background track
                        RoundedRectangle(cornerRadius: 4)
                            .fill(Color.white.opacity(0.1))
                            .frame(height: 6)

                        // Filled bar with shimmer
                        RoundedRectangle(cornerRadius: 4)
                            .fill(
                                LinearGradient(
                                    stops: [
                                        .init(color: .cyan, location: max(0, shimmer - 0.15)),
                                        .init(color: .cyan.opacity(0.6).mix(with: .white, by: 0.4), location: shimmer),
                                        .init(color: .cyan, location: min(1, shimmer + 0.15))
                                    ],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .frame(width: fillWidth, height: 6)
                            .shadow(color: .cyan.opacity(0.4), radius: 4)
                            .animation(.spring(response: 0.5, dampingFraction: 0.75), value: index)

                        // Leading edge glow
                        if fillWidth > 4 {
                            Circle()
                                .fill(.white.opacity(0.7))
                                .frame(width: 6, height: 6)
                                .blur(radius: 3)
                                .shadow(color: .cyan, radius: 6)
                                .offset(x: fillWidth - 3)
                                .animation(.spring(response: 0.5, dampingFraction: 0.75), value: index)
                        }
                    }
                }
                .frame(height: 6)
            }

            Text(elapsedString)
                .font(.system(size: 14, weight: .medium, design: .rounded))
                .monospacedDigit()
                .foregroundStyle(.white.opacity(0.5))
        }
        .padding(.horizontal, 16)
    }

    private var elapsedString: String {
        let totalSeconds = Int(elapsed)
        let minutes = totalSeconds / 60
        let seconds = totalSeconds % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
}
