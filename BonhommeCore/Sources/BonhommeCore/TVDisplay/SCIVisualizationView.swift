import SwiftUI

/// Renders the Shannon Collapse Index score as an animated glow ring with trend indicator.
/// Volumetric ray-traced glow via layered circles + blur. Spring kinematics.
public struct SCIVisualizationView: View {
    public let score: Double?
    public let trend: SCITrend

    public init(score: Double?, trend: SCITrend) {
        self.score = score
        self.trend = trend
    }

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    public var body: some View {
        TimelineView(.animation(
            minimumInterval: SessionMotion.timelineInterval(reduceMotion),
            paused: score == nil || reduceMotion
        )) { context in
            let t = context.date.timeIntervalSinceReferenceDate
            let breath = reduceMotion ? 0.5 : (sin(t * .pi * 2.0 / 3.5) + 1.0) * 0.5

            VStack(spacing: SessionSpacing.xs) {
                ZStack {
                    // Ambient radial glow
                    Circle()
                        .fill(
                            RadialGradient(
                                colors: [glowColor.opacity(0.12 + breath * 0.06), .clear],
                                center: .center, startRadius: 8, endRadius: 60
                            )
                        )
                        .frame(width: 120, height: 120)

                    // Outer volumetric glow (blurred wide)
                    Circle()
                        .trim(from: 0, to: score ?? 0)
                        .stroke(glowColor.opacity(0.25), style: StrokeStyle(lineWidth: 12, lineCap: .round))
                        .rotationEffect(.degrees(-90))
                        .blur(radius: 8)
                        .animation(.spring(response: 0.6, dampingFraction: 0.7), value: score)

                    // Mid glow layer
                    Circle()
                        .trim(from: 0, to: score ?? 0)
                        .stroke(glowColor.opacity(0.4), style: StrokeStyle(lineWidth: 8, lineCap: .round))
                        .rotationEffect(.degrees(-90))
                        .blur(radius: 3)
                        .animation(.spring(response: 0.6, dampingFraction: 0.7), value: score)

                    // Background track
                    Circle()
                        .stroke(BrandColor.hairline, lineWidth: 6)

                    // Main ring
                    Circle()
                        .trim(from: 0, to: score ?? 0)
                        .stroke(glowColor, style: StrokeStyle(lineWidth: 6, lineCap: .round))
                        .rotationEffect(.degrees(-90))
                        .shadow(color: glowColor.opacity(0.7), radius: 2)
                        .sessionGlow(glowColor, radius: 10, paused: reduceMotion)
                        .animation(.spring(response: 0.6, dampingFraction: 0.7), value: score)

                    // Inner highlight
                    Circle()
                        .trim(from: 0, to: score ?? 0)
                        .stroke(BrandColor.magnesium.opacity(0.30), style: StrokeStyle(lineWidth: 1.5, lineCap: .round))
                        .rotationEffect(.degrees(-90))
                        .animation(.spring(response: 0.6, dampingFraction: 0.7), value: score)

                    VStack(spacing: 2) {
                        if let score {
                            Text(String(format: "%.0f", score * 100))
                                .font(SessionType.metric(size: 28))
                                .monospacedDigit()
                                .foregroundStyle(BrandColor.fg)
                                .sessionGlow(glowColor, radius: 6, paused: reduceMotion)
                                .contentTransition(.numericText())
                        } else {
                            Text("--")
                                .font(SessionType.metric(size: 28))
                                .foregroundStyle(BrandColor.magnesium)
                        }

                        Image(systemName: trendIcon)
                            .font(.system(size: 12))
                            .foregroundStyle(trendColor)
                            .shadow(color: trendColor.opacity(0.4), radius: 4)
                            .contentTransition(.symbolEffect(.replace))
                            .animation(.spring(response: 0.4, dampingFraction: 0.7), value: trend)
                    }
                }
                .frame(width: 100, height: 100)

                Text(SessionHUDCopy.focusIndex.localized)
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(BrandColor.fgMuted)
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Text(SessionHUDCopy.focusIndex.localized))
        .accessibilityValue(Text(score.map { "\(Int(($0 * 100).rounded())) percent" } ?? "unavailable"))
    }

    private var glowColor: Color { SessionPalette.sci(score) }

    private var trendIcon: String { trend.symbolName }

    private var trendColor: Color { SessionPalette.trend(trend) }
}
