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
        return VStack {
            Spacer()

            // Pose visual placeholder
            Image(systemName: "figure.yoga")
                .font(.system(size: 120))
                .foregroundStyle(.cyan.opacity(0.4))

            Text(pose.name.localized)
                .font(.system(size: 32, weight: .bold, design: .rounded))
                .foregroundStyle(.white)
                .padding(.top, 16)

            Text(pose.description.localized)
                .font(.system(size: 16))
                .foregroundStyle(.white.opacity(0.6))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)

            // Countdown
            Text("\(Int(viewModel.poseTimeRemaining))")
                .font(.system(size: 64, weight: .bold, design: .rounded))
                .monospacedDigit()
                .foregroundStyle(.white)
                .contentTransition(.numericText())
                .padding(.top, 24)

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
        VStack(spacing: 24) {
            Spacer()

            Text(LocalizedString(en: "Next Up", fr: "Prochaine posture").localized)
                .font(.system(size: 20, weight: .medium))
                .foregroundStyle(.white.opacity(0.5))

            if nextIndex < viewModel.plan.poses.count {
                Text(viewModel.plan.poses[nextIndex].name.localized)
                    .font(.system(size: 36, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
            }

            Text("\(seconds)")
                .font(.system(size: 72, weight: .bold, design: .rounded))
                .monospacedDigit()
                .foregroundStyle(.cyan)
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
