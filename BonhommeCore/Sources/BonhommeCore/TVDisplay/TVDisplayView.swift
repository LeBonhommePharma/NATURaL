import SwiftUI

/// The shared TV display view rendered identically on both native tvOS
/// and AirPlay second-screen. Accepts a plain struct (no ObservableObject)
/// so the hosting context provides its own observation mechanism.
public struct TVDisplayView: View {
    public let payload: TVDisplayPayload

    public init(payload: TVDisplayPayload) {
        self.payload = payload
    }

    public var body: some View {
        GeometryReader { geo in
            HStack(spacing: 0) {
                // Left 60%: pose visual + countdown
                PoseCountdownView(
                    pose: payload.currentPose,
                    remaining: payload.poseTimeRemaining,
                    total: payload.totalPoseTime
                )
                .frame(width: geo.size.width * 0.6)
                .frame(maxHeight: .infinity)

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
                        Text("\(Int(payload.biofeedback.activeCalories)) cal")
                            .font(.system(size: 18, weight: .semibold, design: .rounded))
                            .foregroundStyle(.white)
                    }

                    Spacer()
                }
                .frame(width: geo.size.width * 0.4)
                .frame(maxHeight: .infinity)
            }

            // Pause overlay
            if payload.isPaused {
                pauseOverlay
            }
        }
        .background(Color.black)
        .preferredColorScheme(.dark)
    }

    private var pauseOverlay: some View {
        ZStack {
            Color.black.opacity(0.7)
            VStack(spacing: 16) {
                Image(systemName: "pause.circle.fill")
                    .font(.system(size: 64))
                    .foregroundStyle(.white.opacity(0.8))
                Text(LocalizedString(en: "Paused", fr: "En pause").localized)
                    .font(.system(size: 32, weight: .semibold, design: .rounded))
                    .foregroundStyle(.white.opacity(0.8))
            }
        }
    }
}

/// Idle view shown when waiting for a workout to start on TV.
public struct TVIdleView: View {
    public init() {}

    public var body: some View {
        ZStack {
            Color.black

            VStack(spacing: 24) {
                Image(systemName: "figure.yoga")
                    .font(.system(size: 80))
                    .foregroundStyle(.cyan.opacity(0.6))

                Text("NATURaL")
                    .font(.system(size: 48, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)

                Text(LocalizedString(en: "Waiting for workout session...", fr: "En attente d'une séance d'entraînement...").localized)
                    .font(.system(size: 20, weight: .regular, design: .rounded))
                    .foregroundStyle(.white.opacity(0.5))

                ProgressView()
                    .tint(.cyan)
                    .scaleEffect(1.5)
                    .padding(.top, 8)
            }
        }
        .preferredColorScheme(.dark)
    }
}
