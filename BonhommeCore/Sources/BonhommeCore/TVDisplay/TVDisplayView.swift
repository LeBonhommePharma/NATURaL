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
                        Color(red: 0.02, green: 0.02, blue: 0.08),
                        .black
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
                                colors: [.clear, .white.opacity(0.08), .clear],
                                startPoint: .top, endPoint: .bottom
                            )
                        )
                        .frame(width: 1)

                    // Right 40%: biofeedback panel
                    VStack(spacing: 32) {
                        Spacer()

                        HeartRateGaugeView(bpm: payload.biofeedback.heartRate)

                        SCIVisualizationView(
                            score: payload.biofeedback.sciScore,
                            trend: payload.biofeedback.sciTrend
                        )

                        SessionProgressView(
                            index: payload.sequenceIndex,
                            total: payload.sequenceTotal,
                            elapsed: payload.sessionElapsed
                        )

                        // Calories
                        HStack(spacing: 4) {
                            Image(systemName: "flame.fill")
                                .foregroundStyle(.orange)
                                .shadow(color: .orange.opacity(0.3), radius: 3)
                            Text("\(Int(payload.biofeedback.activeCalories)) cal")
                                .font(.system(size: 18, weight: .semibold, design: .rounded))
                                .foregroundStyle(.white)
                        }

                        Spacer()
                    }
                    .frame(width: geo.size.width * 0.4 - 1)
                    .frame(maxHeight: .infinity)
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
                    .foregroundStyle(.white.opacity(0.8))
                    .shadow(color: .white.opacity(0.15), radius: 10)
                    .transition(.scale.combined(with: .opacity))

                Text(LocalizedString(en: "Paused", fr: "En pause", es: "En pausa", ja: "一時停止", zh: "已暂停", ko: "일시 정지", ru: "Пауза", de: "Pausiert", ar: "متوقف مؤقتًا").localized)
                    .font(.system(size: 32, weight: .semibold, design: .rounded))
                    .foregroundStyle(.white.opacity(0.8))
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
            let shimmerX = fmod(t * 0.3, 1.5) - 0.25 // shimmer band position

            ZStack {
                // Subtle gradient background
                LinearGradient(
                    colors: [
                        Color(red: 0.02, green: 0.02, blue: 0.06),
                        .black
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
                                    colors: [Color.cyan.opacity(0.05 + breath * 0.05), .clear],
                                    center: .center, startRadius: 10, endRadius: 80
                                )
                            )
                            .frame(width: 160, height: 160)

                        Image(systemName: "figure.yoga")
                            .font(.system(size: 80))
                            .foregroundStyle(.cyan.opacity(0.5 + breath * 0.2))
                            .scaleEffect(0.95 + breath * 0.1)
                            .shadow(color: .cyan.opacity(0.2), radius: 12)
                    }

                    // Title with shimmer
                    Text("NATURaL")
                        .font(.system(size: 48, weight: .bold, design: .rounded))
                        .foregroundStyle(.white)
                        .overlay(
                            LinearGradient(
                                stops: [
                                    .init(color: .clear, location: max(0, shimmerX - 0.1)),
                                    .init(color: .white.opacity(0.3), location: shimmerX),
                                    .init(color: .clear, location: min(1, shimmerX + 0.1))
                                ],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                            .mask(
                                Text("NATURaL")
                                    .font(.system(size: 48, weight: .bold, design: .rounded))
                            )
                        )

                    Text(LocalizedString(en: "Waiting for workout session...", fr: "En attente d'une séance d'entraînement...", es: "Esperando la sesión de entrenamiento...", ja: "ワークアウトセッションを待っています...", zh: "正在等待训练课程...", ko: "운동 세션을 기다리는 중...", ru: "Ожидание тренировки...", de: "Warten auf Trainingseinheit...", ar: "في انتظار جلسة التمرين...").localized)
                        .font(.system(size: 20, weight: .regular, design: .rounded))
                        .foregroundStyle(.white.opacity(0.3 + breath * 0.3))

                    ProgressView()
                        .tint(.cyan)
                        .scaleEffect(1.5)
                        .padding(.top, 8)
                }
            }
        }
        .preferredColorScheme(.dark)
    }
}
