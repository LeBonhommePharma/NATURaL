import Foundation

/// Deterministic SCI copy for Siri, Summary, and Foundation Models fallbacks.
/// On-device only — never a cloud LLM.
public enum SCIExplanationCopy {
    public static func technical(score: Double?, trend: SCITrend) -> LocalizedString {
        guard let score, score.isFinite else {
            return LocalizedString(
                en: "SCI is waiting for HRV. Shannon entropy of beat intervals has not been estimated yet.",
                fr: "Le SCI attend l’HRV. L’entropie de Shannon des intervalles n’a pas encore été estimée."
            )
        }
        let pct = Int((min(1, max(0, score)) * 100).rounded())
        let band = SessionEntropyState.resolve(sciScore: score, isGrounding: false)
        let trendPhrase = trendLabel(trend)
        return LocalizedString(
            en: "SCI is \(pct)% (\(band.label.en)). It is Shannon entropy of RR intervals, scaled 0–100. Trend: \(trendPhrase.en).",
            fr: "Le SCI est à \(pct) % (\(band.label.fr)). C’est l’entropie de Shannon des intervalles RR, de 0 à 100. Tendance : \(trendPhrase.fr)."
        )
    }

    public static func plainLanguage(score: Double?, trend: SCITrend) -> LocalizedString {
        guard let score, score.isFinite else {
            return LocalizedString(
                en: "We do not have a focus reading yet. Start moving with a heart-rate source and SCI will appear.",
                fr: "Pas encore de lecture de concentration. Commencez avec une source de rythme cardiaque et le SCI apparaîtra."
            )
        }
        let pct = Int((min(1, max(0, score)) * 100).rounded())
        let band = SessionPalette.SCIBand.resolve(score)
        let body: LocalizedString
        switch band {
        case .fail:
            body = LocalizedString(
                en: "Your focus index is low (\(pct)%). Soften the breath and let the pose be smaller.",
                fr: "Votre indice de concentration est bas (\(pct) %). Adoucissez le souffle et réduisez la pose."
            )
        case .warn:
            body = LocalizedString(
                en: "Your focus index is settling (\(pct)%). Stay with even breathing; the session is finding a rhythm.",
                fr: "Votre indice de concentration se stabilise (\(pct) %). Gardez un souffle régulier; la séance trouve son rythme."
            )
        case .signal:
            body = LocalizedString(
                en: "Your focus index is steady (\(pct)%). Hold with ease — this is a good working range.",
                fr: "Votre indice de concentration est stable (\(pct) %). Tenez avec aisance — c’est une bonne zone de travail."
            )
        case .pass:
            body = LocalizedString(
                en: "Your focus index is high (\(pct)%). You can stay tall and unhurried.",
                fr: "Votre indice de concentration est élevé (\(pct) %). Restez grand(e) et sans précipitation."
            )
        case .apo:
            body = LocalizedString(
                en: "Focus index is not available yet.",
                fr: "L’indice de concentration n’est pas encore disponible."
            )
        }
        let trendPhrase = trendLabel(trend)
        return LocalizedString(
            en: "\(body.en) Trend: \(trendPhrase.en).",
            fr: "\(body.fr) Tendance : \(trendPhrase.fr)."
        )
    }

    private static func trendLabel(_ trend: SCITrend) -> LocalizedString {
        switch trend {
        case .improving:
            return LocalizedString(en: "improving", fr: "en amélioration")
        case .stable:
            return LocalizedString(en: "stable", fr: "stable")
        case .declining:
            return LocalizedString(en: "easing", fr: "en baisse")
        }
    }
}
