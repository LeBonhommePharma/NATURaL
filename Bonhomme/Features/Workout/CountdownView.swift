import SwiftUI
import BonhommeCore

/// Full-screen 3-2-1 countdown overlay with shockwave ripples, depth shadows, and spring physics.
struct CountdownView: View {
    let secondsRemaining: Int

    @State private var rippleTrigger: Int = 0
    @State private var readyOpacity: Double = 0.4

    var body: some View {
        ZStack {
            // Depth gradient background
            RadialGradient(
                colors: [Color.black.opacity(0.6), Color.black.opacity(0.95)],
                center: .center, startRadius: 50, endRadius: 400
            )
            .ignoresSafeArea()

            // Shockwave ripple rings
            ForEach(0..<2, id: \.self) { i in
                Circle()
                    .stroke(Color.white.opacity(0.2), lineWidth: 2)
                    .frame(width: 100, height: 100)
                    .scaleEffect(rippleScale(index: i))
                    .opacity(rippleOpacity(index: i))
                    .animation(
                        .easeOut(duration: 0.8).delay(Double(i) * 0.15),
                        value: rippleTrigger
                    )
            }

            // Radial light burst
            Circle()
                .fill(
                    RadialGradient(
                        colors: [Color.white.opacity(0.12), .clear],
                        center: .center, startRadius: 10, endRadius: 120
                    )
                )
                .frame(width: 240, height: 240)
                .scaleEffect(rippleTrigger % 2 == 0 ? 0.9 : 1.1)
                .animation(.easeOut(duration: 0.4), value: rippleTrigger)

            VStack(spacing: 16) {
                Text("\(secondsRemaining)")
                    .font(.system(size: 120, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
                    .shadow(color: .white.opacity(0.3), radius: 2)
                    .shadow(color: .cyan.opacity(0.2), radius: 8)
                    .shadow(color: .cyan.opacity(0.1), radius: 20)
                    .contentTransition(.numericText())
                    .animation(.spring(response: 0.35, dampingFraction: 0.6, blendDuration: 0.1), value: secondsRemaining)
                    .scaleEffect(rippleTrigger % 2 == 0 ? 1.0 : 1.03)

                Text(LocalizedString(en: "Get Ready", fr: "Préparez-vous").localized)
                    .font(.system(size: 24, weight: .medium, design: .rounded))
                    .foregroundStyle(.white.opacity(readyOpacity))
            }
        }
        .ignoresSafeArea()
        .onChange(of: secondsRemaining) { _, _ in
            rippleTrigger += 1
        }
        .onAppear {
            withAnimation(.easeInOut(duration: 1.2).repeatForever(autoreverses: true)) {
                readyOpacity = 0.7
            }
        }
    }

    private func rippleScale(index: Int) -> CGFloat {
        let base: CGFloat = rippleTrigger > 0 ? 3.0 : 0.5
        return base + CGFloat(index) * 0.5
    }

    private func rippleOpacity(index: Int) -> Double {
        rippleTrigger > 0 ? 0.0 : 0.3
    }
}
