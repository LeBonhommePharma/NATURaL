import SwiftUI

// MARK: - Status chip

/// Compact status pill (entropy, tempo, music). Same language on phone, pad, watch, TV, Mac.
public struct SessionStatusChip: View {
    public var title: String
    public var systemImage: String
    public var tint: Color
    public var compact: Bool
    /// 10-foot / inspector chips (tvOS, spacious iPad).
    public var spacious: Bool

    public init(title: String, systemImage: String, tint: Color, compact: Bool = false, spacious: Bool = false) {
        self.title = title
        self.systemImage = systemImage
        self.tint = tint
        self.compact = compact
        self.spacious = spacious
    }

    public var body: some View {
        HStack(spacing: spacious ? SessionSpacing.xs : SessionSpacing.xxs) {
            Image(systemName: systemImage)
                .font(labelFont)
                .foregroundStyle(tint)
                .accessibilityHidden(true)
            Text(title)
                .font(labelFont)
                .foregroundStyle(BrandColor.fg)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
        }
        .padding(.horizontal, spacious ? SessionSpacing.md : (compact ? SessionSpacing.xs : SessionSpacing.sm))
        .padding(.vertical, spacious ? SessionSpacing.xs : (compact ? SessionSpacing.xxs : SessionSpacing.xxs + 1))
        .background(tint.opacity(0.16), in: Capsule(style: .continuous))
        .overlay(Capsule(style: .continuous).strokeBorder(tint.opacity(0.35), lineWidth: spacious ? 1 : 0.5))
        .accessibilityElement(children: .combine)
    }

    private var labelFont: Font {
        if spacious { return .title3.weight(.semibold) }
        if compact { return .caption2.weight(.semibold) }
        return .caption.weight(.semibold)
    }
}

// MARK: - Compact SCI meter

/// Glanceable SCI ring for phone HUD / Watch. Full TV ring remains `SCIVisualizationView`.
public struct CompactSCIMeter: View {
    public var score: Double?
    public var trend: SCITrend
    public var size: CGFloat
    /// When false, SCI is always violet (Mac single readout). When true, bands by score.
    public var banded: Bool

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    public init(score: Double?, trend: SCITrend = .stable, size: CGFloat = 56, banded: Bool = true) {
        self.score = score
        self.trend = trend
        self.size = size
        self.banded = banded
    }

    public var body: some View {
        let known = score.map(\.isFinite) ?? false
        let tint = banded ? SessionPalette.sci(score) : (known ? BrandColor.violet : BrandColor.magnesium)
        let percentText = SessionHUDMetrics(sciScore: score).sciPercentText
        let progress: CGFloat = {
            guard let score, score.isFinite else { return 0 }
            return CGFloat(min(1, max(0, score)))
        }()

        VStack(spacing: SessionSpacing.xxs) {
            ZStack {
                Circle()
                    .stroke(
                        BrandColor.hairline,
                        style: StrokeStyle(lineWidth: 5, dash: known ? [] : [4, 3])
                    )
                if known, progress > 0 {
                    Circle()
                        .trim(from: 0, to: progress)
                        .stroke(tint, style: StrokeStyle(lineWidth: 5, lineCap: .round))
                        .rotationEffect(.degrees(-90))
                        .sessionGlow(tint, radius: 6, paused: reduceMotion)
                        .animation(SessionMotion.spring(reduceMotion: reduceMotion), value: score)
                }

                VStack(spacing: 0) {
                    Text(percentText)
                        .font(SessionType.metric(size < 50 ? .body : .title3))
                        .monospacedDigit()
                        .foregroundStyle(BrandColor.fg)
                        .minimumScaleFactor(0.6)
                        .contentTransition(reduceMotion ? .identity : .numericText())
                    Image(systemName: trend.symbolName)
                        .font(.system(size: 9, weight: .bold))
                        .foregroundStyle(banded ? SessionPalette.trend(trend) : BrandColor.magnesium)
                        .accessibilityHidden(true)
                }
            }
            .frame(width: size, height: size)

            Text(SessionHUDCopy.sci.localized)
                .font(.caption2.weight(.medium))
                .foregroundStyle(BrandColor.fgMuted)
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Text(SessionHUDCopy.focusIndex.localized))
        .accessibilityValue(Text(percentText == "—" ? "unavailable" : "\(percentText) percent"))
    }
}

// MARK: - Heart rate readout

public struct SessionHeartRateReadout: View {
    public var bpm: Double?
    public var compact: Bool

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    public init(bpm: Double?, compact: Bool = false) {
        self.bpm = bpm
        self.compact = compact
    }

    public var body: some View {
        let tint = SessionPalette.heartRate(bpm)
        let value = SessionHUDMetrics(heartRate: bpm).heartRateText
        VStack(alignment: compact ? .center : .leading, spacing: 2) {
            HStack(spacing: SessionSpacing.xxs) {
                Image(systemName: "heart.fill")
                    .foregroundStyle(tint)
                    .font(compact ? .caption.weight(.semibold) : .body.weight(.semibold))
                    .symbolRenderingMode(.hierarchical)
                    .accessibilityHidden(true)
                Text(value)
                    .font(SessionType.metric(compact ? .title3 : .title2))
                    .monospacedDigit()
                    .foregroundStyle(BrandColor.fg)
                    .contentTransition(reduceMotion ? .identity : .numericText())
                    .minimumScaleFactor(0.6)
            }
            Text(SessionHUDCopy.bpm.localized)
                .font(.caption2.weight(.medium))
                .foregroundStyle(BrandColor.fgMuted)
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Text(SessionHUDCopy.heartRate.localized))
        .accessibilityValue(Text(value == "—" ? SessionHUDCopy.unavailable.localized : "\(value) \(SessionHUDCopy.bpm.localized)"))
    }
}

// MARK: - Pose identity

public struct SessionPoseHeader: View {
    public var pose: Pose
    public var prominence: Prominence

    public enum Prominence: Sendable {
        case compact
        case regular
        case large
    }

    public init(pose: Pose, prominence: Prominence = .regular) {
        self.pose = pose
        self.prominence = prominence
    }

    public var body: some View {
        let tint = Color(hue: pose.category.accentHue, saturation: 0.7, brightness: 0.9)
        VStack(spacing: SessionSpacing.xs) {
            Text(pose.name.localized)
                .font(nameFont)
                .foregroundStyle(BrandColor.fg)
                .multilineTextAlignment(.center)
                .minimumScaleFactor(0.7)
                .accessibilityIdentifier("session.pose.name")

            HStack(spacing: SessionSpacing.xs) {
                HStack(spacing: 3) {
                    ForEach(0..<3, id: \.self) { i in
                        Circle()
                            .fill(i < pose.difficulty.dotCount ? tint : BrandColor.magnesium.opacity(0.22))
                            .frame(width: prominence == .compact ? 5 : 6, height: prominence == .compact ? 5 : 6)
                    }
                }
                .accessibilityHidden(true)

                Text(pose.category.localizedName.localized)
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(BrandColor.fgMuted)
                    .lineLimit(1)
            }
            .accessibilityElement(children: .combine)
            .accessibilityLabel(Text("\(pose.difficulty.localizedName.localized), \(pose.category.localizedName.localized)"))
        }
    }

    private var nameFont: Font {
        switch prominence {
        case .compact: return .headline
        case .regular: return .title.weight(.bold)
        case .large: return .largeTitle.weight(.bold)
        }
    }
}

// MARK: - Phone HUD bar

/// Primary live metrics for iPhone: SCI + HR first, state/tempo chips, pose progress last.
public struct SessionHUDBar: View {
    public var metrics: SessionHUDMetrics

    public init(metrics: SessionHUDMetrics) {
        self.metrics = metrics
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: SessionSpacing.sm) {
            ViewThatFits(in: .horizontal) {
                HStack(alignment: .center, spacing: SessionSpacing.md) {
                    metricReadouts
                    Spacer(minLength: SessionSpacing.xs)
                    VStack(alignment: .trailing, spacing: SessionSpacing.xs) {
                        statusChips
                    }
                }
                VStack(alignment: .leading, spacing: SessionSpacing.sm) {
                    HStack(spacing: SessionSpacing.md) {
                        metricReadouts
                    }
                    VStack(alignment: .leading, spacing: SessionSpacing.xs) {
                        statusChips
                    }
                }
            }

            HStack(spacing: SessionSpacing.sm) {
                if let fraction = metrics.poseProgressFraction {
                    ProgressView(value: fraction)
                        .tint(SessionPalette.accent)
                        .accessibilityLabel(Text("Pose \(metrics.poseProgressText)"))
                } else {
                    Capsule()
                        .fill(BrandColor.magnesium.opacity(0.2))
                        .frame(height: 4)
                        .accessibilityLabel(Text("Pose —"))
                }
                Text(metrics.poseProgressText)
                    .font(.caption.weight(.semibold).monospacedDigit())
                    .foregroundStyle(BrandColor.fgMuted)
                Text(metrics.elapsedText)
                    .font(.caption.monospacedDigit())
                    .foregroundStyle(BrandColor.fgMuted.opacity(0.85))
                    .frame(minWidth: 36, alignment: .trailing)
            }
        }
        .padding(.horizontal, SessionSpacing.md)
        .padding(.vertical, SessionSpacing.sm)
        .sessionGlassFill(in: SessionRadius.cardShape())
        .accessibilityElement(children: .contain)
        .accessibilityLabel(Text(metrics.accessibilitySummary))
    }

    @ViewBuilder
    private var metricReadouts: some View {
        CompactSCIMeter(score: metrics.sciScore, trend: metrics.sciTrend, size: 56)
        SessionHeartRateReadout(bpm: metrics.heartRate)
    }

    @ViewBuilder
    private var statusChips: some View {
        if metrics.isPaused {
            SessionStatusChip(
                title: SessionHUDCopy.paused.localized,
                systemImage: "pause.circle.fill",
                tint: BrandColor.strawberry
            )
        } else {
            SessionStatusChip(
                title: metrics.entropyState.label.localized,
                systemImage: metrics.entropyState.symbolName,
                tint: SessionPalette.entropy(metrics.entropyState)
            )
        }
        if metrics.tempoBPM != nil {
            SessionStatusChip(
                title: "\(metrics.tempoText) \(SessionHUDCopy.bpm.localized)",
                systemImage: metrics.isGrounding ? "metronome.fill" : "metronome",
                tint: metrics.isGrounding ? BrandColor.strawberry : BrandColor.tangerine
            )
        }
        if metrics.isHeadphonesConnected {
            SessionStatusChip(
                title: SessionHUDCopy.airPods.localized,
                systemImage: "airpodspro",
                tint: BrandColor.aqua
            )
        } else if metrics.isMusicPlaying {
            SessionStatusChip(
                title: SessionHUDCopy.music.localized,
                systemImage: "speaker.wave.2.fill",
                tint: BrandColor.aqua
            )
        }
    }
}

// MARK: - Side panel (iPad / TV / Mac)

/// Vertical inspector: SCI ring, HR gauge, chips, progress. Calories stay off the primary scan path.
public struct SessionHUDPanel: View {
    public var metrics: SessionHUDMetrics
    public var showsGauges: Bool
    /// Larger chips for 10-foot TV (HIG / tvOS 18).
    public var spaciousChips: Bool

    public init(metrics: SessionHUDMetrics, showsGauges: Bool = true, spaciousChips: Bool = false) {
        self.metrics = metrics
        self.showsGauges = showsGauges
        self.spaciousChips = spaciousChips
    }

    public var body: some View {
        VStack(spacing: SessionSpacing.lg) {
            if showsGauges {
                HeartRateGaugeView(bpm: metrics.heartRate)
                SCIVisualizationView(score: metrics.sciScore, trend: metrics.sciTrend)
            } else {
                CompactSCIMeter(score: metrics.sciScore, trend: metrics.sciTrend, size: 72)
                SessionHeartRateReadout(bpm: metrics.heartRate)
            }

            HStack(spacing: SessionSpacing.xs) {
                if metrics.isPaused {
                    SessionStatusChip(
                        title: SessionHUDCopy.paused.localized,
                        systemImage: "pause.circle.fill",
                        tint: BrandColor.strawberry,
                        spacious: spaciousChips
                    )
                } else {
                    SessionStatusChip(
                        title: metrics.entropyState.label.localized,
                        systemImage: metrics.entropyState.symbolName,
                        tint: SessionPalette.entropy(metrics.entropyState),
                        spacious: spaciousChips
                    )
                }
                if metrics.tempoBPM != nil {
                    SessionStatusChip(
                        title: "\(metrics.tempoText)",
                        systemImage: "metronome",
                        tint: BrandColor.tangerine,
                        spacious: spaciousChips
                    )
                }
                if metrics.isHeadphonesConnected {
                    SessionStatusChip(
                        title: SessionHUDCopy.airPods.localized,
                        systemImage: "airpodspro",
                        tint: BrandColor.aqua,
                        spacious: spaciousChips
                    )
                }
            }

            SessionProgressView(
                index: metrics.poseIndex,
                total: metrics.poseCount,
                elapsed: metrics.elapsed
            )
        }
        .frame(maxWidth: .infinity)
        .padding(SessionSpacing.lg)
        .accessibilityElement(children: .contain)
    }
}

// MARK: - Watch glance strip

public struct SessionGlanceStrip: View {
    public var metrics: SessionHUDMetrics

    public init(metrics: SessionHUDMetrics) {
        self.metrics = metrics
    }

    public var body: some View {
        VStack(spacing: SessionSpacing.xs) {
            HStack(spacing: SessionSpacing.sm) {
                Text(metrics.sciPercentLabel)
                    .font(SessionType.metric(.title3))
                    .monospacedDigit()
                    .foregroundStyle(SessionPalette.sci(metrics.sciScore))
                Text(metrics.heartRateText)
                    .font(SessionType.metric(.title3))
                    .monospacedDigit()
                    .foregroundStyle(SessionPalette.heartRate(metrics.heartRate))
            }
            SessionStatusChip(
                title: metrics.isPaused
                    ? SessionHUDCopy.paused.localized
                    : metrics.entropyState.label.localized,
                systemImage: metrics.isPaused ? "pause.circle.fill" : metrics.entropyState.symbolName,
                tint: metrics.isPaused ? BrandColor.strawberry : SessionPalette.entropy(metrics.entropyState),
                compact: true
            )
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel(Text(metrics.accessibilitySummary))
    }
}

// MARK: - Session controls

public struct SessionControlBar: View {
    public var isPaused: Bool
    public var onPauseResume: () -> Void
    public var onEnd: () -> Void
    public var showsEnd: Bool
    public var prominence: Prominence

    public enum Prominence: Sendable {
        case phone
        case pad
        case watch
        case tv
        case mac
    }

    public init(
        isPaused: Bool,
        onPauseResume: @escaping () -> Void,
        onEnd: @escaping () -> Void,
        showsEnd: Bool = true,
        prominence: Prominence = .phone
    ) {
        self.isPaused = isPaused
        self.onPauseResume = onPauseResume
        self.onEnd = onEnd
        self.showsEnd = showsEnd
        self.prominence = prominence
    }

    public var body: some View {
        HStack(spacing: SessionSpacing.md) {
            Button(action: onPauseResume) {
                Label(
                    isPaused ? SessionHUDCopy.resume.localized : SessionHUDCopy.pause.localized,
                    systemImage: isPaused ? "play.fill" : "pause.fill"
                )
                .frame(maxWidth: .infinity, minHeight: minHeight)
            }
            .accessibilityIdentifier("session.pauseResume")
            .accessibilityLabel(Text(isPaused ? SessionHUDCopy.resume.localized : SessionHUDCopy.pause.localized))
            .tint(SessionPalette.accent)
            .sessionGlassButtonStyle()

            if showsEnd {
                Button(role: .destructive, action: onEnd) {
                    Label(SessionHUDCopy.end.localized, systemImage: "stop.fill")
                        .frame(maxWidth: .infinity, minHeight: minHeight)
                }
                .accessibilityIdentifier("session.end")
                .accessibilityLabel(Text(SessionHUDCopy.end.localized))
                .sessionGlassButtonStyle()
            }
        }
        .font(prominence == .watch ? .headline : .headline.weight(.semibold))
        .padding(.horizontal, prominence == .watch ? SessionSpacing.xs : SessionSpacing.md)
        .padding(.vertical, SessionSpacing.xs)
    }

    private var minHeight: CGFloat {
        switch prominence {
        case .phone, .pad: return SessionSpacing.phoneControlHeight
        case .watch: return SessionSpacing.minTapTarget
        case .tv: return 60
        case .mac: return SessionSpacing.minTapTarget
        }
    }
}

// MARK: - Begin CTA

public struct SessionBeginButton: View {
    public var action: () -> Void

    public init(action: @escaping () -> Void) {
        self.action = action
    }

    public var body: some View {
        Button(action: action) {
            Text(SessionHUDCopy.beginSession.localized)
                .font(.headline)
                .frame(maxWidth: .infinity, minHeight: SessionSpacing.phoneControlHeight)
        }
        .sessionProminentButtonStyle()
        .tint(SessionPalette.accent)
        .accessibilityIdentifier("session.begin")
        .accessibilityLabel(Text(SessionHUDCopy.beginSession.localized))
    }
}

// MARK: - Countdown numeral

public struct SessionCountdownNumeral: View {
    public var remaining: TimeInterval
    public var tint: Color

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    @ScaledMetric(relativeTo: .largeTitle) private var size: CGFloat = 64

    public init(remaining: TimeInterval, tint: Color = BrandColor.fg) {
        self.remaining = remaining
        self.tint = tint
    }

    public var body: some View {
        Text(SessionHUDMetrics.formatCountdown(remaining))
            .font(SessionType.metric(size: min(size, 96)))
            .monospacedDigit()
            .foregroundStyle(tint)
            .contentTransition(reduceMotion ? .identity : .numericText())
            .accessibilityLabel(Text(accessibleCountdown))
    }

    private var accessibleCountdown: String {
        guard remaining.isFinite,
              let seconds = Int(exactly: max(0, remaining).rounded()) else {
            return SessionHUDCopy.unavailable.localized
        }
        return "\(seconds) seconds remaining"
    }
}

// MARK: - Pause chrome

/// Compact pause status leaves the frozen illustration and instructions readable.
public struct SessionPausedOverlay: View {
    public init() {}

    public var body: some View {
        Label(SessionHUDCopy.paused.localized, systemImage: "pause.circle.fill")
            .font(.subheadline.weight(.semibold))
            .foregroundStyle(BrandColor.fg)
            .padding(.horizontal, SessionSpacing.md)
            .padding(.vertical, SessionSpacing.sm)
            .background(.regularMaterial, in: Capsule())
            .overlay(Capsule().strokeBorder(BrandColor.strawberry.opacity(0.5), lineWidth: 1))
            .padding(SessionSpacing.md)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topTrailing)
            .allowsHitTesting(false)
            .accessibilityElement(children: .ignore)
            .accessibilityAddTraits(.isHeader)
            .accessibilityLabel(Text(SessionHUDCopy.paused.localized))
    }
}
