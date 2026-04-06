import Foundation
#if BONHOMME_ACCEL
import BonhommeAccelSwift
#endif

// MARK: - Types

/// Metric used for outlier detection in population PK analysis.
public enum OutlierMetric: String, Sendable {
    case peakDeltaH
    case onsetTime
    case auc
}

/// CYP2D6 metabolizer phenotype inferred from population PK variability.
public enum MetabolizerPhenotype: String, Sendable {
    case poorMetabolizer
    case normalMetabolizer
    case ultraRapidMetabolizer
}

/// An individual outlier detected in population PK analysis.
public struct OutlierResult: Sendable {
    /// Index of the individual in the input array.
    public let individualIndex: Int
    /// Which metric flagged as outlier.
    public let metric: OutlierMetric
    /// The individual's value for this metric.
    public let value: Double
    /// Z-score (|z| > 2 triggers outlier flag).
    public let zScore: Double
    /// Possible pharmacogenomic explanation (e.g., CYP2D6 poor metabolizer).
    public let possibleExplanation: LocalizedString?

    public init(individualIndex: Int, metric: OutlierMetric, value: Double,
                zScore: Double, possibleExplanation: LocalizedString?) {
        self.individualIndex = individualIndex
        self.metric = metric
        self.value = value
        self.zScore = zScore
        self.possibleExplanation = possibleExplanation
    }
}

/// Population-level PK variability analysis result.
public struct PopulationPKResult: Sendable {
    /// Substance/medication identifier.
    public let substanceId: String
    /// Number of individuals analyzed.
    public let n: Int

    // Peak ΔH statistics
    public let meanPeakDeltaH: Double
    public let sdPeakDeltaH: Double
    public let cvPeakDeltaH: Double

    // Onset time statistics
    public let meanOnsetMinutes: Double?
    public let sdOnsetMinutes: Double?
    public let cvOnsetMinutes: Double?

    // AUC statistics
    public let meanAUC: Double
    public let sdAUC: Double
    public let cvAUC: Double

    /// Individuals flagged as outliers (|z| > 2).
    public let outliers: [OutlierResult]

    /// True if any CV > 40%, indicating high inter-individual variability.
    public var isHighVariability: Bool {
        cvPeakDeltaH > 40.0 || cvAUC > 40.0 || (cvOnsetMinutes ?? 0) > 40.0
    }

    /// Bilingual summary.
    public let summary: LocalizedString

    public init(substanceId: String, n: Int,
                meanPeakDeltaH: Double, sdPeakDeltaH: Double, cvPeakDeltaH: Double,
                meanOnsetMinutes: Double?, sdOnsetMinutes: Double?, cvOnsetMinutes: Double?,
                meanAUC: Double, sdAUC: Double, cvAUC: Double,
                outliers: [OutlierResult], summary: LocalizedString) {
        self.substanceId = substanceId
        self.n = n
        self.meanPeakDeltaH = meanPeakDeltaH
        self.sdPeakDeltaH = sdPeakDeltaH
        self.cvPeakDeltaH = cvPeakDeltaH
        self.meanOnsetMinutes = meanOnsetMinutes
        self.sdOnsetMinutes = sdOnsetMinutes
        self.cvOnsetMinutes = cvOnsetMinutes
        self.meanAUC = meanAUC
        self.sdAUC = sdAUC
        self.cvAUC = cvAUC
        self.outliers = outliers
        self.summary = summary
    }
}

/// Result of comparing two population groups (e.g., normal vs poor metabolizers).
public struct PopulationComparisonResult: Sendable {
    public let groupAStats: PopulationPKResult
    public let groupBStats: PopulationPKResult
    /// Difference in mean peak ΔH between groups.
    public let meanDeltaHDifference: Double
    /// Cohen's d effect size.
    public let cohensD: Double
    /// Bilingual summary.
    public let summary: LocalizedString

    public init(groupAStats: PopulationPKResult, groupBStats: PopulationPKResult,
                meanDeltaHDifference: Double, cohensD: Double, summary: LocalizedString) {
        self.groupAStats = groupAStats
        self.groupBStats = groupBStats
        self.meanDeltaHDifference = meanDeltaHDifference
        self.cohensD = cohensD
        self.summary = summary
    }
}

// MARK: - Analyzer

/// Analyzes inter-individual pharmacokinetic variability from population
/// DrugResponseResult data for pharmacovigilance.
///
/// Computes coefficient of variation (CV%) for peak ΔH, onset time, and AUC.
/// Flags outliers using z-score (|z| > 2), and annotates prodrug substances
/// with CYP2D6 metabolizer phenotype hypotheses.
public struct PopulationPKAnalyzer: Sendable {

    public init() {}

    /// Analyze population PK variability from a set of DrugResponseResults.
    ///
    /// All results must share the same medicationId.
    /// - Returns: PopulationPKResult, or nil if fewer than 2 results or mismatched IDs.
    public static func analyze(results: [DrugResponseResult]) -> PopulationPKResult? {
        guard results.count >= 2 else { return nil }

        let medId = results[0].doseEvent.medicationId.lowercased()
        guard results.allSatisfy({ $0.doseEvent.medicationId.lowercased() == medId }) else {
            return nil
        }

        // Extract values
        let peaks = results.map(\.peakDeltaH)
        let aucs = results.map(\.deltaHAUC)
        let onsets = results.compactMap(\.onsetMinutes)

        let peakStats = descriptiveStats(peaks)
        let aucStats = descriptiveStats(aucs)
        let onsetStats = onsets.count >= 2 ? descriptiveStats(onsets) : nil

        // Detect outliers
        var outliers: [OutlierResult] = []
        let isProdrug = ProdrugRelationship.prodrug(for: medId) != nil

        for i in 0..<results.count {
            // Peak ΔH outlier
            if peakStats.sd > 0 {
                let z = (peaks[i] - peakStats.mean) / peakStats.sd
                if abs(z) > 2.0 {
                    let explanation = isProdrug ? metabolizerExplanation(zScore: z, medId: medId) : nil
                    outliers.append(OutlierResult(
                        individualIndex: i, metric: .peakDeltaH,
                        value: peaks[i], zScore: z, possibleExplanation: explanation
                    ))
                }
            }

            // AUC outlier
            if aucStats.sd > 0 {
                let z = (aucs[i] - aucStats.mean) / aucStats.sd
                if abs(z) > 2.0 {
                    let explanation = isProdrug ? metabolizerExplanation(zScore: z, medId: medId) : nil
                    outliers.append(OutlierResult(
                        individualIndex: i, metric: .auc,
                        value: aucs[i], zScore: z, possibleExplanation: explanation
                    ))
                }
            }

            // Onset outlier
            if let os = onsetStats, os.sd > 0, let onset = results[i].onsetMinutes {
                let z = (onset - os.mean) / os.sd
                if abs(z) > 2.0 {
                    outliers.append(OutlierResult(
                        individualIndex: i, metric: .onsetTime,
                        value: onset, zScore: z, possibleExplanation: nil
                    ))
                }
            }
        }

        let cvPeak = peakStats.mean != 0 ? (peakStats.sd / abs(peakStats.mean)) * 100 : 0
        let cvAUC = aucStats.mean != 0 ? (aucStats.sd / abs(aucStats.mean)) * 100 : 0
        let cvOnset = onsetStats.flatMap { s in s.mean != 0 ? (s.sd / abs(s.mean)) * 100 : 0 }

        let n = results.count
        let highVar = cvPeak > 40.0 || cvAUC > 40.0 || (cvOnset ?? 0) > 40.0

        return PopulationPKResult(
            substanceId: medId,
            n: n,
            meanPeakDeltaH: peakStats.mean,
            sdPeakDeltaH: peakStats.sd,
            cvPeakDeltaH: cvPeak,
            meanOnsetMinutes: onsetStats?.mean,
            sdOnsetMinutes: onsetStats?.sd,
            cvOnsetMinutes: cvOnset,
            meanAUC: aucStats.mean,
            sdAUC: aucStats.sd,
            cvAUC: cvAUC,
            outliers: outliers,
            summary: LocalizedString(
                en: "\(medId) population PK (n=\(n)): CV(peak)=\(String(format: "%.0f", cvPeak))%, CV(AUC)=\(String(format: "%.0f", cvAUC))%. \(outliers.count) outlier(s).\(highVar ? " HIGH VARIABILITY." : "")",
                fr: "\(medId) PK population (n=\(n)) : CV(pic)=\(String(format: "%.0f", cvPeak))%, CV(ASC)=\(String(format: "%.0f", cvAUC))%. \(outliers.count) valeur(s) aberrante(s).\(highVar ? " FORTE VARIABILITÉ." : "")",
                es: "\(medId) PK poblacional (n=\(n)): CV(pico)=\(String(format: "%.0f", cvPeak))%, CV(AUC)=\(String(format: "%.0f", cvAUC))%. \(outliers.count) valor(es) atípico(s).\(highVar ? " ALTA VARIABILIDAD." : "")",
                ja: "\(medId) 母集団PK (n=\(n)): CV(ピーク)=\(String(format: "%.0f", cvPeak))%, CV(AUC)=\(String(format: "%.0f", cvAUC))%. \(outliers.count)件の外れ値。\(highVar ? " 高変動性。" : "")",
                zh: "\(medId) 群体PK (n=\(n))：CV(峰值)=\(String(format: "%.0f", cvPeak))%，CV(AUC)=\(String(format: "%.0f", cvAUC))%。\(outliers.count)个异常值。\(highVar ? " 高变异性。" : "")",
                ko: "\(medId) 모집단 PK (n=\(n)): CV(피크)=\(String(format: "%.0f", cvPeak))%, CV(AUC)=\(String(format: "%.0f", cvAUC))%. \(outliers.count)개 이상치.\(highVar ? " 높은 변동성." : "")",
                ru: "\(medId) популяционная ФК (n=\(n)): КВ(пик)=\(String(format: "%.0f", cvPeak))%, КВ(AUC)=\(String(format: "%.0f", cvAUC))%. \(outliers.count) выброс(ов).\(highVar ? " ВЫСОКАЯ ВАРИАБЕЛЬНОСТЬ." : "")",
                de: "\(medId) Populations-PK (n=\(n)): VK(Peak)=\(String(format: "%.0f", cvPeak))%, VK(AUC)=\(String(format: "%.0f", cvAUC))%. \(outliers.count) Ausreißer.\(highVar ? " HOHE VARIABILITÄT." : "")",
                ar: "\(medId) حركية دوائية سكانية (n=\(n)): CV(الذروة)=\(String(format: "%.0f", cvPeak))%، CV(AUC)=\(String(format: "%.0f", cvAUC))%. \(outliers.count) قيمة شاذة.\(highVar ? " تباين عالٍ." : "")"
            )
        )
    }

    /// Detect metabolizer phenotype for a single individual relative to population stats.
    ///
    /// Only applies to prodrug substances (CYP2D6-metabolized).
    /// - Returns: Phenotype, or nil if not a prodrug or insufficient data.
    public static func detectMetabolizerPhenotype(
        result: DrugResponseResult,
        populationMean: Double,
        populationSD: Double
    ) -> MetabolizerPhenotype? {
        let medId = result.doseEvent.medicationId.lowercased()
        guard ProdrugRelationship.prodrug(for: medId) != nil else { return nil }
        guard populationSD > 0 else { return nil }

        let z = (result.peakDeltaH - populationMean) / populationSD
        if z < -1.5 {
            return .poorMetabolizer
        } else if z > 1.5 {
            return .ultraRapidMetabolizer
        } else {
            return .normalMetabolizer
        }
    }

    /// Compare two population groups (e.g., phenotype subgroups).
    public static func comparePopulations(
        groupA: [DrugResponseResult],
        groupB: [DrugResponseResult]
    ) -> PopulationComparisonResult? {
        guard let statsA = analyze(results: groupA),
              let statsB = analyze(results: groupB) else { return nil }

        let diff = statsA.meanPeakDeltaH - statsB.meanPeakDeltaH
        let pooledSD = sqrt((statsA.sdPeakDeltaH * statsA.sdPeakDeltaH +
                             statsB.sdPeakDeltaH * statsB.sdPeakDeltaH) / 2.0)
        let d = pooledSD > 0 ? diff / pooledSD : 0.0

        let diffText = String(format: "%.3f", diff)
        let dText = String(format: "%.2f", d)
        return PopulationComparisonResult(
            groupAStats: statsA,
            groupBStats: statsB,
            meanDeltaHDifference: diff,
            cohensD: d,
            summary: LocalizedString(
                en: "Group comparison: Δ(mean peak ΔH) = \(diffText), Cohen's d = \(dText).",
                fr: "Comparaison de groupes : Δ(pic moyen ΔH) = \(diffText), d de Cohen = \(dText).",
                es: "Comparación de grupos: Δ(pico medio ΔH) = \(diffText), d de Cohen = \(dText).",
                ja: "グループ比較: Δ(平均ピークΔH) = \(diffText), コーエンのd = \(dText).",
                zh: "组间比较：Δ(平均峰值ΔH) = \(diffText)，Cohen's d = \(dText)。",
                ko: "그룹 비교: Δ(평균 피크 ΔH) = \(diffText), 코헨의 d = \(dText).",
                ru: "Сравнение групп: Δ(средний пик ΔH) = \(diffText), d Коэна = \(dText).",
                de: "Gruppenvergleich: Δ(mittlerer Peak ΔH) = \(diffText), Cohens d = \(dText).",
                ar: "مقارنة المجموعات: Δ(متوسط ذروة ΔH) = \(diffText)، d لكوهين = \(dText)."
            )
        )
    }

    // MARK: - Private

    private static func descriptiveStats(_ values: [Double]) -> (mean: Double, sd: Double) {
        #if BONHOMME_ACCEL
        if let result = AccelStatistics.descriptiveStats(values) {
            return result
        }
        #endif

        let n = Double(values.count)
        guard n >= 1 else { return (0, 0) }
        let mean = values.reduce(0, +) / n
        guard n >= 2 else { return (mean, 0) }
        let variance = values.reduce(0.0) { $0 + ($1 - mean) * ($1 - mean) } / (n - 1)
        return (mean, sqrt(variance))
    }

    private static func metabolizerExplanation(zScore: Double, medId: String) -> LocalizedString {
        let enzyme = ProdrugRelationship.prodrug(for: medId)?.activatingEnzyme ?? "CYP2D6"
        if zScore < -1.5 {
            return LocalizedString(
                en: "Low response — possible \(enzyme) poor metabolizer",
                fr: "Réponse faible — possible métaboliseur lent \(enzyme)",
                es: "Respuesta baja — posible metabolizador lento \(enzyme)",
                ja: "低反応 — \(enzyme)低代謝型の可能性",
                zh: "低反应 — 可能为\(enzyme)慢代谢者",
                ko: "낮은 반응 — \(enzyme) 저대사자 가능성",
                ru: "Низкий ответ — возможный медленный метаболизатор \(enzyme)",
                de: "Niedrige Reaktion — möglicher \(enzyme)-Langsammetabolisierer",
                ar: "استجابة منخفضة — محتمل أيض بطيء \(enzyme)"
            )
        } else if zScore > 1.5 {
            return LocalizedString(
                en: "High response — possible \(enzyme) ultra-rapid metabolizer",
                fr: "Réponse élevée — possible métaboliseur ultra-rapide \(enzyme)",
                es: "Respuesta alta — posible metabolizador ultrarrápido \(enzyme)",
                ja: "高反応 — \(enzyme)超高速代謝型の可能性",
                zh: "高反应 — 可能为\(enzyme)超快代谢者",
                ko: "높은 반응 — \(enzyme) 초고속 대사자 가능성",
                ru: "Высокий ответ — возможный сверхбыстрый метаболизатор \(enzyme)",
                de: "Hohe Reaktion — möglicher \(enzyme)-Ultraschnellmetabolisierer",
                ar: "استجابة عالية — محتمل أيض فائق السرعة \(enzyme)"
            )
        } else {
            return LocalizedString(
                en: "Normal \(enzyme) metabolism expected",
                fr: "Métabolisme \(enzyme) normal attendu",
                es: "Metabolismo \(enzyme) normal esperado",
                ja: "\(enzyme)正常代謝が想定される",
                zh: "预期\(enzyme)正常代谢",
                ko: "정상 \(enzyme) 대사 예상",
                ru: "Ожидается нормальный метаболизм \(enzyme)",
                de: "Normaler \(enzyme)-Metabolismus erwartet",
                ar: "متوقع أيض \(enzyme) طبيعي"
            )
        }
    }
}
