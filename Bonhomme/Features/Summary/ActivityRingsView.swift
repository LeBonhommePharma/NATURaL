import SwiftUI
import BonhommeCore

/// Activity ring visualization. Move / Exercise / Stand use family tokens
/// (firetruck / mint / aqua) plus text — color is never the only cue.
struct ActivityRingsView: View {
    let moveProgress: Double
    let exerciseProgress: Double
    let standProgress: Double

    var moveDelta: String?
    var exerciseDelta: String?

    var body: some View {
        HStack(spacing: SessionSpacing.md) {
            ZStack {
                if standProgress > 0 {
                    RingShape(progress: standProgress)
                        .stroke(BrandColor.aqua, style: StrokeStyle(lineWidth: 14, lineCap: .round))
                        .frame(width: 100, height: 100)
                }

                RingShape(progress: 1.0)
                    .stroke(BrandColor.aqua.opacity(0.2), lineWidth: 14)
                    .frame(width: 100, height: 100)

                if exerciseProgress > 0 {
                    RingShape(progress: exerciseProgress)
                        .stroke(BrandColor.mint, style: StrokeStyle(lineWidth: 14, lineCap: .round))
                        .frame(width: 72, height: 72)
                }

                RingShape(progress: 1.0)
                    .stroke(BrandColor.mint.opacity(0.2), lineWidth: 14)
                    .frame(width: 72, height: 72)

                if moveProgress > 0 {
                    RingShape(progress: moveProgress)
                        .stroke(BrandColor.firetruck, style: StrokeStyle(lineWidth: 14, lineCap: .round))
                        .frame(width: 44, height: 44)
                }

                RingShape(progress: 1.0)
                    .stroke(BrandColor.firetruck.opacity(0.2), lineWidth: 14)
                    .frame(width: 44, height: 44)
            }
            .frame(width: 100, height: 100)
            .accessibilityElement(children: .ignore)
            .accessibilityLabel(ringSummary)

            if moveDelta != nil || exerciseDelta != nil {
                VStack(alignment: .leading, spacing: SessionSpacing.xs) {
                    if let moveDelta {
                        ringLabel(systemImage: "flame.fill", color: BrandColor.firetruck, text: "Move \(moveDelta)")
                    }
                    if let exerciseDelta {
                        ringLabel(systemImage: "figure.walk", color: BrandColor.mint, text: "Exercise \(exerciseDelta)")
                    }
                }
            }
        }
    }

    private var ringSummary: String {
        let move = Int((min(max(moveProgress, 0), 2) * 100).rounded())
        let exercise = Int((min(max(exerciseProgress, 0), 2) * 100).rounded())
        let stand = Int((min(max(standProgress, 0), 2) * 100).rounded())
        return "Move \(move) percent, Exercise \(exercise) percent, Stand \(stand) percent"
    }

    private func ringLabel(systemImage: String, color: Color, text: String) -> some View {
        Label(text, systemImage: systemImage)
            .font(.system(size: 14, weight: .medium, design: .rounded))
            .foregroundStyle(color)
            .labelStyle(.titleAndIcon)
            .symbolRenderingMode(.hierarchical)
    }
}

struct RingShape: Shape {
    var progress: Double

    var animatableData: Double {
        get { progress }
        set { progress = newValue }
    }

    func path(in rect: CGRect) -> Path {
        var path = Path()
        let clampedProgress = min(max(progress, 0), 2.0)
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
