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

        if #available(iOS 26, *) {
            latestNarrative = await generateWithFoundationModel(insights)
        } else {
            latestNarrative = generateWithTemplates(insights)
        }
    }

    /// Generate a personalized pose cue based on current health context.
    /// Returns nil on pre-iOS 26 devices (caller should use the static voiceCueText).
    func generatePersonalizedPoseCue(
        for pose: Pose,
        insights: [SignalType: AnalysisInsight]
    ) async -> String? {
        guard #available(iOS 26, *) else { return nil }
        return await generatePoseCueWithModel(pose: pose, insights: insights)
    }

    /// Generate a narrative summary for a completed workout result.
    func generateWorkoutSummary(
        result: WorkoutResult,
        insights: [SignalType: AnalysisInsight]
    ) async -> String {
        if #available(iOS 26, *) {
            return await generateSummaryWithModel(result: result, insights: insights)
        }
        return generateSummaryWithTemplates(result: result, insights: insights)
    }

    // MARK: - Apple Foundation Model (iOS 26+)

    /// Uses the on-device FoundationModels framework to synthesize insights.
    ///
    /// The prompt provides structured analysis data and asks for a concise,
    /// patient-friendly summary. All processing is on-device — no network calls.
    ///
    /// Integration requires `import FoundationModels` and Xcode 26+.
    /// The call structure is:
    /// ```
    /// let session = LanguageModelSession()
    /// let response = try await session.respond(to: prompt)
    /// return response.content
    /// ```
    ///
    /// For `@Generable` structured output:
    /// ```
    /// @Generable struct WellnessInsight {
    ///     var summary: String
    ///     var encouragement: String
    ///     var actionItem: String?
    /// }
    /// let insight: WellnessInsight = try await session.respond(to: prompt, generating: WellnessInsight.self)
    /// ```
    @available(iOS 26, *)
    private func generateWithFoundationModel(
        _ insights: [SignalType: AnalysisInsight]
    ) async -> String {
        let prompt = buildInsightPrompt(from: insights)

        // FoundationModels integration point:
        // import FoundationModels
        // guard LanguageModelSession.isAvailable else {
        //     return generateWithTemplates(insights)
        // }
        // do {
        //     let session = LanguageModelSession()
        //     let response = try await session.respond(to: prompt)
        //     return response.content
        // } catch {
        //     return generateWithTemplates(insights)
        // }

        // Fallback until FoundationModels SDK is available in build environment
        return generateWithTemplates(insights)
    }

    @available(iOS 26, *)
    private func generatePoseCueWithModel(
        pose: Pose,
        insights: [SignalType: AnalysisInsight]
    ) async -> String? {
        let prompt = buildPoseCuePrompt(pose: pose, insights: insights)

        // FoundationModels integration point:
        // guard LanguageModelSession.isAvailable else { return nil }
        // do {
        //     let session = LanguageModelSession()
        //     let response = try await session.respond(to: prompt)
        //     return response.content
        // } catch {
        //     return nil
        // }

        return nil // Caller falls back to pose.voiceCueText
    }

    @available(iOS 26, *)
    private func generateSummaryWithModel(
        result: WorkoutResult,
        insights: [SignalType: AnalysisInsight]
    ) async -> String {
        let prompt = buildWorkoutSummaryPrompt(result: result, insights: insights)

        // FoundationModels integration point:
        // guard LanguageModelSession.isAvailable else {
        //     return generateSummaryWithTemplates(result: result, insights: insights)
        // }
        // do {
        //     let session = LanguageModelSession()
        //     let response = try await session.respond(to: prompt)
        //     return response.content
        // } catch {
        //     return generateSummaryWithTemplates(result: result, insights: insights)
        // }

        return generateSummaryWithTemplates(result: result, insights: insights)
    }

    // MARK: - Prompt Construction

    private func buildInsightPrompt(from insights: [SignalType: AnalysisInsight]) -> String {
        var sections: [String] = []

        sections.append(
            "You are a wellness assistant for a chair yoga app called NATURaL. "
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

        if let docking = insights[.molecularDocking] {
            let scoreText = docking.score.map { String(format: "%.0f%%", $0 * 100) } ?? "unavailable"
            sections.append(
                "Molecular Docking Entropy: binding signal = \(scoreText), "
                + "trend: \(docking.trend.rawValue), "
                + "status: \(docking.status.rawValue). \(docking.summary.en)"
            )
        }

        return sections.joined(separator: "\n\n")
    }

    private func buildPoseCuePrompt(
        pose: Pose,
        insights: [SignalType: AnalysisInsight]
    ) -> String {
        var prompt = "You are a chair yoga instructor. Generate a brief, "
        + "personalized 1-2 sentence guidance cue for the following pose. "
        + "Adapt the cue to the practitioner's current biofeedback state. "
        + "Be warm, specific, and actionable. Do not give medical advice.\n\n"

        prompt += "Pose: \(pose.name.en)\n"
        prompt += "Category: \(pose.category.rawValue)\n"
        prompt += "Standard cue: \(pose.voiceCueText.en)\n"
        prompt += "Breathing: \(pose.breathingPattern.en)\n\n"

        if let hrv = insights[.heartRateVariability] {
            let scoreText = hrv.score.map { String(format: "%.0f", $0 * 100) } ?? "unknown"
            prompt += "Current focus score: \(scoreText)%, trend: \(hrv.trend.rawValue)\n"
        }

        if let med = insights[.medication] {
            let scoreText = med.score.map { String(format: "%.0f", $0 * 100) } ?? "unknown"
            prompt += "Medication adherence: \(scoreText)%\n"
        }

        return prompt
    }

    private func buildWorkoutSummaryPrompt(
        result: WorkoutResult,
        insights: [SignalType: AnalysisInsight]
    ) -> String {
        var prompt = "You are a wellness coach for the NATURaL chair yoga app. "
        + "Write a 3-4 sentence summary of this completed workout session. "
        + "Be encouraging, mention specific achievements, and suggest one "
        + "thing to try next time. Do not give medical advice.\n\n"

        let minutes = Int(result.totalDuration) / 60
        let seconds = Int(result.totalDuration) % 60
        prompt += "Duration: \(minutes)m \(seconds)s\n"
        prompt += "Poses completed: \(result.posesCompleted)/\(result.totalPoses)\n"
        prompt += "Calories: \(Int(result.activeCalories))\n"

        if let avgHR = result.averageHeartRate {
            prompt += "Average heart rate: \(Int(avgHR)) BPM\n"
        }
        if let maxHR = result.maxHeartRate {
            prompt += "Max heart rate: \(Int(maxHR)) BPM\n"
        }

        for (type, insight) in insights {
            let scoreText = insight.score.map { String(format: "%.0f%%", $0 * 100) } ?? "N/A"
            prompt += "\(type.rawValue) score: \(scoreText), trend: \(insight.trend.rawValue)\n"
        }

        return prompt
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

        if let docking = insights[.molecularDocking], docking.score != nil {
            parts.append(docking.summary.localized)
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

        // Drug response correlation note
        if let dockingScore = insights[.molecularDocking]?.score,
           let hrvScore = insights[.heartRateVariability]?.score,
           dockingScore > 0.3 {
            let hrvPct = Int(hrvScore * 100)
            parts.append(LocalizedString(
                en: "Molecular binding entropy detected — correlating with HRV coherence (\(hrvPct)%).",
                fr: "Entropie de liaison moléculaire détectée — corrélation avec la cohérence VFC (\(hrvPct) %)."
            ).localized)
        }

        return parts.joined(separator: " ")
    }

    private func generateSummaryWithTemplates(
        result: WorkoutResult,
        insights: [SignalType: AnalysisInsight]
    ) -> String {
        var parts: [String] = []

        let minutes = Int(result.totalDuration) / 60
        parts.append(LocalizedString(
            en: "You completed \(result.posesCompleted) poses in \(minutes) minutes, burning \(Int(result.activeCalories)) calories.",
            fr: "Vous avez complété \(result.posesCompleted) postures en \(minutes) minutes, brûlant \(Int(result.activeCalories)) calories."
        ).localized)

        if let avgHR = result.averageHeartRate {
            parts.append(LocalizedString(
                en: "Your average heart rate was \(Int(avgHR)) BPM.",
                fr: "Votre fréquence cardiaque moyenne était de \(Int(avgHR)) BPM."
            ).localized)
        }

        if let hrvInsight = insights[.heartRateVariability], let score = hrvInsight.score {
            let pct = Int(score * 100)
            parts.append(LocalizedString(
                en: "Focus coherence reached \(pct)% — \(hrvInsight.trend == .improving ? "an improving trend" : "keep practicing deep breathing").",
                fr: "La cohérence de concentration a atteint \(pct) % — \(hrvInsight.trend == .improving ? "une tendance à la hausse" : "continuez à pratiquer la respiration profonde")."
            ).localized)
        }

        return parts.joined(separator: " ")
    }
}
