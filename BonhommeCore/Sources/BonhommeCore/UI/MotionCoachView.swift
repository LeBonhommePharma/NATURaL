import SwiftUI

/// Phase styling for the symbolic motion coach.
/// This clean-room component provides procedural guidance without trainer video.
public enum MotionCoachPhase: Sendable {
    case preview
    case active
    case transition
}

/// Procedural, video-free pose guidance view built entirely from symbols and animation.
/// Enhanced with smoothstep orbital kinematics, volumetric ambient bloom, layered shadows, ghost trails,
/// and NEW: directional movement arrows, joint articulation indicators, and biomechanical force vectors.
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
        // Lighting mood modulates background saturation and warmth
        let moodSatBoost: Double = {
            switch pose.category.lightingMood {
            case .warm:    return 0.18   // amber-rose warmth, lower sat for softness
            case .cool:    return -0.08  // sharper, more desaturated baseline
            case .neutral: return 0.0
            }
        }()

        TimelineView(.animation(minimumInterval: reduceMotion ? 1.0 : (1.0 / 24.0), paused: false)) { context in
            let timestamp = context.date.timeIntervalSinceReferenceDate
            let breathAngle = timestamp * (.pi * 2.0) / profile.breathPeriod
            let orbitAngle = timestamp * profile.orbitSpeed
            let wave = reduceMotion ? 0.0 : sin(breathAngle)
            let sway = reduceMotion ? 0.0 : cos(breathAngle * 0.72)
            let pulse = reduceMotion ? 0.0 : ((sin(breathAngle) + 1.0) * 0.5)
            let hueShift = reduceMotion ? 0.0 : sin(breathAngle) * 0.02

            ZStack(alignment: .topLeading) {
                // Background with breathing hue shift, modulated by lighting mood
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

                // Glowing border
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .strokeBorder(
                        LinearGradient(
                            colors: [
                                Color.white.opacity(0.20),
                                Color(hue: profile.accentHue, saturation: 0.60, brightness: 0.92).opacity(0.35)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 1
                    )
                    .shadow(color: Color(hue: profile.accentHue, saturation: 0.6, brightness: 0.9).opacity(0.08), radius: 12)

                GeometryReader { geo in
                    let size = min(geo.size.width, geo.size.height)
                    let orbitRadius = size * 0.24
                    let ringSize = size * 0.68
                    let secondaryRingSize = size * 0.88
                    let kinematicProfile = KinematicProfile(category: pose.category)

                    ZStack {
                        // Ambient bloom (volumetric)
                        Circle()
                            .fill(
                                RadialGradient(
                                    colors: [
                                        Color(hue: profile.accentHue, saturation: 0.3, brightness: 0.95).opacity(0.10 + pulse * 0.06),
                                        Color(hue: profile.accentHue, saturation: 0.65, brightness: 0.92).opacity(0.08),
                                        Color.clear
                                    ],
                                    center: .center,
                                    startRadius: 12,
                                    endRadius: size * 0.55
                                )
                            )
                            .frame(width: size * 1.1, height: size * 1.1)
                            .scaleEffect(1.0 + (pulse * 0.08))

                        // Primary accent ring with emission glow
                        Circle()
                            .stroke(
                                Color(hue: profile.accentHue, saturation: 0.72, brightness: 0.96).opacity(0.30),
                                lineWidth: 2
                            )
                            .frame(width: ringSize, height: ringSize)
                            .scaleEffect(0.96 + (pulse * 0.10))
                            .shadow(color: Color(hue: profile.accentHue, saturation: 0.7, brightness: 0.95).opacity(0.25), radius: 8)

                        // Secondary dashed ring
                        Circle()
                            .stroke(
                                Color.white.opacity(0.12),
                                style: StrokeStyle(lineWidth: 1, dash: [5, 10])
                            )
                            .frame(width: secondaryRingSize, height: secondaryRingSize)
                            .rotationEffect(.degrees(reduceMotion ? 0 : timestamp * 8.0))

                        // ═══════════════════════════════════════════════════════════
                        // NEW: KINEMATIC MOTION LAYER — Movement Vectors & Joints
                        // ═══════════════════════════════════════════════════════════
                        if phase == .active {
                            // Movement vector arrows showing primary motion direction
                            ForEach(kinematicProfile.movementVectors.indices, id: \.self) { index in
                                let vector = kinematicProfile.movementVectors[index]
                                MovementArrow(
                                    start: CGPoint(
                                        x: geo.size.width * vector.startX,
                                        y: geo.size.height * vector.startY
                                    ),
                                    end: CGPoint(
                                        x: geo.size.width * vector.endX,
                                        y: geo.size.height * vector.endY
                                    ),
                                    color: Color(hue: pose.category.accentHue, saturation: 0.85, brightness: 0.95),
                                    timestamp: timestamp,
                                    reduceMotion: reduceMotion,
                                    index: index
                                )
                            }
                            
                            // Joint articulation indicators (pulsing circles at key joints)
                            ForEach(kinematicProfile.jointPositions.indices, id: \.self) { index in
                                let joint = kinematicProfile.jointPositions[index]
                                JointIndicator(
                                    position: CGPoint(
                                        x: geo.size.width * joint.x,
                                        y: geo.size.height * joint.y
                                    ),
                                    size: size * 0.05,
                                    color: Color(hue: pose.category.accentHue, saturation: 0.75, brightness: 0.92),
                                    timestamp: timestamp,
                                    reduceMotion: reduceMotion,
                                    index: index
                                )
                            }
                            
                            // Ghost trail showing start position (faded) for reference
                            if !reduceMotion {
                                ForEach(kinematicProfile.ghostPositions.indices, id: \.self) { index in
                                    let ghost = kinematicProfile.ghostPositions[index]
                                    GhostPosition(
                                        position: CGPoint(
                                            x: geo.size.width * ghost.x,
                                            y: geo.size.height * ghost.y
                                        ),
                                        symbol: ghost.symbol,
                                        size: size * 0.10,
                                        color: Color(hue: pose.category.accentHue, saturation: 0.6, brightness: 0.8),
                                        opacity: 0.15
                                    )
                                }
                            }
                        }

                        // Ghost trail orbits (behind, faded)
                        if !reduceMotion {
                            ForEach(0..<3, id: \.self) { index in
                                let ghostAngle = orbitAngle - 0.15 + (Double(index) * ((.pi * 2.0) / 3.0))
                                let gx = cos(ghostAngle) * orbitRadius
                                let gy = sin(ghostAngle) * orbitRadius * 0.75

                                Image(systemName: profile.orbitSymbol)
                                    .font(.system(size: size * 0.08, weight: .semibold))
                                    .foregroundStyle(
                                        Color(hue: profile.accentHue, saturation: 0.74, brightness: 0.98).opacity(0.20)
                                    )
                                    .offset(x: gx, y: gy)
                            }
                        }

                        // Primary orbiting symbols with smoothstep
                        ForEach(0..<3, id: \.self) { index in
                            let baseAngle = orbitAngle + (Double(index) * ((.pi * 2.0) / 3.0))
                            // Smoothstep on the normalized phase for each node
                            let raw = fmod(baseAngle / (.pi * 2.0), 1.0)
                            let t = raw < 0 ? raw + 1.0 : raw
                            let smooth = t * t * (3.0 - 2.0 * t)
                            let smoothAngle = smooth * .pi * 2.0 + (Double(index) * ((.pi * 2.0) / 3.0))
                            let x = cos(smoothAngle) * orbitRadius
                            let y = sin(smoothAngle) * orbitRadius * 0.75

                            Image(systemName: profile.orbitSymbol)
                                .font(.system(size: size * 0.10, weight: .semibold))
                                .foregroundStyle(
                                    Color(hue: profile.accentHue, saturation: 0.74, brightness: 0.98).opacity(0.80)
                                )
                                .padding(12)
                                .background(.white.opacity(0.05), in: Circle())
                                .overlay(
                                    Circle()
                                        .stroke(Color.white.opacity(0.07), lineWidth: 1)
                                )
                                .shadow(color: Color(hue: profile.accentHue, saturation: 0.6, brightness: 0.9).opacity(0.15), radius: 6)
                                .offset(x: x, y: y)
                        }

                        Text(pose.category.kineticFocusTag.localized)
                            .font(.system(size: size > 240 ? 10 : 9, weight: .semibold, design: .rounded))
                            .foregroundStyle(.white.opacity(0.70))

                        VStack(spacing: 10) {
                            HStack(spacing: 8) {
                                Image(systemName: "sparkles")
                                    .font(.system(size: 11, weight: .semibold))
                                Text(phaseLabel)
                                    .font(.system(size: 11, weight: .semibold, design: .rounded))
                            }
                            .foregroundStyle(.white.opacity(0.92))
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                            .background(.black.opacity(0.26), in: Capsule())
                            .contentTransition(.opacity)
                            .animation(.easeInOut(duration: 0.3), value: phase)

                            // Kinematic focus tag — shows movement direction for the active category
                            HStack(spacing: 5) {
                                Image(systemName: pose.category.symbolName)
                                    .font(.system(size: 10, weight: .bold))
                                    .foregroundStyle(Color(hue: profile.accentHue, saturation: 0.74, brightness: 0.98))
                                Text(pose.category.kineticFocusTag.localized)   // ✅ fix
                                        .font(.system(size: size > 240 ? 10 : 9, weight: .semibold, design: .rounded))
                                        .foregroundStyle(.white.opacity(0.70))
                            }
                            .padding(.horizontal, 10)
                            .padding(.vertical, 6)
                            .background(.black.opacity(0.22), in: Capsule())

                            Spacer()

                            HStack(spacing: 8) {
                                Image(systemName: "wind")
                                    .font(.system(size: 12, weight: .semibold))
                                    .foregroundStyle(Color(hue: profile.accentHue, saturation: 0.74, brightness: 0.98))
                                Text(profile.cue)
                                    .font(.system(size: size > 240 ? 13 : 12, weight: .medium, design: .rounded))
                                    .foregroundStyle(.white.opacity(0.88))
                                    .lineLimit(2)
                                    .multilineTextAlignment(.center)
                            }
                            .padding(.horizontal, 14)
                            .padding(.vertical, 10)
                            .background(.black.opacity(0.28), in: Capsule())
                            .padding(.horizontal, 20)
                            .padding(.bottom, 18)
                        }
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                    }
                    .frame(width: geo.size.width, height: geo.size.height)
                }

                HStack(spacing: 8) {
                    Image(systemName: "video.slash")
                        .font(.system(size: 11, weight: .bold))
                    Text(LocalizedString(en: "Visual coach", fr: "Coach visuel").localized)
                        .font(.system(size: 11, weight: .bold, design: .rounded))
                }
                .foregroundStyle(.white.opacity(0.86))
                .padding(.horizontal, 10)
                .padding(.vertical, 8)
                .background(.black.opacity(0.22), in: Capsule())
                .padding(14)
                .frame(maxWidth: .infinity, alignment: .topTrailing)
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Text(LocalizedString(
            en: "Animated visual guidance for \(pose.name.localized)",
            fr: "Guidage visuel animé pour \(pose.name.localized)"
        ).localized))
    }

    private var phaseLabel: String {
        switch phase {
        case .preview:
            return LocalizedString(en: "Preview", fr: "Aperçu").localized
        case .active:
            return LocalizedString(en: "Hold", fr: "Maintien").localized
        case .transition:
            return LocalizedString(en: "Next", fr: "Suivante").localized
        }
    }
}

private struct MotionCoachProfile {
    let accentHue: Double
    let primarySymbol: String
    let orbitSymbol: String
    let breathPeriod: Double
    let orbitSpeed: Double
    let swayAmplitude: Double
    let verticalAmplitude: Double
    let rotationAmplitude: Double
    let scaleAmplitude: Double
    let cue: String

    init(pose: Pose) {
        self.accentHue = pose.category.accentHue
        self.primarySymbol = pose.position.symbolName
        self.orbitSymbol = pose.category.symbolName == pose.position.symbolName ? "sparkles" : pose.category.symbolName
        self.breathPeriod = max(2.8, min(7.0, pose.durationSeconds / 10.0))
        self.orbitSpeed = 0.22 + (Double(pose.difficulty.dotCount) * 0.05)
        self.swayAmplitude = 4.0 + (Double(pose.difficulty.dotCount) * 2.0)
        self.verticalAmplitude = 3.0 + (Double(pose.difficulty.dotCount) * 1.5)
        self.rotationAmplitude = 2.0 + (Double(pose.difficulty.dotCount) * 1.1)
        self.scaleAmplitude = 0.02 + (Double(pose.difficulty.dotCount) * 0.01)

        let breathing = pose.breathingPattern.localized.trimmingCharacters(in: .whitespacesAndNewlines)
        let voiceCue = pose.voiceCueText.localized.trimmingCharacters(in: .whitespacesAndNewlines)
        let description = pose.description.localized.trimmingCharacters(in: .whitespacesAndNewlines)

        if !breathing.isEmpty {
            self.cue = breathing
        } else if !voiceCue.isEmpty {
            self.cue = voiceCue
        } else {
            self.cue = description
        }
    }
}
// MARK: - Stick figure performing the actual movement

private struct StickFigureKinematicsView: View {
    let pose: Pose
    let phase: MotionCoachPhase
    let time: TimeInterval
    let reduceMotion: Bool

    private var lineColor: Color {
        .white.opacity(0.95)
    }

    var body: some View {
        GeometryReader { geo in
            let size   = min(geo.size.width, geo.size.height)
            let center = CGPoint(x: geo.size.width / 2,
                                 y: geo.size.height / 2 + size * 0.05)

            // Sinusoidal param t ∈ [0,1] for repeating motion
            let t = reduceMotion ? 0.0 : 0.5 + 0.5 * sin(time * 1.6)

            // Base skeleton (torso + legs)
            let headRadius   = size * 0.10
            let shouldersY   = center.y - size * 0.15
            let pelvisY      = center.y + size * 0.12
            let torsoTop     = CGPoint(x: center.x, y: shouldersY)
            let torsoBottom  = CGPoint(x: center.x, y: pelvisY)

            let shoulderOffsetX = size * 0.16
            let leftShoulder  = CGPoint(x: center.x - shoulderOffsetX, y: shouldersY)
            let rightShoulder = CGPoint(x: center.x + shoulderOffsetX, y: shouldersY)

            let leftKnee  = CGPoint(x: center.x - size * 0.10, y: pelvisY + size * 0.12)
            let rightKnee = CGPoint(x: center.x + size * 0.10, y: pelvisY + size * 0.12)
            let leftFoot  = CGPoint(x: center.x - size * 0.12, y: pelvisY + size * 0.26)
            let rightFoot = CGPoint(x: center.x + size * 0.12, y: pelvisY + size * 0.26)

            // Arm kinematics driven by category
            let armConfig = StickArmConfig(category: pose.category)
            let leftAngles  = armConfig.leftAngles(t: t)
            let rightAngles = armConfig.rightAngles(t: t)

            let upperLen = size * 0.22
            let lowerLen = size * 0.20

            let leftElbow = point(onCircleFrom: leftShoulder,
                                  radius: upperLen,
                                  angle: leftAngles.upper)
            let leftHand  = point(onCircleFrom: leftElbow,
                                  radius: lowerLen,
                                  angle: leftAngles.lower)

            let rightElbow = point(onCircleFrom: rightShoulder,
                                   radius: upperLen,
                                   angle: rightAngles.upper)
            let rightHand  = point(onCircleFrom: rightElbow,
                                   radius: lowerLen,
                                   angle: rightAngles.lower)

            ZStack {
                // Torso + legs
                Path { p in
                    p.move(to: torsoTop)
                    p.addLine(to: torsoBottom)

                    p.move(to: torsoBottom)
                    p.addLine(to: leftKnee)
                    p.addLine(to: leftFoot)

                    p.move(to: torsoBottom)
                    p.addLine(to: rightKnee)
                    p.addLine(to: rightFoot)
                }
                .stroke(lineColor.opacity(0.9),
                        style: StrokeStyle(lineWidth: 3,
                                           lineCap: .round,
                                           lineJoin: .round))

                // Head
                Circle()
                    .stroke(lineColor.opacity(0.95), lineWidth: 3)
                    .frame(width: headRadius * 2, height: headRadius * 2)
                    .position(x: center.x, y: shouldersY - headRadius * 1.4)

                // Shoulder joints
                Circle()
                    .fill(lineColor)
                    .frame(width: 4, height: 4)
                    .position(leftShoulder)
                Circle()
                    .fill(lineColor)
                    .frame(width: 4, height: 4)
                    .position(rightShoulder)

                // Arms
                Path { p in
                    p.move(to: leftShoulder)
                    p.addLine(to: leftElbow)
                    p.addLine(to: leftHand)

                    p.move(to: rightShoulder)
                    p.addLine(to: rightElbow)
                    p.addLine(to: rightHand)
                }
                .stroke(Color(hue: pose.category.accentHue,
                              saturation: 0.9,
                              brightness: 1.0),
                        style: StrokeStyle(lineWidth: 3.2,
                                           lineCap: .round,
                                           lineJoin: .round))
                .shadow(color: Color(hue: pose.category.accentHue,
                                     saturation: 0.8,
                                     brightness: 0.95).opacity(0.5),
                        radius: 6)
            }
            .frame(width: geo.size.width, height: geo.size.height)
        }
    }

    private func point(onCircleFrom center: CGPoint,
                       radius: CGFloat,
                       angle: CGFloat) -> CGPoint {
        CGPoint(
            x: center.x + cos(angle) * radius,
            y: center.y + sin(angle) * radius
        )
    }
}

/// Per‑category arm motion configuration (angles interpolated over t ∈ [0,1]).
private struct StickArmConfig {
    let startUpperLeft:  CGFloat
    let endUpperLeft:    CGFloat
    let startLowerLeft:  CGFloat
    let endLowerLeft:    CGFloat

    let startUpperRight: CGFloat
    let endUpperRight:   CGFloat
    let startLowerRight: CGFloat
    let endLowerRight:   CGFloat

    init(category: PoseCategory) {
        switch category {
        case .shoulders, .chest:
            // Shoulder retraction + opening
            startUpperLeft  =  .pi * 0.35
            endUpperLeft    = -.pi * 0.10
            startLowerLeft  =  .pi * 0.55
            endLowerLeft    =  .pi * 0.80

            startUpperRight =  .pi - startUpperLeft
            endUpperRight   =  .pi - endUpperLeft
            startLowerRight =  .pi - startLowerLeft
            endLowerRight   =  .pi - endLowerLeft

        case .hips, .legs:
            // More grounding / downward arms
            startUpperLeft  =  .pi * 0.65
            endUpperLeft    =  .pi * 0.75
            startLowerLeft  =  .pi * 0.90
            endLowerLeft    =  .pi * 1.05

            startUpperRight =  .pi - startUpperLeft
            endUpperRight   =  .pi - endUpperLeft
            startLowerRight =  .pi - startLowerLeft
            endLowerRight   =  .pi - endLowerLeft

        case .spine, .back:
            // Small stabilizing oscillation
            startUpperLeft  =  .pi * 0.40
            endUpperLeft    =  .pi * 0.25
            startLowerLeft  =  .pi * 0.60
            endLowerLeft    =  .pi * 0.70

            startUpperRight =  .pi - startUpperLeft
            endUpperRight   =  .pi - endUpperLeft
            startLowerRight =  .pi - startLowerLeft
            endLowerRight   =  .pi - endLowerLeft

        default:
            // Generic open/close
            startUpperLeft  =  .pi * 0.45
            endUpperLeft    =  .pi * 0.20
            startLowerLeft  =  .pi * 0.65
            endLowerLeft    =  .pi * 0.85

            startUpperRight =  .pi - startUpperLeft
            endUpperRight   =  .pi - endUpperLeft
            startLowerRight =  .pi - startLowerLeft
            endLowerRight   =  .pi - endLowerLeft
        }
    }

    func leftAngles(t: Double) -> (upper: CGFloat, lower: CGFloat) {
        let tt = CGFloat(t)
        return (
            upper: lerp(startUpperLeft,  endUpperLeft,  tt),
            lower: lerp(startLowerLeft,  endLowerLeft,  tt)
        )
    }

    func rightAngles(t: Double) -> (upper: CGFloat, lower: CGFloat) {
        let tt = CGFloat(t)
        return (
            upper: lerp(startUpperRight, endUpperRight, tt),
            lower: lerp(startLowerRight, endLowerRight, tt)
        )
    }

    private func lerp(_ a: CGFloat, _ b: CGFloat, _ t: CGFloat) -> CGFloat {
        a + (b - a) * t
    }
}
// ═══════════════════════════════════════════════════════════════════════════════
// MARK: - Kinematic Motion Components
// ═══════════════════════════════════════════════════════════════════════════════

/// Animated arrow showing movement direction with flow animation
private struct MovementArrow: View {
    let start: CGPoint
    let end: CGPoint
    let color: Color
    let timestamp: TimeInterval
    let reduceMotion: Bool
    let index: Int
    
    var body: some View {
        let angle = atan2(end.y - start.y, end.x - start.x)
        let length = hypot(end.x - start.x, end.y - start.y)
        let flowPhase = reduceMotion ? 0.5 : fmod(timestamp * 1.5 + Double(index) * 0.3, 1.0)
        
        ZStack {
            // Arrow shaft with flowing gradient
            Rectangle()
                .fill(
                    LinearGradient(
                        stops: [
                            .init(color: color.opacity(0.15), location: max(0, flowPhase - 0.3)),
                            .init(color: color.opacity(0.75), location: flowPhase),
                            .init(color: color.opacity(0.15), location: min(1, flowPhase + 0.3))
                        ],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .frame(width: length * 0.85, height: 2.5)
                .shadow(color: color.opacity(0.4), radius: 4)
            
            // Arrowhead
            ArrowHead(color: color)
                .frame(width: 14, height: 14)
                .offset(x: length * 0.42)
                .shadow(color: color.opacity(0.5), radius: 3)
        }
        .rotationEffect(.radians(angle))
        .position(x: (start.x + end.x) / 2, y: (start.y + end.y) / 2)
    }
}

/// Triangle arrowhead shape
private struct ArrowHead: View {
    let color: Color
    
    var body: some View {
        Path { path in
            path.move(to: CGPoint(x: 14, y: 7))
            path.addLine(to: CGPoint(x: 0, y: 0))
            path.addLine(to: CGPoint(x: 0, y: 14))
            path.closeSubpath()
        }
        .fill(color)
    }
}

/// Pulsing circle indicating a joint or articulation point
private struct JointIndicator: View {
    let position: CGPoint
    let size: CGFloat
    let color: Color
    let timestamp: TimeInterval
    let reduceMotion: Bool
    let index: Int
    
    var body: some View {
        let pulse = reduceMotion ? 1.0 : 0.85 + sin(timestamp * 2.5 + Double(index) * 0.5) * 0.15
        
        ZStack {
            // Outer ring
            Circle()
                .stroke(color.opacity(0.4), lineWidth: 2)
                .frame(width: size * 1.4, height: size * 1.4)
                .scaleEffect(pulse)
            
            // Inner filled circle
            Circle()
                .fill(
                    RadialGradient(
                        colors: [
                            color.opacity(0.8),
                            color.opacity(0.4)
                        ],
                        center: .center,
                        startRadius: 0,
                        endRadius: size * 0.5
                    )
                )
                .frame(width: size, height: size)
                .shadow(color: color.opacity(0.6), radius: 6)
        }
        .position(position)
    }
}

/// Faded ghost position showing starting or reference posture
private struct GhostPosition: View {
    let position: CGPoint
    let symbol: String
    let size: CGFloat
    let color: Color
    let opacity: Double
    
    var body: some View {
        Image(systemName: symbol)
            .font(.system(size: size, weight: .thin))
            .foregroundStyle(color.opacity(opacity))
            .position(position)
    }
}

/// Kinematic profile defining movement vectors and joint positions for each category.
/// Maps anatomical movements to visual coordinate space (0.0-1.0 normalized).
private struct KinematicProfile {
    let movementVectors: [MovementVector]
    let jointPositions: [JointPosition]
    let ghostPositions: [GhostSymbol]
    
    init(category: PoseCategory) {
        switch category {
        case .shoulders:
            // Shoulder retraction: arrows showing shoulders pulling back + opening outward
            movementVectors = [
                MovementVector(startX: 0.35, startY: 0.42, endX: 0.25, endY: 0.38), // Left shoulder back
                MovementVector(startX: 0.65, startY: 0.42, endX: 0.75, endY: 0.38), // Right shoulder back
                MovementVector(startX: 0.35, startY: 0.45, endX: 0.28, endY: 0.52), // Left opening down
                MovementVector(startX: 0.65, startY: 0.45, endX: 0.72, endY: 0.52)  // Right opening down
            ]
            jointPositions = [
                JointPosition(x: 0.35, y: 0.42), // Left shoulder
                JointPosition(x: 0.65, y: 0.42), // Right shoulder
                JointPosition(x: 0.50, y: 0.48)  // Upper spine (T4-T6)
            ]
            ghostPositions = [
                GhostSymbol(x: 0.38, y: 0.44, symbol: "circle.fill"), // Left shoulder start
                GhostSymbol(x: 0.62, y: 0.44, symbol: "circle.fill")  // Right shoulder start
            ]
            
        case .hips:
            // Hip opening: arrows showing hip external rotation + abduction
            movementVectors = [
                MovementVector(startX: 0.40, startY: 0.58, endX: 0.32, endY: 0.64), // Left hip opening
                MovementVector(startX: 0.60, startY: 0.58, endX: 0.68, endY: 0.64)  // Right hip opening
            ]
            jointPositions = [
                JointPosition(x: 0.40, y: 0.58), // Left hip
                JointPosition(x: 0.60, y: 0.58), // Right hip
                JointPosition(x: 0.50, y: 0.52)  // Sacrum
            ]
            ghostPositions = [
                GhostSymbol(x: 0.42, y: 0.60, symbol: "circle.fill"),
                GhostSymbol(x: 0.58, y: 0.60, symbol: "circle.fill")
            ]
            
        case .spine:
            // Spinal extension/flexion: arrows showing vertebral movement
            movementVectors = [
                MovementVector(startX: 0.50, startY: 0.35, endX: 0.50, endY: 0.28), // Cervical extension
                MovementVector(startX: 0.50, startY: 0.48, endX: 0.48, endY: 0.42), // Thoracic curve
                MovementVector(startX: 0.50, startY: 0.60, endX: 0.50, endY: 0.54)  // Lumbar extension
            ]
            jointPositions = [
                JointPosition(x: 0.50, y: 0.35), // C7
                JointPosition(x: 0.50, y: 0.48), // T6
                JointPosition(x: 0.50, y: 0.60)  // L3
            ]
            ghostPositions = [
                GhostSymbol(x: 0.50, y: 0.32, symbol: "circle.fill"),
                GhostSymbol(x: 0.50, y: 0.45, symbol: "circle.fill"),
                GhostSymbol(x: 0.50, y: 0.58, symbol: "circle.fill")
            ]
            
        case .chest:
            // Chest opening: arrows showing sternum lift + shoulder blade retraction
            movementVectors = [
                MovementVector(startX: 0.50, startY: 0.45, endX: 0.50, endY: 0.38), // Sternum lift
                MovementVector(startX: 0.38, startY: 0.42, endX: 0.32, endY: 0.40), // Left scapula retract
                MovementVector(startX: 0.62, startY: 0.42, endX: 0.68, endY: 0.40)  // Right scapula retract
            ]
            jointPositions = [
                JointPosition(x: 0.50, y: 0.45), // Sternum
                JointPosition(x: 0.38, y: 0.42),
                JointPosition(x: 0.62, y: 0.42)
            ]
            ghostPositions = [
                GhostSymbol(x: 0.50, y: 0.47, symbol: "heart.fill")
            ]
            
        case .neck:
            // Cervical decompression: arrows showing head/neck alignment
            movementVectors = [
                MovementVector(startX: 0.50, startY: 0.28, endX: 0.50, endY: 0.22), // Crown lift
                MovementVector(startX: 0.50, startY: 0.34, endX: 0.50, endY: 0.38)  // Chin tuck
            ]
            jointPositions = [
                JointPosition(x: 0.50, y: 0.28), // Occiput
                JointPosition(x: 0.50, y: 0.34)  // C7
            ]
            ghostPositions = [
                GhostSymbol(x: 0.48, y: 0.30, symbol: "circle.fill")
            ]
            
        case .core:
            // Core activation: arrows showing trunk stabilization
            movementVectors = [
                MovementVector(startX: 0.42, startY: 0.52, endX: 0.46, endY: 0.50), // Left oblique
                MovementVector(startX: 0.58, startY: 0.52, endX: 0.54, endY: 0.50), // Right oblique
                MovementVector(startX: 0.50, startY: 0.56, endX: 0.50, endY: 0.52)  // Rectus pull
            ]
            jointPositions = [
                JointPosition(x: 0.50, y: 0.50), // Navel
                JointPosition(x: 0.50, y: 0.56)  // Lower abs
            ]
            ghostPositions = []
            
        case .legs:
            // Lower limb grounding: arrows showing root/press
            movementVectors = [
                MovementVector(startX: 0.42, startY: 0.75, endX: 0.40, endY: 0.82), // Left leg press
                MovementVector(startX: 0.58, startY: 0.75, endX: 0.60, endY: 0.82)  // Right leg press
            ]
            jointPositions = [
                JointPosition(x: 0.42, y: 0.75),
                JointPosition(x: 0.58, y: 0.75)
            ]
            ghostPositions = []
            
        case .arms:
            // Upper limb lengthening
            movementVectors = [
                MovementVector(startX: 0.35, startY: 0.45, endX: 0.25, endY: 0.48), // Left arm reach
                MovementVector(startX: 0.65, startY: 0.45, endX: 0.75, endY: 0.48)  // Right arm reach
            ]
            jointPositions = [
                JointPosition(x: 0.35, y: 0.45),
                JointPosition(x: 0.65, y: 0.45)
            ]
            ghostPositions = []
            
        case .back:
            // Posterior chain release
            movementVectors = [
                MovementVector(startX: 0.50, startY: 0.38, endX: 0.50, endY: 0.45),
                MovementVector(startX: 0.50, startY: 0.55, endX: 0.50, endY: 0.62)
            ]
            jointPositions = [
                JointPosition(x: 0.50, y: 0.40),
                JointPosition(x: 0.50, y: 0.55)
            ]
            ghostPositions = []
            
        default:
            // Generic full-body integration vectors
            movementVectors = [
                MovementVector(startX: 0.50, startY: 0.30, endX: 0.50, endY: 0.25), // Crown lift
                MovementVector(startX: 0.50, startY: 0.70, endX: 0.50, endY: 0.76)  // Root ground
            ]
            jointPositions = [
                JointPosition(x: 0.50, y: 0.35),
                JointPosition(x: 0.50, y: 0.50),
                JointPosition(x: 0.50, y: 0.65)
            ]
            ghostPositions = []
        }
    }
}

private struct MovementVector {
    let startX: Double
    let startY: Double
    let endX: Double
    let endY: Double
}

private struct JointPosition {
    let x: Double
    let y: Double
}

private struct GhostSymbol {
    let x: Double
    let y: Double
    let symbol: String
}
