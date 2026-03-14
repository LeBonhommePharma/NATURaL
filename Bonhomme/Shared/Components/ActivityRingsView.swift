import SwiftUI

/// Draws Apple Activity-style concentric rings for Move, Exercise, and Stand.
struct ActivityRingsView: View {
    let moveProgress: Double
    let exerciseProgress: Double
    let standProgress: Double

    var body: some View {
        ZStack {
            // Stand ring (outermost)
            ringView(progress: standProgress, color: .cyan, size: 100)
            // Exercise ring (middle)
            ringView(progress: exerciseProgress, color: .green, size: 76)
            // Move ring (innermost)
            ringView(progress: moveProgress, color: .red, size: 52)
        }
        .frame(width: 110, height: 110)
    }

    private func ringView(progress: Double, color: Color, size: CGFloat) -> some View {
        ZStack {
            Circle()
                .stroke(color.opacity(0.2), lineWidth: 10)

            Circle()
                .trim(from: 0, to: min(progress, 1.0))
                .stroke(
                    color,
                    style: StrokeStyle(lineWidth: 10, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))
                .animation(.easeInOut(duration: 0.6), value: progress)

            // Overflow: if progress > 1.0, draw second lap with reduced opacity
            if progress > 1.0 {
                Circle()
                    .trim(from: 0, to: min(progress - 1.0, 1.0))
                    .stroke(
                        color.opacity(0.6),
                        style: StrokeStyle(lineWidth: 10, lineCap: .round)
                    )
                    .rotationEffect(.degrees(-90))
                    .animation(.easeInOut(duration: 0.6), value: progress)
            }
        }
        .frame(width: size, height: size)
    }
}
