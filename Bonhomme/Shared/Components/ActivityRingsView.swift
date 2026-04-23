import SwiftUI

/// Draws Apple Activity-style concentric rings with glow halos, spring physics, and staggered entry.
struct ActivityRingsView: View {
    let moveProgress: Double
    let exerciseProgress: Double
    let standProgress: Double

    @State private var animatedMove: Double = 0
    @State private var animatedExercise: Double = 0
    @State private var animatedStand: Double = 0

    var body: some View {
        ZStack {
            // Background depth disc
            Circle()
                .fill(
                    RadialGradient(
                        colors: [Color.white.opacity(0.03), .clear],
                        center: .center, startRadius: 10, endRadius: 55
                    )
                )
                .frame(width: 110, height: 110)

            ringView(progress: animatedStand, color: .cyan, size: 100)
            ringView(progress: animatedExercise, color: .green, size: 76)
            ringView(progress: animatedMove, color: .red, size: 52)
        }
        .frame(width: 110, height: 110)
        .onAppear {
            withAnimation(.spring(response: 0.7, dampingFraction: 0.75)) {
                animatedStand = standProgress
            }
            withAnimation(.spring(response: 0.7, dampingFraction: 0.75).delay(0.1)) {
                animatedExercise = exerciseProgress
            }
            withAnimation(.spring(response: 0.7, dampingFraction: 0.75).delay(0.2)) {
                animatedMove = moveProgress
            }
        }
        .onChange(of: moveProgress) { _, new in
            withAnimation(.spring(response: 0.7, dampingFraction: 0.75)) { animatedMove = new }
        }
        .onChange(of: exerciseProgress) { _, new in
            withAnimation(.spring(response: 0.7, dampingFraction: 0.75)) { animatedExercise = new }
        }
        .onChange(of: standProgress) { _, new in
            withAnimation(.spring(response: 0.7, dampingFraction: 0.75)) { animatedStand = new }
        }
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
                .shadow(color: color.opacity(0.4), radius: 6)
                .shadow(color: .black.opacity(0.3), radius: 2)

            // Overflow: second lap with extra glow
            if progress > 1.0 {
                Circle()
                    .trim(from: 0, to: min(progress - 1.0, 1.0))
                    .stroke(
                        color.opacity(0.6),
                        style: StrokeStyle(lineWidth: 10, lineCap: .round)
                    )
                    .rotationEffect(.degrees(-90))
                    .shadow(color: color.opacity(0.5), radius: 8)
                    .shadow(color: color.opacity(0.2), radius: 14)
            }
        }
        .frame(width: size, height: size)
    }
}
