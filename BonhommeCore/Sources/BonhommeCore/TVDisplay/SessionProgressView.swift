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
                                        .init(color: blendColors(.cyan.opacity(0.6), .white, by: 0.4), location: shimmer),
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

private func blendColors(_ c1: Color, _ c2: Color, by t: CGFloat) -> Color {
    // Prefer native mix when available
    if #available(iOS 18.0, macOS 15.0, tvOS 18.0, watchOS 11.0, *) {
        return c1.mix(with: c2, by: t)
    }

    #if canImport(UIKit)
    let ui1 = UIColor(c1)
    let ui2 = UIColor(c2)

    var r1: CGFloat = 0, g1: CGFloat = 0, b1: CGFloat = 0, a1: CGFloat = 0
    var r2: CGFloat = 0, g2: CGFloat = 0, b2: CGFloat = 0, a2: CGFloat = 0

    ui1.getRed(&r1, green: &g1, blue: &b1, alpha: &a1)
    ui2.getRed(&r2, green: &g2, blue: &b2, alpha: &a2)

    let clampedT = max(0, min(1, t))
    let r = r1 + (r2 - r1) * clampedT
    let g = g1 + (g2 - g1) * clampedT
    let b = b1 + (b2 - b1) * clampedT
    let a = a1 + (a2 - a1) * clampedT

    return Color(UIColor(red: r, green: g, blue: b, alpha: a))
    #elseif canImport(AppKit)
    let ns1 = NSColor(c1)
    let ns2 = NSColor(c2)

    guard let c1rgb = ns1.usingColorSpace(.deviceRGB), let c2rgb = ns2.usingColorSpace(.deviceRGB) else {
        // Fallback if conversion fails
        return c1
    }

    let r = c1rgb.redComponent + (c2rgb.redComponent - c1rgb.redComponent) * t
    let g = c1rgb.greenComponent + (c2rgb.greenComponent - c1rgb.greenComponent) * t
    let b = c1rgb.blueComponent + (c2rgb.blueComponent - c1rgb.blueComponent) * t
    let a = c1rgb.alphaComponent + (c2rgb.alphaComponent - c1rgb.alphaComponent) * t

    return Color(NSColor(calibratedRed: r, green: g, blue: b, alpha: a))
    #else
    // Generic fallback: return the first color if platform is unknown
    return c1
    #endif
}
