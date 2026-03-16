import Foundation

/// Analyzes medication adherence patterns and flags timing concerns.
///
/// Tracks dose events (taken, missed, skipped, late) over a rolling window
/// and computes an adherence score. Cross-references HRV context to detect
/// potential physiological responses to medication timing.
public struct MedicationAnalyzer: SignalAnalyzer, Sendable {
    public let primarySignalType: SignalType = .medication

    /// Rolling window for adherence calculation.
    private let windowDays: Int

    public init(windowDays: Int = 7) {
        self.windowDays = windowDays
    }

    public func analyze(
        signals: [any HealthSignal],
        context: AnalysisContext
    ) -> AnalysisInsight {
        let medSignals = signals.compactMap { $0 as? MedicationSignal }

        guard !medSignals.isEmpty else {
            return AnalysisInsight(
                signalType: .medication,
                score: nil,
                trend: .stable,
                status: .normal,
                summary: LocalizedString(
                    en: "No medication data recorded.",
                    fr: "Aucune donnée de médicament enregistrée.",
                    es: "No se han registrado datos de medicación.",
                    ja: "服薬データが記録されていません。",
                    zh: "尚未记录用药数据。",
                    ko: "기록된 투약 데이터가 없습니다.",
                    ru: "Данные о приёме лекарств не зарегистрированы.",
                    de: "Keine Medikamentendaten erfasst.",
                    ar: "لم يتم تسجيل بيانات الأدوية."
                )
            )
        }

        let cutoff = Calendar.current.date(
            byAdding: .day,
            value: -windowDays,
            to: Date()
        )!
        let windowedSignals = medSignals.filter { $0.timestamp >= cutoff }

        let adherence = computeAdherence(windowedSignals)
        let trend = computeTrend(windowedSignals)
        let status = adherenceStatus(adherence)
        let missedNames = recentMissedMedications(windowedSignals)
        let hrvCorrelation = hrvCorrelationNote(context: context, medSignals: windowedSignals)

        let pct = String(format: "%.0f", adherence * 100)
        var enSummary = "\(windowDays)-day adherence: \(pct)%."
        var frSummary = "Adhérence sur \(windowDays) jours : \(pct) %."

        if !missedNames.isEmpty {
            let names = missedNames.joined(separator: ", ")
            enSummary += " Missed: \(names)."
            frSummary += " Manqué : \(names)."
        }

        enSummary += hrvCorrelation
        frSummary += hrvCorrelation

        return AnalysisInsight(
            signalType: .medication,
            score: adherence,
            trend: trend,
            status: status,
            summary: LocalizedString(
                en: enSummary,
                fr: frSummary,
                es: "Adherencia de \(windowDays) días: \(pct) %." + (!missedNames.isEmpty ? " Omitidos: \(missedNames.joined(separator: ", "))." : "") + hrvCorrelation,
                ja: "\(windowDays)日間の服薬遵守率：\(pct)%。" + (!missedNames.isEmpty ? " 未服用：\(missedNames.joined(separator: "、"))。" : "") + hrvCorrelation,
                zh: "\(windowDays)天服药依从性：\(pct)%。" + (!missedNames.isEmpty ? " 漏服：\(missedNames.joined(separator: "、"))。" : "") + hrvCorrelation,
                ko: "\(windowDays)일 복약 순응도: \(pct)%." + (!missedNames.isEmpty ? " 누락: \(missedNames.joined(separator: ", "))." : "") + hrvCorrelation,
                ru: "Приверженность за \(windowDays) дней: \(pct) %." + (!missedNames.isEmpty ? " Пропущено: \(missedNames.joined(separator: ", "))." : "") + hrvCorrelation,
                de: "Adhärenz über \(windowDays) Tage: \(pct) %." + (!missedNames.isEmpty ? " Verpasst: \(missedNames.joined(separator: ", "))." : "") + hrvCorrelation,
                ar: "الالتزام خلال \(windowDays) أيام: \(pct)٪." + (!missedNames.isEmpty ? " فائت: \(missedNames.joined(separator: "، "))." : "") + hrvCorrelation
            )
        )
    }

    // MARK: - Adherence Calculation

    /// Adherence = taken / (taken + missed + late). Skipped events are excluded
    /// (intentional skip is not non-adherence).
    private func computeAdherence(_ signals: [MedicationSignal]) -> Double {
        let taken = signals.filter { $0.event == .taken }.count
        let late = signals.filter { $0.event == .late }.count
        let missed = signals.filter { $0.event == .missed }.count

        let total = taken + late + missed
        guard total > 0 else { return 1.0 }

        // Late doses count as 50% adherence (dose received but timing off).
        return (Double(taken) + Double(late) * 0.5) / Double(total)
    }

    private func computeTrend(_ signals: [MedicationSignal]) -> InsightTrend {
        guard signals.count >= 4 else { return .stable }

        let mid = signals.count / 2
        let firstHalf = Array(signals[..<mid])
        let secondHalf = Array(signals[mid...])

        let firstAdherence = computeAdherence(firstHalf)
        let secondAdherence = computeAdherence(secondHalf)
        let delta = secondAdherence - firstAdherence

        if delta > 0.1 { return .improving }
        if delta < -0.1 { return .declining }
        return .stable
    }

    private func adherenceStatus(_ adherence: Double) -> InsightStatus {
        switch adherence {
        case 0.8...: return .normal
        case 0.5...: return .advisory
        default: return .alert
        }
    }

    /// Names of medications missed in the last 24 hours.
    private func recentMissedMedications(_ signals: [MedicationSignal]) -> [String] {
        let dayAgo = Date().addingTimeInterval(-86400)
        let missed = signals.filter { $0.event == .missed && $0.timestamp >= dayAgo }
        let uniqueNames = Set(missed.map { $0.name.localized })
        return Array(uniqueNames).sorted()
    }

    /// If HRV data is available, note whether a recent dose correlated with HRV changes.
    private func hrvCorrelationNote(
        context: AnalysisContext,
        medSignals: [MedicationSignal]
    ) -> String {
        guard let hrvInsight = context.priorInsights[.heartRateVariability],
              let hrvScore = hrvInsight.score,
              let lastDose = medSignals.last(where: { $0.event == .taken }) else {
            return ""
        }

        let timeSinceDose = Date().timeIntervalSince(lastDose.timestamp)
        guard timeSinceDose < 7200 else { return "" } // 2-hour window

        if hrvInsight.trend == .improving && hrvScore > 0.6 {
            return " HRV improved following recent dose."
        } else if hrvInsight.trend == .declining && hrvScore < 0.3 {
            return " HRV declined after recent dose — monitor."
        }
        return ""
    }
}
