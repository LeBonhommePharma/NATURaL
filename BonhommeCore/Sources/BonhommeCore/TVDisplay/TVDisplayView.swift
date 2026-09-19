import SwiftUI

/// Shared native-TV and AirPlay/HDMI canvas. Pause preserves the visible guide.
public struct TVDisplayView: View {
    public let payload: TVDisplayPayload
    public init(payload: TVDisplayPayload) { self.payload = payload }

    public var body: some View {
        GeometryReader { geometry in
            ScrollView {
                if geometry.size.width >= 900 {
                    HStack(alignment: .top, spacing: 24) {
                        poseGuide.frame(maxWidth: .infinity)
                        inspector.frame(width: min(420, geometry.size.width * 0.32))
                    }
                } else {
                    VStack(spacing: 24) { poseGuide; inspector }
                }
            }
            .padding(.horizontal, geometry.size.width >= 900 ? 48 : 16)
            .padding(.vertical, 32)
            .background(BrandColor.bg.ignoresSafeArea())
        }
        .preferredColorScheme(.dark)
    }

    private var poseGuide: some View {
        PoseCountdownView(pose: payload.currentPose, remaining: payload.poseTimeRemaining,
                          total: payload.totalPoseTime, isPaused: payload.isPaused,
                          isTransition: payload.isTransition ?? false)
    }

    private var inspector: some View {
        SessionHUDPanel(metrics: payload.hudMetrics, showsGauges: true, spaciousChips: true)
            .background(BrandColor.bgPanel, in: RoundedRectangle(cornerRadius: 26))
    }
}

/// Idle view shown when waiting for a workout to start on TV.
/// Breathing animation + title shimmer + ambient glow.
public struct TVIdleView: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    public init() {}

    public var body: some View {
        TimelineView(.animation(
            minimumInterval: SessionMotion.timelineInterval(reduceMotion),
            paused: SessionMotion.timelinePaused(reduceMotion)
        )) { context in
            let t = context.date.timeIntervalSinceReferenceDate
            let breath = reduceMotion ? 0.5 : (sin(t * .pi * 2.0 / 4.0) + 1.0) * 0.5 // 4s cycle

            ZStack {
                // Subtle gradient background
                LinearGradient(
                    colors: [
                        BrandColor.bgPanel,
                        BrandColor.bg
                    ],
                    startPoint: .top, endPoint: .bottom
                )
                .ignoresSafeArea()

                VStack(spacing: 24) {
                    ZStack {
                        // Ambient glow behind icon
                        Circle()
                            .fill(
                                RadialGradient(
                                    colors: [BrandColor.mint.opacity(0.05 + breath * 0.05), .clear],
                                    center: .center, startRadius: 10, endRadius: 80
                                )
                            )
                            .frame(width: 160, height: 160)

                        Image(systemName: "figure.yoga")
                            .font(.system(size: 80))
                            .foregroundStyle(BrandColor.mint.opacity(0.5 + breath * 0.2))
                            .scaleEffect(0.95 + breath * 0.1)
                            .sessionGlow(BrandColor.mint, radius: 12)
                    }

                    Text("NATURaL")
                        .font(.largeTitle.weight(.bold))
                        .foregroundStyle(BrandColor.fg)

                    Text(LocalizedString(en: "Waiting for workout session...", fr: "En attente d'une séance d'entraînement...", es: "Esperando la sesión de entrenamiento...", ja: "ワークアウトセッションを待っています...", zh: "正在等待训练课程...", ko: "운동 세션을 기다리는 중...", ru: "Ожидание тренировки...", de: "Warten auf Trainingseinheit...", ar: "في انتظار جلسة التمرين...").localized)
                        .font(.title2)
                        .foregroundStyle(BrandColor.fgMuted.opacity(0.7 + breath * 0.3))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 80)

                    ProgressView()
                        .tint(SessionPalette.accent)
                        .scaleEffect(1.5)
                        .padding(.top, 8)
                }
            }
        }
        .preferredColorScheme(.dark)
    }
}
