import SwiftUI

/// Phase styling for the symbolic motion coach.
/// This clean-room component provides procedural guidance without trainer video.
public enum MotionCoachPhase: Sendable {
    case preview
    case active
    case transition
}

/// Procedural, video-free pose guidance view built entirely from symbols and animation.
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

        TimelineView(.animation(minimumInterval: reduceMotion ? 1.0 : (1.0 / 24.0), paused: false)) { context in
            let timestamp = context.date.timeIntervalSinceReferenceDate
            let breathAngle = timestamp * (.pi * 2.0) / profile.breathPeriod
            let orbitAngle = timestamp * profile.orbitSpeed
            let wave = reduceMotion ? 0.0 : sin(breathAngle)
            let sway = reduceMotion ? 0.0 : cos(breathAngle * 0.72)
            let pulse = reduceMotion ? 0.0 : ((sin(breathAngle) + 1.0) * 0.5)

            ZStack(alignment: .topLeading) {
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [
                                Color(hue: profile.accentHue, saturation: 0.42, brightness: 0.20),
                                Color(hue: profile.accentHue, saturation: 0.58, brightness: 0.11),
                                Color.black.opacity(0.96)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )

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

                GeometryReader { geo in
                    let size = min(geo.size.width, geo.size.height)
                    let orbitRadius = size * 0.24
                    let ringSize = size * 0.68
                    let secondaryRingSize = size * 0.88

                    ZStack {
                        Circle()
                            .fill(
                                RadialGradient(
                                    colors: [
                                        Color(hue: profile.accentHue, saturation: 0.65, brightness: 0.92).opacity(0.22),
                                        Color.clear
                                    ],
                                    center: .center,
                                    startRadius: 12,
                                    endRadius: size * 0.48
                                )
                            )
                            .frame(width: size * 0.92, height: size * 0.92)
                            .scaleEffect(1.0 + (pulse * 0.08))

                        Circle()
                            .stroke(
                                Color(hue: profile.accentHue, saturation: 0.72, brightness: 0.96).opacity(0.30),
                                lineWidth: 2
                            )
                            .frame(width: ringSize, height: ringSize)
                            .scaleEffect(0.96 + (pulse * 0.10))

                        Circle()
                            .stroke(
                                Color.white.opacity(0.12),
                                style: StrokeStyle(lineWidth: 1, dash: [5, 10])
                            )
                            .frame(width: secondaryRingSize, height: secondaryRingSize)
                            .rotationEffect(.degrees(reduceMotion ? 0 : timestamp * 8.0))

                        ForEach(0..<3, id: \.self) { index in
                            let offsetAngle = orbitAngle + (Double(index) * ((.pi * 2.0) / 3.0))
                            let x = cos(offsetAngle) * orbitRadius
                            let y = sin(offsetAngle) * orbitRadius * 0.75

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
                                .offset(x: x, y: y)
                        }

                        Image(systemName: profile.primarySymbol)
                            .font(.system(size: size * 0.34, weight: .regular))
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [
                                        Color.white.opacity(0.95),
                                        Color(hue: profile.accentHue, saturation: 0.58, brightness: 0.98)
                                    ],
                                    startPoint: .top,
                                    endPoint: .bottom
                                )
                            )
                            .shadow(color: Color(hue: profile.accentHue, saturation: 0.72, brightness: 0.98).opacity(0.28), radius: 22)
                            .scaleEffect(1.0 + (pulse * profile.scaleAmplitude))
                            .rotationEffect(.degrees(wave * profile.rotationAmplitude))
                            .offset(x: sway * profile.swayAmplitude, y: wave * profile.verticalAmplitude)

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
