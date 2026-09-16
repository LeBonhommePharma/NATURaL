import Foundation
import CoreMotion
import BonhommeCore

/// AirPods / headphone IMU → ClusterFleet yaw + spatial environment node.
///
/// Starts only when a headphone route is live. Stops and zeros yaw on disconnect.
/// Requires `NSMotionUsageDescription`. Availability: `CMHeadphoneMotionManager`.
@MainActor
final class HeadphoneMotionActuator {
    static let shared = HeadphoneMotionActuator()

    private let manager = CMHeadphoneMotionManager()
    private(set) var isRunning = false

    var isDeviceMotionAvailable: Bool {
        manager.isDeviceMotionAvailable
    }

    func start() {
        guard !isRunning else { return }
        guard manager.isDeviceMotionAvailable else { return }
        if CMHeadphoneMotionManager.authorizationStatus() == .denied { return }

        isRunning = true
        manager.startDeviceMotionUpdates(to: .main) { motion, _ in
            guard let motion else { return }
            let yawDegrees = motion.attitude.yaw * 180.0 / .pi
            Task { @MainActor in
                await ClusterFleet.shared.applyHeadphoneAttitude(yawDegrees: yawDegrees)
                let snap = await ClusterFleet.shared.snapshot()
                LowLatencyAudioRouter.shared.applySpatialState(
                    yawDegrees: snap.listenerYawDegrees,
                    depth: snap.spatialDepth
                )
            }
        }
    }

    func stop() {
        guard isRunning else { return }
        manager.stopDeviceMotionUpdates()
        isRunning = false
        Task {
            await ClusterFleet.shared.applyHeadphoneAttitude(yawDegrees: 0)
            let snap = await ClusterFleet.shared.snapshot()
            LowLatencyAudioRouter.shared.applySpatialState(
                yawDegrees: snap.listenerYawDegrees,
                depth: snap.spatialDepth
            )
        }
    }
}
