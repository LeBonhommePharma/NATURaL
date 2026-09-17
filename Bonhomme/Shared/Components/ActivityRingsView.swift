import SwiftUI
import BonhommeCore

/// Concentric Move / Exercise / Stand rings. Family tokens (firetruck / mint / aqua)
/// plus VoiceOver percents — color is never the only cue.
struct ActivityRingsView: View {
    let moveProgress: Double
    let exerciseProgress: Double
    let standProgress: Double

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var animatedMove: Double = 0
    @State private var animatedExercise: Double = 0
    @State private var animatedStand: Double = 0

    var body: some View {
        ZStack {
            Circle()
                .fill(
                    RadialGradient(
                        colors: [Color.white.opacity(0.03), .clear],
                        center: .center, startRadius: 10, endRadius: 55
                    )
                )
                .frame(width: 110, height: 110)

            ringView(progress: animatedStand, color: BrandColor.aqua, size: 100)
            ringView(progress: animatedExercise, color: BrandColor.mint, size: 76)
            ringView(progress: animatedMove, color: BrandColor.firetruck, size: 52)
        }
        .frame(width: 110, height: 110)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(ringSummary)
        .onAppear { applyProgress(animated: !reduceMotion) }
        .onChange(of: moveProgress) { _, new in setMove(new) }
        .onChange(of: exerciseProgress) { _, new in setExercise(new) }
        .onChange(of: standProgress) { _, new in setStand(new) }
        .onChange(of: reduceMotion) { _, off in
            if off { snap() }
        }
    }

    private var ringSummary: String {
        let move = Int((min(max(moveProgress, 0), 2) * 100).rounded())
        let exercise = Int((min(max(exerciseProgress, 0), 2) * 100).rounded())
        let stand = Int((min(max(standProgress, 0), 2) * 100).rounded())
        return "Move \(move) percent, Exercise \(exercise) percent, Stand \(stand) percent"
    }

    private func snap() {
        animatedMove = moveProgress
        animatedExercise = exerciseProgress
        animatedStand = standProgress
    }

    private func applyProgress(animated: Bool) {
        if animated {
            withAnimation(.spring(response: 0.7, dampingFraction: 0.75)) {
                animatedStand = standProgress
            }
            withAnimation(.spring(response: 0.7, dampingFraction: 0.75).delay(0.1)) {
                animatedExercise = exerciseProgress
            }
            withAnimation(.spring(response: 0.7, dampingFraction: 0.75).delay(0.2)) {
                animatedMove = moveProgress
            }
        } else {
            snap()
        }
    }

    private func setMove(_ value: Double) {
        guard !reduceMotion else { animatedMove = value; return }
        withAnimation(.spring(response: 0.7, dampingFraction: 0.75)) { animatedMove = value }
    }

    private func setExercise(_ value: Double) {
        guard !reduceMotion else { animatedExercise = value; return }
        withAnimation(.spring(response: 0.7, dampingFraction: 0.75)) { animatedExercise = value }
    }

    private func setStand(_ value: Double) {
        guard !reduceMotion else { animatedStand = value; return }
        withAnimation(.spring(response: 0.7, dampingFraction: 0.75)) { animatedStand = value }
    }

    private func ringView(progress: Double, color: Color, size: CGFloat) -> some View {
        ZStack {
            Circle()
                .stroke(color.opacity(0.2), lineWidth: 10)
            Circle()
                .trim(from: 0, to: min(progress, 1.0))
                .stroke(color, style: StrokeStyle(lineWidth: 10, lineCap: .round))
                .rotationEffect(.degrees(-90))
            if progress > 1.0 {
                Circle()
                    .trim(from: 0, to: min(progress - 1.0, 1.0))
                    .stroke(color.opacity(0.6), style: StrokeStyle(lineWidth: 10, lineCap: .round))
                    .rotationEffect(.degrees(-90))
            }
        }
        .frame(width: size, height: size)
    }
}
