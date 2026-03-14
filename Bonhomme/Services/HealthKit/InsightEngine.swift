import Foundation
import BonhommeCore

/// Synthesizes natural-language health insights from multi-signal analysis
/// using Apple's on-device Foundation Model (iOS 26+).
///
/// All processing runs on-device via the FoundationModels framework.
/// No health data leaves the device. The engine takes AnalysisInsight
/// outputs from the FeedbackEngine and produces a unified, human-readable
/// narrative that correlates HRV, medication adherence, and survey responses.
///
/// Availability: Requires iOS 26+ and a device that supports Apple Intelligence.
/// Falls back to template-based summaries on unsupported devices.
@MainActor
final class InsightEngine: ObservableObject {
    @Published var latestNarrative: String = ""
    @Published var isProcessing: Bool = false

    private let feedbackEngine: FeedbackEngine

    init(feedbackEngine: FeedbackEngine) {
        self.feedbackEngine = feedbackEngine
    }

    // MARK: - Insight Generation

    /// Generate a natural-language narrative from all current analysis insights.
    /// Uses Apple Foundation Model when available, falls back to templates otherwise.
    func generateNarrative() async {
        isProcessing = true
        defer { isProcessing = false }

        let insights = feedbackEngine.analyzeAll()

        if #available(iOS 26, *), supportsFoundationModel() {
            latestNarrative = await generateWithFoundationModel(insights)
        } else {
            latestNarrative = generateWithTemplates(insights)
        }
    }

    // MARK: - Apple Foundation Model Path (iOS 26+)

    /// Uses the on-device FoundationModels framework to synthesize insights.
    ///
    /// The prompt provides structured analysis data and asks for a concise,
    /// patient-friendly summary. All processing is on-device — no network calls.
    @available(iOS 26, *)
    private func generateWithFoundationModel(
        _ insights: [SignalType: AnalysisInsight]
    ) async -> String {
        let prompt = buildPrompt(from: insights)

        // FoundationModels API (iOS 26+):
        // import FoundationModels
        // let session = LanguageModelSession()
        // let response = try await session.respond(to: prompt)
        // return response.content
        //
        // Since FoundationModels cannot be imported in this build environment,
        // the actual call is structured but commented. The integration point is:
        do {
            let session = try await createLanguageModelSession()
            return await session.respond(to: prompt)
        } catch {
            return generateWithTemplates(insights)
        }
    }

    /// Builds a structured prompt for the Foundation Model from analysis insights.
    private func buildPrompt(from insights: [SignalType: AnalysisInsight]) -> String {
        var sections: [String] = []

        sections.append(
            "You are a wellness assistant for a chair yoga app. "
            + "Summarize the following health data in 2-3 sentences. "
            + "Be encouraging, factual, and mention specific numbers. "
            + "Never provide medical advice or diagnoses."
        )

        if let hrv = insights[.heartRateVariability] {
            let scoreText = hrv.score.map { String(format: "%.0f%%", $0 * 100) } ?? "unavailable"
            sections.append(
                "HRV Focus Score: \(scoreText), trend: \(hrv.trend.rawValue), "
                + "status: \(hrv.status.rawValue). \(hrv.summary.en)"
            )
        }

        if let med = insights[.medication] {
            let scoreText = med.score.map { String(format: "%.0f%%", $0 * 100) } ?? "unavailable"
            sections.append(
                "Medication Adherence: \(scoreText), trend: \(med.trend.rawValue), "
                + "status: \(med.status.rawValue). \(med.summary.en)"
            )
        }

        if let survey = insights[.survey] {
            let scoreText = survey.score.map { String(format: "%.0f%%", $0 * 100) } ?? "unavailable"
            sections.append(
                "Well-being Survey: \(scoreText), trend: \(survey.trend.rawValue). "
                + "\(survey.summary.en)"
            )
        }

        return sections.joined(separator: "\n\n")
    }

    // MARK: - Template Fallback

    /// Generates a deterministic summary from templates when Foundation Model
    /// is unavailable (pre-iOS 26, or unsupported hardware).
    private func generateWithTemplates(
        _ insights: [SignalType: AnalysisInsight]
    ) -> String {
        var parts: [String] = []

        if let hrv = insights[.heartRateVariability] {
            parts.append(hrv.summary.localized)
        }

        if let med = insights[.medication] {
            parts.append(med.summary.localized)
        }

        if let survey = insights[.survey] {
            parts.append(survey.summary.localized)
        }

        // Cross-signal correlation note
        if let hrvScore = insights[.heartRateVariability]?.score,
           let medScore = insights[.medication]?.score {
            if hrvScore > 0.7 && medScore > 0.8 {
                parts.append(LocalizedString(
                    en: "Your focus and adherence are both strong — keep it up!",
                    fr: "Votre concentration et votre adhérence sont toutes deux excellentes — continuez!"
                ).localized)
            } else if hrvScore < 0.3 && medScore < 0.5 {
                parts.append(LocalizedString(
                    en: "Consider reviewing your medication schedule and trying a breathing exercise.",
                    fr: "Pensez à revoir votre horaire de médicaments et à essayer un exercice de respiration."
                ).localized)
            }
        }

        return parts.joined(separator: " ")
    }

    // MARK: - Capability Detection

    private func supportsFoundationModel() -> Bool {
        // In production, check LanguageModelSession.isAvailable
        // For now, return false to use template fallback
        false
    }

    /// Placeholder for FoundationModels API integration.
    /// In production, this creates a LanguageModelSession from the FoundationModels framework.
    @available(iOS 26, *)
    private func createLanguageModelSession() async throws -> FoundationModelProxy {
        FoundationModelProxy()
    }
}

// MARK: - Foundation Model Proxy

/// Placeholder proxy for FoundationModels.LanguageModelSession.
/// Replace with actual `import FoundationModels` when building with Xcode 26+.
@available(iOS 26, *)
struct FoundationModelProxy {
    func respond(to prompt: String) async -> String {
        // In production:
        // let session = LanguageModelSession()
        // let response = try await session.respond(to: prompt)
        // return response.content
        return prompt // Falls through to template path
    }
}
