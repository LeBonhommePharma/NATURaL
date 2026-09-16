import SwiftUI
import BonhommeCore

/// Full-screen 3-2-1 countdown overlay with shockwave ripples, depth shadows, and spring physics.
struct CountdownView: View {
    let secondsRemaining: Int

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var rippleTrigger: Int = 0

    var body: some View {
        ZStack {
            RadialGradient(
                colors: [BrandColor.bg.opacity(0.6), BrandColor.bg],
                center: .center, startRadius: 50, endRadius: 400
            )
            .ignoresSafeArea()

            if !reduceMotion {
                ForEach(0..<2, id: \.self) { i in
                    Circle()
                        .stroke(BrandColor.magnesium.opacity(0.22), lineWidth: 2)
                        .frame(width: 100, height: 100)
                        .scaleEffect(rippleScale(index: i))
                        .opacity(rippleOpacity(index: i))
                        .animation(
                            .easeOut(duration: 0.8).delay(Double(i) * 0.15),
                            value: rippleTrigger
                        )
                }

                Circle()
                    .fill(
                        RadialGradient(
                            colors: [BrandColor.mint.opacity(0.12), .clear],
                            center: .center, startRadius: 10, endRadius: 120
                        )
                    )
                    .frame(width: 240, height: 240)
                    .scaleEffect(rippleTrigger % 2 == 0 ? 0.9 : 1.1)
                    .animation(.easeOut(duration: 0.4), value: rippleTrigger)
            }

            VStack(spacing: SessionSpacing.md) {
                SessionCountdownNumeral(remaining: TimeInterval(secondsRemaining), tint: BrandColor.fg)
                Text(SessionHUDCopy.getReady.localized)
                    .font(.title3.weight(.medium))
                    .foregroundStyle(BrandColor.fgMuted)
            }
        }
        .ignoresSafeArea()
        .onChange(of: secondsRemaining) { _, _ in
            guard !reduceMotion else { return }
            rippleTrigger += 1
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
