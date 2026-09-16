import SwiftUI
import BonhommeCore

/// Phone live metrics — kept as a named type for the Xcode target.
/// Canonical HUD is `SessionHUDBar` in BonhommeCore.
struct MetricsOverlayView: View {
    let heartRate: Double?
    let calories: Double
    let elapsed: TimeInterval
    let poseIndex: Int
    let totalPoses: Int
    var sciScore: Double? = nil
    var sciTrend: SCITrend = .stable
    var tempoBPM: Double? = nil
    var isGrounding: Bool = false
    var isPaused: Bool = false
    var isMusicPlaying: Bool = false

    var body: some View {
        SessionHUDBar(
            metrics: SessionHUDMetrics(
                sciScore: sciScore,
                sciTrend: sciTrend,
                heartRate: heartRate,
                tempoBPM: tempoBPM,
                isGrounding: isGrounding,
                isPaused: isPaused,
                isMusicPlaying: isMusicPlaying,
                calories: calories,
                elapsed: elapsed,
                poseIndex: poseIndex,
                poseCount: totalPoses
            )
        )
    }
}
