import SwiftUI
import BonhommeCore

/// Full-screen 3-2-1 countdown overlay shown before workout starts.
struct CountdownView: View {
    let secondsRemaining: Int

    var body: some View {
        ZStack {
            Color.black.opacity(0.85)

            VStack(spacing: 16) {
                Text("\(secondsRemaining)")
                    .font(.system(size: 120, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
                    .contentTransition(.numericText())
                    .animation(.spring(duration: 0.3), value: secondsRemaining)

                Text(LocalizedString(en: "Get Ready", fr: "Préparez-vous").localized)
                    .font(.system(size: 24, weight: .medium, design: .rounded))
                    .foregroundStyle(.white.opacity(0.6))
            }
        }
        .ignoresSafeArea()
    }
}
