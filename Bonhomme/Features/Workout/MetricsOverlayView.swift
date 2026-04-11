import SwiftUI

/// Bottom metrics bar with glassmorphism polish, micro-animated icons, and enhanced burn bar.
struct MetricsOverlayView: View {
    let heartRate: Double?
    let calories: Double
    let elapsed: TimeInterval
    let poseIndex: Int
    let totalPoses: Int

    @State private var heartPulse = false
    @State private var flameFlicker = false

    var body: some View {
        HStack(spacing: 24) {
            // Heart rate
            HStack(spacing: 6) {
                Image(systemName: "heart.fill")
                    .foregroundStyle(hrZoneColor)
                    .scaleEffect(heartPulse ? 1.08 : 1.0)
                    .shadow(color: hrZoneColor.opacity(0.3), radius: 3)
                Text(heartRate.map { "\(Int($0))" } ?? "--")
                    .monospacedDigit()
                Text("BPM")
                    .foregroundStyle(.secondary)
            }
            .font(.system(size: 16, weight: .semibold))

            // Custom divider
            Rectangle()
                .fill(
                    LinearGradient(
                        colors: [.white.opacity(0.0), .white.opacity(0.15), .white.opacity(0.0)],
                        startPoint: .top, endPoint: .bottom
                    )
                )
                .frame(width: 1, height: 20)

            // Calories
            HStack(spacing: 6) {
                Image(systemName: "flame.fill")
                    .foregroundStyle(.orange)
                    .opacity(flameFlicker ? 1.0 : 0.85)
                    .shadow(color: .orange.opacity(0.3), radius: 3)
                Text("\(Int(calories))")
                    .monospacedDigit()
                Text("CAL")
                    .foregroundStyle(.secondary)
            }
            .font(.system(size: 16, weight: .semibold))

            // Custom divider
            Rectangle()
                .fill(
                    LinearGradient(
                        colors: [.white.opacity(0.0), .white.opacity(0.15), .white.opacity(0.0)],
                        startPoint: .top, endPoint: .bottom
                    )
                )
                .frame(width: 1, height: 20)

            // Elapsed time
            HStack(spacing: 6) {
                Image(systemName: "timer")
                    .foregroundStyle(.cyan)
                    .shadow(color: .cyan.opacity(0.2), radius: 3)
                Text(formattedTime)
                    .monospacedDigit()
            }
            .font(.system(size: 16, weight: .semibold))

            Spacer()

            // Pose progress
            Text("\(poseIndex + 1)/\(totalPoses)")
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(.secondary)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 12)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16))
        .shadow(color: .black.opacity(0.2), radius: 8, y: 4)
        .padding(.horizontal, 16)
        .onAppear {
            withAnimation(.easeInOut(duration: 0.8).repeatForever(autoreverses: true)) {
                heartPulse = true
            }
            withAnimation(.easeInOut(duration: 0.6).repeatForever(autoreverses: true).delay(0.2)) {
                flameFlicker = true
            }
        }
    }

    private var formattedTime: String {
        let minutes = Int(elapsed) / 60
        let seconds = Int(elapsed) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }

    private var hrZoneColor: Color {
        guard let hr = heartRate else { return .gray }
        switch hr {
        case ..<100: return .green
        case 100..<130: return .yellow
        case 130..<160: return .orange
        default: return .red
        }
    }
}

/// Horizontal HR zone indicator bar with glowing position indicator.
struct BurnBarView: View {
    let heartRate: Double?
    let maxHR: Double

    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                // Zone segments with inner glow
                HStack(spacing: 2) {
                    zoneSegment(.green, width: 0.25, geo: geo)
                    zoneSegment(.yellow, width: 0.25, geo: geo)
                    zoneSegment(.orange, width: 0.25, geo: geo)
                    zoneSegment(.red, width: 0.25, geo: geo)
                }
                .clipShape(Capsule())

                // Glowing position indicator
                if let heartRate, maxHR > 0 {
                    let fraction = min(1.0, max(0, heartRate / maxHR))
                    Circle()
                        .fill(.white)
                        .shadow(color: .white.opacity(0.6), radius: 6)
                        .shadow(color: .black.opacity(0.4), radius: 2)
                        .frame(width: 16, height: 16)
                        .offset(x: fraction * (geo.size.width - 16))
                        .animation(.easeInOut(duration: 0.5), value: heartRate)
                }
            }
        }
        .frame(height: 20)
    }

    private func zoneSegment(
        _ color: Color,
        width: Double,
        geo: GeometryProxy
    ) -> some View {
        ZStack {
            Rectangle()
                .fill(color.opacity(0.6))
            // Inner glow overlay
            LinearGradient(
                colors: [color.opacity(0.3), .clear],
                startPoint: .top, endPoint: .bottom
            )
        }
        .frame(width: geo.size.width * width)
    }
}
