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
                                StickFigureKinematicsView(
                                    pose: pose,
                                    phase: phase,
                                    smooth: gs,
                                    wave: ghostWave
                                )
                                    .frame(width: size * 0.58, height: size * 0.58)
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
                        StickFigureKinematicsView(
                            pose: pose,
                            phase: phase,
                            smooth: smooth,
                            wave: wave
                        )
                            .frame(width: size * 0.62, height: size * 0.62)
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

// MARK: - Stick figure kinematics

private struct StickFigureKinematicsView: View {
    let pose: Pose
    let phase: MotionCoachPhase
    let smooth: Double
    let wave: Double

    var body: some View {
        GeometryReader { geo in
            let size = min(geo.size.width, geo.size.height)
            let center = CGPoint(x: geo.size.width / 2.0, y: geo.size.height / 2.0)
            let profile = StickFigureMotionProfile(
                category: pose.category,
                difficulty: pose.difficulty,
                phase: phase
            )

            let cycle = smooth * .pi * 2.0
            let torsoTilt = profile.torsoTiltRadians * wave
            let torsoBob = profile.verticalBob * cos(cycle) * size
            let sway = profile.lateralSway * sin(cycle) * size

            let pelvis = CGPoint(
                x: center.x + sway,
                y: center.y + size * 0.10 + torsoBob
            )
            let torsoLength = size * 0.30
            let neck = point(from: pelvis, length: torsoLength, angle: -.pi / 2.0 + torsoTilt)
            let headRadius = size * 0.075
            let headCenter = point(from: neck, length: headRadius * 1.6, angle: -.pi / 2.0 + torsoTilt)

            let shoulderHalfWidth = size * 0.14
            let hipHalfWidth = size * 0.10
            let shoulderAxis = torsoTilt

            let leftShoulder = point(from: neck, length: shoulderHalfWidth, angle: shoulderAxis + .pi)
            let rightShoulder = point(from: neck, length: shoulderHalfWidth, angle: shoulderAxis)
            let leftHip = point(from: pelvis, length: hipHalfWidth, angle: shoulderAxis + .pi)
            let rightHip = point(from: pelvis, length: hipHalfWidth, angle: shoulderAxis)

            let armSwing = profile.armSwingRadians * sin(cycle)
            let elbowFlexBase = profile.elbowFlexRadians
            let elbowFlexPulse = profile.elbowFlexVarianceRadians * (0.5 + 0.5 * cos(cycle))
            let elbowFlex = elbowFlexBase + elbowFlexPulse

            let upperArm = size * 0.18
            let lowerArm = size * 0.16
            let leftUpperAngle = -.pi / 2.0 + torsoTilt + armSwing
            let rightUpperAngle = -.pi / 2.0 + torsoTilt - armSwing

            let leftElbow = point(from: leftShoulder, length: upperArm, angle: leftUpperAngle)
            let rightElbow = point(from: rightShoulder, length: upperArm, angle: rightUpperAngle)
            let leftHand = point(from: leftElbow, length: lowerArm, angle: leftUpperAngle + (.pi - elbowFlex))
            let rightHand = point(from: rightElbow, length: lowerArm, angle: rightUpperAngle - (.pi - elbowFlex))

            let upperLeg = size * 0.19
            let lowerLeg = size * 0.19
            let kneeDrift = profile.kneeDriftRadians * sin(cycle)
            let kneeFlex = profile.kneeFlexRadians + profile.kneeFlexVarianceRadians * (0.5 + 0.5 * sin(cycle + .pi / 2.0))

            let leftKnee = point(from: leftHip, length: upperLeg, angle: .pi / 2.0 + torsoTilt - kneeDrift)
            let rightKnee = point(from: rightHip, length: upperLeg, angle: .pi / 2.0 + torsoTilt + kneeDrift)
            let leftFoot = point(from: leftKnee, length: lowerLeg, angle: .pi / 2.0 + torsoTilt - kneeFlex * 0.35)
            let rightFoot = point(from: rightKnee, length: lowerLeg, angle: .pi / 2.0 + torsoTilt + kneeFlex * 0.35)

            let lineColor = Color.white.opacity(0.94)
            let limbColor = Color(hue: pose.category.accentHue, saturation: 0.78, brightness: 0.99)

            ZStack {
                Path { p in
                    p.move(to: neck)
                    p.addLine(to: pelvis)

                    p.move(to: leftShoulder)
                    p.addLine(to: rightShoulder)
                    p.move(to: leftHip)
                    p.addLine(to: rightHip)

                    p.move(to: leftHip)
                    p.addLine(to: leftKnee)
                    p.addLine(to: leftFoot)

                    p.move(to: rightHip)
                    p.addLine(to: rightKnee)
                    p.addLine(to: rightFoot)
                }
                .stroke(
                    lineColor,
                    style: StrokeStyle(lineWidth: 2.4, lineCap: .round, lineJoin: .round)
                )

                Path { p in
                    p.move(to: leftShoulder)
                    p.addLine(to: leftElbow)
                    p.addLine(to: leftHand)

                    p.move(to: rightShoulder)
                    p.addLine(to: rightElbow)
                    p.addLine(to: rightHand)
                }
                .stroke(
                    limbColor,
                    style: StrokeStyle(lineWidth: 2.8, lineCap: .round, lineJoin: .round)
                )

                Circle()
                    .stroke(lineColor, lineWidth: 2.2)
                    .frame(width: headRadius * 2.0, height: headRadius * 2.0)
                    .position(headCenter)

                joint(at: neck, color: lineColor)
                joint(at: leftShoulder, color: limbColor)
                joint(at: rightShoulder, color: limbColor)
                joint(at: leftElbow, color: limbColor)
                joint(at: rightElbow, color: limbColor)
                joint(at: pelvis, color: lineColor)
                joint(at: leftKnee, color: lineColor)
                joint(at: rightKnee, color: lineColor)
            }
            .frame(width: geo.size.width, height: geo.size.height)
        }
    }

    private func point(from origin: CGPoint, length: CGFloat, angle: Double) -> CGPoint {
        CGPoint(
            x: origin.x + cos(angle) * length,
            y: origin.y + sin(angle) * length
        )
    }

    @ViewBuilder
    private func joint(at point: CGPoint, color: Color) -> some View {
        Circle()
            .fill(color.opacity(0.92))
            .frame(width: 4.0, height: 4.0)
            .position(point)
    }
}

private struct StickFigureMotionProfile {
    let torsoTiltRadians: Double
    let verticalBob: Double
    let lateralSway: Double
    let armSwingRadians: Double
    let elbowFlexRadians: Double
    let elbowFlexVarianceRadians: Double
    let kneeDriftRadians: Double
    let kneeFlexRadians: Double
    let kneeFlexVarianceRadians: Double

    init(category: PoseCategory, difficulty: PoseDifficulty, phase: MotionCoachPhase) {
        let difficultyScale = 1.0 + (Double(difficulty.dotCount) - 1.0) * 0.12
        let phaseScale: Double
        switch phase {
        case .preview: phaseScale = 0.68
        case .active: phaseScale = 1.0
        case .transition: phaseScale = 0.82
        }

        switch category {
        case .spine, .back:
            torsoTiltRadians = 0.18 * difficultyScale * phaseScale
            verticalBob = 0.030 * difficultyScale * phaseScale
            lateralSway = 0.018 * phaseScale
            armSwingRadians = 0.15 * difficultyScale * phaseScale
            elbowFlexRadians = 0.95
            elbowFlexVarianceRadians = 0.20 * phaseScale
            kneeDriftRadians = 0.06 * phaseScale
            kneeFlexRadians = 0.30
            kneeFlexVarianceRadians = 0.12 * phaseScale

        case .hips, .legs:
            torsoTiltRadians = 0.10 * difficultyScale * phaseScale
            verticalBob = 0.024 * difficultyScale * phaseScale
            lateralSway = 0.045 * difficultyScale * phaseScale
            armSwingRadians = 0.10 * phaseScale
            elbowFlexRadians = 1.10
            elbowFlexVarianceRadians = 0.12 * phaseScale
            kneeDriftRadians = 0.12 * difficultyScale * phaseScale
            kneeFlexRadians = 0.42
            kneeFlexVarianceRadians = 0.15 * phaseScale

        case .shoulders, .arms, .chest:
            torsoTiltRadians = 0.08 * phaseScale
            verticalBob = 0.018 * phaseScale
            lateralSway = 0.012 * phaseScale
            armSwingRadians = 0.42 * difficultyScale * phaseScale
            elbowFlexRadians = 1.28
            elbowFlexVarianceRadians = 0.32 * difficultyScale * phaseScale
            kneeDriftRadians = 0.03 * phaseScale
            kneeFlexRadians = 0.24
            kneeFlexVarianceRadians = 0.08 * phaseScale

        case .neck:
            torsoTiltRadians = 0.14 * difficultyScale * phaseScale
            verticalBob = 0.012 * phaseScale
            lateralSway = 0.016 * phaseScale
            armSwingRadians = 0.06 * phaseScale
            elbowFlexRadians = 1.02
            elbowFlexVarianceRadians = 0.09 * phaseScale
            kneeDriftRadians = 0.02 * phaseScale
            kneeFlexRadians = 0.22
            kneeFlexVarianceRadians = 0.06 * phaseScale

        case .balance:
            torsoTiltRadians = 0.12 * difficultyScale * phaseScale
            verticalBob = 0.020 * phaseScale
            lateralSway = 0.052 * difficultyScale * phaseScale
            armSwingRadians = 0.20 * difficultyScale * phaseScale
            elbowFlexRadians = 1.15
            elbowFlexVarianceRadians = 0.16 * phaseScale
            kneeDriftRadians = 0.15 * difficultyScale * phaseScale
            kneeFlexRadians = 0.48
            kneeFlexVarianceRadians = 0.18 * phaseScale

        case .core, .fullBody, .inversion:
            torsoTiltRadians = 0.20 * difficultyScale * phaseScale
            verticalBob = 0.026 * difficultyScale * phaseScale
            lateralSway = 0.026 * phaseScale
            armSwingRadians = 0.26 * difficultyScale * phaseScale
            elbowFlexRadians = 1.20
            elbowFlexVarianceRadians = 0.22 * phaseScale
            kneeDriftRadians = 0.08 * phaseScale
            kneeFlexRadians = 0.35
            kneeFlexVarianceRadians = 0.14 * phaseScale

        case .breathing, .relaxation:
            torsoTiltRadians = 0.05 * phaseScale
            verticalBob = 0.014 * phaseScale
            lateralSway = 0.010 * phaseScale
            armSwingRadians = 0.05 * phaseScale
            elbowFlexRadians = 1.05
            elbowFlexVarianceRadians = 0.08 * phaseScale
            kneeDriftRadians = 0.02 * phaseScale
            kneeFlexRadians = 0.20
            kneeFlexVarianceRadians = 0.04 * phaseScale
        }
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
