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
            BrandColor.bg.ignoresSafeArea()

            switch viewModel.phase {
            case .ready:
                if usesRegularSessionLayout {
                    scrollableSessionContent { iPadReadyView }
                } else {
                    scrollableSessionContent { readyView }
                }
            case .countdown(let seconds):
                CountdownView(secondsRemaining: seconds)
            case .active(let poseIndex):
                if usesRegularSessionLayout {
                    scrollableSessionContent { iPadActivePoseView(poseIndex: poseIndex) }
                } else {
                    scrollableSessionContent { activePoseView(poseIndex: poseIndex) }
                }
            case .transition(let nextIndex, let seconds):
                if usesRegularSessionLayout {
                    scrollableSessionContent { iPadTransitionView(nextIndex: nextIndex, seconds: seconds) }
                } else {
                    scrollableSessionContent { transitionView(nextIndex: nextIndex, seconds: seconds) }
                }
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
                .padding(.bottom, showsSessionControls ? 8 : 0)
                .allowsHitTesting(false)
            }

            if viewModel.isPaused && showsSessionControls {
                SessionPausedOverlay()
            }
        }
        .safeAreaInset(edge: .bottom, spacing: 0) {
            phoneSessionChrome
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

    private var usesRegularSessionLayout: Bool {
        sizeClass == .regular && !dynamicTypeSize.isAccessibilitySize
    }

    /// Phone HUD sits in the thumb zone: metrics (active only) then pause/end.
    /// iPad regular width keeps metrics in the inspector panel instead.
    @ViewBuilder
    private var phoneSessionChrome: some View {
        if showsSessionControls {
            VStack(spacing: SessionSpacing.xs) {
                if showsLiveHUD {
                    SessionHUDBar(metrics: viewModel.sessionHUDMetrics)
                        .padding(.horizontal, SessionSpacing.md)
                }
                SessionControlBar(
                    isPaused: viewModel.isPaused,
                    onPauseResume: {
                        if viewModel.isPaused { viewModel.resume() } else { viewModel.pause() }
                    },
                    onEnd: { viewModel.stop() },
                    prominence: usesRegularSessionLayout ? .pad : .phone
                )
                .padding(.bottom, SessionSpacing.xxs)
                .background(.ultraThinMaterial)
            }
        }
    }

    private var showsLiveHUD: Bool {
        guard case .active = viewModel.phase else { return false }
        return !usesRegularSessionLayout
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
            .scrollIndicators(.hidden)
        }
    }

    private var showsSessionControls: Bool {
        switch viewModel.phase {
        case .countdown, .active, .transition: return true
        default: return false
        }
    }

    // MARK: - iPad Active Pose (stage + inspector)

    private var iPadReadyView: some View {
        HStack(alignment: .center, spacing: SessionSpacing.xxl) {
            if let firstPose = viewModel.plan.poses.first {
                MotionCoachView(pose: firstPose, phase: .preview)
                    .frame(maxWidth: 480, maxHeight: 420)
                    .accessibilityHidden(true)
            }

            VStack(alignment: .leading, spacing: SessionSpacing.md) {
                Text(viewModel.plan.name.localized)
                    .font(.largeTitle.weight(.bold))
                    .foregroundStyle(BrandColor.fg)
                Text("\(viewModel.plan.poseCount) \(LocalizedString(en: "poses", fr: "postures").localized) · \(formattedDuration(viewModel.plan.totalDuration))")
                    .font(.title3)
                    .foregroundStyle(BrandColor.fg.opacity(0.6))
                if !viewModel.plan.description.localized.isEmpty {
                    Text(viewModel.plan.description.localized)
                        .font(.body)
                        .foregroundStyle(BrandColor.fg.opacity(0.7))
                        .fixedSize(horizontal: false, vertical: true)
                }
                SessionBeginButton { viewModel.start() }
                    .frame(maxWidth: 360)
                Button(SessionHUDCopy.cancel.localized) { dismiss() }
                    .font(.body)
                    .foregroundStyle(BrandColor.fg.opacity(0.55))
                    .frame(minHeight: SessionSpacing.minTapTarget)
            }
            .frame(maxWidth: 420, alignment: .leading)
        }
        .padding(.horizontal, SessionSpacing.xxl)
        .padding(.vertical, SessionSpacing.xl)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private func iPadActivePoseView(poseIndex: Int) -> some View {
        let pose = viewModel.plan.poses[poseIndex]
        return HStack(spacing: 0) {
            VStack(spacing: SessionSpacing.md) {
                Spacer(minLength: SessionSpacing.md)
                MotionCoachView(pose: pose, phase: .active,
                                poseElapsed: pose.durationSeconds - viewModel.poseTimeRemaining)
                    .frame(maxWidth: 560, minHeight: 320, maxHeight: 440)
                    .padding(.horizontal, SessionSpacing.xl)

                SessionPoseHeader(pose: pose, prominence: .large)

                SessionCountdownNumeral(remaining: viewModel.poseTimeRemaining)

                if !pose.breathingPattern.localized.isEmpty {
                    Label(pose.breathingPattern.localized, systemImage: "wind")
                        .font(.title3.weight(.medium))
                        .foregroundStyle(BrandColor.fg.opacity(0.5))
                }

                if !viewModel.currentVoiceCue.isEmpty {
                    Text(viewModel.currentVoiceCue)
                        .font(.title3.weight(.medium))
                        .foregroundStyle(BrandColor.fg.opacity(0.8))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, SessionSpacing.xl)
                        .animation(.easeInOut(duration: 0.35), value: viewModel.currentVoiceCue)
                }
                Spacer(minLength: SessionSpacing.md)
            }
            .frame(maxWidth: .infinity)

            Rectangle()
                .fill(
                    LinearGradient(
                        colors: [.clear, BrandColor.hairlineStrong, .clear],
                        startPoint: .top, endPoint: .bottom
                    )
                )
                .frame(width: 1)

            SessionHUDPanel(metrics: viewModel.sessionHUDMetrics, showsGauges: true)
                .frame(width: 340)
                .frame(maxHeight: .infinity)
                .background(BrandColor.bgCard)
        }
    }

    private func iPadTransitionView(nextIndex: Int, seconds: Int) -> some View {
        HStack(spacing: 0) {
            transitionView(nextIndex: nextIndex, seconds: seconds)
                .frame(maxWidth: .infinity)

            Rectangle()
                .fill(
                    LinearGradient(
                        colors: [.clear, BrandColor.hairlineStrong, .clear],
                        startPoint: .top, endPoint: .bottom
                    )
                )
                .frame(width: 1)

            SessionHUDPanel(metrics: viewModel.sessionHUDMetrics, showsGauges: true)
                .frame(width: 340)
                .frame(maxHeight: .infinity)
                .background(BrandColor.bgCard)
        }
    }

    // MARK: - Phone Phase Views

    private var readyView: some View {
        VStack(spacing: SessionSpacing.lg) {
            Spacer(minLength: SessionSpacing.md)

            if let firstPose = viewModel.plan.poses.first {
                MotionCoachView(pose: firstPose, phase: .preview)
                    .frame(maxHeight: 280)
                    .padding(.horizontal, SessionSpacing.lg)
                    .accessibilityHidden(true)
            } else {
                Image(systemName: "figure.yoga")
                    .font(.system(size: 64, weight: .medium))
                    .foregroundStyle(SessionPalette.accent)
                    .symbolRenderingMode(.hierarchical)
                    .accessibilityHidden(true)
            }

            Text(viewModel.plan.name.localized)
                .font(.title.weight(.bold))
                .foregroundStyle(BrandColor.fg)
                .multilineTextAlignment(.center)
                .padding(.horizontal, SessionSpacing.md)

            Text("\(viewModel.plan.poseCount) \(LocalizedString(en: "poses", fr: "postures").localized) · \(formattedDuration(viewModel.plan.totalDuration))")
                .font(.body)
                .foregroundStyle(BrandColor.fg.opacity(0.6))

            Spacer(minLength: SessionSpacing.md)

            SessionBeginButton { viewModel.start() }
                .padding(.horizontal, SessionSpacing.xl)

            Button(SessionHUDCopy.cancel.localized) { dismiss() }
                .font(.body)
                .foregroundStyle(BrandColor.fg.opacity(0.55))
                .frame(minHeight: SessionSpacing.minTapTarget)
                .padding(.bottom, SessionSpacing.lg)
        }
        .padding(.horizontal, SessionSpacing.sm)
    }

    private func activePoseView(poseIndex: Int) -> some View {
        let pose = viewModel.plan.poses[poseIndex]
        let catColor = Color(hue: pose.category.accentHue, saturation: 0.7, brightness: 0.9)

        return VStack(spacing: 0) {
            Spacer(minLength: SessionSpacing.sm)

            MotionCoachView(pose: pose, phase: .active,
                            poseElapsed: pose.durationSeconds - viewModel.poseTimeRemaining)
                .frame(height: dynamicTypeSize.isAccessibilitySize ? 220 : 280)
                .padding(.horizontal, SessionSpacing.lg)

            SessionPoseHeader(pose: pose, prominence: dynamicTypeSize.isAccessibilitySize ? .compact : .regular)
                .padding(.top, SessionSpacing.md)
                .padding(.horizontal, SessionSpacing.md)

            SessionCountdownNumeral(remaining: viewModel.poseTimeRemaining, tint: BrandColor.fg)
                .padding(.top, SessionSpacing.md)

            if !pose.breathingPattern.localized.isEmpty {
                Label(pose.breathingPattern.localized, systemImage: "wind")
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(BrandColor.fg.opacity(0.5))
                    .symbolRenderingMode(.hierarchical)
                    .labelStyle(.titleAndIcon)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.horizontal, SessionSpacing.xl)
                    .padding(.top, SessionSpacing.xs)
            }

            if !viewModel.currentVoiceCue.isEmpty {
                Text(viewModel.currentVoiceCue)
                    .font(.callout.weight(.medium))
                    .foregroundStyle(BrandColor.fg.opacity(0.78))
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.horizontal, SessionSpacing.lg)
                    .padding(.top, SessionSpacing.sm)
                    .animation(.easeInOut(duration: 0.35), value: viewModel.currentVoiceCue)
            }

            Spacer(minLength: SessionSpacing.xl)
        }
        .tint(catColor)
    }

    private func transitionView(nextIndex: Int, seconds: Int) -> some View {
        let nextPose = nextIndex < viewModel.plan.poses.count ? viewModel.plan.poses[nextIndex] : nil
        let catColor = nextPose.map { Color(hue: $0.category.accentHue, saturation: 0.7, brightness: 0.9) } ?? SessionPalette.accent

        return VStack(spacing: SessionSpacing.md) {
            Spacer(minLength: SessionSpacing.md)

            Text(SessionHUDCopy.nextUp.localized)
                .font(.headline)
                .foregroundStyle(BrandColor.fg.opacity(0.5))

            if let nextPose {
                MotionCoachView(pose: nextPose, phase: .transition)
                    .frame(height: 240)
                    .padding(.horizontal, SessionSpacing.lg)
                SessionPoseHeader(pose: nextPose, prominence: .regular)
                    .padding(.horizontal, SessionSpacing.md)
            }

            SessionCountdownNumeral(remaining: TimeInterval(seconds), tint: catColor)

            Spacer(minLength: SessionSpacing.md)
        }
    }

    private var cooldownView: some View {
        VStack(spacing: SessionSpacing.md) {
            Spacer()
            Image(systemName: "sparkles")
                .font(.system(size: 56, weight: .medium))
                .foregroundStyle(SessionPalette.accent)
                .symbolRenderingMode(.hierarchical)
            Text(LocalizedString(en: "Great work!", fr: "Excellent travail!").localized)
                .font(.title.weight(.bold))
                .foregroundStyle(BrandColor.fg)
            Text(LocalizedString(en: "Wrapping up your session...", fr: "Fin de votre séance...").localized)
                .font(.body)
                .foregroundStyle(BrandColor.fg.opacity(0.6))
            ProgressView()
                .tint(SessionPalette.accent)
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
