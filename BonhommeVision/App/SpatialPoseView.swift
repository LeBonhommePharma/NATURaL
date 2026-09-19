import SwiftUI
import BonhommeCore

/// 2D window view for the visionOS NATURaL app.
/// Displays workout plan selection, active pose flow, and controls.
/// Biofeedback gauges are rendered as ornament attachments on the window.
struct SpatialPoseView: View {
    @Binding var viewModel: SpatialWorkoutViewModel?
    @Binding var isImmersiveSpaceOpen: Bool
    @Environment(\.openImmersiveSpace) private var openImmersiveSpace
    @Environment(\.dismissImmersiveSpace) private var dismissImmersiveSpace

    @Environment(\.scenePhase) private var scenePhase
    @State private var changingImmersion = false
    private var phase: SpatialWorkoutViewModel.Phase { viewModel?.phase ?? .browsing }

    var body: some View {
        NavigationStack {
            Group {
                switch phase {
                case .browsing:
                    planBrowser
                case .active:
                    if let vm = viewModel {
                        activeWorkoutView(vm: vm)
                    }
                case .complete:
                    completionView
                }
            }
            .navigationTitle("NATURaL")
        }
        .ornament(attachmentAnchor: .scene(.trailing)) {
            if phase == .active, let vm = viewModel {
                SpatialBiofeedbackView(viewModel: vm)
                    .frame(width: 200)
            }
        }
        .onChange(of: phase) { _, value in
            if value == .complete { closeImmersion() }
        }
        .onChange(of: scenePhase) { _, value in
            if value == .background { viewModel?.pause() }
        }
        .onDisappear { viewModel?.pause() }
    }

    // MARK: - Plan Browser

    private var planBrowser: some View {
        ScrollView {
            VStack(spacing: 20) {
                Image(systemName: "figure.yoga")
                    .font(.system(size: 64))
                    .foregroundStyle(SessionPalette.accent)
                    .symbolRenderingMode(.hierarchical)
                    .padding(.top, 32)

                Text(LocalizedString(en: "Chair Yoga", fr: "Yoga sur chaise").localized)
                    .font(.system(size: 24, weight: .medium))
                    .foregroundStyle(.secondary)

                ForEach(PoseCatalog.allPlans) { plan in
                    Button {
                        startWorkout(plan: plan)
                    } label: {
                        HStack(spacing: 16) {
                            Image(systemName: plan.poses.first?.category.symbolName ?? "figure.yoga")
                                .font(.system(size: 32))
                                .foregroundStyle(SessionPalette.accent)
                                .symbolRenderingMode(.hierarchical)
                                .frame(width: 48)

                            VStack(alignment: .leading, spacing: 4) {
                                Text(plan.name.localized)
                                    .font(.system(size: 20, weight: .semibold))
                                    .foregroundStyle(.primary)

                                Text(plan.description.localized)
                                    .font(.system(size: 14))
                                    .foregroundStyle(.secondary)
                                    .lineLimit(2)

                                HStack(spacing: 12) {
                                    Label("\(plan.poseCount) poses", systemImage: "list.number")
                                    Label("\(Int(plan.totalDuration) / 60) min", systemImage: "clock")
                                }
                                .font(.system(size: 13))
                                .foregroundStyle(.tertiary)
                            }

                            Spacer()

                            Image(systemName: "chevron.right")
                                .foregroundStyle(.secondary)
                        }
                        .padding()
                        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 16))
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding()
        }
    }

    // MARK: - Active Workout

    private func activeWorkoutView(vm: SpatialWorkoutViewModel) -> some View {
        ScrollView {
            VStack(spacing: SessionSpacing.lg) {
                if let pose = vm.currentPose {
                    if vm.coachPhase == .transition {
                        Text(SessionHUDCopy.nextUp.localized).font(.headline)
                    }
                    SessionPoseHeader(pose: pose, prominence: .large)
                    MotionCoachView(pose: pose, phase: vm.coachPhase,
                                    poseElapsed: vm.poseElapsed, isPaused: vm.isPaused)
                        .frame(maxWidth: 620).frame(height: 340)
                    SessionCountdownNumeral(remaining: vm.displayTimeRemaining)
                    if vm.isPaused {
                        Label(SessionHUDCopy.paused.localized, systemImage: "pause.circle.fill")
                            .font(.headline).foregroundStyle(BrandColor.strawberry)
                    }
                    PoseGuideDetails(pose: pose).frame(maxWidth: 620)
                }
            }
            .padding(SessionSpacing.lg)
            .frame(maxWidth: .infinity)
        }
        .safeAreaInset(edge: .bottom) {
            ViewThatFits(in: .horizontal) {
                HStack(spacing: 24) { sessionControls(vm) }
                VStack(spacing: 12) { sessionControls(vm) }
            }
            .padding().frame(maxWidth: .infinity).background(.regularMaterial)
        }
    }

    @ViewBuilder
    private func sessionControls(_ vm: SpatialWorkoutViewModel) -> some View {
        Button {
            changingImmersion = true
            Task { @MainActor in
                defer { changingImmersion = false }
                if isImmersiveSpaceOpen {
                    await dismissImmersiveSpace()
                    isImmersiveSpaceOpen = false
                } else {
                    let result = await openImmersiveSpace(id: "poseSpace")
                    isImmersiveSpaceOpen = result == .opened
                    if vm.phase != .active && isImmersiveSpaceOpen {
                        await dismissImmersiveSpace()
                        isImmersiveSpaceOpen = false
                    }
                }
            }
        } label: {
            Label(isImmersiveSpaceOpen
                  ? LocalizedString(en: "Close 3D", fr: "Fermer 3D").localized
                  : LocalizedString(en: "Open 3D", fr: "Ouvrir 3D").localized,
                  systemImage: isImmersiveSpaceOpen ? "cube.transparent" : "cube.fill")
        }
        .disabled(changingImmersion)
        Button {
            if vm.isPaused { vm.resume() } else { vm.pause() }
        } label: {
            Label(vm.isPaused ? SessionHUDCopy.resume.localized : SessionHUDCopy.pause.localized,
                  systemImage: vm.isPaused ? "play.fill" : "pause.fill")
        }
        Button(role: .destructive) { vm.stop() } label: {
            Label(LocalizedString(en: "End", fr: "Fin").localized, systemImage: "xmark.circle")
        }
    }

    private func closeImmersion() {
        guard isImmersiveSpaceOpen else { return }
        Task { @MainActor in
            await dismissImmersiveSpace()
            isImmersiveSpaceOpen = false
        }
    }

    // MARK: - Completion

    private var completionView: some View {
        VStack(spacing: 24) {
            Spacer()

            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 72))
                .foregroundStyle(BrandColor.mint)
                .symbolRenderingMode(.hierarchical)

            Text((viewModel?.session.endedEarly == true
                  ? LocalizedString(en: "Session ended", fr: "Séance arrêtée")
                  : LocalizedString(en: "Session complete", fr: "Séance terminée")).localized)
                .font(.system(size: 28, weight: .bold, design: .rounded))

            if let vm = viewModel {
                if vm.plan.poseCount > 0 {
                    Text(LocalizedString(
                        en: "\(vm.session.posesCompletedCount) / \(vm.plan.poseCount) poses completed · \(vm.hudMetrics.elapsedText)",
                        fr: "\(vm.session.posesCompletedCount) / \(vm.plan.poseCount) postures terminées · \(vm.hudMetrics.elapsedText)"
                    ).localized)
                    .font(.system(size: 18))
                    .foregroundStyle(.secondary)
                } else {
                    Text(vm.hudMetrics.elapsedText).foregroundStyle(.secondary)
                }
            }

            Spacer()

            Button {
                viewModel = nil
            } label: {
                Text(LocalizedString(en: "Done", fr: "Terminé").localized)
                    .font(.system(size: 18, weight: .semibold))
                    .padding(.horizontal, 48)
                    .padding(.vertical, 12)
                    .background(SessionPalette.accent, in: RoundedRectangle(cornerRadius: SessionRadius.control, style: .continuous))
            }
            .buttonStyle(.plain)
            .padding(.bottom, 40)
        }
    }

    // MARK: - Actions

    private func startWorkout(plan: WorkoutPlan) {
        let vm = SpatialWorkoutViewModel(plan: plan)
        viewModel = vm
        vm.start()
    }
}

// MARK: - Spatial Workout ViewModel

/// Both Vision scenes read the same tested monotonic session controller.
/// This platform has no health-data input; missing telemetry stays unavailable.
@Observable
@MainActor
final class SpatialWorkoutViewModel {
    enum Phase { case browsing, active, complete }
    let session: GuidedSessionController

    init(plan: WorkoutPlan) { session = GuidedSessionController(plan: plan) }
    var plan: WorkoutPlan { session.plan }
    var phase: Phase {
        switch session.phase {
        case .ready: return .browsing
        case .active, .transition: return .active
        case .complete: return .complete
        }
    }
    var currentPose: Pose? { session.upcomingPose ?? session.currentPose }
    var coachPhase: MotionCoachPhase {
        if case .transition = session.phase { return .transition }
        return .active
    }
    var poseElapsed: TimeInterval {
        guard coachPhase == .active, let pose = session.currentPose else { return 0 }
        return max(0, pose.durationSeconds - session.poseTimeRemaining)
    }
    var displayTimeRemaining: TimeInterval {
        if case .transition(_, let seconds) = session.phase { return TimeInterval(seconds) }
        return session.poseTimeRemaining
    }
    var elapsedTime: TimeInterval { session.elapsedTime }
    var isPaused: Bool { session.isPaused }
    var hudMetrics: SessionHUDMetrics { session.hudMetrics }
    func start() { session.start() }
    func stop() { session.stop() }
    func pause() { session.pause() }
    func resume() { session.resume() }
}
