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
            paused: !known || reduceMotion
        )) { context in
            let t = context.date.timeIntervalSinceReferenceDate
            let breath = reduceMotion || !known ? 0.5 : (sin(t * .pi * 2.0 / 3.5) + 1.0) * 0.5

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

                    if known, clampedScore > 0 {
                        // Outer volumetric glow (blurred wide)
                        Circle()
                            .trim(from: 0, to: clampedScore)
                            .stroke(glowColor.opacity(0.25), style: StrokeStyle(lineWidth: 12, lineCap: .round))
                            .rotationEffect(.degrees(-90))
                            .blur(radius: reduceMotion ? 0 : 8)
                            .animation(SessionMotion.spring(reduceMotion: reduceMotion), value: score)

                        // Mid glow layer
                        Circle()
                            .trim(from: 0, to: clampedScore)
                            .stroke(glowColor.opacity(0.4), style: StrokeStyle(lineWidth: 8, lineCap: .round))
                            .rotationEffect(.degrees(-90))
                            .blur(radius: reduceMotion ? 0 : 3)
                            .animation(SessionMotion.spring(reduceMotion: reduceMotion), value: score)
                    }

                    // Background track — dashed when SCI is unknown (same language as CompactSCIMeter)
                    Circle()
                        .stroke(
                            BrandColor.hairline,
                            style: StrokeStyle(lineWidth: 6, dash: known ? [] : [4, 3])
                        )

                    if known, clampedScore > 0 {
                        // Main ring
                        Circle()
                            .trim(from: 0, to: clampedScore)
                            .stroke(glowColor, style: StrokeStyle(lineWidth: 6, lineCap: .round))
                            .rotationEffect(.degrees(-90))
                            .shadow(color: glowColor.opacity(0.7), radius: reduceMotion ? 0 : 2)
                            .sessionGlow(glowColor, radius: 10, paused: reduceMotion)
                            .animation(SessionMotion.spring(reduceMotion: reduceMotion), value: score)

                        // Inner highlight
                        Circle()
                            .trim(from: 0, to: clampedScore)
                            .stroke(BrandColor.magnesium.opacity(0.30), style: StrokeStyle(lineWidth: 1.5, lineCap: .round))
                            .rotationEffect(.degrees(-90))
                            .animation(SessionMotion.spring(reduceMotion: reduceMotion), value: score)
                    }

                    VStack(spacing: 2) {
                        Text(percentText)
                            .font(SessionType.metric(size: 28))
                            .monospacedDigit()
                            .foregroundStyle(known ? BrandColor.fg : BrandColor.magnesium)
                            .sessionGlow(glowColor, radius: 6, paused: reduceMotion || !known)
                            .contentTransition(reduceMotion ? .identity : .numericText())

                        Image(systemName: trendIcon)
                            .font(.system(size: 12))
                            .foregroundStyle(trendColor)
                            .shadow(color: trendColor.opacity(reduceMotion || !known ? 0 : 0.4), radius: reduceMotion || !known ? 0 : 4)
                            .contentTransition(reduceMotion ? .identity : .symbolEffect(.replace))
                            .animation(SessionMotion.spring(reduceMotion: reduceMotion), value: trend)
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
        .accessibilityValue(Text(percentText == "—" ? "unavailable" : "\(percentText) percent"))
    }

    private var known: Bool {
        score.map(\.isFinite) ?? false
    }

    private var clampedScore: CGFloat {
        guard let score, score.isFinite else { return 0 }
        return CGFloat(min(1, max(0, score)))
    }

    private var percentText: String {
        SessionHUDMetrics(sciScore: score).sciPercentText
    }

    private var glowColor: Color { SessionPalette.sci(score) }

    private var trendIcon: String { trend.symbolName }

    private var trendColor: Color { SessionPalette.trend(trend) }
}
