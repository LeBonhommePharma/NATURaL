import SwiftUI

/// Displays current heart rate with realistic heartbeat kinematics, pulse ring emanation, and HR zone coloring.
public struct HeartRateGaugeView: View {
    public let bpm: Double?

    public init(bpm: Double?) {
        self.bpm = bpm
    }

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    public var body: some View {
        TimelineView(.animation(
            minimumInterval: reduceMotion ? 1.0 : (1.0 / 60.0),
            paused: bpm == nil || reduceMotion
        )) { context in
            let t = context.date.timeIntervalSinceReferenceDate
            let scale = heartbeatScale(t)
            let ringPhase = bpm != nil ? fmod(t, beatDuration) / beatDuration : 0.0
            let ring2Phase = bpm != nil ? fmod(t + beatDuration * 0.5, beatDuration) / beatDuration : 0.0

            VStack(spacing: 8) {
                ZStack {
                    // Pulse ring 1
                    if bpm != nil {
                        Circle()
                            .stroke(zoneColor.opacity(max(0, 0.4 - ringPhase * 0.5)), lineWidth: 2)
                            .scaleEffect(1.0 + ringPhase * 1.5)
                            .frame(width: 40, height: 40)
                        // Pulse ring 2 (staggered)
                        Circle()
                            .stroke(zoneColor.opacity(max(0, 0.25 - ring2Phase * 0.35)), lineWidth: 1.5)
                            .scaleEffect(1.0 + ring2Phase * 1.8)
                            .frame(width: 40, height: 40)
                    }

                    Image(systemName: "heart.fill")
                        .font(.system(size: 32))
                        .foregroundStyle(zoneColor)
                        .scaleEffect(scale)
                        .sessionGlow(zoneColor, radius: 8, paused: reduceMotion)
                }
                .frame(width: 80, height: 80)

                if let bpm {
                    Text("\(Int(bpm))")
                        .font(SessionType.metric(size: 48))
                        .monospacedDigit()
                        .foregroundStyle(BrandColor.fg)
                        .sessionGlow(zoneColor, radius: 6)
                        .contentTransition(.numericText())

                    Text(SessionHUDCopy.bpm.localized)
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(BrandColor.fgMuted)
                } else {
                    Text("--")
                        .font(SessionType.metric(size: 48))
                        .foregroundStyle(BrandColor.magnesium)

                    Text(SessionHUDCopy.bpm.localized)
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(BrandColor.fgMuted)
                }

                Text(zoneName)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(zoneColor)
                    .animation(reduceMotion ? nil : .easeInOut(duration: 0.5), value: zoneName)
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Text(SessionHUDCopy.heartRate.localized))
        .accessibilityValue(Text(bpm.map { "\(Int($0.rounded())) BPM, \(zoneName)" } ?? zoneName))
    }

    /// Multi-phase heartbeat: systolic spike -> diastolic rebound -> settle
    private func heartbeatScale(_ t: TimeInterval) -> CGFloat {
        guard bpm != nil, beatDuration > 0 else { return 1.0 }
        let phase = fmod(t, beatDuration) / beatDuration
        switch phase {
        case ..<0.08:
            let p = phase / 0.08
            return 1.0 + 0.22 * CGFloat(p * p)
        case 0.08..<0.20:
            let p = (phase - 0.08) / 0.12
            return 1.22 - 0.28 * CGFloat(p)
        case 0.20..<0.40:
            let p = (phase - 0.20) / 0.20
            let s = CGFloat(p * p * (3.0 - 2.0 * p))
            return 0.94 + 0.06 * s
        default:
            return 1.0
        }
    }

    private var beatDuration: TimeInterval {
        guard let bpm, bpm > 0 else { return 1.0 }
        return 60.0 / bpm
    }

    private var zoneColor: Color { SessionPalette.heartRate(bpm) }

    private var zoneName: String {
        guard let bpm else {
            return LocalizedString(en: "No Signal", fr: "Aucun signal", es: "Sin señal", ja: "信号なし", zh: "无信号", ko: "신호 없음", ru: "Нет сигнала", de: "Kein Signal", ar: "لا توجد إشارة").localized
        }
        switch bpm {
        case ..<100: return LocalizedString(en: "Recovery", fr: "Récupération", es: "Recuperación", ja: "回復", zh: "恢复", ko: "회복", ru: "Восстановление", de: "Erholung", ar: "تعافٍ").localized
        case 100..<130: return LocalizedString(en: "Fat Burn", fr: "Brûle-graisse", es: "Quema de grasa", ja: "脂肪燃焼", zh: "燃脂", ko: "지방 연소", ru: "Жиросжигание", de: "Fettverbrennung", ar: "حرق الدهون").localized
        case 130..<160: return LocalizedString(en: "Cardio", fr: "Cardio", es: "Cardio", ja: "有酸素", zh: "有氧", ko: "유산소", ru: "Кардио", de: "Kardio", ar: "تمارين القلب").localized
        default: return LocalizedString(en: "Peak", fr: "Pointe", es: "Máximo", ja: "ピーク", zh: "峰値", ko: "최고", ru: "Пик", de: "Spitze", ar: "الذروة").localized
        }
    }
}
