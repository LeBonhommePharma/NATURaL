import SwiftUI

// MARK: - Breath phase model

/// Discrete half of a guided breath cycle (UI + Watch haptics).
public enum BreathGuidePhase: String, Sendable, Equatable {
    case inhale
    case exhale

    public var label: LocalizedString {
        switch self {
        case .inhale:
            return LocalizedString(en: "Inhale", fr: "Inspirez")
        case .exhale:
            return LocalizedString(en: "Exhale", fr: "Expirez")
        }
    }
}

/// Pure timing helpers for phase-synced breath UI and haptic boundaries.
///
/// Phase is driven from absolute time so late-mounted views and Watch haptics
/// stay locked without sharing mutable phase state with the control loop.
public enum BreathGuideTiming: Sendable {
    /// Normalized phase in [0, 1) for a full inhale+exhale cycle.
    public static func phase01(at date: Date, period: TimeInterval, origin: Date = .distantPast) -> Double {
        let p = period.isFinite && period > 0.25 ? period : 4.0
        let elapsed = date.timeIntervalSince(origin)
        guard elapsed.isFinite else { return 0 }
        let t = elapsed.truncatingRemainder(dividingBy: p)
        let normalized = t < 0 ? t + p : t
        return normalized / p
    }

    /// Scale for the guide circle: 0.72 (exhale end) … 1.0 (inhale peak).
    public static func expandScale(phase01: Double) -> CGFloat {
        let p = max(0, min(1, phase01))
        // Smooth half-sine: expand 0→0.5, contract 0.5→1.
        let wave = sin(p * .pi)
        return CGFloat(0.72 + 0.28 * wave)
    }

    public static func phase(at date: Date, period: TimeInterval, origin: Date = .distantPast) -> BreathGuidePhase {
        phase01(at: date, period: period, origin: origin) < 0.5 ? .inhale : .exhale
    }

    /// True when `date` crossed an inhale (0) or exhale (0.5) boundary since `previous`.
    public static func crossedBoundary(
        previous: Date,
        current: Date,
        period: TimeInterval,
        origin: Date = .distantPast
    ) -> BreathGuidePhase? {
        let p = period.isFinite && period > 0.25 ? period : 4.0
        let prev = phase01(at: previous, period: p, origin: origin)
        let curr = phase01(at: current, period: p, origin: origin)
        // Wrapped past 0 → inhale boundary.
        if curr < prev {
            return .inhale
        }
        // Crossed 0.5 without wrap → exhale boundary.
        if prev < 0.5 && curr >= 0.5 {
            return .exhale
        }
        return nil
    }
}

// MARK: - Breathing guide view

/// Phase-synced expand/contract breath circle for workout overlays.
///
/// Driven by session `breathsPerMinute` (from `BreathingGuideActuatorChannel` via
/// `PharmaControlSessionSnapshot`). Does **not** touch the control loop — pure UI.
///
/// - `prominence`: `.subtle` always-on soft ring; `.grounding` stronger cue + label.
public struct BreathingGuideView: View {
    public enum Prominence: Sendable, Equatable {
        /// Soft ambient ring (non-grounding sessions).
        case subtle
        /// Emphasized ring + phase label during grounding recovery.
        case grounding
    }

    public var breathsPerMinute: Double
    public var isGrounding: Bool
    public var prominence: Prominence
    public var accent: Color
    /// Shared timeline origin so iOS / Watch / overlays stay phase-locked.
    public var phaseOrigin: Date

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    public init(
        breathsPerMinute: Double,
        isGrounding: Bool = false,
        prominence: Prominence? = nil,
        accent: Color = .cyan,
        phaseOrigin: Date = Date(timeIntervalSinceReferenceDate: 0)
    ) {
        self.breathsPerMinute = breathsPerMinute
        self.isGrounding = isGrounding
        self.prominence = prominence ?? (isGrounding ? .grounding : .subtle)
        self.accent = accent
        self.phaseOrigin = phaseOrigin
    }

    private var period: TimeInterval {
        BreathingGuideActuatorChannel.breathPeriodSeconds(rate: breathsPerMinute)
    }

    public var body: some View {
        TimelineView(.animation(minimumInterval: reduceMotion ? 1.0 / 15.0 : 1.0 / 30.0, paused: false)) { context in
            let phase01 = BreathGuideTiming.phase01(
                at: context.date,
                period: period,
                origin: phaseOrigin
            )
            let scale = reduceMotion ? 0.9 : BreathGuideTiming.expandScale(phase01: phase01)
            let half = BreathGuideTiming.phase(at: context.date, period: period, origin: phaseOrigin)
            let ringOpacity = prominence == .grounding ? 0.85 : 0.35
            let fillOpacity = prominence == .grounding ? 0.18 : 0.08

            VStack(spacing: 6) {
                ZStack {
                    Circle()
                        .fill(accent.opacity(fillOpacity))
                        .scaleEffect(scale)
                    Circle()
                        .stroke(accent.opacity(ringOpacity), lineWidth: prominence == .grounding ? 3 : 1.5)
                        .scaleEffect(scale)
                        .shadow(color: accent.opacity(prominence == .grounding ? 0.45 : 0.15), radius: 8)

                    if prominence == .grounding {
                        Image(systemName: half == .inhale ? "arrow.up.circle" : "arrow.down.circle")
                            .font(.system(size: 22, weight: .medium))
                            .foregroundStyle(accent.opacity(0.9))
                            .scaleEffect(scale * 0.95)
                    }
                }
                .frame(width: 72, height: 72)

                if prominence == .grounding {
                    Text(half.label.localized)
                        .font(.system(size: 12, weight: .semibold, design: .rounded))
                        .foregroundStyle(.white.opacity(0.75))
                    Text(String(format: "%.0f / min", breathsPerMinute > 0.1 ? breathsPerMinute : BreathingGuideActuatorChannel.defaultBreathsPerMinute))
                        .font(.system(size: 10, weight: .medium, design: .monospaced))
                        .foregroundStyle(.white.opacity(0.4))
                }
            }
            .accessibilityElement(children: .ignore)
            .accessibilityLabel(Text(half.label.localized))
            .accessibilityValue(Text(String(format: "%.0f breaths per minute", breathsPerMinute)))
        }
    }
}

// MARK: - Compact overlay helper

/// Bottom-trailing breath overlay for workout screens.
public struct BreathingGuideOverlay: View {
    public var breathsPerMinute: Double
    public var isGrounding: Bool
    /// When false, only show during grounding; when true, always show (subtle).
    public var alwaysVisible: Bool

    public init(
        breathsPerMinute: Double,
        isGrounding: Bool,
        alwaysVisible: Bool = true
    ) {
        self.breathsPerMinute = breathsPerMinute
        self.isGrounding = isGrounding
        self.alwaysVisible = alwaysVisible
    }

    public var body: some View {
        if alwaysVisible || isGrounding {
            BreathingGuideView(
                breathsPerMinute: breathsPerMinute > 0.1
                    ? breathsPerMinute
                    : BreathingGuideActuatorChannel.defaultBreathsPerMinute,
                isGrounding: isGrounding,
                prominence: isGrounding ? .grounding : .subtle
            )
            .padding(.trailing, 16)
            .padding(.bottom, 8)
            .transition(.opacity.combined(with: .scale(scale: 0.9)))
            .animation(.easeInOut(duration: 0.35), value: isGrounding)
        }
    }
}
