import Foundation

/// Coarse entropy / coherence band for the live HUD (not a Crooks σ_irr readout).
public enum SessionEntropyState: String, Sendable, Codable, Equatable {
    case unknown
    case grounding
    case collapsed
    case settling
    case focused
    case coherent

    public var label: LocalizedString {
        switch self {
        case .unknown:
            return LocalizedString(
                en: "Waiting", fr: "En attente", es: "Esperando",
                ja: "待機", zh: "等待", ko: "대기",
                ru: "Ожидание", de: "Warten", ar: "انتظار"
            )
        case .grounding:
            return LocalizedString(
                en: "Grounding", fr: "Ancrage", es: "Anclaje",
                ja: "グラウンディング", zh: "落地", ko: "그라운딩",
                ru: "Заземление", de: "Erdung", ar: "تثبيت"
            )
        case .collapsed:
            return LocalizedString(
                en: "Unsteady", fr: "Instable", es: "Inestable",
                ja: "不安定", zh: "不稳", ko: "불안정",
                ru: "Нестабильно", de: "Unruhig", ar: "غير مستقر"
            )
        case .settling:
            return LocalizedString(
                en: "Settling", fr: "Stabilisation", es: "Estabilizando",
                ja: "落ち着き", zh: "趋稳", ko: "안정 중",
                ru: "Стабилизация", de: "Beruhigung", ar: "استقرار"
            )
        case .focused:
            return LocalizedString(
                en: "Focused", fr: "Concentré", es: "Enfocado",
                ja: "集中", zh: "专注", ko: "집중",
                ru: "В фокусе", de: "Fokussiert", ar: "تركيز"
            )
        case .coherent:
            return LocalizedString(
                en: "Coherent", fr: "Cohérent", es: "Coherente",
                ja: "整っている", zh: "连贯", ko: "일관",
                ru: "Связно", de: "Kohärent", ar: "متسق"
            )
        }
    }

    public var symbolName: String {
        switch self {
        case .unknown: return "ellipsis"
        case .grounding: return "leaf.fill"
        case .collapsed: return "exclamationmark.triangle.fill"
        case .settling: return "wind"
        case .focused: return "eye.fill"
        case .coherent: return "checkmark.circle.fill"
        }
    }

    /// Derive a scannable band from grounding + SCI. Grounding always wins.
    public static func resolve(sciScore: Double?, isGrounding: Bool) -> SessionEntropyState {
        if isGrounding { return .grounding }
        guard let sciScore, sciScore.isFinite else { return .unknown }
        let score = min(1, max(0, sciScore))
        switch score {
        case ..<0.3: return .collapsed
        case 0.3..<0.6: return .settling
        case 0.6..<0.8: return .focused
        default: return .coherent
        }
    }
}

/// Snapshot of the live session HUD. Platform views render this; they do not invent metrics.
public struct SessionHUDMetrics: Sendable, Equatable {
    public var sciScore: Double?
    public var sciTrend: SCITrend
    public var heartRate: Double?
    public var tempoBPM: Double?
    public var isGrounding: Bool
    public var isPaused: Bool
    public var isMusicPlaying: Bool
    /// AirPods / headphone route is live (volume rocker + spatial actuators).
    public var isHeadphonesConnected: Bool
    public var calories: Double
    public var elapsed: TimeInterval
    public var poseIndex: Int
    public var poseCount: Int
    public var breathsPerMinute: Double?

    public init(
        sciScore: Double? = nil,
        sciTrend: SCITrend = .stable,
        heartRate: Double? = nil,
        tempoBPM: Double? = nil,
        isGrounding: Bool = false,
        isPaused: Bool = false,
        isMusicPlaying: Bool = false,
        isHeadphonesConnected: Bool = false,
        calories: Double = 0,
        elapsed: TimeInterval = 0,
        poseIndex: Int = 0,
        poseCount: Int = 0,
        breathsPerMinute: Double? = nil
    ) {
        self.sciScore = sciScore
        self.sciTrend = sciTrend
        self.heartRate = heartRate
        self.tempoBPM = tempoBPM
        self.isGrounding = isGrounding
        self.isPaused = isPaused
        self.isMusicPlaying = isMusicPlaying
        self.isHeadphonesConnected = isHeadphonesConnected
        self.calories = calories
        self.elapsed = elapsed
        self.poseIndex = poseIndex
        self.poseCount = poseCount
        self.breathsPerMinute = breathsPerMinute
    }

    public var entropyState: SessionEntropyState {
        SessionEntropyState.resolve(sciScore: sciScore, isGrounding: isGrounding)
    }

    public var sciPercentText: String {
        guard let sciScore, sciScore.isFinite else { return "—" }
        return "\(Int((min(1, max(0, sciScore)) * 100).rounded()))"
    }

    /// Watch / glance label. Never suffixes `%` onto an em dash.
    public var sciPercentLabel: String {
        sciPercentText == "—" ? "—" : "\(sciPercentText)%"
    }

    public var heartRateText: String {
        guard let heartRate, heartRate.isFinite, heartRate > 0 else { return "—" }
        return "\(Int(heartRate.rounded()))"
    }

    public var tempoText: String {
        guard let tempoBPM, tempoBPM.isFinite, tempoBPM > 0 else { return "—" }
        return "\(Int(tempoBPM.rounded()))"
    }

    public var elapsedText: String {
        Self.formatElapsed(elapsed)
    }

    public var poseProgressText: String {
        guard poseCount > 0 else { return "—" }
        let display = min(poseCount, max(1, poseIndex + 1))
        return "\(display)/\(poseCount)"
    }

    public var poseProgressFraction: Double {
        guard poseCount > 0 else { return 0 }
        return min(1, max(0, Double(poseIndex + 1) / Double(poseCount)))
    }

    public var accessibilitySummary: String {
        let sci = sciPercentText == "—" ? "unavailable" : "\(sciPercentText) percent"
        let hr = heartRateText == "—" ? "unavailable" : "\(heartRateText) BPM"
        let state = isPaused ? "paused" : entropyState.label.en
        let audio = isHeadphonesConnected ? "AirPods connected" : (isMusicPlaying ? "music playing" : "speaker")
        return "SCI \(sci), heart rate \(hr), \(state), \(audio), pose \(poseProgressText), \(elapsedText) elapsed"
    }

    public static func formatElapsed(_ elapsed: TimeInterval) -> String {
        let total = max(0, Int(elapsed))
        let minutes = total / 60
        let seconds = total % 60
        return String(format: "%d:%02d", minutes, seconds)
    }

    public static func formatCountdown(_ remaining: TimeInterval) -> String {
        let seconds = max(0, Int(remaining.rounded()))
        if seconds >= 60 {
            return String(format: "%d:%02d", seconds / 60, seconds % 60)
        }
        return "\(seconds)"
    }
}

public extension BiofeedbackSnapshot {
    /// Map a wire snapshot into HUD metrics (tempo/grounding filled by the session layer).
    func hudMetrics(
        elapsed: TimeInterval,
        poseIndex: Int,
        poseCount: Int,
        tempoBPM: Double? = nil,
        isGrounding: Bool = false,
        isPaused: Bool = false,
        isMusicPlaying: Bool = false,
        isHeadphonesConnected: Bool = false,
        breathsPerMinute: Double? = nil
    ) -> SessionHUDMetrics {
        SessionHUDMetrics(
            sciScore: sciScore,
            sciTrend: sciTrend,
            heartRate: heartRate,
            tempoBPM: tempoBPM,
            isGrounding: isGrounding,
            isPaused: isPaused,
            isMusicPlaying: isMusicPlaying,
            isHeadphonesConnected: isHeadphonesConnected,
            calories: activeCalories,
            elapsed: elapsed,
            poseIndex: poseIndex,
            poseCount: poseCount,
            breathsPerMinute: breathsPerMinute
        )
    }
}
