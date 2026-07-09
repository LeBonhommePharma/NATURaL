import SwiftUI
import BonhommeCore

/// Compact workout session UI for Apple Watch.
/// Uses a vertical paging TabView (watchOS 10+) with three pages:
/// 1. Current pose + countdown
/// 2. Heart rate + SCI focus score
/// 3. Session progress + controls
struct WatchSessionView: View {
    @Environment(WatchWorkoutManager.self) private var manager
    @Environment(WatchConnectivityBridge.self) private var connectivity
    @Environment(\.dismiss) private var dismiss

    let plan: WorkoutPlan

    @State private var selectedTab = 0
    @State private var relayTask: Task<Void, Never>?
    @State private var crownRotationalDelta: Double = 0
    @State private var sigmaIrr: Double = 0
    @State private var crownBeta: Double = 0

    var body: some View {
        TabView(selection: $selectedTab) {
            poseTab.tag(0)
            biofeedbackTab.tag(1)
            controlsTab.tag(2)
        }
        .tabViewStyle(.verticalPage)
        .focusable()
        .digitalCrownRotation(
            $crownRotationalDelta,
            from: -20,
            through: 20,
            by: 0.25,
            sensitivity: .medium,
            isContinuous: true,
            isHapticFeedbackEnabled: true
        )
        .onChange(of: crownRotationalDelta) { oldValue, newValue in
            let delta = newValue - oldValue
            guard abs(delta) > 1e-6 else { return }
            Task {
                let beta = await PharmaControlSessionManager.shared.applyCrownDelta(delta)
                crownBeta = beta
                // Drive Crooks update with current HR + crown β.
                let bpm = manager.currentHeartRate ?? CrooksCycleDefaults.nominalBPM
                let sci = manager.feedbackEngine.latestInsight(for: .heartRateVariability)?.score
                let result = await PharmaControlSessionManager.shared.tickFromSCI(
                    sciScore: sci,
                    bpm: bpm,
                    crownBeta: beta
                )
                sigmaIrr = result.sigmaIrr
            }
        }
        .onAppear { startWorkout() }
        .onDisappear { relayTask?.cancel() }
        .onChange(of: manager.phase) { _, newPhase in
            if case .complete = newPhase {
                handleWorkoutComplete()
            }
        }
    }

    // MARK: - Tab 1: Pose + Countdown

    private var poseTab: some View {
        VStack(spacing: 8) {
            switch manager.phase {
            case .idle:
                ProgressView()
                    .tint(.cyan)
                Text(LocalizedString(en: "Starting...", fr: "Démarrage...").localized)
                    .font(.system(size: 14))
                    .foregroundStyle(.secondary)

            case .active(let index):
                if let pose = plan.poses[safe: index] {
                    activePoseContent(pose: pose)
                }

            case .transition(let nextIndex, let seconds):
                transitionContent(nextIndex: nextIndex, seconds: seconds)

            case .cooldown:
                Image(systemName: "sparkles")
                    .font(.system(size: 32))
                    .foregroundStyle(.cyan)
                Text(LocalizedString(en: "Great work!", fr: "Bravo!").localized)
                    .font(.system(size: 16, weight: .bold))
                    .foregroundStyle(.white)

            case .complete:
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 40))
                    .foregroundStyle(.green)
                Text(LocalizedString(en: "Done!", fr: "Terminé!").localized)
                    .font(.system(size: 18, weight: .bold))
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private func activePoseContent(pose: Pose) -> some View {
        let catColor = Color(hue: pose.category.accentHue, saturation: 0.7, brightness: 0.9)
        let kinematics = pose.kinematics
        let regionLabel = kinematics.highlightedRegions.first?.localizedName ?? pose.category.localizedName
        return VStack(spacing: 6) {
            ZStack {
                Circle()
                    .fill(catColor.opacity(0.15))
                    .frame(width: 44, height: 44)
                Image(systemName: pose.category.symbolName)
                    .font(.system(size: 24))
                    .foregroundStyle(catColor)
            }

            Text(pose.name.localized)
                .font(.system(size: 16, weight: .bold, design: .rounded))
                .foregroundStyle(.white)
                .lineLimit(1)
                .minimumScaleFactor(0.7)

            HStack(spacing: 3) {
                ForEach(0..<3, id: \.self) { i in
                    Circle()
                        .fill(i < pose.difficulty.dotCount ? catColor : Color.white.opacity(0.15))
                        .frame(width: 5, height: 5)
                }
                Text(regionLabel.localized)
                    .font(.system(size: 10, weight: .medium))
                    .foregroundStyle(catColor.opacity(0.7))
                    .lineLimit(1)
            }

            Text("\(Int(manager.poseTimeRemaining))")
                .font(.system(size: 44, weight: .bold, design: .rounded))
                .monospacedDigit()
                .foregroundStyle(.white)
                .contentTransition(.numericText())

            if !kinematics.setupSteps.isEmpty {
                let stepIdx = min(
                    Int(Double(manager.poseTimeRemaining) / pose.durationSeconds * Double(kinematics.setupSteps.count)),
                    kinematics.setupSteps.count - 1
                )
                Text(kinematics.setupSteps[stepIdx].localized)
                    .font(.system(size: 11))
                    .foregroundStyle(.white.opacity(0.5))
                    .lineLimit(1)
            } else if !pose.breathingPattern.localized.isEmpty {
                Text(pose.breathingPattern.localized)
                    .font(.system(size: 11))
                    .foregroundStyle(.white.opacity(0.4))
                    .lineLimit(1)
            }
        }
    }

    private func transitionContent(nextIndex: Int, seconds: Int) -> some View {
        VStack(spacing: 8) {
            Text(LocalizedString(en: "Next", fr: "Suivant").localized)
                .font(.system(size: 13))
                .foregroundStyle(.white.opacity(0.5))

            if let nextPose = plan.poses[safe: nextIndex] {
                Text(nextPose.name.localized)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(.white)
                    .lineLimit(1)
            }

            Text("\(seconds)")
                .font(.system(size: 48, weight: .bold, design: .rounded))
                .monospacedDigit()
                .foregroundStyle(.cyan)
                .contentTransition(.numericText())
        }
    }

    // MARK: - Tab 2: Biofeedback

    private var biofeedbackTab: some View {
        VStack(spacing: 12) {
            // Heart rate
            HStack(spacing: 6) {
                Image(systemName: "heart.fill")
                    .foregroundStyle(.red)
                    .font(.system(size: 16))
                Text(manager.currentHeartRate.map { "\(Int($0))" } ?? "--")
                    .font(.system(size: 36, weight: .bold, design: .rounded))
                    .monospacedDigit()
                    .foregroundStyle(.white)
                Text("BPM")
                    .font(.system(size: 12))
                    .foregroundStyle(.white.opacity(0.5))
            }

            Divider()
                .background(Color.white.opacity(0.2))

            // SCI Focus Score
            let insight = manager.feedbackEngine.latestInsight(for: .heartRateVariability)
            VStack(spacing: 4) {
                Text(LocalizedString(en: "Focus", fr: "Concentration").localized)
                    .font(.system(size: 12))
                    .foregroundStyle(.white.opacity(0.5))

                if let score = insight?.score {
                    Text("\(Int(score * 100))%")
                        .font(.system(size: 28, weight: .bold, design: .rounded))
                        .foregroundStyle(sciColor(for: score))
                } else {
                    Text("--")
                        .font(.system(size: 28, weight: .bold, design: .rounded))
                        .foregroundStyle(.white.opacity(0.3))
                }

                // Trend arrow
                if let trend = insight?.trend {
                    Image(systemName: trendIcon(trend))
                        .font(.system(size: 14))
                        .foregroundStyle(trendColor(trend))
                }
            }

            // Calories
            HStack(spacing: 4) {
                Image(systemName: "flame.fill")
                    .foregroundStyle(.orange)
                    .font(.system(size: 12))
                Text("\(Int(manager.activeCalories)) cal")
                    .font(.system(size: 14))
                    .foregroundStyle(.white.opacity(0.7))
            }

            // Crooks σ_irr + crown β
            HStack(spacing: 8) {
                Text(String(format: "σ_irr: %.3f", sigmaIrr))
                    .font(.system(size: 11, design: .monospaced))
                    .foregroundStyle(sigmaIrr > CrooksCycleDefaults.groundingThreshold ? .orange : .cyan)
                Text(String(format: "β: %.2f", crownBeta))
                    .font(.system(size: 11, design: .monospaced))
                    .foregroundStyle(.white.opacity(0.6))
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // MARK: - Tab 3: Controls

    private var controlsTab: some View {
        VStack(spacing: 12) {
            // Progress
            let poseIndex: Int = {
                switch manager.phase {
                case .active(let idx): return idx
                case .transition(let nextIdx, _): return max(0, nextIdx - 1)
                default: return 0
                }
            }()

            Text("\(poseIndex + 1)/\(plan.poseCount)")
                .font(.system(size: 20, weight: .bold, design: .rounded))
                .foregroundStyle(.white)

            // Elapsed time
            let minutes = Int(manager.elapsedTime) / 60
            let seconds = Int(manager.elapsedTime) % 60
            Text(String(format: "%d:%02d", minutes, seconds))
                .font(.system(size: 16, design: .rounded))
                .monospacedDigit()
                .foregroundStyle(.white.opacity(0.6))

            Spacer()

            // Pause / Resume
            if manager.isRecording {
                Button {
                    manager.pause()
                } label: {
                    Image(systemName: "pause.fill")
                        .font(.system(size: 24))
                        .frame(width: 60, height: 44)
                        .background(.white.opacity(0.15), in: RoundedRectangle(cornerRadius: 12))
                }
                .buttonStyle(.plain)
            } else {
                Button {
                    manager.resume()
                } label: {
                    Image(systemName: "play.fill")
                        .font(.system(size: 24))
                        .frame(width: 60, height: 44)
                        .background(.cyan.opacity(0.3), in: RoundedRectangle(cornerRadius: 12))
                }
                .buttonStyle(.plain)
            }

            // End workout
            Button {
                Task { try? await manager.end() }
            } label: {
                Text(LocalizedString(en: "End", fr: "Fin").localized)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(.red)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
                    .background(.red.opacity(0.15), in: RoundedRectangle(cornerRadius: 12))
            }
            .buttonStyle(.plain)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(.vertical, 8)
    }

    // MARK: - Lifecycle

    private func startWorkout() {
        Task {
            await PharmaControlSessionManager.shared.start()
            try? await manager.start(plan: plan)
            startBiofeedbackRelay()
        }
    }

    /// WCSession biofeedback relay + Crooks control tick (σ_irr, β, beat).
    private func startBiofeedbackRelay() {
        relayTask = Task {
            while !Task.isCancelled {
                try? await Task.sleep(for: .seconds(2))
                guard !Task.isCancelled, manager.isRecording else { continue }

                let snapshot = manager.buildBiofeedbackSnapshot()
                connectivity.sendBiofeedback(snapshot)

                manager.feedbackEngine.analyzeAll()
                let sci = manager.feedbackEngine.latestInsight(for: .heartRateVariability)?.score
                let bpm = manager.currentHeartRate ?? CrooksCycleDefaults.nominalBPM
                let result = await PharmaControlSessionManager.shared.tickFromSCI(
                    sciScore: sci,
                    bpm: bpm
                )
                sigmaIrr = result.sigmaIrr
                let snap = await PharmaControlSessionManager.shared.snapshot()
                crownBeta = snap.crownBeta
            }
        }
    }

    private func handleWorkoutComplete() {
        relayTask?.cancel()
        Task { await PharmaControlSessionManager.shared.stop() }
        if let result = manager.buildResult() {
            connectivity.transferWorkoutResult(result)
        }
    }

    // MARK: - Helpers

    private func sciColor(for score: Double) -> Color {
        switch score {
        case 0.8...: return .green
        case 0.6...: return .cyan
        case 0.3...: return .orange
        default: return .red
        }
    }

    private func trendIcon(_ trend: InsightTrend) -> String {
        switch trend {
        case .improving: return "arrow.up.right"
        case .stable: return "arrow.right"
        case .declining: return "arrow.down.right"
        }
    }

    private func trendColor(_ trend: InsightTrend) -> Color {
        switch trend {
        case .improving: return .green
        case .stable: return .white.opacity(0.5)
        case .declining: return .orange
        }
    }
}

// MARK: - Safe Array Access

private extension Array {
    subscript(safe index: Int) -> Element? {
        indices.contains(index) ? self[index] : nil
    }
}
