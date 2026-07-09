import Foundation

/// SignalAnalyzer adapter that feeds FlexAID∆S docking insights into FeedbackEngine.
///
/// Receives `DockingSignal` instances (summaries of docking runs) and produces
/// `AnalysisInsight` with ΔS_config information. Cross-references medication context
/// from `AnalysisContext` to correlate in-silico predictions with in-vivo observations.
///
/// Registration:
/// ```swift
/// let engine = FeedbackEngine()
/// engine.register(DockingInsightAnalyzer())
/// engine.ingest(DockingSignal(...))
/// let insights = engine.analyzeAll()
/// // insights[.molecularDocking] contains ΔS summary
/// ```
public struct DockingInsightAnalyzer: SignalAnalyzer, Sendable {
    public let primarySignalType: SignalType = .molecularDocking

    private let dockingAnalyzer: FlexAIDdSAnalyzer
    private let configuration: AnalysisConfiguration

    public init(binCount: Int = 32) {
        self.dockingAnalyzer = FlexAIDdSAnalyzer(binCount: binCount)
        self.configuration = .default
    }

    public init(configuration: AnalysisConfiguration) {
        self.dockingAnalyzer = FlexAIDdSAnalyzer(configuration: configuration)
        self.configuration = configuration
    }

    public func analyze(
        signals: [any HealthSignal],
        context: AnalysisContext
    ) -> AnalysisInsight {
        let dockingSignals = signals.compactMap { $0 as? DockingSignal }

        guard !dockingSignals.isEmpty else {
            return AnalysisInsight(
                signalType: .molecularDocking,
                score: nil,
                trend: .stable,
                status: .normal,
                summary: LocalizedString(
                    en: "No molecular docking data available.",
                    fr: "Aucune donnée d'amarrage moléculaire disponible.",
                    es: "No hay datos de acoplamiento molecular disponibles.",
                    ja: "分子ドッキングデータがありません。",
                    zh: "无分子对接数据。",
                    ko: "분자 도킹 데이터가 없습니다.",
                    ru: "Данные молекулярного докинга недоступны.",
                    de: "Keine molekularen Docking-Daten verfügbar.",
                    ar: "لا تتوفر بيانات الالتحام الجزيئي."
                )
            )
        }

        // Use the most recent docking signal (O(n) instead of O(n log n) sort)
        guard let latest = dockingSignals.max(by: { $0.timestamp < $1.timestamp }) else {
            return AnalysisInsight(
                signalType: .molecularDocking,
                score: nil,
                trend: .stable,
                status: .normal,
                summary: LocalizedString(
                    en: "No molecular docking data available.",
                    fr: "Aucune donnée de docking moléculaire disponible.",
                    es: "No hay datos de acoplamiento molecular disponibles.",
                    ja: "分子ドッキングデータがありません。",
                    zh: "无分子对接数据。",
                    ko: "분자 도킹 데이터가 없습니다.",
                    ru: "Данные молекулярного докинга недоступны.",
                    de: "Keine molekularen Docking-Daten verfügbar.",
                    ar: "لا تتوفر بيانات الالتحام الجزيئي."
                )
            )
        }
        let deltaSConfig = latest.deltaSConfig

        // Normalize to a 0–1 score: larger |ΔS| = stronger binding signal
        let score = min(1.0, abs(deltaSConfig) / configuration.dockingNormalizationMax)

        let trend = computeTrend(signals: dockingSignals)

        // Status based on binding entropy magnitude
        let status: InsightStatus
        if abs(deltaSConfig) > configuration.dockingAlertThreshold {
            status = .alert       // Very strong binding entropy penalty
        } else if abs(deltaSConfig) > configuration.dockingAdvisoryThreshold {
            status = .advisory    // Moderate binding
        } else {
            status = .normal
        }

        // Cross-reference with medication context
        let medNote = medicationCrossReference(
            substanceId: latest.substanceId,
            context: context
        )

        let deltaText = String(format: "%.2f", deltaSConfig)
        let penaltyKcal = dockingAnalyzer.entropyPenaltyKcal(deltaSBits: deltaSConfig)
        let kcalText = String(format: "%.1f", penaltyKcal)
        let bondText = "\(latest.rotatableBondCount)"

        return AnalysisInsight(
            signalType: .molecularDocking,
            score: score,
            trend: trend,
            status: status,
            summary: LocalizedString(
                en: "Binding entropy: ΔS = \(deltaText) bits (-TΔS = \(kcalText) kcal/mol). \(bondText) rotatable bonds analyzed for \(latest.substanceName.en).\(medNote)",
                fr: "Entropie de liaison : ΔS = \(deltaText) bits (-TΔS = \(kcalText) kcal/mol). \(bondText) liaisons rotatives analysées pour \(latest.substanceName.fr).\(medNote)",
                es: "Entropía de unión: ΔS = \(deltaText) bits (-TΔS = \(kcalText) kcal/mol). \(bondText) enlaces rotables analizados para \(latest.substanceName.en).\(medNote)",
                ja: "結合エントロピー：ΔS = \(deltaText) ビット（-TΔS = \(kcalText) kcal/mol）。\(latest.substanceName.en) の回転可能結合 \(bondText) 本を解析。\(medNote)",
                zh: "结合熵：ΔS = \(deltaText) 比特（-TΔS = \(kcalText) kcal/mol）。已分析 \(latest.substanceName.en) 的 \(bondText) 个可旋转键。\(medNote)",
                ko: "결합 엔트로피: ΔS = \(deltaText) 비트 (-TΔS = \(kcalText) kcal/mol). \(latest.substanceName.en)의 회전 가능 결합 \(bondText)개 분석.\(medNote)",
                ru: "Энтропия связывания: ΔS = \(deltaText) бит (-TΔS = \(kcalText) ккал/моль). Проанализировано \(bondText) вращаемых связей для \(latest.substanceName.en).\(medNote)",
                de: "Bindungsentropie: ΔS = \(deltaText) Bits (-TΔS = \(kcalText) kcal/mol). \(bondText) drehbare Bindungen analysiert für \(latest.substanceName.en).\(medNote)",
                ar: "إنتروبيا الارتباط: ΔS = \(deltaText) بت (-TΔS = \(kcalText) kcal/mol). تم تحليل \(bondText) روابط قابلة للدوران لـ \(latest.substanceName.en).\(medNote)"
            )
        )
    }

    // MARK: - Trend Detection

    /// Compare first vs second half of docking signals by |ΔS|.
    /// Increasing |ΔS| = declining (stronger binding penalty over time).
    private func computeTrend(signals: [DockingSignal]) -> InsightTrend {
        guard signals.count >= 4 else { return .stable }

        let sorted = signals.sorted { $0.timestamp < $1.timestamp }
        let mid = sorted.count / 2
        let firstHalf = sorted[..<mid].map { abs($0.deltaSConfig) }
        let secondHalf = sorted[mid...].map { abs($0.deltaSConfig) }

        let avgFirst = firstHalf.reduce(0, +) / Double(firstHalf.count)
        let avgSecond = secondHalf.reduce(0, +) / Double(secondHalf.count)
        let delta = avgSecond - avgFirst

        if delta > configuration.dockingTrendThreshold { return .declining }   // Increasing entropy penalty
        if delta < -configuration.dockingTrendThreshold { return .improving }  // Decreasing entropy penalty
        return .stable
    }

    // MARK: - Cross-Signal Correlation

    /// Cross-reference docking results with medication and HRV context.
    private func medicationCrossReference(
        substanceId: String,
        context: AnalysisContext
    ) -> String {
        guard let medSignals = context.signalsByType[.medication] else { return "" }

        let matchingMeds = medSignals.compactMap { $0 as? MedicationSignal }
            .filter { $0.medicationId == substanceId && $0.event == .taken }

        guard let latestMed = matchingMeds.last else { return "" }

        if let hrvInsight = context.priorInsights[.heartRateVariability],
           let hrvScore = hrvInsight.score {
            let scoreText = String(format: "%.0f", hrvScore * 100)
            return " Correlating with \(latestMed.name.localized) dose — HRV coherence: \(scoreText)%."
        }

        return " \(latestMed.name.localized) dose recorded; awaiting HRV correlation."
    }
}
