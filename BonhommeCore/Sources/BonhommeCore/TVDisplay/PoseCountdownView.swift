import SwiftUI

/// A readable large-screen guide driven by the phone's authoritative hold state.
public struct PoseCountdownView: View {
    public let pose: Pose
    public let remaining: TimeInterval
    public let total: TimeInterval
    public var isPaused: Bool
    public var isTransition: Bool

    public init(pose: Pose, remaining: TimeInterval, total: TimeInterval,
                isPaused: Bool = false, isTransition: Bool = false) {
        self.pose = pose; self.remaining = remaining; self.total = total
        self.isPaused = isPaused; self.isTransition = isTransition
    }

    public var body: some View {
        VStack(spacing: 20) {
            if isTransition {
                Text(SessionHUDCopy.nextUp.localized)
                    .font(.title2).foregroundStyle(BrandColor.mint)
            }
            Text(pose.name.localized)
                .font(.largeTitle.weight(.semibold))
                .foregroundStyle(BrandColor.fg)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
            HStack(spacing: 16) {
                if isPaused {
                    Label(SessionHUDCopy.paused.localized, systemImage: "pause.circle.fill")
                        .foregroundStyle(BrandColor.strawberry)
                }
                Text(timeString)
                    .font(.largeTitle.monospacedDigit().weight(.bold))
                    .foregroundStyle(BrandColor.fg)
                    .accessibilityLabel(LocalizedString(en: "Time remaining", fr: "Temps restant").localized)
                    .accessibilityValue(timeString)
            }
            MotionCoachView(pose: pose, phase: isTransition ? .transition : .active,
                            cornerRadius: 26, poseElapsed: poseElapsed,
                            isPaused: isPaused || !known)
                .frame(minHeight: 280, idealHeight: 420, maxHeight: 500)
                .id(pose.id)
            if let fraction {
                ProgressView(value: fraction)
                    .tint(BrandColor.mint)
                    .accessibilityLabel(LocalizedString(en: "Hold remaining", fr: "Maintien restant").localized)
            }
            PoseGuideDetails(pose: pose)
                .font(.title3)
                .foregroundStyle(BrandColor.fg)
        }
        .frame(maxWidth: .infinity)
        .padding(24)
    }

    private var known: Bool { total.isFinite && total > 0 && remaining.isFinite && remaining >= 0 }
    private var fraction: Double? { known ? min(1, max(0, remaining / total)) : nil }
    private var poseElapsed: TimeInterval { known && !isTransition ? max(0, total - remaining) : 0 }
    private var timeString: String {
        guard known, let seconds = Int(exactly: remaining.rounded(.down)) else { return "—" }
        return "\(seconds / 60):\(String(format: "%02d", seconds % 60))"
    }
}
