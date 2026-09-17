import SwiftUI
import BonhommeCore

/// 2D window view for the visionOS NATURaL app.
/// Displays workout plan selection, active pose flow, and controls.
/// Biofeedback gauges are rendered as ornament attachments on the window.
struct SpatialPoseView: View {
    @Binding var selectedPlan: WorkoutPlan?
    @Binding var isImmersiveSpaceOpen: Bool
    @Environment(\.openImmersiveSpace) private var openImmersiveSpace
    @Environment(\.dismissImmersiveSpace) private var dismissImmersiveSpace

    @State private var viewModel: SpatialWorkoutViewModel?
    @State private var phase: SpatialWorkoutViewModel.Phase = .browsing

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
        VStack(spacing: 24) {
            Spacer()

            if let pose = vm.currentPose {
                Image(systemName: pose.category.symbolName)
                    .font(.system(size: 72))
                    .foregroundStyle(Color(hue: pose.category.accentHue, saturation: 0.7, brightness: 0.9).opacity(0.4))
                    .symbolRenderingMode(.hierarchical)
                    .accessibilityHidden(true)

                SessionPoseHeader(pose: pose, prominence: .large)

                Text(pose.description.localized)
                    .font(.body)
                    .foregroundStyle(BrandColor.fgMuted)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 48)

                SessionCountdownNumeral(remaining: vm.poseTimeRemaining)

                if !pose.breathingPattern.localized.isEmpty {
                    Label(pose.breathingPattern.localized, systemImage: "wind")
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(BrandColor.fgMuted)
                }
            }

            Spacer()

            // Controls
            HStack(spacing: 32) {
                // Immersive space toggle
                Button {
                    Task {
                        if isImmersiveSpaceOpen {
                            await dismissImmersiveSpace()
                            isImmersiveSpaceOpen = false
                        } else {
                            let result = await openImmersiveSpace(id: "poseSpace")
                            isImmersiveSpaceOpen = result == .opened
                        }
                    }
                } label: {
                    Label(
                        isImmersiveSpaceOpen
                            ? LocalizedString(en: "Close 3D", fr: "Fermer 3D").localized
                            : LocalizedString(en: "Open 3D", fr: "Ouvrir 3D").localized,
                        systemImage: isImmersiveSpaceOpen ? "cube.transparent" : "cube.fill"
                    )
                }

                Button {
                    vm.stop()
                    phase = .complete
                    Task {
                        if isImmersiveSpaceOpen {
                            await dismissImmersiveSpace()
                            isImmersiveSpaceOpen = false
                        }
                    }
                } label: {
                    Label(
                        LocalizedString(en: "End", fr: "Fin").localized,
                        systemImage: "xmark.circle"
                    )
                    .foregroundStyle(BrandColor.firetruck)
                }
            }
            .padding(.bottom, 24)
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

            Text(LocalizedString(en: "Session Complete!", fr: "Séance terminée!").localized)
                .font(.system(size: 28, weight: .bold, design: .rounded))

            if let vm = viewModel {
                let completed = min(vm.currentPoseIndex + 1, vm.plan.poseCount)
                let minutes = Int(vm.elapsedTime) / 60
                Text(LocalizedString(
                    en: "\(completed)/\(vm.plan.poseCount) poses in \(minutes) minutes",
                    fr: "\(completed)/\(vm.plan.poseCount) postures en \(minutes) minutes"
                ).localized)
                .font(.system(size: 18))
                .foregroundStyle(.secondary)
            }

            Spacer()

            Button {
                phase = .browsing
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
        selectedPlan = plan
        let vm = SpatialWorkoutViewModel(plan: plan)
        viewModel = vm
        phase = .active
        vm.start()
    }
}

// MARK: - Spatial Workout ViewModel

/// Simplified workout state machine for visionOS (no HealthKit recording).
@Observable
@MainActor
final class SpatialWorkoutViewModel {
    enum Phase { case browsing, active, complete }

    let plan: WorkoutPlan
    let feedbackEngine = FeedbackEngine()
    private let hrvAnalyzer = HRVAnalyzer()

    private(set) var currentPoseIndex: Int = 0
    private(set) var poseTimeRemaining: TimeInterval = 0
    private(set) var elapsedTime: TimeInterval = 0
    private(set) var isActive = false

    var currentPose: Pose? {
        plan.poses[safe: currentPoseIndex]
    }

    var hudMetrics: SessionHUDMetrics {
        let insight = feedbackEngine.latestInsight(for: .heartRateVariability)
        return SessionHUDMetrics(
            sciScore: insight?.score,
            sciTrend: insight?.trend.asSCITrend ?? .stable,
            elapsed: elapsedTime,
            poseIndex: currentPoseIndex,
            poseCount: plan.poseCount
        )
    }

    private var timerTask: Task<Void, Never>?
    private var sessionStartDate: Date?

    init(plan: WorkoutPlan) {
        self.plan = plan
        feedbackEngine.register(hrvAnalyzer)
    }

    func start() {
        sessionStartDate = Date()
        isActive = true
        beginPose(at: 0)
    }

    func stop() {
        timerTask?.cancel()
        isActive = false
    }

    private func beginPose(at index: Int) {
        guard index < plan.poses.count else {
            isActive = false
            return
        }

        currentPoseIndex = index
        poseTimeRemaining = plan.poses[index].durationSeconds
        startPoseTimer(for: index)
    }

    private func startPoseTimer(for index: Int) {
        timerTask?.cancel()
        timerTask = Task {
            while poseTimeRemaining > 0 {
                try? await Task.sleep(for: .seconds(1))
                guard !Task.isCancelled else { return }
                poseTimeRemaining = max(0, poseTimeRemaining - 1)
                if let start = sessionStartDate {
                    elapsedTime = Date().timeIntervalSince(start)
                }
            }

            let nextIndex = index + 1
            if nextIndex < plan.poses.count {
                // Brief transition pause
                try? await Task.sleep(for: .seconds(Int(plan.transitionSeconds)))
                guard !Task.isCancelled else { return }
                beginPose(at: nextIndex)
            } else {
                isActive = false
            }
        }
    }
}

// MARK: - Safe Array Access

private extension Array {
    subscript(safe index: Int) -> Element? {
        indices.contains(index) ? self[index] : nil
    }
}
