import SwiftUI

/// Phase styling for the symbolic motion coach.
public enum MotionCoachPhase: Sendable {
    case preview
    case active
    case transition
}

/// Named geometric proportions for stick figure rendering.
/// All values are fractions of the available `size` (min(width, height)).
private enum Proportion {
    static let pelvisYOffset: CGFloat = 0.10
    static let torsoLength: CGFloat = 0.30
    static let headRadius: CGFloat = 0.072
    static let shoulderHalfWidth: CGFloat = 0.14
    static let hipHalfWidth: CGFloat = 0.10
    static let upperArm: CGFloat = 0.18
    static let lowerArm: CGFloat = 0.16
    static let upperLeg: CGFloat = 0.19
    static let lowerLeg: CGFloat = 0.19
    static let jointRadius: CGFloat = 0.016
    static let arrowArcRadius: CGFloat = 0.035
    static let mainFigure: CGFloat = 0.62
    static let ghostFigure: CGFloat = 0.58
    static let breathingRingBase: CGFloat = 0.34
    static let groundReflectionWidth: CGFloat = 0.50
    static let groundReflectionHeight: CGFloat = 0.25
    static let groundReflectionY: CGFloat = 0.22
    static let particleOrbitBase: CGFloat = 0.18
    static let groundShadowOffset: CGFloat = 0.025
    static let groundShadowHeight: CGFloat = 0.035
    static let torsoGradientEnd: CGFloat = 0.18
    static let limbArcRadius: CGFloat = 0.30
    static let radialGlowEnd: CGFloat = 0.50
    static let groundShadowWidthPadding: CGFloat = 0.10
    /// Arrowhead barb angle ≈ 149°, giving a ~31° opening from the tip direction.
    static let arrowheadBarbAngle: Double = 2.6
}

/// Free helper for skeleton geometry — shared by SkeletonState.
private func skelPoint(from origin: CGPoint, length: CGFloat, angle: Double) -> CGPoint {
    CGPoint(x: origin.x + cos(angle) * length, y: origin.y + sin(angle) * length)
}

/// Pre-computed skeleton joint positions and kinematic state.
/// Extracted from the view body to decouple geometry from rendering
/// and enable unit testing of kinematics without SwiftUI.
private struct SkeletonState {
    let pelvis: CGPoint
    let neck: CGPoint
    let spineMid: CGPoint
    let headCenter: CGPoint
    let headRadius: CGFloat
    let leftShoulder: CGPoint
    let rightShoulder: CGPoint
    let leftHip: CGPoint
    let rightHip: CGPoint
    let leftElbow: CGPoint
    let rightElbow: CGPoint
    let leftHand: CGPoint
    let rightHand: CGPoint
    let leftKnee: CGPoint
    let rightKnee: CGPoint
    let leftFoot: CGPoint
    let rightFoot: CGPoint

    let cycle: Double
    let torsoTilt: Double
    let armSwing: Double
    let kneeDrift: Double

    let secWave: Double
    let secWaveRight: Double
    let tertWave: Double
    let tertWaveRight: Double

    let armDepthPhase: Double
    let leftIsFront: Bool
    let backDepth: Double
    let frontDepth: Double

    let backShoulder: CGPoint
    let backElbow: CGPoint
    let backHand: CGPoint
    let frontShoulder: CGPoint
    let frontElbow: CGPoint
    let frontHand: CGPoint

    init(profile: StickFigureMotionProfile, smooth: Double, t: Double, size: CGFloat, center: CGPoint) {
        let c = smooth * .pi * 2.0
        cycle = c

        torsoTilt = profile.torsoTiltRadians * sin(c)
        armSwing = profile.armSwingRadians * sin(c)
        kneeDrift = profile.kneeDriftRadians * sin(c)

        secWave = sin(c - 0.9)
        secWaveRight = sin(c - 1.1)
        tertWave = sin(c - 1.8)
        tertWaveRight = sin(c - 2.0)

        let depthCycle = t * 0.08
        armDepthPhase = sin(depthCycle) * 0.5 + 0.5

        // cos(cycle) convention: smooth=0 is start of inhale, cos(0)=1 → figure bobs UP.
        // Thoracic expansion on inhale lifts the torso; cos(π)=−1 → bobs DOWN on exhale.
        let torsoBob: CGFloat = CGFloat(profile.verticalBob * cos(c)) * size
        let sway: CGFloat = CGFloat(profile.lateralSway * sin(c)) * size

        pelvis = CGPoint(x: center.x + sway, y: center.y + size * Proportion.pelvisYOffset + torsoBob)

        let core = Self.computeCore(pelvis: pelvis, size: size, torsoTilt: torsoTilt,
                                     secWave: secWave, tertWave: tertWave, cycle: c)
        spineMid = core.spineMid
        neck = core.neck
        headRadius = core.headRadius
        headCenter = core.headCenter

        let girdle = Self.computeGirdle(neck: neck, pelvis: pelvis, size: size,
                                         torsoTilt: torsoTilt, cycle: c)
        leftShoulder = girdle.leftShoulder
        rightShoulder = girdle.rightShoulder
        leftHip = girdle.leftHip
        rightHip = girdle.rightHip

        let arms = Self.computeArms(
            leftShoulder: girdle.leftShoulder, rightShoulder: girdle.rightShoulder,
            size: size, torsoTilt: torsoTilt, armSwing: armSwing,
            secWave: secWave, secWaveRight: secWaveRight,
            tertWave: tertWave, tertWaveRight: tertWaveRight,
            cycle: c, profile: profile
        )
        leftElbow = arms.leftElbow
        rightElbow = arms.rightElbow
        leftHand = arms.leftHand
        rightHand = arms.rightHand

        let legs = Self.computeLegs(
            leftHip: girdle.leftHip, rightHip: girdle.rightHip,
            size: size, torsoTilt: torsoTilt, kneeDrift: kneeDrift,
            secWave: secWave, secWaveRight: secWaveRight,
            tertWave: tertWave, tertWaveRight: tertWaveRight,
            cycle: c, profile: profile
        )
        leftKnee = legs.leftKnee
        rightKnee = legs.rightKnee
        leftFoot = legs.leftFoot
        rightFoot = legs.rightFoot

        leftIsFront = armDepthPhase > 0.5
        backShoulder = leftIsFront ? rightShoulder : leftShoulder
        backElbow = leftIsFront ? rightElbow : leftElbow
        backHand = leftIsFront ? rightHand : leftHand
        frontShoulder = leftIsFront ? leftShoulder : rightShoulder
        frontElbow = leftIsFront ? leftElbow : rightElbow
        frontHand = leftIsFront ? leftHand : rightHand
        backDepth = leftIsFront ? (1.0 - armDepthPhase) : armDepthPhase
        frontDepth = leftIsFront ? armDepthPhase : (1.0 - armDepthPhase)
    }

    private struct CoreData {
        let spineMid: CGPoint; let neck: CGPoint; let headCenter: CGPoint; let headRadius: CGFloat
    }

    private static func computeCore(
        pelvis: CGPoint, size: CGFloat, torsoTilt: Double,
        secWave: Double, tertWave: Double, cycle: Double
    ) -> CoreData {
        let torsoLen = size * Proportion.torsoLength
        let halfAngle = -.pi / 2.0 + torsoTilt
        let spineMid = skelPoint(from: pelvis, length: torsoLen * 0.5,
                                  angle: halfAngle + secWave * 0.6)
        let neck = skelPoint(from: pelvis, length: torsoLen, angle: halfAngle)
        let headRadius = size * Proportion.headRadius
        let headCenter = skelPoint(from: neck, length: headRadius * 1.6,
                                    angle: halfAngle + tertWave * 0.45)
        return CoreData(spineMid: spineMid, neck: neck, headCenter: headCenter, headRadius: headRadius)
    }

    private struct GirdleData {
        let leftShoulder: CGPoint; let rightShoulder: CGPoint
        let leftHip: CGPoint; let rightHip: CGPoint
    }

    private static func computeGirdle(
        neck: CGPoint, pelvis: CGPoint, size: CGFloat,
        torsoTilt: Double, cycle: Double
    ) -> GirdleData {
        let breathExp = CGFloat(1.0 + 0.06 * (0.5 + 0.5 * sin(cycle)))
        let shoulderHW = size * Proportion.shoulderHalfWidth * breathExp
        let hipHW = size * Proportion.hipHalfWidth
        let axis = torsoTilt
        return GirdleData(
            leftShoulder: skelPoint(from: neck, length: shoulderHW, angle: axis + .pi),
            rightShoulder: skelPoint(from: neck, length: shoulderHW, angle: axis),
            leftHip: skelPoint(from: pelvis, length: hipHW, angle: axis + .pi),
            rightHip: skelPoint(from: pelvis, length: hipHW, angle: axis)
        )
    }

    private struct ArmData {
        let leftElbow: CGPoint; let rightElbow: CGPoint
        let leftHand: CGPoint; let rightHand: CGPoint
    }

    private static func computeArms(
        leftShoulder: CGPoint, rightShoulder: CGPoint,
        size: CGFloat, torsoTilt: Double, armSwing: Double,
        secWave: Double, secWaveRight: Double,
        tertWave: Double, tertWaveRight: Double,
        cycle: Double, profile: StickFigureMotionProfile
    ) -> ArmData {
        let elbowFlex = profile.elbowFlexRadians
            + profile.elbowFlexVarianceRadians * (0.5 + 0.5 * cos(cycle))
        let upperArmLen = size * Proportion.upperArm
        let lowerArmLen = size * Proportion.lowerArm

        let leftAngle = -.pi / 2.0 + torsoTilt + armSwing + secWave * 0.12
        let rightAngle = -.pi / 2.0 + torsoTilt - armSwing - secWaveRight * 0.12

        let leftElbow = skelPoint(from: leftShoulder, length: upperArmLen, angle: leftAngle)
        let rightElbow = skelPoint(from: rightShoulder, length: upperArmLen, angle: rightAngle)

        let leftHandAngle = leftAngle + (.pi - elbowFlex) + tertWave * 0.10
        let rightHandAngle = rightAngle - (.pi - elbowFlex) - tertWaveRight * 0.10
        let leftHand = skelPoint(from: leftElbow, length: lowerArmLen, angle: leftHandAngle)
        let rightHand = skelPoint(from: rightElbow, length: lowerArmLen, angle: rightHandAngle)

        return ArmData(leftElbow: leftElbow, rightElbow: rightElbow,
                       leftHand: leftHand, rightHand: rightHand)
    }

    private struct LegData {
        let leftKnee: CGPoint; let rightKnee: CGPoint
        let leftFoot: CGPoint; let rightFoot: CGPoint
    }

    private static func computeLegs(
        leftHip: CGPoint, rightHip: CGPoint,
        size: CGFloat, torsoTilt: Double, kneeDrift: Double,
        secWave: Double, secWaveRight: Double,
        tertWave: Double, tertWaveRight: Double,
        cycle: Double, profile: StickFigureMotionProfile
    ) -> LegData {
        let upperLegLen = size * Proportion.upperLeg
        let lowerLegLen = size * Proportion.lowerLeg
        let kneeFlex = profile.kneeFlexRadians
            + profile.kneeFlexVarianceRadians * (0.5 + 0.5 * sin(cycle + .pi / 2.0))
        let downAngle = Double.pi / 2.0 + torsoTilt

        let leftKnee = skelPoint(from: leftHip, length: upperLegLen,
                                  angle: downAngle - kneeDrift + secWave * 0.04)
        let rightKnee = skelPoint(from: rightHip, length: upperLegLen,
                                   angle: downAngle + kneeDrift - secWaveRight * 0.04)
        let leftFoot = skelPoint(from: leftKnee, length: lowerLegLen,
                                  angle: downAngle - kneeFlex * 0.35 + tertWave * 0.03)
        let rightFoot = skelPoint(from: rightKnee, length: lowerLegLen,
                                   angle: downAngle + kneeFlex * 0.35 - tertWaveRight * 0.03)

        return LegData(leftKnee: leftKnee, rightKnee: rightKnee,
                       leftFoot: leftFoot, rightFoot: rightFoot)
    }
}

/// Procedural, video-free pose guidance view.
/// Kinematics: per-category limb arcs driven by quintic ease, depth-aware limb painting,
/// breathing ring, ground reflection, and ambient particles.
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
            let sinBreath = reduceMotion ? 0.0 : sin(breathAngle)
            let wave  = sinBreath
            let pulse = reduceMotion ? 0.0 : (sinBreath + 1.0) * 0.5
            let hueShift = reduceMotion ? 0.0 : sinBreath * 0.02

            // Quintic ease (5th-order Hermite) for silkier transitions than cubic smoothstep
            let rawPhase = fmod(t / profile.breathPeriod, 1.0)
            let normPhase = rawPhase < 0 ? rawPhase + 1.0 : rawPhase
            let s = normPhase
            let smooth = s * s * s * (s * (s * 6.0 - 15.0) + 10.0) // quintic ease-in-out

            ZStack(alignment: .bottom) {
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
                    .overlay(
                        RadialGradient(
                            colors: [.clear, .black.opacity(0.35)],
                            center: .center,
                            startRadius: cornerRadius,
                            endRadius: 300
                        )
                        .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
                    )

                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .strokeBorder(
                        LinearGradient(
                            colors: [
                                Color.white.opacity(0.15 + pulse * 0.06),
                                Color(hue: profile.accentHue, saturation: 0.60, brightness: 0.92).opacity(0.25 + pulse * 0.10)
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
                        Circle()
                            .fill(
                                RadialGradient(
                                    colors: [
                                        Color(hue: profile.accentHue, saturation: 0.3, brightness: 0.95).opacity(0.08 + pulse * 0.05),
                                        .clear
                                    ],
                                    center: .center,
                                    startRadius: 8,
                                    endRadius: size * Proportion.radialGlowEnd
                                )
                            )
                            .frame(width: size, height: size)
                            .position(x: cx, y: cy)

                        if !reduceMotion {
                            ambientParticles(
                                t: t, accentHue: profile.accentHue,
                                size: size, cx: cx, cy: cy
                            )
                        }

                        if !reduceMotion {
                            ghostTrail(
                                pose: pose, phase: phase, profile: profile,
                                t: t, normPhase: normPhase, size: size,
                                cx: cx, cy: cy
                            )
                        }

                        let (offX, offY, rot) = profile.limbOffset(smooth: smooth, wave: wave)
                        StickFigureKinematicsView(
                            pose: pose,
                            phase: phase,
                            smooth: smooth,
                            time: t
                        )
                            .frame(width: size * Proportion.mainFigure, height: size * Proportion.mainFigure)
                            .shadow(color: Color(hue: profile.accentHue, saturation: 0.72, brightness: 0.98).opacity(0.35), radius: 3)
                            .shadow(color: Color(hue: profile.accentHue, saturation: 0.72, brightness: 0.98).opacity(0.20), radius: 12)
                            .shadow(color: Color(hue: profile.accentHue, saturation: 0.72, brightness: 0.98).opacity(0.08), radius: 28)
                            .scaleEffect(1.0 + pulse * profile.scaleAmplitude)
                            .rotationEffect(.degrees(rot))
                            .offset(x: offX, y: offY)
                            .position(x: cx, y: cy)

                        if !reduceMotion {
                            groundReflection(
                                pose: pose, phase: phase, profile: profile,
                                smooth: smooth, wave: wave,
                                size: size, cx: cx, cy: cy
                            )
                        }

                        if !reduceMotion {
                            LimbArcView(
                                profile: profile,
                                smooth: smooth,
                                accentHue: profile.accentHue,
                                size: size
                            )
                            .position(x: cx, y: cy)
                        }

                        if !reduceMotion {
                            breathingRing(
                                smooth: smooth, pulse: pulse,
                                accentHue: profile.accentHue,
                                size: size, cx: cx, cy: cy
                            )
                        }
                    }
                    .drawingGroup()
                    .frame(width: geo.size.width, height: geo.size.height)
                }

                if phase == .active {
                    HStack(spacing: 7) {
                        Circle()
                            .fill(
                                RadialGradient(
                                    colors: [
                                        Color(hue: profile.accentHue, saturation: 0.80, brightness: 0.98),
                                        Color(hue: profile.accentHue, saturation: 0.60, brightness: 0.80).opacity(0.6)
                                    ],
                                    center: .center,
                                    startRadius: 0,
                                    endRadius: 5
                                )
                            )
                            .frame(width: 7 + CGFloat(pulse) * 3, height: 7 + CGFloat(pulse) * 3)
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
            fr: "Guidage visuel anim\u{00e9} pour \(pose.name.localized)"
        ).localized))
    }

    // MARK: - Ghost trail helper

    @ViewBuilder
    private func ghostTrail(
        pose: Pose, phase: MotionCoachPhase, profile: MotionCoachProfile,
        t: Double, normPhase: Double, size: CGFloat,
        cx: CGFloat, cy: CGFloat
    ) -> some View {
        ForEach(0..<6, id: \.self) { i in
            let lag = Double(i + 1) * 0.06
            let ghostPhase = fmod(normPhase - lag, 1.0)
            let gp = ghostPhase < 0 ? ghostPhase + 1.0 : ghostPhase
            let s = gp
            let gs = s * s * s * (s * (s * 6.0 - 15.0) + 10.0) // quintic ease
            let ghostTimeOffset = t - lag * profile.breathPeriod
            let ghostWave = sin(ghostTimeOffset * .pi * 2.0 / profile.breathPeriod)
            let (gOffX, gOffY, gRot) = profile.limbOffset(smooth: gs, wave: ghostWave)
            let fade = 0.10 - Double(i) * 0.014
            StickFigureKinematicsView(pose: pose, phase: phase, smooth: gs, time: ghostTimeOffset, detail: .simplified)
                .frame(width: size * Proportion.ghostFigure, height: size * Proportion.ghostFigure)
                .opacity(max(fade, 0))
                .rotationEffect(.degrees(gRot))
                .offset(x: gOffX, y: gOffY)
                .position(x: cx, y: cy)
                .blur(radius: CGFloat(i) * 1.2)
        }
    }

    // MARK: - Breathing ring

    @ViewBuilder
    private func breathingRing(
        smooth: Double, pulse: Double,
        accentHue: Double, size: CGFloat,
        cx: CGFloat, cy: CGFloat
    ) -> some View {
        let ringRadius = size * (Proportion.breathingRingBase + pulse * 0.04)
        let ringAlpha = 0.08 + pulse * 0.06
        Circle()
            .stroke(
                AngularGradient(
                    colors: [
                        Color(hue: accentHue, saturation: 0.65, brightness: 0.95).opacity(ringAlpha),
                        Color(hue: accentHue + 0.05, saturation: 0.50, brightness: 0.90).opacity(ringAlpha * 0.4),
                        Color(hue: accentHue, saturation: 0.65, brightness: 0.95).opacity(ringAlpha)
                    ],
                    center: .center,
                    startAngle: .degrees(0),
                    endAngle: .degrees(360)
                ),
                style: StrokeStyle(lineWidth: 1.2, lineCap: .round)
            )
            .frame(width: ringRadius * 2.0, height: ringRadius * 2.0)
            .position(x: cx, y: cy)

        Circle()
            .trim(from: 0, to: max(0, min(smooth, 1)))
            .stroke(
                Color(hue: accentHue, saturation: 0.75, brightness: 0.98).opacity(0.18),
                style: StrokeStyle(lineWidth: 2.0, lineCap: .round)
            )
            .frame(width: ringRadius * 2.0 - 6, height: ringRadius * 2.0 - 6)
            .position(x: cx, y: cy)
    }

    // MARK: - Ground reflection

    @ViewBuilder
    private func groundReflection(
        pose: Pose, phase: MotionCoachPhase, profile: MotionCoachProfile,
        smooth: Double, wave: Double,
        size: CGFloat, cx: CGFloat, cy: CGFloat
    ) -> some View {
        let (offX, offY, rot) = profile.limbOffset(smooth: smooth, wave: wave)
        StickFigureKinematicsView(pose: pose, phase: phase, smooth: smooth, time: 0, detail: .simplified)
            .frame(width: size * Proportion.groundReflectionWidth, height: size * Proportion.groundReflectionHeight)
            .opacity(0.04)
            .scaleEffect(y: -0.4)
            .rotationEffect(.degrees(-rot))
            .blur(radius: 6)
            .position(x: cx + offX, y: cy + size * Proportion.groundReflectionY - offY * 0.3)
    }

    // MARK: - Ambient particles

    @ViewBuilder
    private func ambientParticles(
        t: Double, accentHue: Double,
        size: CGFloat, cx: CGFloat, cy: CGFloat
    ) -> some View {
        ForEach(0..<8, id: \.self) { i in
            let seed = Double(i) * 137.508 // golden angle offset (≈ 137.508° vs true 137.50776°)
            let orbitRadius = size * (Proportion.particleOrbitBase + 0.12 * sin(seed))
            let speed = 0.08 + Double(i) * 0.015
            let angle = t * speed + seed
            let px = cx + cos(angle) * orbitRadius
            let py = cy + sin(angle) * orbitRadius * 0.6
            let dotSize = 1.5 + sin(seed * 3.0) * 1.0
            let alpha = 0.12 + 0.08 * sin(t * 0.5 + seed)

            Circle()
                .fill(
                    RadialGradient(
                        colors: [
                            Color(hue: accentHue, saturation: 0.5, brightness: 1.0).opacity(alpha),
                            .clear
                        ],
                        center: .center,
                        startRadius: 0,
                        endRadius: dotSize * 2
                    )
                )
                .frame(width: dotSize * 4, height: dotSize * 4)
                .position(x: px, y: py)
        }
    }
}

// MARK: - Stick figure kinematics (organic 3D-like)

private enum RenderDetail {
    case full, simplified
}

private struct StickFigureKinematicsView: View {
    let pose: Pose
    let phase: MotionCoachPhase
    let smooth: Double
    let time: Double
    let detail: RenderDetail

    init(pose: Pose, phase: MotionCoachPhase, smooth: Double, time: Double, detail: RenderDetail = .full) {
        self.pose = pose
        self.phase = phase
        self.smooth = smooth
        self.time = time
        self.detail = detail
    }

    var body: some View {
        GeometryReader { geo in
            let size = min(geo.size.width, geo.size.height)
            let center = CGPoint(x: geo.size.width / 2.0, y: geo.size.height / 2.0)
            let profile = StickFigureMotionProfile(
                category: pose.category,
                difficulty: pose.difficulty,
                phase: phase
            )
            let skel = SkeletonState(
                profile: profile, smooth: smooth, t: time,
                size: size, center: center
            )
            let baseHue = pose.category.accentHue
            let isFull = detail == .full

            ZStack {
                if isFull {
                    groundShadow(
                        leftFoot: skel.leftFoot, rightFoot: skel.rightFoot,
                        pelvis: skel.pelvis, size: size
                    )
                }

                let backOpacity  = 0.38 + skel.backDepth * 0.30
                let backW: CGFloat = 2.0 + CGFloat(skel.backDepth) * 1.4
                let backGlow: Color? = isFull ? Color(hue: baseHue, saturation: 0.80, brightness: 1.0).opacity(backOpacity * 0.3) : nil
                taperedLimb(
                    from: skel.backShoulder, to: skel.backElbow,
                    startW: backW * 1.15, endW: backW * 0.75,
                    color: Color(hue: baseHue, saturation: 0.72, brightness: 0.95).opacity(backOpacity),
                    glowColor: backGlow,
                    curvature: skel.secWave * 0.08
                )
                taperedLimb(
                    from: skel.backElbow, to: skel.backHand,
                    startW: backW * 0.75, endW: backW * 0.40,
                    color: Color(hue: baseHue, saturation: 0.72, brightness: 0.95).opacity(backOpacity),
                    glowColor: backGlow,
                    curvature: skel.tertWave * 0.06
                )

                let coreColor = Color.white.opacity(0.92)
                let legGlow: Color? = isFull ? Color(hue: baseHue, saturation: 0.30, brightness: 1.0).opacity(0.15) : nil
                taperedLimb(from: skel.leftHip,  to: skel.leftKnee,
                            startW: 3.2, endW: 2.6,
                            color: coreColor.opacity(0.88), glowColor: legGlow,
                            curvature: skel.secWave * 0.04)
                taperedLimb(from: skel.leftKnee, to: skel.leftFoot,
                            startW: 2.6, endW: 2.0,
                            color: coreColor.opacity(0.85), glowColor: legGlow,
                            curvature: skel.tertWave * 0.03)
                taperedLimb(from: skel.rightHip,  to: skel.rightKnee,
                            startW: 3.2, endW: 2.6,
                            color: coreColor.opacity(0.88), glowColor: legGlow,
                            curvature: -skel.secWaveRight * 0.04)
                taperedLimb(from: skel.rightKnee, to: skel.rightFoot,
                            startW: 2.6, endW: 2.0,
                            color: coreColor.opacity(0.85), glowColor: legGlow,
                            curvature: -skel.tertWaveRight * 0.03)

                if isFull {
                    torsoVolume(
                        neck: skel.neck, pelvis: skel.pelvis, spineMid: skel.spineMid,
                        leftShoulder: skel.leftShoulder, rightShoulder: skel.rightShoulder,
                        leftHip: skel.leftHip, rightHip: skel.rightHip,
                        size: size, hue: baseHue
                    )
                }

                let frontOpacity = 0.55 + skel.frontDepth * 0.40
                let frontW: CGFloat = 2.4 + CGFloat(skel.frontDepth) * 1.6
                let limbAccent = Color(hue: baseHue, saturation: 0.82, brightness: 0.99)
                let limbGlow: Color? = isFull ? Color(hue: baseHue, saturation: 0.90, brightness: 1.0).opacity(frontOpacity * 0.25) : nil
                taperedLimb(
                    from: skel.frontShoulder, to: skel.frontElbow,
                    startW: frontW * 1.20, endW: frontW * 0.78,
                    color: limbAccent.opacity(frontOpacity),
                    glowColor: limbGlow,
                    curvature: -skel.secWaveRight * 0.08
                )
                taperedLimb(
                    from: skel.frontElbow, to: skel.frontHand,
                    startW: frontW * 0.78, endW: frontW * 0.38,
                    color: limbAccent.opacity(frontOpacity),
                    glowColor: limbGlow,
                    curvature: -skel.tertWaveRight * 0.06
                )

                if isFull {
                    headSphere(at: skel.headCenter, radius: skel.headRadius, hue: baseHue, tilt: skel.torsoTilt)
                }

                if isFull {
                    let jr = size * Proportion.jointRadius
                    jointSphere(at: skel.neck,           radius: jr * 1.1, lightAngle: -.pi / 4.0 + skel.torsoTilt,
                                baseColor: .white)
                    jointSphere(at: skel.pelvis,         radius: jr * 1.3, lightAngle: -.pi / 4.0,
                                baseColor: .white)
                    jointSphere(at: skel.leftShoulder,   radius: jr * (0.9 + CGFloat(skel.backDepth) * 0.3),
                                lightAngle: -.pi / 3.0, baseColor: limbAccent)
                    jointSphere(at: skel.rightShoulder,  radius: jr * (0.9 + CGFloat(skel.frontDepth) * 0.3),
                                lightAngle: -.pi / 3.0, baseColor: limbAccent)
                    jointSphere(at: skel.backElbow,      radius: jr * 0.85,
                                lightAngle: -.pi / 5.0, baseColor: limbAccent.opacity(backOpacity))
                    jointSphere(at: skel.frontElbow,     radius: jr * 0.95,
                                lightAngle: -.pi / 5.0, baseColor: limbAccent.opacity(frontOpacity))
                    jointSphere(at: skel.backHand,       radius: jr * 0.65,
                                lightAngle: -.pi / 6.0, baseColor: limbAccent.opacity(backOpacity * 0.9))
                    jointSphere(at: skel.frontHand,      radius: jr * 0.75,
                                lightAngle: -.pi / 6.0, baseColor: limbAccent.opacity(frontOpacity * 0.9))
                    jointSphere(at: skel.leftKnee,       radius: jr * 1.05, lightAngle: -.pi / 4.0,
                                baseColor: .white)
                    jointSphere(at: skel.rightKnee,      radius: jr * 1.05, lightAngle: -.pi / 4.0,
                                baseColor: .white)
                    jointSphere(at: skel.leftFoot,       radius: jr * 0.70, lightAngle: -.pi / 4.0,
                                baseColor: .white.opacity(0.85))
                    jointSphere(at: skel.rightFoot,      radius: jr * 0.70, lightAngle: -.pi / 4.0,
                                baseColor: .white.opacity(0.85))
                }

                if isFull, phase == .active {
                    motionArrows(skel: skel, profile: profile, size: size, hue: baseHue)
                }
            }
            .frame(width: geo.size.width, height: geo.size.height)
        }
    }

    // MARK: - Motion arrows (refactored: SkeletonState replaces 18 params)

    /// Draws explicit directional motion arrows at active joints.
    /// Each arrow shows: (1) an arc indicating the range of motion,
    /// (2) a bold arrowhead at the current position showing live direction.
    @ViewBuilder
    private func motionArrows(
        skel: SkeletonState,
        profile: StickFigureMotionProfile,
        size: CGFloat, hue: Double
    ) -> some View {
        let arrowColor = Color(hue: hue, saturation: 0.85, brightness: 1.0)
        let arrowAlpha = 0.55
        let r = size * Proportion.arrowArcRadius

        ZStack {
            let lsArcStart = -.pi / 2.0 + skel.torsoTilt - profile.armSwingRadians
            let lsArcEnd   = -.pi / 2.0 + skel.torsoTilt + profile.armSwingRadians
            arcArrow(
                center: skel.leftShoulder, radius: r * 1.4,
                startAngle: lsArcStart, endAngle: lsArcEnd,
                currentAngle: -.pi / 2.0 + skel.torsoTilt + skel.armSwing,
                color: arrowColor.opacity(arrowAlpha)
            )
            let rsArcStart = -.pi / 2.0 + skel.torsoTilt + profile.armSwingRadians
            let rsArcEnd   = -.pi / 2.0 + skel.torsoTilt - profile.armSwingRadians
            arcArrow(
                center: skel.rightShoulder, radius: r * 1.4,
                startAngle: rsArcStart, endAngle: rsArcEnd,
                currentAngle: -.pi / 2.0 + skel.torsoTilt - skel.armSwing,
                color: arrowColor.opacity(arrowAlpha)
            )

            let elbowArcR = r * 1.1
            arcArrow(
                center: skel.leftElbow, radius: elbowArcR,
                startAngle: 0, endAngle: profile.elbowFlexVarianceRadians,
                currentAngle: profile.elbowFlexVarianceRadians * (0.5 + 0.5 * cos(skel.cycle)),
                color: arrowColor.opacity(arrowAlpha * 0.7)
            )
            arcArrow(
                center: skel.rightElbow, radius: elbowArcR,
                startAngle: -.pi, endAngle: -.pi + profile.elbowFlexVarianceRadians,
                currentAngle: -.pi + profile.elbowFlexVarianceRadians * (0.5 + 0.5 * cos(skel.cycle)),
                color: arrowColor.opacity(arrowAlpha * 0.7)
            )

            arcArrow(
                center: skel.pelvis, radius: r * 1.8,
                startAngle: -.pi / 2.0 - profile.torsoTiltRadians,
                endAngle:   -.pi / 2.0 + profile.torsoTiltRadians,
                currentAngle: -.pi / 2.0 + skel.torsoTilt,
                color: arrowColor.opacity(arrowAlpha * 0.8)
            )

            arcArrow(
                center: skel.headCenter, radius: r * 1.0,
                startAngle: -.pi / 2.0 - profile.torsoTiltRadians * 0.5,
                endAngle:   -.pi / 2.0 + profile.torsoTiltRadians * 0.5,
                currentAngle: -.pi / 2.0 + skel.torsoTilt,
                color: arrowColor.opacity(arrowAlpha * 0.6)
            )

            if profile.kneeDriftRadians > 0.04 {
                arcArrow(
                    center: skel.leftKnee, radius: r * 1.0,
                    startAngle: .pi / 2.0 - profile.kneeDriftRadians,
                    endAngle:   .pi / 2.0 + profile.kneeDriftRadians,
                    currentAngle: .pi / 2.0 - skel.kneeDrift,
                    color: arrowColor.opacity(arrowAlpha * 0.6)
                )
                arcArrow(
                    center: skel.rightKnee, radius: r * 1.0,
                    startAngle: .pi / 2.0 - profile.kneeDriftRadians,
                    endAngle:   .pi / 2.0 + profile.kneeDriftRadians,
                    currentAngle: .pi / 2.0 + skel.kneeDrift,
                    color: arrowColor.opacity(arrowAlpha * 0.6)
                )
            }
        }
    }

    /// Draws an arc range indicator with a directional arrowhead at the current position.
    /// - Arc shows the full range of motion (faint)
    /// - Arrowhead at `currentAngle` shows live direction (bold)
    @ViewBuilder
    private func arcArrow(
        center: CGPoint, radius: CGFloat,
        startAngle: Double, endAngle: Double,
        currentAngle: Double,
        color: Color
    ) -> some View {
        let a1 = startAngle
        let a2 = endAngle
        let arcSpan = abs(a2 - a1)
        if arcSpan < 0.02 {
            EmptyView()
        } else {
            let tipLen = radius * 0.45
            let tipX = center.x + cos(currentAngle) * (radius + tipLen * 0.3)
            let tipY = center.y + sin(currentAngle) * (radius + tipLen * 0.3)
            let tangentAngle = currentAngle + .pi / 2.0
            let headAngle1 = tangentAngle + Proportion.arrowheadBarbAngle
            let headAngle2 = tangentAngle - Proportion.arrowheadBarbAngle
            let dotPos = CGPoint(
                x: center.x + cos(currentAngle) * radius,
                y: center.y + sin(currentAngle) * radius
            )

            ZStack {
                Path { p in
                    p.addArc(
                        center: center,
                        radius: radius,
                        startAngle: Angle(radians: min(a1, a2)),
                        endAngle: Angle(radians: max(a1, a2)),
                        clockwise: false
                    )
                }
                .stroke(
                    color.opacity(0.4),
                    style: StrokeStyle(lineWidth: 1.5, lineCap: .round)
                )

                Path { p in
                    p.move(to: CGPoint(x: tipX, y: tipY))
                    p.addLine(to: CGPoint(
                        x: tipX + cos(headAngle1) * tipLen,
                        y: tipY + sin(headAngle1) * tipLen
                    ))
                    p.move(to: CGPoint(x: tipX, y: tipY))
                    p.addLine(to: CGPoint(
                        x: tipX + cos(headAngle2) * tipLen,
                        y: tipY + sin(headAngle2) * tipLen
                    ))
                }
                .stroke(color, style: StrokeStyle(lineWidth: 2.0, lineCap: .round))

                Circle()
                    .fill(color)
                    .frame(width: 4, height: 4)
                    .position(dotPos)
            }
        }
    }

    /// Tapered limb: filled shape narrowing from startW to endW with optional glow layer.
    @ViewBuilder
    private func taperedLimb(
        from start: CGPoint, to end: CGPoint,
        startW: CGFloat, endW: CGFloat,
        color: Color, glowColor: Color? = nil,
        curvature: Double
    ) -> some View {
        let dx = end.x - start.x
        let dy = end.y - start.y
        let len = sqrt(dx * dx + dy * dy)
        if len < 0.5 {
            EmptyView()
        } else {
            let nx = -dy / len
            let ny = dx / len

            let midX = (start.x + end.x) / 2.0 + nx * curvature * len
            let midY = (start.y + end.y) / 2.0 + ny * curvature * len
            let midW = (startW + endW) / 2.0 * 1.08

            let limbPath = Path { p in
                p.move(to: CGPoint(x: start.x + nx * startW / 2.0, y: start.y + ny * startW / 2.0))
                p.addQuadCurve(
                    to: CGPoint(x: end.x + nx * endW / 2.0, y: end.y + ny * endW / 2.0),
                    control: CGPoint(x: midX + nx * midW / 2.0, y: midY + ny * midW / 2.0)
                )
                p.addArc(
                    center: end,
                    radius: endW / 2.0,
                    startAngle: Angle(radians: atan2(ny, nx)),
                    endAngle: Angle(radians: atan2(-ny, -nx)),
                    clockwise: true
                )
                p.addQuadCurve(
                    to: CGPoint(x: start.x - nx * startW / 2.0, y: start.y - ny * startW / 2.0),
                    control: CGPoint(x: midX - nx * midW / 2.0, y: midY - ny * midW / 2.0)
                )
                p.addArc(
                    center: start,
                    radius: startW / 2.0,
                    startAngle: Angle(radians: atan2(-ny, -nx)),
                    endAngle: Angle(radians: atan2(ny, nx)),
                    clockwise: true
                )
                p.closeSubpath()
            }

            ZStack {
                if let glow = glowColor {
                    limbPath
                        .fill(glow)
                        .blur(radius: 4)
                }
                limbPath.fill(color)
            }
        }
    }

    /// 3D-looking joint sphere with specular highlight.
    private func jointSphere(
        at center: CGPoint, radius: CGFloat,
        lightAngle: Double, baseColor: Color
    ) -> some View {
        let hlx = cos(lightAngle) * radius * 0.30
        let hly = sin(lightAngle) * radius * 0.30
        let gradCenter = UnitPoint(x: 0.5 + hlx / (radius * 2.0),
                                   y: 0.5 + hly / (radius * 2.0))
        let grad = RadialGradient(
            colors: [
                Color.white.opacity(0.95),
                baseColor.opacity(0.90),
                baseColor.opacity(0.55)
            ],
            center: gradCenter,
            startRadius: 0,
            endRadius: radius
        )
        return Circle()
            .fill(grad)
            .frame(width: radius * 2.0, height: radius * 2.0)
            .position(center)
            .shadow(color: baseColor.opacity(0.20), radius: radius * 0.6)
    }

    /// 3D head: gradient sphere with specular highlight, rim light, and face direction dot.
    private func headSphere(at center: CGPoint, radius: CGFloat, hue: Double, tilt: Double) -> some View {
        let skinTint = Color(hue: hue, saturation: 0.18, brightness: 0.98)
        let headGrad = RadialGradient(
            colors: [
                Color.white.opacity(0.97),
                skinTint.opacity(0.92),
                skinTint.opacity(0.70),
                skinTint.opacity(0.45)
            ],
            center: UnitPoint(x: 0.38, y: 0.32),
            startRadius: radius * 0.05,
            endRadius: radius
        )
        let rimGrad = AngularGradient(
            colors: [
                .white.opacity(0.0),
                .white.opacity(0.14),
                .white.opacity(0.0),
                .white.opacity(0.07),
                .white.opacity(0.0)
            ],
            center: .center,
            startAngle: .degrees(200),
            endAngle: .degrees(520)
        )
        let glowColor = Color(hue: hue, saturation: 0.60, brightness: 0.95).opacity(0.25)

        // Face direction dot: -π/2 points up; lateral head tilt shifts the indicator.
        let faceAngle = -.pi / 2.0 + tilt
        let faceDist = radius * 0.50
        let faceDotX = center.x + cos(faceAngle) * faceDist
        let faceDotY = center.y + sin(faceAngle) * faceDist
        let faceDotRadius = radius * 0.14

        return ZStack {
            Circle()
                .fill(glowColor)
                .frame(width: radius * 2.4, height: radius * 2.4)
                .blur(radius: radius * 0.5)
                .position(center)

            Circle()
                .fill(headGrad)
                .frame(width: radius * 2.0, height: radius * 2.0)
                .position(center)
                .shadow(color: glowColor, radius: radius * 0.8)

            Circle()
                .stroke(rimGrad, lineWidth: 1.5)
                .frame(width: radius * 2.05, height: radius * 2.05)
                .position(center)

            Circle()
                .fill(
                    RadialGradient(
                        colors: [.white.opacity(0.8), skinTint.opacity(0.5)],
                        center: UnitPoint(x: 0.4, y: 0.35),
                        startRadius: 0,
                        endRadius: faceDotRadius
                    )
                )
                .frame(width: faceDotRadius * 2, height: faceDotRadius * 2)
                .position(x: faceDotX, y: faceDotY)
        }
    }

    /// Filled torso volume: cubic-Bezier tapered shape with waist pinch.
    @ViewBuilder
    private func torsoVolume(
        neck: CGPoint, pelvis: CGPoint, spineMid: CGPoint,
        leftShoulder: CGPoint, rightShoulder: CGPoint,
        leftHip: CGPoint, rightHip: CGPoint,
        size: CGFloat, hue: Double
    ) -> some View {
        let bodyColor = Color(hue: hue, saturation: 0.10, brightness: 0.95)
        let directMidX = (pelvis.x + neck.x) / 2.0
        let spineOffset = (spineMid.x - directMidX) * size * 0.004

        let waistFactor: CGFloat = 0.78
        let leftWaist = CGPoint(
            x: leftShoulder.x * (1.0 - waistFactor) + leftHip.x * waistFactor + spineOffset * 0.5,
            y: leftShoulder.y * (1.0 - waistFactor) + leftHip.y * waistFactor
        )
        let rightWaist = CGPoint(
            x: rightShoulder.x * (1.0 - waistFactor) + rightHip.x * waistFactor - spineOffset * 0.5,
            y: rightShoulder.y * (1.0 - waistFactor) + rightHip.y * waistFactor
        )

        Path { p in
            p.move(to: leftShoulder)
            p.addCurve(
                to: leftHip,
                control1: CGPoint(x: leftShoulder.x + spineOffset * 0.3, y: (leftShoulder.y + leftWaist.y) / 2.0),
                control2: CGPoint(x: leftWaist.x, y: leftWaist.y)
            )
            p.addLine(to: rightHip)
            p.addCurve(
                to: rightShoulder,
                control1: CGPoint(x: rightWaist.x, y: rightWaist.y),
                control2: CGPoint(x: rightShoulder.x - spineOffset * 0.3, y: (rightShoulder.y + rightWaist.y) / 2.0)
            )
            p.addLine(to: leftShoulder)
            p.closeSubpath()

            p.move(to: neck)
            p.addQuadCurve(to: pelvis, control: spineMid)
        }
        .fill(
            RadialGradient(
                colors: [
                    bodyColor.opacity(0.28),
                    bodyColor.opacity(0.12),
                    bodyColor.opacity(0.04)
                ],
                center: UnitPoint(x: 0.5, y: 0.35),
                startRadius: size * 0.02,
                endRadius: size * Proportion.torsoGradientEnd
            )
        )

        Path { p in
            p.move(to: neck)
            p.addQuadCurve(to: pelvis, control: spineMid)
            p.move(to: leftHip)
            p.addLine(to: rightHip)
        }
        .stroke(
            Color.white.opacity(0.75),
            style: StrokeStyle(lineWidth: 2.0, lineCap: .round, lineJoin: .round)
        )
    }

    /// Elliptical ground shadow.
    private func groundShadow(
        leftFoot: CGPoint, rightFoot: CGPoint,
        pelvis: CGPoint, size: CGFloat
    ) -> some View {
        let shadowY = max(leftFoot.y, rightFoot.y) + size * Proportion.groundShadowOffset
        let shadowX = (leftFoot.x + rightFoot.x) / 2.0
        let shadowW = abs(rightFoot.x - leftFoot.x) + size * Proportion.groundShadowWidthPadding
        let shadowGrad = RadialGradient(
            colors: [
                .black.opacity(0.18),
                .black.opacity(0.06),
                .clear
            ],
            center: .center,
            startRadius: shadowW * 0.15,
            endRadius: shadowW * 0.55
        )
        return Ellipse()
            .fill(shadowGrad)
            .frame(width: shadowW, height: size * Proportion.groundShadowHeight)
            .position(x: shadowX, y: shadowY)
            .blur(radius: 2)
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

// MARK: - Limb arc path

private struct LimbArcView: View {
    let profile: MotionCoachProfile
    let smooth: Double
    let accentHue: Double
    let size: CGFloat

    var body: some View {
        let arcPath = profile.limbArcPath(size: size, progress: smooth)

        ZStack {
            arcPath
                .stroke(
                    Color(hue: accentHue, saturation: 0.65, brightness: 0.95).opacity(0.18),
                    style: StrokeStyle(lineWidth: 1.2, lineCap: .round, dash: [3, 7])
                )
                .shadow(color: Color(hue: accentHue, saturation: 0.7, brightness: 0.95).opacity(0.12), radius: 4)

            arcPath
                .trim(from: 0, to: max(0, min(smooth, 1)))
                .stroke(
                    Color(hue: accentHue, saturation: 0.72, brightness: 0.98).opacity(0.45),
                    style: StrokeStyle(lineWidth: 2.2, lineCap: .round)
                )
                .shadow(color: Color(hue: accentHue, saturation: 0.80, brightness: 1.0).opacity(0.20), radius: 3)
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

    /// Returns (offsetX, offsetY, rotationDegrees) for the central figure.
    func limbOffset(smooth: Double, wave: Double) -> (CGFloat, CGFloat, Double) {
        let d = Double(difficulty.dotCount)

        switch category {
        case .spine, .back:
            let y = wave * (5.0 + d * 2.5)
            let rot = wave * (3.0 + d * 1.5)
            return (0, CGFloat(y), rot)

        case .hips, .legs:
            let x = wave * (6.0 + d * 2.0)
            let rot = wave * (4.0 + d * 1.0)
            return (CGFloat(x), 0, rot)

        case .shoulders, .arms, .chest:
            let rot = smooth * (8.0 + d * 3.0) - (4.0 + d * 1.5)
            let x   = sin(smooth * .pi) * (4.0 + d * 1.5)
            return (CGFloat(x), 0, rot)

        case .neck:
            let rot = wave * (6.0 + d * 2.0)
            return (0, 0, rot)

        case .balance:
            let x = sin(smooth * .pi * 2.0) * (3.0 + d * 1.0)
            let y = cos(smooth * .pi * 2.0) * (2.0 + d * 0.8)
            let rot = wave * (2.0 + d * 0.8)
            return (CGFloat(x), CGFloat(y), rot)

        case .core, .fullBody:
            let x   = wave * (3.0 + d * 1.5)
            let y   = sin(smooth * .pi) * (3.0 + d * 1.0)
            let rot = wave * (3.5 + d * 1.2)
            return (CGFloat(x), CGFloat(y), rot)

        case .breathing, .relaxation:
            let y = wave * (4.0 + d * 1.0)
            return (0, CGFloat(y), 0)

        case .inversion:
            let rot = smooth * (12.0 + d * 4.0) - (6.0 + d * 2.0)
            let y   = wave * (3.0 + d * 1.0) * -1.0
            return (0, CGFloat(y), rot)
        }
    }

    /// Generates the limb arc Path for the category's movement envelope.
    func limbArcPath(size: CGFloat, progress: Double) -> Path {
        let r = size * Proportion.limbArcRadius

        switch category {
        case .spine, .back:
            return Path { p in
                p.move(to:    CGPoint(x: 0, y:  r))
                p.addQuadCurve(to: CGPoint(x: 0, y: -r),
                               control: CGPoint(x: r * 0.5, y: 0))
            }

        case .hips, .legs:
            return Path { p in
                p.move(to:    CGPoint(x: -r, y: 0))
                p.addQuadCurve(to: CGPoint(x: r, y: 0),
                               control: CGPoint(x: 0, y: r * 0.4))
            }

        case .shoulders, .arms, .chest:
            return Path { p in
                p.move(to:    CGPoint(x: -r * 0.7, y:  r * 0.5))
                p.addQuadCurve(to: CGPoint(x: r * 0.7, y: -r * 0.5),
                               control: CGPoint(x: 0, y: -r * 0.6))
            }

        case .neck:
            return Path { p in
                p.move(to:    CGPoint(x: -r * 0.4, y: -r * 0.2))
                p.addQuadCurve(to: CGPoint(x: r * 0.4, y: -r * 0.2),
                               control: CGPoint(x: 0, y: -r * 0.7))
            }

        case .balance:
            return Path { p in
                p.move(to:    CGPoint(x: 0, y:  r * 0.5))
                p.addQuadCurve(to: CGPoint(x: 0, y: -r * 0.5),
                               control: CGPoint(x: r * 0.6, y: 0))
                p.addQuadCurve(to: CGPoint(x: 0, y:  r * 0.5),
                               control: CGPoint(x: -r * 0.6, y: 0))
            }

        default:
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
