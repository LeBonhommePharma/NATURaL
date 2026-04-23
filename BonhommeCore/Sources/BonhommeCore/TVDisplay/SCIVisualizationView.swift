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

    public var body: some View {
        TimelineView(.animation(minimumInterval: 1.0 / 30.0, paused: score == nil)) { context in
            let t = context.date.timeIntervalSinceReferenceDate
            let breath = (sin(t * .pi * 2.0 / 3.5) + 1.0) * 0.5

            VStack(spacing: 8) {
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
                        .stroke(Color.white.opacity(0.08), lineWidth: 6)

                    // Main ring
                    Circle()
                        .trim(from: 0, to: score ?? 0)
                        .stroke(glowColor, style: StrokeStyle(lineWidth: 6, lineCap: .round))
                        .rotationEffect(.degrees(-90))
                        .shadow(color: glowColor.opacity(0.7), radius: 2)
                        .shadow(color: glowColor.opacity(0.4), radius: 10)
                        .animation(.spring(response: 0.6, dampingFraction: 0.7), value: score)

                    // Inner highlight
                    Circle()
                        .trim(from: 0, to: score ?? 0)
                        .stroke(Color.white.opacity(0.3), style: StrokeStyle(lineWidth: 1.5, lineCap: .round))
                        .rotationEffect(.degrees(-90))
                        .animation(.spring(response: 0.6, dampingFraction: 0.7), value: score)

                    VStack(spacing: 2) {
                        if let score {
                            Text(String(format: "%.0f", score * 100))
                                .font(.system(size: 28, weight: .bold, design: .rounded))
                                .monospacedDigit()
                                .foregroundStyle(.white)
                                .shadow(color: glowColor.opacity(0.5), radius: 6)
                                .contentTransition(.numericText())
                        } else {
                            Text("--")
                                .font(.system(size: 28, weight: .bold, design: .rounded))
                                .foregroundStyle(.white.opacity(0.3))
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

                Text(LocalizedString(en: "Focus Index", fr: "Indice de concentration", es: "Índice de concentración", ja: "集中力指数", zh: "专注力指数", ko: "집중력 지수", ru: "Индекс концентрации", de: "Fokus-Index", ar: "مؤشر التركيز").localized)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(.white.opacity(0.5))
            }
        }
    }

    private var glowColor: Color {
        guard let score else { return .gray }
        switch score {
        case ..<0.3: return .red
        case 0.3..<0.6: return .orange
        case 0.6..<0.8: return .cyan
        default: return .green
        }
    }

    private var trendIcon: String {
        switch trend {
        case .improving: return "arrow.up.right"
        case .stable: return "arrow.right"
        case .declining: return "arrow.down.right"
        }
    }

    private var trendColor: Color {
        switch trend {
        case .improving: return .green
        case .stable: return .white.opacity(0.5)
        case .declining: return .orange
        }
    }
}
