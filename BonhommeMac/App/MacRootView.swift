import SwiftUI
import BonhommeCore

/// Quiet single-window Mac session: pick a plan, run it, read SCI/HR/tempo.
/// No sidebar, no dashboard — toolbar + one focus surface (macOS 27 kit, stripped).
struct MacRootView: View {
    @State private var selectedPlan: WorkoutPlan = PoseCatalog.beginnerFlow
    @State private var session: GuidedSessionController?

    var body: some View {
        NavigationStack {
            Group {
                if let session, session.phase != .ready {
                    MacSessionCanvas(session: session, onClose: closeSession)
                } else {
                    MacReadyCanvas(selectedPlan: $selectedPlan) {
                        let controller = GuidedSessionController(plan: selectedPlan)
                        session = controller
                        controller.start()
                    }
                }
            }
            .frame(minWidth: 680, minHeight: 480)
            .background(BrandColor.bg)
            .toolbarBackground(BrandColor.bgPanel, for: .automatic)
        }
    }

    private func closeSession() {
        session?.reset()
        session = nil
    }
}

private struct MacReadyCanvas: View {
    @Binding var selectedPlan: WorkoutPlan
    var onBegin: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: SessionSpacing.lg) {
            Text("NATURaL")
                .font(.largeTitle.weight(.semibold))
                .foregroundStyle(BrandColor.fg)
            Text(LocalizedString(
                en: "Chair yoga on your Mac. One plan, one session.",
                fr: "Yoga sur chaise sur Mac. Un programme, une séance."
            ).localized)
            .font(.title3)
            .foregroundStyle(BrandColor.magnesium)

            Picker(LocalizedString(en: "Plan", fr: "Programme").localized, selection: $selectedPlan) {
                ForEach(PoseCatalog.allPlans) { plan in
                    Text(plan.name.localized).tag(plan)
                }
            }
            .pickerStyle(.menu)
            .frame(maxWidth: 420)
            .tint(SessionPalette.accent)

            Text(selectedPlan.description.localized)
                .font(.body)
                .foregroundStyle(BrandColor.fgMuted)
                .fixedSize(horizontal: false, vertical: true)
                .frame(maxWidth: 520, alignment: .leading)

            Text("\(selectedPlan.poseCount) \(LocalizedString(en: "poses", fr: "postures").localized) · \(Int(selectedPlan.totalDuration) / 60) min")
                .font(.subheadline)
                .foregroundStyle(BrandColor.magnesium)

            SessionBeginButton(action: onBegin)
                .tint(SessionPalette.accent)
                .frame(maxWidth: 280)

            Text(LocalizedString(
                en: "Heart rate and SCI need an iPhone or Apple Watch with Health. This Mac window is the quiet session chrome.",
                fr: "La fréquence cardiaque et le SCI nécessitent un iPhone ou une Apple Watch avec Santé. Cette fenêtre Mac est le chrome de séance."
            ).localized)
            .font(.caption)
            .foregroundStyle(BrandColor.magnesium)
            .frame(maxWidth: 520, alignment: .leading)
            .padding(.top, SessionSpacing.xs)
        }
        .padding(SessionSpacing.xxl)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .background(BrandColor.bg)
    }
}

private struct MacSessionCanvas: View {
    @Bindable var session: GuidedSessionController
    var onClose: () -> Void

    var body: some View {
        VStack(spacing: SessionSpacing.xl) {
            Spacer(minLength: SessionSpacing.md)

            switch session.phase {
            case .active:
                if let pose = session.currentPose {
                    active(pose)
                }
            case .transition(_, let seconds):
                VStack(spacing: SessionSpacing.md) {
                    Text(SessionHUDCopy.nextUp.localized)
                        .font(.headline)
                        .foregroundStyle(BrandColor.magnesium)
                    if let pose = session.currentPose {
                        SessionPoseHeader(pose: pose, prominence: .regular)
                    }
                    SessionCountdownNumeral(remaining: TimeInterval(seconds), tint: SessionPalette.accent)
                }
            case .complete:
                VStack(spacing: SessionSpacing.md) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 48))
                        .foregroundStyle(BrandColor.mint)
                    Text(LocalizedString(en: "Session complete", fr: "Séance terminée").localized)
                        .font(.title.weight(.semibold))
                        .foregroundStyle(BrandColor.fg)
                    Button(LocalizedString(en: "Done", fr: "Terminé").localized, action: onClose)
                        .sessionProminentButtonStyle()
                        .tint(SessionPalette.accent)
                        .keyboardShortcut(.defaultAction)
                }
            case .ready:
                EmptyView()
            }

            Spacer(minLength: SessionSpacing.md)

            if session.phase != .complete {
                HStack(alignment: .bottom, spacing: SessionSpacing.xl) {
                    CompactSCIMeter(
                        score: session.hudMetrics.sciScore,
                        trend: session.hudMetrics.sciTrend,
                        size: 64,
                        banded: false
                    )
                    SessionHeartRateReadout(bpm: session.hudMetrics.heartRate)
                    VStack(alignment: .leading, spacing: SessionSpacing.xs) {
                        SessionStatusChip(
                            title: session.hudMetrics.entropyState.label.localized,
                            systemImage: session.hudMetrics.entropyState.symbolName,
                            tint: SessionPalette.entropy(session.hudMetrics.entropyState)
                        )
                        SessionStatusChip(
                            title: "\(session.hudMetrics.tempoText) \(SessionHUDCopy.bpm.localized)",
                            systemImage: "metronome",
                            tint: SessionPalette.accent
                        )
                        Text(session.hudMetrics.poseProgressText)
                            .font(.caption.monospacedDigit())
                            .foregroundStyle(BrandColor.magnesium)
                    }
                    Spacer()
                }
                .padding(SessionSpacing.md)
                .sessionGlassFill(in: SessionRadius.cardShape())
            }
        }
        .padding(SessionSpacing.xl)
        .background(BrandColor.bg)
        .toolbar {
            if session.phase != .complete && session.phase != .ready {
                ToolbarItemGroup(placement: .primaryAction) {
                    Button {
                        if session.isPaused { session.resume() } else { session.pause() }
                    } label: {
                        Label(
                            session.isPaused ? SessionHUDCopy.resume.localized : SessionHUDCopy.pause.localized,
                            systemImage: session.isPaused ? "play.fill" : "pause.fill"
                        )
                    }
                    .keyboardShortcut(.space, modifiers: [])
                    Button(role: .destructive) {
                        session.stop()
                    } label: {
                        Label(SessionHUDCopy.end.localized, systemImage: "stop.fill")
                    }
                    .tint(BrandColor.strawberry)
                }
            }
        }
    }

    private func active(_ pose: Pose) -> some View {
        VStack(spacing: SessionSpacing.md) {
            SessionPoseHeader(pose: pose, prominence: .large)
            SessionCountdownNumeral(remaining: session.poseTimeRemaining)
            if !pose.voiceCueText.localized.isEmpty {
                Text(pose.voiceCueText.localized)
                    .font(.title3)
                    .foregroundStyle(BrandColor.magnesium)
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: 560)
            }
        }
    }
}
