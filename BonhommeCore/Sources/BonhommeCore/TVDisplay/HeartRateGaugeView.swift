import SwiftUI

/// Displays current heart rate with an animated heart icon and HR zone coloring.
public struct HeartRateGaugeView: View {
    public let bpm: Double?

    public init(bpm: Double?) {
        self.bpm = bpm
    }

    @State private var heartScale: CGFloat = 1.0

    public var body: some View {
        VStack(spacing: 8) {
            Image(systemName: "heart.fill")
                .font(.system(size: 32))
                .foregroundStyle(zoneColor)
                .scaleEffect(heartScale)
                .animation(
                    bpm != nil
                        ? .easeInOut(duration: beatDuration).repeatForever(autoreverses: true)
                        : .default,
                    value: heartScale
                )
                .onAppear {
                    if bpm != nil { heartScale = 1.15 }
                }
                .onChange(of: bpm != nil) { _, hasHR in
                    heartScale = hasHR ? 1.15 : 1.0
                }

            if let bpm {
                Text("\(Int(bpm))")
                    .font(.system(size: 48, weight: .bold, design: .rounded))
                    .monospacedDigit()
                    .foregroundStyle(.white)
                    .contentTransition(.numericText())

                Text("BPM")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(.white.opacity(0.5))
            } else {
                Text("--")
                    .font(.system(size: 48, weight: .bold, design: .rounded))
                    .foregroundStyle(.white.opacity(0.3))

                Text("BPM")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(.white.opacity(0.3))
            }

            Text(zoneName)
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(zoneColor)
        }
    }

    private var beatDuration: TimeInterval {
        guard let bpm, bpm > 0 else { return 1.0 }
        return 60.0 / bpm
    }

    private var zoneColor: Color {
        guard let bpm else { return .gray }
        switch bpm {
        case ..<100: return .green
        case 100..<130: return .yellow
        case 130..<160: return .orange
        default: return .red
        }
    }

    private var zoneName: String {
        guard let bpm else {
            return LocalizedString(en: "No Signal", fr: "Aucun signal").localized
        }
        switch bpm {
        case ..<100: return LocalizedString(en: "Recovery", fr: "Récupération").localized
        case 100..<130: return LocalizedString(en: "Fat Burn", fr: "Brûle-graisse").localized
        case 130..<160: return LocalizedString(en: "Cardio", fr: "Cardio").localized
        default: return LocalizedString(en: "Peak", fr: "Pointe").localized
        }
    }
}
