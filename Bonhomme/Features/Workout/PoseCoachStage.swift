import SwiftUI
import ARKit
import AVFoundation
import BonhommeCore

/// The complete 2D guide is the default; the spatial illustration is optional.
struct PoseCoachStage: View {
    let pose: Pose
    var phase: MotionCoachPhase = .active
    var poseElapsed: TimeInterval = 0
    var cornerRadius: CGFloat = 28
    var isPaused: Bool = false

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.scenePhase) private var scenePhase
    @State private var requestedAR = false
    @State private var acquiredPlane = false
    @State private var requestingCamera = false
    @State private var status = ""

    var body: some View {
        ZStack {
            MotionCoachView(pose: pose, phase: phase, cornerRadius: cornerRadius,
                            poseElapsed: poseElapsed, isPaused: isPaused || requestedAR)
                .accessibilityHidden(requestedAR)
            if usesAR {
                ARPoseCoachView(pose: pose, phase: phase, poseElapsed: poseElapsed,
                                isPaused: isPaused, reduceMotion: reduceMotion,
                                onReady: { if requestedAR { acquiredPlane = true; status = "" } },
                                onUnavailable: { fallBack() })
                if !acquiredPlane {
                    VStack(spacing: 8) {
                        ProgressView()
                        Text(copy("Point the camera toward a clear floor area. Use the 2D button to return to the illustrated guide.",
                                  "Pointez la caméra vers un espace libre au sol. Le bouton 2D vous ramène au guide illustré."))
                            .multilineTextAlignment(.center).font(.callout)
                    }
                    .padding().background(.regularMaterial, in: RoundedRectangle(cornerRadius: 16))
                    .padding()
                }
            }
        }
        .overlay(alignment: .bottomTrailing) {
            if phase == .active && ARWorldTrackingConfiguration.isSupported {
                Button {
                    if requestedAR { requestedAR = false; status = "" }
                    else { requestAR() }
                } label: {
                    Label(requestedAR ? SessionHUDCopy.twoDCoach.localized : copy("Try spatial guide", "Essayer le guide spatial"),
                          systemImage: requestedAR ? "figure.yoga" : "arkit")
                        .font(.caption.weight(.semibold)).padding(10)
                }
                .buttonStyle(.borderedProminent)
                .disabled(!requestedAR && (isPaused || requestingCamera || scenePhase != .active))
                .padding(12)
            }
        }
        .overlay(alignment: .top) {
            if !status.isEmpty {
                Text(status).font(.caption).multilineTextAlignment(.center)
                    .padding(10).background(.regularMaterial, in: RoundedRectangle(cornerRadius: 12))
                    .padding(12).accessibilityIdentifier("poseCoach.status")
            }
        }
        .task(id: requestedAR) {
            guard requestedAR else { return }
            do { try await Task.sleep(for: .seconds(15)) } catch { return }
            if !acquiredPlane { fallBack() }
        }
        .onChange(of: isPaused) { _, paused in if paused { requestedAR = false } }
        .onChange(of: scenePhase) { _, state in if state != .active { requestedAR = false } }
        .onChange(of: phase) { _, value in if value != .active { requestedAR = false } }
    }

    private var usesAR: Bool {
        requestedAR && phase == .active && !isPaused && scenePhase == .active
            && AVCaptureDevice.authorizationStatus(for: .video) == .authorized
    }

    private func requestAR() {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            acquiredPlane = false
            status = ""
            requestedAR = true
        case .notDetermined:
            requestingCamera = true
            Task { @MainActor in
                let granted = await AVCaptureDevice.requestAccess(for: .video)
                requestingCamera = false
                if granted && !isPaused && scenePhase == .active && phase == .active {
                    acquiredPlane = false
                    status = ""
                    requestedAR = true
                } else { fallBack() }
            }
        default:
            fallBack()
        }
    }

    private func fallBack() {
        requestedAR = false
        status = copy("Spatial guide unavailable. Continue with the illustrated 2D guide.",
                      "Guide spatial indisponible. Continuez avec le guide illustré 2D.")
    }

    private func copy(_ en: String, _ fr: String) -> String { LocalizedString(en: en, fr: fr).localized }
}
