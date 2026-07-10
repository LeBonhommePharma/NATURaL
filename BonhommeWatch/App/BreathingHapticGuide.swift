import Foundation
import WatchKit
import BonhommeCore

/// Watch breath-boundary haptics driven by session breath rate.
///
/// Polls absolute-time phase from `BreathGuideTiming` and plays a short
/// `WKInterfaceDevice` haptic at inhale / exhale edges. Debounced so rapid
/// rate changes or overlapping timers cannot flood the Taptic Engine.
///
/// Does **not** run on the Crooks control path — only consumes published rates.
@MainActor
final class BreathingHapticGuide {
    /// Minimum gap between haptic pulses (prevents double-fire near boundaries).
    private static let minInterval: TimeInterval = 1.2

    private var pollTask: Task<Void, Never>?
    private var lastPulseDate: Date = .distantPast
    private var lastSampleDate: Date = Date()
    private var breathsPerMinute: Double = BreathingGuideActuatorChannel.defaultBreathsPerMinute
    private var isEnabled = false
    private let phaseOrigin = Date(timeIntervalSinceReferenceDate: 0)

    /// Update rate from `PharmaControlSessionSnapshot` (non-blocking).
    func update(breathsPerMinute rate: Double, isGrounding: Bool) {
        let safe = rate.isFinite && rate > 0.1
            ? rate
            : BreathingGuideActuatorChannel.defaultBreathsPerMinute
        breathsPerMinute = safe
        // Always cue during active session; grounding uses slightly stronger type.
        _ = isGrounding
    }

    func start() {
        guard pollTask == nil else { return }
        isEnabled = true
        lastSampleDate = Date()
        pollTask = Task { [weak self] in
            // ~8 Hz poll is enough for boundary detection without battery thrash.
            while let self, !Task.isCancelled, self.isEnabled {
                self.pollOnce()
                try? await Task.sleep(for: .milliseconds(125))
            }
        }
    }

    func stop() {
        isEnabled = false
        pollTask?.cancel()
        pollTask = nil
    }

    private func pollOnce() {
        let now = Date()
        let period = BreathingGuideActuatorChannel.breathPeriodSeconds(rate: breathsPerMinute)
        guard let boundary = BreathGuideTiming.crossedBoundary(
            previous: lastSampleDate,
            current: now,
            period: period,
            origin: phaseOrigin
        ) else {
            lastSampleDate = now
            return
        }
        lastSampleDate = now

        // Debounce: skip if we pulsed too recently (rate jump / double edge).
        guard now.timeIntervalSince(lastPulseDate) >= Self.minInterval else { return }
        lastPulseDate = now
        play(for: boundary)
    }

    private func play(for phase: BreathGuidePhase) {
        // Inhale: upward direction; exhale: softer click — maps cleanly on Series 4+.
        let type: WKHapticType = phase == .inhale ? .directionUp : .directionDown
        WKInterfaceDevice.current().play(type)
    }
}
