import SwiftUI
import CoreImage.CIFilterBuiltins
import UIKit
import BonhommeCore

struct TVRootView: View {
    @StateObject private var listener = CompanionListener()
    @Environment(\.scenePhase) private var scenePhase
    @State private var selectedPlan = PoseCatalog.beginnerFlow
    @State private var localSession: GuidedSessionController?
    @State private var isPairingMode = false
    @State private var confirmsEnd = false
    @State private var resumesAfterCancel = false

    var body: some View {
        Group {
            if localSession != nil || isPairingMode {
                content.onExitCommand { handleExit() }
            } else {
                content // Let Menu return to the system from the catalog.
            }
        }
        .background(BrandColor.bg.ignoresSafeArea())
        .preferredColorScheme(.dark)
        .confirmationDialog(copy("End this session?", "Terminer cette séance ?"), isPresented: $confirmsEnd) {
            Button(copy("End session", "Terminer la séance"), role: .destructive) { localSession?.stop() }
            Button(copy("Keep session", "Garder la séance"), role: .cancel) {
                if resumesAfterCancel { localSession?.resume() }
            }
        } message: {
            Text(copy("Your session is paused while you decide.", "Votre séance est en pause pendant votre choix."))
        }
        .onDisappear { listener.stopAdvertising(); localSession?.pause() }
        .onChange(of: scenePhase) { _, phase in
            if phase != .active { listener.stopAdvertising(); localSession?.pause() }
        }
    }

    @ViewBuilder
    private var content: some View {
        if let session = localSession {
            localContent(session)
        } else if isPairingMode {
            pairedContent
        } else {
            catalog
        }
    }

    private var catalog: some View {
        HStack(alignment: .top, spacing: 48) {
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 20) {
                    Text("NATURaL").font(.largeTitle.bold()).foregroundStyle(BrandColor.fg)
                    Text(copy("All plans are free", "Tous les programmes sont gratuits"))
                        .font(.headline).foregroundStyle(BrandColor.mint)
                    ForEach(PoseCatalog.allPlans) { plan in
                        Button { selectedPlan = plan } label: {
                            HStack {
                                VStack(alignment: .leading, spacing: 6) {
                                    Text(plan.name.localized).font(.headline)
                                    Text("\(plan.poseCount) " + copy("poses", "postures"))
                                        .font(.caption).foregroundStyle(.secondary)
                                }
                                Spacer()
                                if selectedPlan.id == plan.id {
                                    Image(systemName: "checkmark.circle.fill").foregroundStyle(BrandColor.mint)
                                }
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                        }
                        .accessibilityAddTraits(selectedPlan.id == plan.id ? .isSelected : [])
                    }
                }
                .padding(20)
            }
            .frame(width: 480).focusSection()

            ScrollView {
                VStack(alignment: .leading, spacing: 28) {
                    Text(selectedPlan.name.localized).font(.largeTitle.weight(.semibold))
                    Text(selectedPlan.description.localized).font(.title3)
                        .fixedSize(horizontal: false, vertical: true)
                    Text(copy("Follow the illustrated guide at your own pace. No iPhone is needed. Heart rate and SCI are unavailable in standalone sessions.",
                              "Suivez le guide illustré à votre rythme. Aucun iPhone n’est requis. La fréquence cardiaque et le SCI ne sont pas disponibles en séance autonome."))
                        .font(.body).foregroundStyle(BrandColor.fgMuted)
                    Button { beginLocalSession() } label: {
                        Label(SessionHUDCopy.beginSession.localized, systemImage: "play.fill")
                    }
                    .tint(BrandColor.mint)
                    .accessibilityIdentifier("tv.beginLocalSession")
                    Divider()
                    Text(copy("Or use your iPhone session", "Ou utilisez votre séance iPhone"))
                        .font(.headline)
                    Button(TVRelayCopy.pair.localized) { beginPairing() }
                        .accessibilityIdentifier("tv.pairPhone")
                    Text(TVRelayCopy.introduction.localized).font(.callout).foregroundStyle(BrandColor.fgMuted)
                }
                .padding(20)
            }
            .frame(maxWidth: .infinity).focusSection()
        }
        .padding(48)
        .foregroundStyle(BrandColor.fg)
    }

    @ViewBuilder
    private func localContent(_ session: GuidedSessionController) -> some View {
        if session.phase == .complete {
            VStack(spacing: 32) {
                Image(systemName: "checkmark.circle.fill").font(.system(size: 64)).foregroundStyle(BrandColor.mint)
                    .accessibilityHidden(true)
                Text(session.endedEarly ? copy("Session ended", "Séance arrêtée") : copy("Session complete", "Séance terminée"))
                    .font(.largeTitle.bold())
                Text(session.plan.name.localized).font(.title2)
                Text("\(session.posesCompletedCount) / \(session.plan.poseCount) " + copy("poses completed", "postures terminées") + " · " + session.hudMetrics.elapsedText)
                    .font(.title3).foregroundStyle(BrandColor.fgMuted)
                HStack(spacing: 32) {
                    Button(copy("Choose another plan", "Choisir un autre programme")) { closeLocalSession() }
                    Button(TVRelayCopy.pair.localized) { beginPairing() }
                }
            }
            .padding(60).frame(maxWidth: .infinity, maxHeight: .infinity)
            .foregroundStyle(BrandColor.fg)
        } else if let payload = localPayload(session) {
            TVDisplayView(payload: payload)
                .safeAreaInset(edge: .bottom, spacing: 0) { localControls(session) }
                .onPlayPauseCommand {
                    if session.isPaused { session.resume() } else { session.pause() }
                }
        }
    }

    private func localControls(_ session: GuidedSessionController) -> some View {
        HStack(spacing: 32) {
            VStack(alignment: .leading, spacing: 6) {
                Text(session.plan.name.localized).font(.headline)
                Text(copy("Standalone session · Health data unavailable", "Séance autonome · Données de santé indisponibles"))
                    .font(.caption).foregroundStyle(BrandColor.fgMuted)
            }
            Spacer()
            Button {
                if session.isPaused { session.resume() } else { session.pause() }
            } label: {
                Label(session.isPaused ? SessionHUDCopy.resume.localized : SessionHUDCopy.pause.localized,
                      systemImage: session.isPaused ? "play.fill" : "pause.fill")
            }
            .accessibilityIdentifier("tv.pauseResume")
            Button(SessionHUDCopy.end.localized) { requestEnd(session) }
                .accessibilityIdentifier("tv.endSession")
        }
        .padding(.horizontal, 60).padding(.vertical, 24)
        .background(BrandColor.bgPanel)
    }

    /// Project authoritative local state into the same renderer as a paired phone.
    /// No HealthKit data or adaptive-music state is synthesized on this platform.
    private func localPayload(_ session: GuidedSessionController) -> TVDisplayPayload? {
        let pose: Pose
        let remaining: TimeInterval
        let total: TimeInterval
        let index: Int
        let transition: Bool
        switch session.phase {
        case .active(let current):
            guard let currentPose = session.currentPose else { return nil }
            pose = currentPose; remaining = session.poseTimeRemaining
            total = currentPose.durationSeconds; index = current; transition = false
        case .transition(let next, let seconds):
            guard let upcomingPose = session.upcomingPose else { return nil }
            pose = upcomingPose; remaining = TimeInterval(seconds)
            total = session.plan.transitionSeconds; index = next; transition = true
        case .ready, .complete: return nil
        }
        return TVDisplayPayload(currentPose: pose, poseTimeRemaining: remaining, totalPoseTime: total,
                                biofeedback: BiofeedbackSnapshot(), sessionElapsed: session.elapsedTime,
                                isPaused: session.isPaused, sequenceIndex: index,
                                sequenceTotal: session.plan.poseCount, isTransition: transition)
    }

    @ViewBuilder
    private var pairedContent: some View {
        if let payload = listener.latestPayload {
            TVDisplayView(payload: payload)
                .safeAreaInset(edge: .bottom, spacing: 0) {
                    HStack {
                        Text(copy("Controlled by your iPhone", "Commandé par votre iPhone"))
                        Spacer()
                        disconnectButton
                    }
                    .padding(.horizontal, 60).padding(.vertical, 24).background(BrandColor.bgPanel)
                }
        } else {
            VStack(spacing: SessionSpacing.lg) {
                Text("NATURaL").font(.largeTitle.bold()).foregroundStyle(BrandColor.fg)
                if listener.isConnected {
                    Text(TVRelayCopy.waiting.localized).font(.title2)
                    disconnectButton
                } else if let invitation = listener.invitation {
                    pairingCard(invitation)
                    Button(TVRelayCopy.cancel.localized) { leavePairing() }
                } else {
                    Text(TVRelayCopy.introduction.localized)
                        .font(.title2).multilineTextAlignment(.center).frame(maxWidth: 1000)
                    if listener.failedToStart {
                        Text(TVRelayCopy.unavailable.localized).foregroundStyle(BrandColor.strawberry)
                    }
                    Button(TVRelayCopy.pair.localized) { listener.startAdvertising() }.tint(BrandColor.mint)
                    Button(copy("Back to plans", "Retour aux programmes")) { leavePairing() }
                }
            }
            .foregroundStyle(BrandColor.fgMuted).padding(60)
        }
    }

    private var disconnectButton: some View {
        Button(TVRelayCopy.disconnect.localized) { leavePairing() }
    }

    private func beginLocalSession() {
        guard localSession == nil else { return }
        listener.stopAdvertising()
        isPairingMode = false
        let session = GuidedSessionController(plan: selectedPlan)
        localSession = session
        session.start()
    }

    private func closeLocalSession() {
        localSession?.reset()
        localSession = nil
    }

    private func beginPairing() {
        closeLocalSession()
        isPairingMode = true
        listener.startAdvertising()
    }

    private func leavePairing() {
        listener.stopAdvertising()
        isPairingMode = false
    }

    private func requestEnd(_ session: GuidedSessionController) {
        resumesAfterCancel = !session.isPaused
        session.pause()
        guard session.phase != .complete else { return }
        confirmsEnd = true
    }

    private func handleExit() {
        if let session = localSession {
            if session.phase == .complete { closeLocalSession() }
            else { requestEnd(session) }
        } else if isPairingMode { leavePairing() }
    }

    private func copy(_ en: String, _ fr: String) -> String { LocalizedString(en: en, fr: fr).localized }

    private func pairingCard(_ invitation: TVRelayPairing) -> some View {
        HStack(spacing: SessionSpacing.xxl) {
            if let qr = qrImage(invitation.url.absoluteString) {
                Image(uiImage: qr).interpolation(.none).resizable()
                    .scaledToFit().frame(width: 340, height: 340)
                    .padding(20).background(.white, in: RoundedRectangle(cornerRadius: SessionRadius.card))
                    .accessibilityHidden(true)
            }
            VStack(alignment: .leading, spacing: SessionSpacing.lg) {
                Text("NATURaL TV · " + invitation.id.uuidString.prefix(8))
                    .font(.title2.bold()).foregroundStyle(BrandColor.fg)
                Text(TVRelayCopy.instructions.localized).font(.title3)
                    .fixedSize(horizontal: false, vertical: true)
                Text(invitation.code).font(.system(.title2, design: .monospaced))
                    .foregroundStyle(BrandColor.fg)
                    .fixedSize(horizontal: false, vertical: true)
                Text(TVRelayCopy.expires.localized).font(.callout)
            }
            .frame(maxWidth: 920, alignment: .leading)
        }
        .padding(SessionSpacing.xl)
        .background(BrandColor.bgPanel, in: RoundedRectangle(cornerRadius: SessionRadius.panel))
    }

    private func qrImage(_ invitation: String) -> UIImage? {
        let filter = CIFilter.qrCodeGenerator()
        filter.message = Data(invitation.utf8)
        filter.correctionLevel = "M"
        guard let output = filter.outputImage,
              let image = CIContext().createCGImage(output, from: output.extent) else { return nil }
        return UIImage(cgImage: image)
    }
}
