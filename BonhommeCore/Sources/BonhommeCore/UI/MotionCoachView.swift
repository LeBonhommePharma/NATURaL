import SwiftUI

/// Phase styling for the symbolic motion coach.
public enum MotionCoachPhase: Sendable {
    case preview
    case active
    case transition
}

/// Procedural, video-free pose guidance view.
/// Kinematics: per-category limb arcs driven by smoothstep, no label clutter.
public struct MotionCoachView: View {
    public let pose: Pose
    public var phase: MotionCoachPhase
    public var cornerRadius: CGFloat

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    public init(
        pose: Pose,
        phase: MotionCoachPhase = .active,
        cornerRadius: CGFloat = 28
    ) {
        self.pose = pose
        self.phase = phase
        self.cornerRadius = cornerRadius
    }

    public var body: some View {
        let profile = MotionCoachProfile(pose: pose)
        let moodSatBoost: Double = {
            switch pose.category.lightingMood {
            case .warm:    return 0.18
            case .cool:    return -0.08
            case .neutral: return 0.0
            }
        }()

        TimelineView(.animation(minimumInterval: reduceMotion ? 1.0 : (1.0 / 60.0), paused: false)) { context in
            let t = context.date.timeIntervalSinceReferenceDate
            let breathAngle = t * (.pi * 2.0) / profile.breathPeriod
            let wave  = reduceMotion ? 0.0 : sin(breathAngle)
            let pulse = reduceMotion ? 0.0 : (sin(breathAngle) + 1.0) * 0.5
            let hueShift = reduceMotion ? 0.0 : sin(breathAngle) * 0.02

            // Smoothstep on normalised breath phase [0,1] -> [0,1]
            let rawPhase = fmod(t / profile.breathPeriod, 1.0)
            let normPhase = rawPhase < 0 ? rawPhase + 1.0 : rawPhase
            let smooth = normPhase * normPhase * (3.0 - 2.0 * normPhase)

            ZStack(alignment: .bottom) {
                // Background
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [
                                Color(hue: profile.accentHue + hueShift, saturation: 0.42 + moodSatBoost, brightness: 0.20),
                                Color(hue: profile.accentHue + hueShift, saturation: 0.58 + moodSatBoost, brightness: 0.11),
                                Color.black.opacity(0.96)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )

                // Border glow
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .strokeBorder(
                        LinearGradient(
                            colors: [
                                Color.white.opacity(0.18),
                                Color(hue: profile.accentHue, saturation: 0.60, brightness: 0.92).opacity(0.30)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 1
                    )

                GeometryReader { geo in
                    let size = min(geo.size.width, geo.size.height)
                    let cx = geo.size.width  / 2.0
                    let cy = geo.size.height / 2.0

                    ZStack {
                        // Ambient bloom
                        Circle()
                            .fill(
                                RadialGradient(
                                    colors: [
                                        Color(hue: profile.accentHue, saturation: 0.3, brightness: 0.95).opacity(0.08 + pulse * 0.05),
                                        .clear
                                    ],
                                    center: .center,
                                    startRadius: 8,
                                    endRadius: size * 0.50
                                )
                            )
                            .frame(width: size, height: size)
                            .position(x: cx, y: cy)

                        // Ghost trail: 4 fading copies displaced along the limb arc
                        if !reduceMotion {
                            ForEach(0..<4, id: \.self) { i in
                                let lag = Double(i + 1) * 0.07
                                let ghostPhase = fmod(normPhase - lag, 1.0)
                                let gp = ghostPhase < 0 ? ghostPhase + 1.0 : ghostPhase
                                let gs = gp * gp * (3.0 - 2.0 * gp)
                                let ghostWave = sin((t - lag * profile.breathPeriod) * .pi * 2.0 / profile.breathPeriod)
                                let (gOffX, gOffY, gRot) = profile.limbOffset(
                                    smooth: gs,
                                    wave: ghostWave
                                )
                                let fade = 0.12 - Double(i) * 0.025

                                Image(systemName: profile.primarySymbol)
                                    .font(.system(size: size * 0.34, weight: .thin))
                                    .foregroundStyle(
                                        Color(hue: profile.accentHue, saturation: 0.74, brightness: 0.98)
                                            .opacity(max(fade, 0))
                                    )
                                    .rotationEffect(.degrees(gRot))
                                    .offset(x: gOffX, y: gOffY)
                                    .position(x: cx, y: cy)
                                    .blur(radius: CGFloat(i) * 0.8)
                            }
                        }

                        // Central figure: pose-specific kinematic displacement
                        let (offX, offY, rot) = profile.limbOffset(smooth: smooth, wave: wave)
                        Image(systemName: profile.primarySymbol)
                            .font(.system(size: size * 0.38, weight: .regular))
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [
                                        Color.white.opacity(0.97),
                                        Color(hue: profile.accentHue, saturation: 0.58, brightness: 0.98)
                                    ],
                                    startPoint: .top,
                                    endPoint: .bottom
                                )
                            )
                            .shadow(color: Color(hue: profile.accentHue, saturation: 0.72, brightness: 0.98).opacity(0.45), radius: 4)
                            .shadow(color: Color(hue: profile.accentHue, saturation: 0.72, brightness: 0.98).opacity(0.28), radius: 16)
                            .shadow(color: Color(hue: profile.accentHue, saturation: 0.72, brightness: 0.98).opacity(0.14), radius: 32)
                            .scaleEffect(1.0 + pulse * profile.scaleAmplitude)
                            .rotationEffect(.degrees(rot))
                            .offset(x: offX, y: offY)
                            .position(x: cx, y: cy)

                        // Limb arc indicator: motion trace
                        if !reduceMotion {
                            LimbArcView(
                                profile: profile,
                                smooth: smooth,
                                accentHue: profile.accentHue,
                                size: size
                            )
                            .position(x: cx, y: cy)
                        }
                    }
                    .frame(width: geo.size.width, height: geo.size.height)
                }

                // Single breathing cue at bottom, only in active phase
                if phase == .active {
                    HStack(spacing: 7) {
                        Image(systemName: "wind")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundStyle(Color(hue: profile.accentHue, saturation: 0.74, brightness: 0.98))
                        Text(profile.cue)
                            .font(.system(size: 13, weight: .medium, design: .rounded))
                            .foregroundStyle(.white.opacity(0.88))
                            .lineLimit(1)
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                    .background(.black.opacity(0.30), in: Capsule())
                    .padding(.bottom, 18)
                    .transition(.opacity.combined(with: .move(edge: .bottom)))
                }
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Text(LocalizedString(
            en: "Animated visual guidance for \(pose.name.localized)",
            fr: "Guidage visuel animé pour \(pose.name.localized)"
        ).localized))
    }
}

// MARK: - Limb arc path drawn as a subtle motion trace

private struct LimbArcView: View {
    let profile: MotionCoachProfile
    let smooth: Double
    let accentHue: Double
    let size: CGFloat

    var body: some View {
        let arcPath = profile.limbArcPath(size: size, progress: smooth)

        ZStack {
            // Full faint arc
            arcPath
                .stroke(
                    Color(hue: accentHue, saturation: 0.65, brightness: 0.95).opacity(0.22),
                    style: StrokeStyle(lineWidth: 1.5, lineCap: .round, dash: [3, 7])
                )
                .shadow(color: Color(hue: accentHue, saturation: 0.7, brightness: 0.95).opacity(0.15), radius: 4)

            // Bright segment showing current progress
            arcPath
                .trim(from: 0, to: max(0, min(smooth, 1)))
                .stroke(
                    Color(hue: accentHue, saturation: 0.72, brightness: 0.98).opacity(0.50),
                    style: StrokeStyle(lineWidth: 2.5, lineCap: .round)
                )
        }
    }
}

// MARK: - Profile

private struct MotionCoachProfile {
    let accentHue: Double
    let primarySymbol: String
    let breathPeriod: Double
    let scaleAmplitude: Double
    let cue: String
    private let category: PoseCategory
    private let difficulty: PoseDifficulty

    init(pose: Pose) {
        self.accentHue       = pose.category.accentHue
        self.primarySymbol   = pose.position.symbolName
        self.breathPeriod    = max(2.8, min(7.0, pose.durationSeconds / 10.0))
        self.scaleAmplitude  = 0.025 + Double(pose.difficulty.dotCount) * 0.008
        self.category        = pose.category
        self.difficulty      = pose.difficulty

        let breathing    = pose.breathingPattern.localized.trimmingCharacters(in: .whitespacesAndNewlines)
        let voiceCue     = pose.voiceCueText.localized.trimmingCharacters(in: .whitespacesAndNewlines)
        let description  = pose.description.localized.trimmingCharacters(in: .whitespacesAndNewlines)

        if !breathing.isEmpty {
            self.cue = breathing
        } else if !voiceCue.isEmpty {
            self.cue = voiceCue
        } else {
            self.cue = description
        }
    }

    /// Returns (offsetX, offsetY, rotationDegrees) for the central figure
    /// based on the category's characteristic kinematic motion.
    /// smooth ∈ [0,1] is the smoothstep-interpolated breath phase.
    /// wave ∈ [-1,1] is the raw sinusoidal phase.
    func limbOffset(smooth: Double, wave: Double) -> (CGFloat, CGFloat, Double) {
        let d = Double(difficulty.dotCount)

        switch category {
        case .spine, .back:
            // Spinal flexion/extension: vertical arc, slight forward lean
            let y = wave * (5.0 + d * 2.5)
            let rot = wave * (3.0 + d * 1.5)
            return (0, CGFloat(y), rot)

        case .hips, .legs:
            // Hip hinge: lateral sway dominant
            let x = wave * (6.0 + d * 2.0)
            let rot = wave * (4.0 + d * 1.0)
            return (CGFloat(x), 0, rot)

        case .shoulders, .arms, .chest:
            // Shoulder open/close: arms sweep, figure rotates around vertical axis
            let rot = smooth * (8.0 + d * 3.0) - (4.0 + d * 1.5)
            let x   = sin(smooth * .pi) * (4.0 + d * 1.5)
            return (CGFloat(x), 0, rot)

        case .neck:
            // Neck lateral tilt: head-side offset
            let rot = wave * (6.0 + d * 2.0)
            return (0, 0, rot)

        case .balance:
            // Single-leg balance: oscillation in both axes, reduced amplitude
            let x = sin(smooth * .pi * 2.0) * (3.0 + d * 1.0)
            let y = cos(smooth * .pi * 2.0) * (2.0 + d * 0.8)
            let rot = wave * (2.0 + d * 0.8)
            return (CGFloat(x), CGFloat(y), rot)

        case .core, .fullBody:
            // Full body engagement: compound twist
            let x   = wave * (3.0 + d * 1.5)
            let y   = sin(smooth * .pi) * (3.0 + d * 1.0)
            let rot = wave * (3.5 + d * 1.2)
            return (CGFloat(x), CGFloat(y), rot)

        case .breathing, .relaxation:
            // Minimal motion: pure vertical float, no rotation
            let y = wave * (4.0 + d * 1.0)
            return (0, CGFloat(y), 0)

        case .inversion:
            // Inverted balance: figure tilts toward inversion, larger rotation
            let rot = smooth * (12.0 + d * 4.0) - (6.0 + d * 2.0)
            let y   = wave * (3.0 + d * 1.0) * -1.0
            return (0, CGFloat(y), rot)
        }
    }

    /// Generates the limb arc Path: a quadratic / cubic Bezier tracing the
    /// characteristic movement envelope for the category.
    func limbArcPath(size: CGFloat, progress: Double) -> Path {
        let r = size * 0.30

        switch category {
        case .spine, .back:
            // Vertical arc
            return Path { p in
                p.move(to:    CGPoint(x: 0, y:  r))
                p.addQuadCurve(to: CGPoint(x: 0, y: -r),
                               control: CGPoint(x: r * 0.5, y: 0))
            }

        case .hips, .legs:
            // Horizontal sway arc
            return Path { p in
                p.move(to:    CGPoint(x: -r, y: 0))
                p.addQuadCurve(to: CGPoint(x: r, y: 0),
                               control: CGPoint(x: 0, y: r * 0.4))
            }

        case .shoulders, .arms, .chest:
            // Diagonal sweep arc
            return Path { p in
                p.move(to:    CGPoint(x: -r * 0.7, y:  r * 0.5))
                p.addQuadCurve(to: CGPoint(x: r * 0.7, y: -r * 0.5),
                               control: CGPoint(x: 0, y: -r * 0.6))
            }

        case .neck:
            // Short lateral tilt arc
            return Path { p in
                p.move(to:    CGPoint(x: -r * 0.4, y: -r * 0.2))
                p.addQuadCurve(to: CGPoint(x: r * 0.4, y: -r * 0.2),
                               control: CGPoint(x: 0, y: -r * 0.7))
            }

        case .balance:
            // Figure-8 approximation (two arcs)
            return Path { p in
                p.move(to:    CGPoint(x: 0, y:  r * 0.5))
                p.addQuadCurve(to: CGPoint(x: 0, y: -r * 0.5),
                               control: CGPoint(x: r * 0.6, y: 0))
                p.addQuadCurve(to: CGPoint(x: 0, y:  r * 0.5),
                               control: CGPoint(x: -r * 0.6, y: 0))
            }

        default:
            // Compound diagonal arc
            return Path { p in
                p.move(to: CGPoint(x: -r * 0.5, y:  r * 0.3))
                p.addCurve(
                    to:       CGPoint(x:  r * 0.5, y: -r * 0.3),
                    control1: CGPoint(x: -r * 0.2, y: -r * 0.6),
                    control2: CGPoint(x:  r * 0.2, y:  r * 0.5)
                )
            }
        }
    }
}
