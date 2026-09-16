import SwiftUI

/// The shared TV display view with ambient depth gradient and refined panel separator.
public struct TVDisplayView: View {
    public let payload: TVDisplayPayload

    public init(payload: TVDisplayPayload) {
        self.payload = payload
    }

    public var body: some View {
        GeometryReader { geo in
            ZStack {
                // Ambient depth background
                RadialGradient(
                    colors: [
                        BrandColor.bgPanel,
                        BrandColor.bg
                    ],
                    center: .center,
                    startRadius: 100,
                    endRadius: max(geo.size.width, geo.size.height) * 0.7
                )
                .ignoresSafeArea()

                HStack(spacing: 0) {
                    // Left 60%: pose visual + countdown
                    PoseCountdownView(
                        pose: payload.currentPose,
                        remaining: payload.poseTimeRemaining,
                        total: payload.totalPoseTime
                    )
                    .frame(width: geo.size.width * 0.6)
                    .frame(maxHeight: .infinity)

                    // Subtle vertical separator
                    Rectangle()
                        .fill(
                            LinearGradient(
                                colors: [.clear, BrandColor.hairlineStrong, .clear],
                                startPoint: .top, endPoint: .bottom
                            )
                        )
                        .frame(width: 1)

                    // Right 40%: biofeedback inspector (shared HUD language)
                    SessionHUDPanel(metrics: payload.hudMetrics, showsGauges: true)
                        .frame(width: geo.size.width * 0.4 - 1)
                        .frame(maxHeight: .infinity)
                        .focusable(true)
                }

                // Pause overlay
                if payload.isPaused {
                    pauseOverlay
                }
            }
        }
        .preferredColorScheme(.dark)
    }

    private var pauseOverlay: some View {
        ZStack {
            Rectangle()
                .fill(.ultraThinMaterial)
                .ignoresSafeArea()

            VStack(spacing: 16) {
                Image(systemName: "pause.circle.fill")
                    .font(.system(size: 64))
                    .foregroundStyle(BrandColor.strawberry)
                    .sessionGlow(BrandColor.strawberry, radius: 10)
                    .transition(.scale.combined(with: .opacity))

                Text(SessionHUDCopy.paused.localized)
                    .font(.largeTitle.weight(.semibold))
                    .foregroundStyle(BrandColor.fg)
            }
        }
    }
}

/// Idle view shown when waiting for a workout to start on TV.
/// Breathing animation + title shimmer + ambient glow.
public struct TVIdleView: View {
    public init() {}

    public var body: some View {
        TimelineView(.animation(minimumInterval: 1.0 / 30.0, paused: false)) { context in
            let t = context.date.timeIntervalSinceReferenceDate
            let breath = (sin(t * .pi * 2.0 / 4.0) + 1.0) * 0.5 // 4s cycle

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
