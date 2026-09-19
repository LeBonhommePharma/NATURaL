import SwiftUI
import BonhommeCore

/// The Mac companion offers local guided movement; it has no live Health feed.
struct MacRootView: View {
    @State private var selectedPlan: WorkoutPlan = PoseCatalog.beginnerFlow
    @State private var session: GuidedSessionController?

    var body: some View {
        NavigationStack {
            ScrollView {
                Group {
                    if let session, session.phase != .ready {
                        MacSessionCanvas(session: session, onClose: closeSession)
                    } else {
                        readyCanvas
                    }
                }
                .frame(maxWidth: 760)
                .padding(SessionSpacing.lg)
                .frame(maxWidth: .infinity)
            }
            .background(BrandColor.bg)
            .navigationTitle("NATURaL")
            .toolbarBackground(BrandColor.bgPanel, for: .automatic)
            .safeAreaInset(edge: .bottom) {
                VStack(spacing: 0) {
                    if let session, session.phase != .ready && session.phase != .complete {
                        MacSessionControls(session: session)
                            .padding(SessionSpacing.md).background(BrandColor.bgPanel)
                    }
                    footer
                }
            }
        }
        .frame(minWidth: 480, minHeight: 420)
        .onDisappear { closeSession() }
    }

    private var readyCanvas: some View {
        VStack(alignment: .leading, spacing: SessionSpacing.lg) {
            HStack(alignment: .center, spacing: SessionSpacing.lg) {
                Image("Bloom")
                    .resizable().scaledToFit()
                    .frame(width: 96, height: 96)
                    .clipShape(SessionRadius.cardShape())
                    .accessibilityHidden(true)
                VStack(alignment: .leading, spacing: SessionSpacing.xs) {
                    Text(copy("A little room to move.", "Un moment pour bouger."))
                        .font(.largeTitle.weight(.semibold))
                        .foregroundStyle(BrandColor.fg)
                    Text(copy("Your chair. Your pace. A moment for yourself.", "Votre chaise. Votre rythme. Un moment pour vous."))
                        .font(.body).foregroundStyle(BrandColor.magnesium)
                }
            }
            VStack(alignment: .leading, spacing: SessionSpacing.md) {
                Label(copy("Choose your session", "Choisissez votre séance"), systemImage: "leaf")
                    .font(.headline).foregroundStyle(BrandColor.mint)
                Picker(copy("Plan", "Programme"), selection: $selectedPlan) {
                    ForEach(PoseCatalog.allPlans) { plan in
                        Text(plan.name.localized).tag(plan)
                    }
                }
                .pickerStyle(.menu)
                .controlSize(.large)
                Text(selectedPlan.description.localized)
                    .foregroundStyle(BrandColor.fg)
                    .fixedSize(horizontal: false, vertical: true)
                Label("\(selectedPlan.poseCount) \(copy("poses", "postures")) · \(Int(selectedPlan.totalDuration) / 60) min", systemImage: "clock")
                    .font(.subheadline).foregroundStyle(BrandColor.magnesium)
                SessionBeginButton {
                    let controller = GuidedSessionController(plan: selectedPlan)
                    session = controller
                    controller.start()
                }
                .tint(SessionPalette.accent)
                .keyboardShortcut(.defaultAction)
            }
            .padding(SessionSpacing.lg)
            .background(BrandColor.bgPanel, in: SessionRadius.cardShape())
            .overlay(SessionRadius.cardShape().strokeBorder(BrandColor.hairline))

            DisclosureGroup(copy("Explore the poses", "Découvrir les postures")) {
                VStack(alignment: .leading, spacing: SessionSpacing.md) {
                    ForEach(Array(selectedPlan.poses.enumerated()), id: \.offset) { index, pose in
                        HStack(alignment: .top, spacing: SessionSpacing.sm) {
                            Text(String(index + 1)).font(.body.monospacedDigit())
                                .foregroundStyle(BrandColor.mint).frame(width: 28)
                            VStack(alignment: .leading, spacing: SessionSpacing.xxs) {
                                Text(pose.name.localized).font(.headline)
                                Text(pose.description.localized).font(.body)
                                    .foregroundStyle(BrandColor.magnesium)
                            }
                        }
                    }
                }.padding(.top, SessionSpacing.md)
            }
            .foregroundStyle(BrandColor.fg)
            .tint(BrandColor.mint)
            Text(copy("Use a stable chair and move within a comfortable range. You can pause or finish whenever you need.", "Utilisez une chaise stable et bougez sans inconfort. Vous pouvez faire une pause ou terminer à tout moment."))
                .font(.callout).foregroundStyle(BrandColor.magnesium)
            Label(copy("Guided movement on Mac. Live Health measurements are available in the iPhone and Watch apps.", "Séances guidées sur Mac. Les mesures Santé en direct sont disponibles dans les apps iPhone et Watch."), systemImage: "heart.text.clipboard")
                .font(.caption).foregroundStyle(BrandColor.fgMuted)
        }
    }

    private var footer: some View {
        HStack(spacing: SessionSpacing.lg) {
            Link(copy("Privacy", "Confidentialité"), destination: URL(string: "https://thebonhomme.com/NATURaL/privacy/")!)
            Link(copy("Support", "Assistance"), destination: URL(string: "https://thebonhomme.com/NATURaL/support/")!)
            Spacer()
            Text(copy("All plans are free", "Tous les programmes sont gratuits"))
                .foregroundStyle(BrandColor.fgMuted)
        }
        .font(.caption).tint(BrandColor.mint)
        .padding(SessionSpacing.md)
        .background(BrandColor.bgPanel)
    }

    private func closeSession() { session?.reset(); session = nil }
}

private struct MacSessionCanvas: View {
    @Bindable var session: GuidedSessionController
    var onClose: () -> Void

    var body: some View {
        VStack(spacing: SessionSpacing.lg) {
            Text(session.plan.name.localized)
                .font(.headline).foregroundStyle(BrandColor.magnesium)
            switch session.phase {
            case .active:
                if let pose = session.currentPose { active(pose) }
            case .transition(_, let seconds):
                VStack(spacing: SessionSpacing.md) {
                    Text(SessionHUDCopy.nextUp.localized).font(.headline)
                    if let pose = session.upcomingPose {
                        SessionPoseHeader(pose: pose)
                        MotionCoachView(pose: pose, phase: .transition, isPaused: session.isPaused)
                            .frame(height: 260)
                    }
                    SessionCountdownNumeral(remaining: TimeInterval(seconds), tint: SessionPalette.accent)
                }
            case .complete:
                Image(systemName: "checkmark.circle.fill")
                    .font(.largeTitle).foregroundStyle(BrandColor.mint)
                    .accessibilityHidden(true)
                Text(session.endedEarly ? copy("A moment well spent", "Un moment pour vous") : copy("Session complete", "Séance terminée"))
                    .font(.title.weight(.semibold))
                Text("\(session.posesCompletedCount) / \(session.plan.poseCount) \(copy("poses completed", "postures terminées")) · \(session.hudMetrics.elapsedText)")
                    .foregroundStyle(BrandColor.magnesium)
                Button(copy("Done", "Terminé"), action: onClose)
                    .sessionProminentButtonStyle().tint(SessionPalette.accent)
                    .keyboardShortcut(.defaultAction)
            case .ready: EmptyView()
            }
            if session.phase != .complete && session.phase != .ready {
                if session.isPaused {
                    Label(session.pausedForSuspension
                          ? copy("Paused after an interruption · Resume when ready", "En pause après une interruption · Reprenez à votre rythme")
                          : copy("Paused · Take your time", "En pause · Prenez votre temps"), systemImage: "pause.circle.fill")
                        .font(.headline).foregroundStyle(BrandColor.strawberry)
                        .accessibilityIdentifier("session.paused")
                }
                HStack {
                    Label(session.hudMetrics.elapsedText, systemImage: "clock")
                    Spacer()
                    Text("\(copy("Pose", "Posture")) \(session.hudMetrics.poseProgressText)")
                }
                .font(.body.monospacedDigit())
                .padding(SessionSpacing.md)
                .background(BrandColor.bgPanel, in: SessionRadius.cardShape())

            }
        }
        .foregroundStyle(BrandColor.fg)
        .frame(maxWidth: .infinity)
    }

    private func active(_ pose: Pose) -> some View {
        VStack(spacing: SessionSpacing.md) {
            SessionPoseHeader(pose: pose, prominence: .large)
            SessionCountdownNumeral(remaining: session.poseTimeRemaining)
            MotionCoachView(pose: pose, phase: .active,
                            poseElapsed: pose.durationSeconds - session.poseTimeRemaining,
                            isPaused: session.isPaused)
                .frame(height: 320)
            PoseGuideDetails(pose: pose)

        }
    }
}

private struct MacSessionControls: View {
    @Bindable var session: GuidedSessionController
    var body: some View {
                HStack(spacing: SessionSpacing.md) {
                    Button {
                        if session.isPaused { session.resume() } else { session.pause() }
                    } label: {
                        Label(session.isPaused ? SessionHUDCopy.resume.localized : SessionHUDCopy.pause.localized,
                              systemImage: session.isPaused ? "play.fill" : "pause.fill")
                            .frame(maxWidth: .infinity, minHeight: SessionSpacing.minTapTarget)
                    }
                    .sessionProminentButtonStyle().tint(BrandColor.mint)
                    .keyboardShortcut(.space, modifiers: [])
                    .accessibilityIdentifier("session.pauseResume")
                    Button(role: .destructive) { session.stop() } label: {
                        Label(SessionHUDCopy.end.localized, systemImage: "stop.fill")
                            .frame(minHeight: SessionSpacing.minTapTarget)
                    }
                    .buttonStyle(.bordered).tint(BrandColor.strawberry)
                    .accessibilityIdentifier("session.end")
                }
    }
}

private func copy(_ en: String, _ fr: String) -> String {
    LocalizedString(en: en, fr: fr).localized
}
