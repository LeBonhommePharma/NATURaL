import SwiftUI

/// Shows the session progress: which pose in the sequence and total elapsed time.
/// Shimmering gradient fill with leading edge glow.
public struct SessionProgressView: View {
    public let index: Int
    public let total: Int
    public let elapsed: TimeInterval

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    public init(index: Int, total: Int, elapsed: TimeInterval) {
        self.index = index
        self.total = total
        self.elapsed = elapsed
    }

    public var body: some View {
        VStack(spacing: 8) {
            Text(total > 0 ? "\(index + 1) / \(total)" : "—")
                .font(SessionType.metric(size: 20, weight: .semibold))
                .monospacedDigit()
                .foregroundStyle(BrandColor.fg)
                .accessibilityLabel(Text(total > 0 ? "Pose \(index + 1) of \(total)" : "Pose —"))

            TimelineView(.animation(
                minimumInterval: SessionMotion.timelineInterval(reduceMotion),
                paused: reduceMotion || total <= 0
            )) { context in
                let shimmer = reduceMotion || total <= 0
                    ? 0.5
                    : CGFloat(fmod(context.date.timeIntervalSinceReferenceDate, 2.0) / 2.0)
                let fraction: CGFloat? = total > 0 ? CGFloat(index + 1) / CGFloat(total) : nil

                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 4)
                            .fill(BrandColor.magnesium.opacity(0.16))
                            .frame(height: 6)

                        if let fraction {
                            let fillWidth = geo.size.width * fraction
                            RoundedRectangle(cornerRadius: 4)
                                .fill(
                                    LinearGradient(
                                        stops: [
                                            .init(color: BrandColor.mint, location: max(0, shimmer - 0.15)),
                                            .init(color: BrandColor.mint.opacity(0.7), location: shimmer),
                                            .init(color: BrandColor.mint, location: min(1, shimmer + 0.15))
                                        ],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                                .frame(width: fillWidth, height: 6)
                                .sessionGlow(BrandColor.mint, radius: 4, paused: reduceMotion)
                                .animation(.spring(response: 0.5, dampingFraction: 0.75), value: index)

                            if fillWidth > 4 {
                                Circle()
                                    .fill(BrandColor.fg.opacity(0.7))
                                    .frame(width: 6, height: 6)
                                    .sessionGlow(BrandColor.mint, radius: 6, paused: reduceMotion)
                                    .offset(x: fillWidth - 3)
                                    .animation(.spring(response: 0.5, dampingFraction: 0.75), value: index)
                            }
                        }
                    }
                }
                .frame(height: 6)
            }

            Text(elapsedString)
                .font(SessionType.metric(size: 14, weight: .medium))
                .monospacedDigit()
                .foregroundStyle(BrandColor.fgMuted)
        }
        .padding(.horizontal, 16)
    }

    private var elapsedString: String {
        SessionHUDMetrics.formatElapsed(elapsed)
    }
}
