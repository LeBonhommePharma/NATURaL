import ActivityKit
import Foundation

/// ActivityKit attributes for the workout Live Activity displayed in Dynamic Island
/// and on the Lock Screen during active yoga sessions.
struct WorkoutActivityAttributes: ActivityAttributes {
    /// Static context set when the Live Activity starts.
    let planName: String
    let styleName: String
    let styleSymbol: String
    let totalPoses: Int
    let accentHue: Double

    /// Dynamic state updated every second during the workout.
    struct ContentState: Codable, Hashable {
        let currentPoseName: String
        let poseIndex: Int
        let poseTimeRemaining: Int
        let elapsedTime: TimeInterval
        let heartRate: Int?
        let calories: Int
    }
}
