import SwiftUI
import BonhommeCore

/// The main guided workout screen that drives the pose-by-pose flow.
struct WorkoutFlowView: View {
    @State private var viewModel: WorkoutFlowViewModel
    @Environment(\.dismiss) private var dismiss

    init(plan: WorkoutPlan) {
        _viewModel = State(initialValue: WorkoutFlowViewModel(plan: plan))
    }

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            switch viewModel.phase {
            case .ready:
                readyView
            case .countdown(let seconds):
                CountdownView(secondsRemaining: seconds)
            case .active(let poseIndex):
                activePoseView(poseIndex: poseIndex)
            case .transition(let nextIndex, let seconds):
                transitionView(nextIndex: nextIndex, seconds: seconds)
            case .cooldown:
                cooldownView
            case .complete:
                SummaryView(result: viewModel.buildResult()) {
                    dismiss()
                }
            }
        }
        .preferredColorScheme(.dark)
        .navigationBarBackButtonHidden()
        .statusBarHidden()
    }

    // MARK: - Phase Views

    private var readyView: some View {
        VStack(spacing: 32) {
            Spacer()

            Image(systemName: "figure.yoga")
                .font(.system(size: 80))
                .foregroundStyle(.cyan)

            Text(viewModel.plan.name.localized)
                .font(.system(size: 28, weight: .bold, design: .rounded))
                .foregroundStyle(.white)

            Text("\(viewModel.plan.poseCount) poses · \(formattedDuration(viewModel.plan.totalDuration))")
                .font(.system(size: 18))
                .foregroundStyle(.white.opacity(0.6))

            Spacer()

            Button {
                viewModel.start()
            } label: {
                Text(LocalizedString(en: "Begin Session", fr: "Commencer la séance").localized)
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundStyle(.black)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(.cyan, in: RoundedRectangle(cornerRadius: 16))
            }
            .padding(.horizontal, 40)

            Button(LocalizedString(en: "Cancel", fr: "Annuler").localized) { dismiss() }
                .foregroundStyle(.white.opacity(0.5))
                .padding(.bottom, 32)
        }
    }

    private func activePoseView(poseIndex: Int) -> some View {
        let pose = viewModel.plan.poses[poseIndex]
        let catColor = Color(hue: pose.category.accentHue, saturation: 0.7, brightness: 0.9)
        return VStack(spacing: 0) {
            Spacer()

            // Category icon — specific to this pose's target area
            Image(systemName: pose.category.symbolName)
                .font(.system(size: 80))
                .foregroundStyle(catColor.opacity(0.35))
                .shadow(color: catColor.opacity(0.2), radius: 16)

            Text(pose.name.localized)
                .font(.system(size: 32, weight: .bold, design: .rounded))
                .foregroundStyle(.white)
                .padding(.top, 16)

            // Difficulty dots + category label
            HStack(spacing: 12) {
                HStack(spacing: 4) {
                    ForEach(0..<3, id: \.self) { i in
                        Circle()
                            .fill(i < pose.difficulty.dotCount ? catColor : Color.white.opacity(0.15))
                            .frame(width: 6, height: 6)
                    }
                }
                Text(pose.category.localizedName.localized)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(.white.opacity(0.4))
            }
            .padding(.top, 6)

            Text(pose.description.localized)
                .font(.system(size: 16))
                .foregroundStyle(.white.opacity(0.6))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
                .padding(.top, 10)

            // Countdown
            Text("\(Int(viewModel.poseTimeRemaining))")
                .font(.system(size: 64, weight: .bold, design: .rounded))
                .monospacedDigit()
                .foregroundStyle(.white)
                .contentTransition(.numericText())
                .padding(.top, 20)

            // Breathing cue
            if !pose.breathingPattern.localized.isEmpty {
                HStack(spacing: 5) {
                    Image(systemName: "wind")
                        .font(.system(size: 12))
                        .foregroundStyle(catColor.opacity(0.6))
                    Text(pose.breathingPattern.localized)
                        .font(.system(size: 13, weight: .medium, design: .rounded))
                        .foregroundStyle(.white.opacity(0.4))
                }
                .lineLimit(1)
                .padding(.horizontal, 40)
                .padding(.top, 6)
            }

            Spacer()

            // Metrics bar
            MetricsOverlayView(
                heartRate: viewModel.recorder.currentHeartRate,
                calories: viewModel.recorder.activeCalories,
                elapsed: viewModel.elapsedTime,
                poseIndex: poseIndex,
                totalPoses: viewModel.plan.poseCount
            )

            // Controls
            HStack(spacing: 40) {
                Button { viewModel.pause() } label: {
                    Image(systemName: "pause.circle.fill")
                        .font(.system(size: 48))
                        .foregroundStyle(.white.opacity(0.7))
                }

                Button { viewModel.stop() } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 48))
                        .foregroundStyle(.red.opacity(0.7))
                }
            }
            .padding(.bottom, 32)
        }
    }

    private func transitionView(nextIndex: Int, seconds: Int) -> some View {
        let nextPose = nextIndex < viewModel.plan.poses.count ? viewModel.plan.poses[nextIndex] : nil
        let catColor = nextPose.map { Color(hue: $0.category.accentHue, saturation: 0.7, brightness: 0.9) } ?? .cyan
        return VStack(spacing: 20) {
            Spacer()

            Text(LocalizedString(en: "Next Up", fr: "Prochaine posture").localized)
                .font(.system(size: 20, weight: .medium))
                .foregroundStyle(.white.opacity(0.5))

            if let nextPose {
                Image(systemName: nextPose.category.symbolName)
                    .font(.system(size: 48))
                    .foregroundStyle(catColor.opacity(0.5))

                Text(nextPose.name.localized)
                    .font(.system(size: 36, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)

                // Difficulty + category
                HStack(spacing: 10) {
                    HStack(spacing: 4) {
                        ForEach(0..<3, id: \.self) { i in
                            Circle()
                                .fill(i < nextPose.difficulty.dotCount ? catColor : Color.white.opacity(0.15))
                                .frame(width: 6, height: 6)
                        }
                    }
                    Text(nextPose.category.localizedName.localized)
                        .font(.system(size: 13, weight: .medium))
                        .foregroundStyle(.white.opacity(0.4))
                }
            }

            Text("\(seconds)")
                .font(.system(size: 72, weight: .bold, design: .rounded))
                .monospacedDigit()
                .foregroundStyle(catColor)
                .contentTransition(.numericText())

            Spacer()
        }
    }

    private var cooldownView: some View {
        VStack(spacing: 24) {
            Spacer()

            Image(systemName: "sparkles")
                .font(.system(size: 64))
                .foregroundStyle(.cyan)

            Text(LocalizedString(en: "Great work!", fr: "Excellent travail!").localized)
                .font(.system(size: 32, weight: .bold, design: .rounded))
                .foregroundStyle(.white)

            Text(LocalizedString(en: "Wrapping up your session...", fr: "Fin de votre séance...").localized)
                .font(.system(size: 18))
                .foregroundStyle(.white.opacity(0.6))

            ProgressView()
                .tint(.cyan)

            Spacer()
        }
    }

    private func formattedDuration(_ duration: TimeInterval) -> String {
        let minutes = Int(duration) / 60
        let seconds = Int(duration) % 60
        if seconds == 0 {
            return "\(minutes) min"
        }
        return "\(minutes)m \(seconds)s"
    }
}
