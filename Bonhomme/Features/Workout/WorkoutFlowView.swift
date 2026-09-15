import SwiftUI
import BonhommeCore

/// Create services only when a destination appears. Eager NavigationLink construction
/// must not mutate the shared feedback engine during a parent SwiftUI body update.
struct WorkoutFlowView: View {
    private let plan: WorkoutPlan?
    private let feedbackEngine: FeedbackEngine?
    private let restoredViewModel: WorkoutFlowViewModel?
    @State private var viewModel: WorkoutFlowViewModel?

    init(plan: WorkoutPlan, feedbackEngine: FeedbackEngine = FeedbackEngine()) {
        self.plan = plan
        self.feedbackEngine = feedbackEngine
        restoredViewModel = nil
    }

    init(restoredViewModel: WorkoutFlowViewModel) {
        plan = nil
        feedbackEngine = nil
        self.restoredViewModel = restoredViewModel
    }

    var body: some View {
        Group {
            if let viewModel { WorkoutSessionView(viewModel: viewModel) }
            else { ProgressView() }
        }
        .task {
            guard viewModel == nil else { return }
            if let restoredViewModel { viewModel = restoredViewModel }
            else if let plan, let feedbackEngine {
                viewModel = WorkoutFlowViewModel(plan: plan, feedbackEngine: feedbackEngine)
            }
        }
    }
}

/// The main guided workout screen that drives the pose-by-pose flow.
/// On iPad (regular width), displays a 60/40 split with pose visual and metrics panel.
private struct WorkoutSessionView: View {
    @State private var viewModel: WorkoutFlowViewModel
    @Environment(\.dismiss) private var dismiss
    @Environment(\.horizontalSizeClass) private var sizeClass
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    /// Shared app state — used to mark any live workout as presenting so scene-active
    /// auto-load cannot re-enter and spawn a second session from 5s persist state.
    @Environment(AppState.self) private var appState

    init(viewModel: WorkoutFlowViewModel) {
        _viewModel = State(initialValue: viewModel)
    }

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            switch viewModel.phase {
            case .ready:
                scrollableSessionContent { readyView }
            case .countdown(let seconds):
                CountdownView(secondsRemaining: seconds)
            case .active(let poseIndex):
                if sizeClass == .regular && !dynamicTypeSize.isAccessibilitySize {
                    scrollableSessionContent { iPadActivePoseView(poseIndex: poseIndex) }
                } else {
                    scrollableSessionContent { activePoseView(poseIndex: poseIndex) }
                }
            case .transition(let nextIndex, let seconds):
                scrollableSessionContent { transitionView(nextIndex: nextIndex, seconds: seconds) }
            case .cooldown:
                cooldownView
            case .complete:
                let sciScore = viewModel.feedbackEngine.latestInsight(for: .heartRateVariability)?.score
                SummaryView(
                    result: viewModel.buildResult(),
                    sciScore: sciScore,
                    healthSaveFailed: viewModel.healthSaveFailed,
                    isFinishing: viewModel.isFinishing,
                    drugResponse: appState.medicationTracker.latestDrugResponse
                        ?? viewModel.insightEngine.latestDrugResponse
                ) {
                    dismiss()
                }
            }

            // Live breath guide — subtle always; stronger during grounding.
            // Driven by session snapshot (BreathingGuideActuatorChannel); never blocks control.
            if showsBreathingGuide {
                VStack {
                    Spacer()
                    HStack {
                        Spacer()
                        BreathingGuideOverlay(
                            breathsPerMinute: viewModel.breathsPerMinute,
                            isGrounding: viewModel.isGrounding,
                            alwaysVisible: true
                        )
                    }
                }
                .allowsHitTesting(false)
            }
        }
        .safeAreaInset(edge: .bottom, spacing: 0) {
            if showsSessionControls { sessionControls }
        }
        .preferredColorScheme(.dark)
        .navigationBarBackButtonHidden()
        .statusBarHidden()
        .onAppear {
            // All entry paths (catalog start, banner, auto-restore navigation) mark active
            // so BonhommeApp scenePhase.active does not re-run detect→auto-load mid-session.
            appState.noteWorkoutPresented()
            // Wire drug-response / cross-domain context into InsightEngine (pose/session narratives).
            // Non-blocking — does not start or delay the pose timer.
            viewModel.syncPharmaContext(
                drugResponse: appState.medicationTracker.latestDrugResponse,
                crossDomain: appState.medicationTracker.latestCrossDomainValidation
            )
            if viewModel.isRestoredSession {
                viewModel.resumeRestoredSession()
            }
        }
        .onChange(of: appState.medicationTracker.latestDrugResponse?.doseEvent.timestamp) { _, _ in
            viewModel.syncPharmaContext(
                drugResponse: appState.medicationTracker.latestDrugResponse,
                crossDomain: appState.medicationTracker.latestCrossDomainValidation
            )
        }
        .onDisappear {
            if viewModel.phase != .ready && viewModel.phase != .complete { viewModel.stop() }
            appState.noteWorkoutDismissed()
        }
        .onReceive(NotificationCenter.default.publisher(for: .workoutShouldPersistState)) { _ in
            viewModel.persistState()
        }
    }

    /// Breath ring during active / transition / countdown (not ready or summary).
    private var showsBreathingGuide: Bool {
        switch viewModel.phase {
        case .active, .transition, .countdown, .cooldown:
            return true
        case .ready, .complete:
            return false
        }
    }

    /// Scrollable content keeps instructions reachable on short windows and at large text sizes.
    private func scrollableSessionContent<Content: View>(@ViewBuilder content: @escaping () -> Content) -> some View {
        GeometryReader { geometry in
            ScrollView {
                content()
                    .frame(maxWidth: .infinity, minHeight: geometry.size.height)
            }
        }
    }

    private var showsSessionControls: Bool {
        switch viewModel.phase {
        case .countdown, .active, .transition: return true
        default: return false
        }
    }

    private var sessionControls: some View {
        HStack(spacing: 24) {
            Button {
                if viewModel.isPaused { viewModel.resume() } else { viewModel.pause() }
            } label: {
                Label(viewModel.isPaused
                      ? LocalizedString(en: "Resume", fr: "Reprendre").localized
                      : LocalizedString(en: "Pause", fr: "Pause").localized,
                      systemImage: viewModel.isPaused ? "play.fill" : "pause.fill")
                    .frame(maxWidth: .infinity, minHeight: 48)
            }
            .accessibilityIdentifier("session.pauseResume")
            .tint(.cyan)
            Button(role: .destructive) { viewModel.stop() } label: {
                Label(LocalizedString(en: "End", fr: "Terminer").localized, systemImage: "stop.fill")
                    .frame(maxWidth: .infinity, minHeight: 48)
            }
            .accessibilityIdentifier("session.end")
        }
        .font(.headline)
        .buttonStyle(.bordered)
        .padding(.horizontal, 24).padding(.vertical, 8)
        .background(.ultraThinMaterial)
    }

    // MARK: - iPad Active Pose (60/40 Split)

    private func iPadActivePoseView(poseIndex: Int) -> some View {
        let pose = viewModel.plan.poses[poseIndex]
        let catColor = Color(hue: pose.category.accentHue, saturation: 0.7, brightness: 0.9)

        return HStack(spacing: 0) {
            // Left 60%: Pose visual + countdown
            VStack(spacing: 0) {
                Spacer()

                MotionCoachView(pose: pose, phase: .active,
                                poseElapsed: pose.durationSeconds - viewModel.poseTimeRemaining)
                    .frame(maxWidth: 520, minHeight: 360, maxHeight: 420)
                    .padding(.horizontal, 56)

                Text(pose.name.localized)
                    .accessibilityIdentifier("session.pose.name")
                    .font(.system(size: 36, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
                    .padding(.top, 20)

                HStack(spacing: 12) {
                    HStack(spacing: 4) {
                        ForEach(0..<3, id: \.self) { i in
                            Circle()
                                .fill(i < pose.difficulty.dotCount ? catColor : Color.white.opacity(0.15))
                                .frame(width: 8, height: 8)
                        }
                    }
                    Text(pose.category.localizedName.localized)
                        .font(.system(size: 15, weight: .medium))
                        .foregroundStyle(.white.opacity(0.4))
                }
                .padding(.top, 6)

                Text(pose.description.localized)
                    .font(.system(size: 17))
                    .foregroundStyle(.white.opacity(0.6))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 48)
                    .padding(.top, 10)

                Text("\(Int(viewModel.poseTimeRemaining))")
                    .font(.system(size: 80, weight: .bold, design: .rounded))
                    .monospacedDigit()
                    .foregroundStyle(.white)
                    .contentTransition(.numericText())
                    .padding(.top, 24)

                if !pose.breathingPattern.localized.isEmpty {
                    HStack(spacing: 5) {
                        Image(systemName: "wind")
                            .font(.system(size: 14))
                            .foregroundStyle(catColor.opacity(0.6))
                        Text(pose.breathingPattern.localized)
                            .font(.system(size: 15, weight: .medium, design: .rounded))
                            .foregroundStyle(.white.opacity(0.4))
                    }
                    .padding(.top, 8)
                }

                if !viewModel.currentVoiceCue.isEmpty {
                    Text(viewModel.currentVoiceCue)
                        .font(.system(size: 16, weight: .medium, design: .rounded))
                        .foregroundStyle(.white.opacity(0.75))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 40)
                        .padding(.top, 12)
                        .animation(.easeInOut(duration: 0.35), value: viewModel.currentVoiceCue)
                }

                Spacer()

            }
            .frame(maxWidth: .infinity)

            // Right 40%: Biofeedback panel (mirrors TV display layout)
            VStack(spacing: 24) {
                Spacer()

                // Heart rate gauge (reuse BonhommeCore view)
                HeartRateGaugeView(bpm: viewModel.recorder.currentHeartRate)
                    .frame(width: 160, height: 160)

                // SCI visualization
                let insight = viewModel.feedbackEngine.latestInsight(for: .heartRateVariability)
                SCIVisualizationView(
                    score: insight?.score,
                    trend: insight?.trend.asSCITrend ?? .stable
                )
                .frame(width: 120, height: 120)

                // Session progress
                SessionProgressView(
                    index: poseIndex,
                    total: viewModel.plan.poseCount,
                    elapsed: viewModel.elapsedTime
                )

                // Calories
                HStack {
                    Image(systemName: "flame.fill")
                        .foregroundStyle(.orange)
                    Text("\(Int(viewModel.recorder.activeCalories))")
                        .font(.system(size: 24, weight: .bold, design: .rounded))
                        .foregroundStyle(.white)
                    Text("cal")
                        .font(.system(size: 14))
                        .foregroundStyle(.white.opacity(0.5))
                }

                Spacer()
            }
            .frame(maxWidth: .infinity)
            .background(Color.white.opacity(0.03))
        }
    }

    // MARK: - Phone Phase Views

    private var readyView: some View {
        VStack(spacing: 32) {
            Spacer()

            if let firstPose = viewModel.plan.poses.first {
                MotionCoachView(pose: firstPose, phase: .preview)
                    .frame(height: 280)
                    .padding(.horizontal, 28)
            } else {
                Image(systemName: "figure.yoga")
                    .font(.system(size: 80))
                    .foregroundStyle(.cyan)
            }

            Text(viewModel.plan.name.localized)
                .font(.system(size: 28, weight: .bold, design: .rounded))
                .foregroundStyle(.white)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 24)

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

            MotionCoachView(pose: pose, phase: .active,
                            poseElapsed: pose.durationSeconds - viewModel.poseTimeRemaining)
                .frame(height: 300)
                .padding(.horizontal, 28)

            Text(pose.name.localized)
                    .accessibilityIdentifier("session.pose.name")
                .font(.title.bold())
                .foregroundStyle(.white)
                .padding(.top, 16)

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
                .font(.body)
                .foregroundStyle(.white.opacity(0.6))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
                .padding(.top, 10)

            Text("\(Int(viewModel.poseTimeRemaining))")
                .font(.system(size: 64, weight: .bold, design: .rounded))
                .monospacedDigit()
                .foregroundStyle(.white)
                .contentTransition(.numericText())
                .padding(.top, 20)

            if !pose.breathingPattern.localized.isEmpty {
                HStack(spacing: 5) {
                    Image(systemName: "wind")
                        .font(.system(size: 12))
                        .foregroundStyle(catColor.opacity(0.6))
                    Text(pose.breathingPattern.localized)
                        .font(.system(size: 13, weight: .medium, design: .rounded))
                        .foregroundStyle(.white.opacity(0.4))
                }
                .fixedSize(horizontal: false, vertical: true)
                .padding(.horizontal, 40)
                .padding(.top, 6)
            }

            if !viewModel.currentVoiceCue.isEmpty {
                Text(viewModel.currentVoiceCue)
                    .font(.system(size: 14, weight: .medium, design: .rounded))
                    .foregroundStyle(.white.opacity(0.72))
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.horizontal, 28)
                    .padding(.top, 10)
                    .animation(.easeInOut(duration: 0.35), value: viewModel.currentVoiceCue)
            }

            Spacer()

            MetricsOverlayView(
                heartRate: viewModel.recorder.currentHeartRate,
                calories: viewModel.recorder.activeCalories,
                elapsed: viewModel.elapsedTime,
                poseIndex: poseIndex,
                totalPoses: viewModel.plan.poseCount
            )


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
                MotionCoachView(pose: nextPose, phase: .transition)
                    .frame(height: 250)
                    .padding(.horizontal, 32)

                Text(nextPose.name.localized)
                    .font(.system(size: 36, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)

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
                .font(.title.bold())
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

// InsightTrend → SCITrend bridge is defined in BonhommeCore/TVDisplay/TVDisplayPayload.swift
