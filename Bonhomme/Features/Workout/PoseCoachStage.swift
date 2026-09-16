import SwiftUI
import ARKit
import AVFoundation
import BonhommeCore

/// Session stage: AR coach when world tracking is supported, otherwise the 2D MotionCoach.
struct PoseCoachStage: View {
    let pose: Pose
    var phase: MotionCoachPhase = .active
    var poseElapsed: TimeInterval = 0
    var cornerRadius: CGFloat = 28

    @State private var arFailed = false

    var body: some View {
        Group {
            if usesAR {
                ARPoseCoachView(pose: pose, phase: phase, poseElapsed: poseElapsed) {
                    arFailed = true
                }
            } else {
                MotionCoachView(
                    pose: pose,
                    phase: phase,
                    cornerRadius: cornerRadius,
                    poseElapsed: poseElapsed
                )
            }
        }
        .accessibilityLabel(Text(
            usesAR ? SessionHUDCopy.arCoach.localized : SessionHUDCopy.twoDCoach.localized
        ))
    }

    private var usesAR: Bool {
        ARWorldTrackingConfiguration.isSupported
            && !arFailed
            && AVCaptureDevice.authorizationStatus(for: .video) != .denied
    }
}
