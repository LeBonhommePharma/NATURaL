import SwiftUI

// MARK: - Limb Arc View

/// Draws a dashed category-specific limb-arc path with a solid progress overlay.
struct LimbArcView: View {
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

// MARK: - MotionCoachProfile

/// Pose-derived constants for the motion coach visualization.
///
/// Pure value type with no SwiftUI rendering dependencies — independently unit-testable.
/// Encodes per-category kinematics via `limbOffset()` and `limbArcPath()`.
struct MotionCoachProfile: Sendable {
    let accentHue: Double
    let primarySymbol: String
    let breathPeriod: Double
    let scaleAmplitude: Double
    let cue: String
    let category: PoseCategory
    let difficulty: PoseDifficulty

    /// Radius fraction used by `limbArcPath` (matches MotionCoachView's Proportion.limbArcRadius).
    static let limbArcRadiusFraction: CGFloat = 0.30

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

    /// Per-category kinematic offset and rotation.
    ///
    /// - Parameters:
    ///   - smooth: Smoothstep-normalized phase (0–1).
    ///   - wave: Sinusoidal breathing wave (–1 to 1).
    /// - Returns: `(offsetX, offsetY, rotation)` where rotation is in degrees.
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

    /// Category-specific Bezier arc showing the full movement envelope.
    ///
    /// - Parameters:
    ///   - size: Container size for scaling.
    ///   - progress: Current progress (0–1) used by the caller for trim overlay.
    /// - Returns: A `Path` describing the arc geometry.
    func limbArcPath(size: CGFloat, progress: Double) -> Path {
        let r = size * Self.limbArcRadiusFraction

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
