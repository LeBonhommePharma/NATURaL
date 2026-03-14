import SwiftUI

/// Bottom metrics bar showing HR, calories, and elapsed time during a workout.
/// Styled similar to the Fitness+ burn bar but with personal HR zones.
struct MetricsOverlayView: View {
    let heartRate: Double?
    let calories: Double
    let elapsed: TimeInterval
    let poseIndex: Int
    let totalPoses: Int

    var body: some View {
        HStack(spacing: 24) {
            // Heart rate
            HStack(spacing: 6) {
                Image(systemName: "heart.fill")
                    .foregroundStyle(hrZoneColor)
                Text(heartRate.map { "\(Int($0))" } ?? "--")
                    .monospacedDigit()
                Text("BPM")
                    .foregroundStyle(.secondary)
            }
            .font(.system(size: 16, weight: .semibold))

            Divider()
                .frame(height: 20)

            // Calories
            HStack(spacing: 6) {
                Image(systemName: "flame.fill")
                    .foregroundStyle(.orange)
                Text("\(Int(calories))")
                    .monospacedDigit()
                Text("CAL")
                    .foregroundStyle(.secondary)
            }
            .font(.system(size: 16, weight: .semibold))

            Divider()
                .frame(height: 20)

            // Elapsed time
            HStack(spacing: 6) {
                Image(systemName: "timer")
                    .foregroundStyle(.cyan)
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
        .padding(.horizontal, 16)
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

/// Horizontal HR zone indicator bar, similar to Fitness+ burn bar
/// but showing personal effort zones instead of competitive comparison.
struct BurnBarView: View {
    let heartRate: Double?
    let maxHR: Double

    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                // Zone segments
                HStack(spacing: 2) {
                    zoneSegment(.green, label: "Recovery", width: 0.25, geo: geo)
                    zoneSegment(.yellow, label: "Fat Burn", width: 0.25, geo: geo)
                    zoneSegment(.orange, label: "Cardio", width: 0.25, geo: geo)
                    zoneSegment(.red, label: "Peak", width: 0.25, geo: geo)
                }
                .clipShape(Capsule())

                // Current position indicator
                if let heartRate, maxHR > 0 {
                    let fraction = min(1.0, max(0, heartRate / maxHR))
                    Circle()
                        .fill(.white)
                        .shadow(color: .black.opacity(0.4), radius: 4)
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
        label: String,
        width: Double,
        geo: GeometryProxy
    ) -> some View {
        Rectangle()
            .fill(color.opacity(0.6))
            .frame(width: geo.size.width * width)
    }
}
