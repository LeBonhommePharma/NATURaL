import SwiftUI

/// Renders the Shannon Collapse Index score as an animated glow ring with trend indicator.
public struct SCIVisualizationView: View {
    public let score: Double?
    public let trend: SCITrend

    public init(score: Double?, trend: SCITrend) {
        self.score = score
        self.trend = trend
    }

    public var body: some View {
        VStack(spacing: 8) {
            ZStack {
                // Outer glow ring
                Circle()
                    .stroke(Color.white.opacity(0.1), lineWidth: 6)

                Circle()
                    .trim(from: 0, to: score ?? 0)
                    .stroke(
                        glowColor,
                        style: StrokeStyle(lineWidth: 6, lineCap: .round)
                    )
                    .rotationEffect(.degrees(-90))
                    .shadow(color: glowColor.opacity(0.6), radius: 8)
                    .animation(.easeInOut(duration: 0.8), value: score)

                VStack(spacing: 2) {
                    if let score {
                        Text(String(format: "%.0f", score * 100))
                            .font(.system(size: 28, weight: .bold, design: .rounded))
                            .monospacedDigit()
                            .foregroundStyle(.white)
                            .contentTransition(.numericText())
                    } else {
                        Text("--")
                            .font(.system(size: 28, weight: .bold, design: .rounded))
                            .foregroundStyle(.white.opacity(0.3))
                    }

                    Image(systemName: trendIcon)
                        .font(.system(size: 12))
                        .foregroundStyle(trendColor)
                }
            }
            .frame(width: 100, height: 100)

            Text(LocalizedString(en: "Focus Index", fr: "Indice de concentration", es: "Índice de concentración", ja: "集中力指数", zh: "专注力指数", ko: "집중력 지수", ru: "Индекс концентрации", de: "Fokus-Index", ar: "مؤشر التركيز").localized)
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(.white.opacity(0.5))
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
