import SwiftUI

/// Activity ring visualization mirroring Apple Fitness+ post-workout ring display.
/// Shows Move (red), Exercise (green), and Stand (cyan) rings with progress.
struct ActivityRingsView: View {
    let moveProgress: Double
    let exerciseProgress: Double
    let standProgress: Double

    /// Optional delta labels (e.g., "+45 cal", "+12 min")
    var moveDelta: String?
    var exerciseDelta: String?

    var body: some View {
        HStack(spacing: 20) {
            ZStack {
                // Stand ring (outermost)
                RingShape(progress: standProgress)
                    .stroke(Color.cyan, style: StrokeStyle(lineWidth: 14, lineCap: .round))
                    .frame(width: 100, height: 100)

                RingShape(progress: 1.0)
                    .stroke(Color.cyan.opacity(0.2), lineWidth: 14)
                    .frame(width: 100, height: 100)

                // Exercise ring (middle)
                RingShape(progress: exerciseProgress)
                    .stroke(Color.green, style: StrokeStyle(lineWidth: 14, lineCap: .round))
                    .frame(width: 72, height: 72)

                RingShape(progress: 1.0)
                    .stroke(Color.green.opacity(0.2), lineWidth: 14)
                    .frame(width: 72, height: 72)

                // Move ring (innermost)
                RingShape(progress: moveProgress)
                    .stroke(Color.red, style: StrokeStyle(lineWidth: 14, lineCap: .round))
                    .frame(width: 44, height: 44)

                RingShape(progress: 1.0)
                    .stroke(Color.red.opacity(0.2), lineWidth: 14)
                    .frame(width: 44, height: 44)
            }
            .frame(width: 100, height: 100)

            if moveDelta != nil || exerciseDelta != nil {
                VStack(alignment: .leading, spacing: 8) {
                    if let moveDelta {
                        ringLabel(color: .red, text: moveDelta)
                    }
                    if let exerciseDelta {
                        ringLabel(color: .green, text: exerciseDelta)
                    }
                }
            }
        }
    }

    private func ringLabel(color: Color, text: String) -> some View {
        HStack(spacing: 6) {
            Circle()
                .fill(color)
                .frame(width: 8, height: 8)
            Text(text)
                .font(.system(size: 14, weight: .medium, design: .rounded))
                .foregroundStyle(.secondary)
        }
    }
}

/// A circular arc shape used for activity ring rendering.
struct RingShape: Shape {
    var progress: Double

    var animatableData: Double {
        get { progress }
        set { progress = newValue }
    }

    func path(in rect: CGRect) -> Path {
        var path = Path()
        let clampedProgress = min(max(progress, 0), 2.0) // Allow up to 200%
        path.addArc(
            center: CGPoint(x: rect.midX, y: rect.midY),
            radius: rect.width / 2,
            startAngle: .degrees(-90),
            endAngle: .degrees(-90 + 360 * clampedProgress),
            clockwise: false
        )
        return path
    }
}
