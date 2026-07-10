import Foundation
import BonhommeCore

#if canImport(FoundationModels)
import FoundationModels
#endif

/// Synthesizes natural-language health insights from multi-signal analysis
/// using Apple's on-device Foundation Model (iOS 26+).
///
/// **Privacy:** All generation uses `SystemLanguageModel` (on-device Apple Intelligence).
/// No health data is sent to the network by this engine. Cloud / Private Cloud Compute
/// models are intentionally not used.
///
/// Availability: Requires iOS 26+ and a device that supports Apple Intelligence
/// with the model ready. Falls back to template-based summaries and static
/// `pose.voiceCueText` on unsupported OS / hardware / disabled AI.
@MainActor
final class InsightEngine: ObservableObject {
    /// Last multi-signal narrative from `generateNarrative()`.
    @Published var latestNarrative: String = ""
    /// True while a narrative or pose-cue generation call is in flight.
    @Published var isProcessing: Bool = false
    /// Latest resolved pose cue (model or static). Safe to bind in the pose UI.
    @Published private(set) var latestPoseCue: String = ""
    /// Pose id for `latestPoseCue` (used to ignore stale async completions).
    @Published private(set) var latestPoseCuePoseId: String?
    /// True when on-device Foundation Models reported available at last check.
    @Published private(set) var isOnDeviceModelAvailable: Bool = false

    private let feedbackEngine: FeedbackEngine

    /// Per-pose cache of the last successful model (or template) cue this session.
    private var poseCueCache: [String: String] = [:]
    /// In-flight pose generation — cancelled when a new pose starts.
    private var poseCueTask: Task<Void, Never>?

    init(feedbackEngine: FeedbackEngine) {
        self.feedbackEngine = feedbackEngine
        refreshModelAvailability()
    }

    // MARK: - Availability

    /// Re-check on-device model readiness (call on appear / session start).
    func refreshModelAvailability() {
        isOnDeviceModelAvailable = Self.checkOnDeviceModelAvailable()
    }

    /// On-device only — never treats cloud compute as available.
    static func checkOnDeviceModelAvailable() -> Bool {
        #if canImport(FoundationModels)
        if #available(iOS 26.0, *) {
            return SystemLanguageModel.default.isAvailable
        }
        #endif
        return false
    }

    // MARK: - Insight Generation

    /// Generate a natural-language narrative from all current analysis insights.
    /// Uses Apple Foundation Model when available, falls back to templates otherwise.
    func generateNarrative() async {
        isProcessing = true
        defer { isProcessing = false }

        let insights = feedbackEngine.analyzeAll()

        if #available(iOS 26.0, *), Self.checkOnDeviceModelAvailable() {
            latestNarrative = await generateWithFoundationModel(insights)
        } else {
            latestNarrative = generateWithTemplates(insights)
        }
    }

    /// Generate a personalized pose cue based on current health context.
    /// Returns `nil` when the model path is unavailable or fails so callers can
    /// fall back to `pose.voiceCueText` / templates.
    func generatePersonalizedPoseCue(
        for pose: Pose,
        insights: [SignalType: AnalysisInsight],
        heartRate: Double? = nil
    ) async -> String? {
        guard #available(iOS 26.0, *) else { return nil }
        guard Self.checkOnDeviceModelAvailable() else { return nil }
        return await generatePoseCueWithModel(
            pose: pose,
            insights: insights,
            heartRate: heartRate
        )
    }

    /// Always returns a usable cue: model → cache → SCI-aware template → static voice cue.
    func resolvePoseCue(
        for pose: Pose,
        insights: [SignalType: AnalysisInsight],
        heartRate: Double? = nil
    ) async -> String {
        if let cached = poseCueCache[pose.id] {
            return cached
        }

        if let modelCue = await generatePersonalizedPoseCue(
            for: pose,
            insights: insights,
            heartRate: heartRate
        ) {
            let cleaned = Self.sanitizeCue(modelCue)
            if !cleaned.isEmpty {
                poseCueCache[pose.id] = cleaned
                return cleaned
            }
        }

        let template = generatePoseCueWithTemplates(
            pose: pose,
            insights: insights,
            heartRate: heartRate
        )
        poseCueCache[pose.id] = template
        return template
    }

    /// Non-blocking pose cue refresh for the workout timer path.
    ///
    /// Immediately publishes the static / cached cue, then generates in the background
    /// and updates `latestPoseCue` only if the pose is still current. Never blocks the
    /// pose timer — call from `beginPose` via a detached `Task`.
    func refreshPoseCueAsync(
        for pose: Pose,
        insights: [SignalType: AnalysisInsight],
        heartRate: Double? = nil
    ) {
        let poseId = pose.id
        let immediate = poseCueCache[poseId]
            ?? generatePoseCueWithTemplates(pose: pose, insights: insights, heartRate: heartRate)
        latestPoseCue = immediate
        latestPoseCuePoseId = poseId

        // Cache hit — nothing more to do (and do not flip isProcessing).
        if poseCueCache[poseId] != nil {
            return
        }

        poseCueTask?.cancel()
        poseCueTask = Task { [weak self] in
            guard let self else { return }
            self.isProcessing = true
            defer { self.isProcessing = false }

            let resolved = await self.resolvePoseCue(
                for: pose,
                insights: insights,
                heartRate: heartRate
            )
            guard !Task.isCancelled else { return }
            // Ignore stale completions after the user advanced poses.
            guard self.latestPoseCuePoseId == poseId else { return }
            self.latestPoseCue = resolved
        }
    }

    /// Generate a narrative summary for a completed workout result.
    func generateWorkoutSummary(
        result: WorkoutResult,
        insights: [SignalType: AnalysisInsight]
    ) async -> String {
        if #available(iOS 26.0, *), Self.checkOnDeviceModelAvailable() {
            return await generateSummaryWithModel(result: result, insights: insights)
        }
        return generateSummaryWithTemplates(result: result, insights: insights)
    }

    /// Drop per-pose cue cache (call at session end).
    func clearPoseCueCache() {
        poseCueTask?.cancel()
        poseCueTask = nil
        poseCueCache.removeAll(keepingCapacity: false)
        latestPoseCue = ""
        latestPoseCuePoseId = nil
    }

    // MARK: - Apple Foundation Model (iOS 26+)

    /// Uses the on-device FoundationModels framework to synthesize insights.
    ///
    /// The prompt provides structured analysis data and asks for a concise,
    /// patient-friendly summary. All processing is on-device — no network calls.
    @available(iOS 26.0, *)
    private func generateWithFoundationModel(
        _ insights: [SignalType: AnalysisInsight]
    ) async -> String {
        #if canImport(FoundationModels)
        do {
            let session = makeSession(instructions: Self.wellnessInstructions)
            let prompt = buildInsightPrompt(from: insights)
            let options = GenerationOptions(
                samplingMode: nil,
                temperature: 0.4,
                maximumResponseTokens: 160
            )
            let response = try await session.respond(to: prompt, options: options)
            let text = Self.sanitizeCue(response.content)
            return text.isEmpty ? generateWithTemplates(insights) : text
        } catch {
            return generateWithTemplates(insights)
        }
        #else
        return generateWithTemplates(insights)
        #endif
    }

    @available(iOS 26.0, *)
    private func generatePoseCueWithModel(
        pose: Pose,
        insights: [SignalType: AnalysisInsight],
        heartRate: Double?
    ) async -> String? {
        #if canImport(FoundationModels)
        do {
            let session = makeSession(instructions: Self.poseCoachInstructions)
            let prompt = buildPoseCuePrompt(
                pose: pose,
                insights: insights,
                heartRate: heartRate
            )
            let options = GenerationOptions(
                samplingMode: nil,
                temperature: 0.35,
                maximumResponseTokens: 72
            )
            let response = try await session.respond(to: prompt, options: options)
            let text = Self.sanitizeCue(response.content)
            return text.isEmpty ? nil : text
        } catch {
            return nil
        }
        #else
        return nil
        #endif
    }

    @available(iOS 26.0, *)
    private func generateSummaryWithModel(
        result: WorkoutResult,
        insights: [SignalType: AnalysisInsight]
    ) async -> String {
        #if canImport(FoundationModels)
        do {
            let session = makeSession(instructions: Self.wellnessInstructions)
            let prompt = buildWorkoutSummaryPrompt(result: result, insights: insights)
            let options = GenerationOptions(
                samplingMode: nil,
                temperature: 0.4,
                maximumResponseTokens: 200
            )
            let response = try await session.respond(to: prompt, options: options)
            let text = Self.sanitizeCue(response.content)
            return text.isEmpty
                ? generateSummaryWithTemplates(result: result, insights: insights)
                : text
        } catch {
            return generateSummaryWithTemplates(result: result, insights: insights)
        }
        #else
        return generateSummaryWithTemplates(result: result, insights: insights)
        #endif
    }

    #if canImport(FoundationModels)
    @available(iOS 26.0, *)
    private func makeSession(instructions: String) -> LanguageModelSession {
        // Explicit SystemLanguageModel — on-device only (never PrivateCloudCompute).
        let model = SystemLanguageModel.default
        return LanguageModelSession(
            model: model,
            tools: [],
            instructions: instructions
        )
    }
    #endif

    // MARK: - System instructions (on-device)

    private static let wellnessInstructions = """
        You are a wellness assistant for NATURaL, a chair yoga app.
        Summarize health signals in 2–3 short sentences. Be encouraging and factual.
        Mention specific numbers when provided. Never give medical advice or diagnoses.
        Never invent data. Prefer the user's language when specified; otherwise English.
        All data is processed on-device; do not mention cloud services or external servers.
        """

    private static let poseCoachInstructions = """
        You are a chair yoga instructor for the NATURaL app.
        Produce a single brief guidance cue (1–2 short sentences, max ~35 words).
        Adapt to the practitioner's biofeedback (SCI focus, heart rate, trends).
        Be warm, specific, and actionable. No medical advice or diagnoses.
        Prefer the language indicated in the prompt (English or French).
        Do not use markdown, bullet lists, or quotation marks around the whole cue.
        """

    // MARK: - Prompt Construction

    private func preferredLanguageCode() -> String {
        let code = Locale.current.language.languageCode?.identifier ?? "en"
        // Bilingual-safe: FR locales get French cues; everything else English.
        return code.hasPrefix("fr") ? "fr" : "en"
    }

    private func buildInsightPrompt(from insights: [SignalType: AnalysisInsight]) -> String {
        var sections: [String] = []
        let lang = preferredLanguageCode() == "fr" ? "French" : "English"

        sections.append(
            "Write the summary in \(lang). "
            + "You are a wellness assistant for a chair yoga app called NATURaL. "
            + "Summarize the following health data in 2-3 sentences. "
            + "Be encouraging, factual, and mention specific numbers. "
            + "Never provide medical advice or diagnoses. "
            + "Processing is on-device only."
        )

        if let hrv = insights[.heartRateVariability] {
            let scoreText = hrv.score.map { String(format: "%.0f%%", $0 * 100) } ?? "unavailable"
            sections.append(
                "SCI / HRV Focus Score: \(scoreText), trend: \(hrv.trend.rawValue), "
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
        insights: [SignalType: AnalysisInsight],
        heartRate: Double?
    ) -> String {
        let lang = preferredLanguageCode() == "fr" ? "French" : "English"
        var prompt = "Respond in \(lang) only. "
        + "Generate a brief, personalized 1-2 sentence guidance cue for this chair yoga pose. "
        + "Adapt to the practitioner's current biofeedback. "
        + "Be warm, specific, and actionable. Do not give medical advice.\n\n"

        prompt += "Pose: \(pose.name.en)\n"
        prompt += "Category: \(pose.category.rawValue)\n"
        prompt += "Standard cue: \(pose.voiceCueText.en)\n"
        prompt += "Breathing: \(pose.breathingPattern.en)\n"

        if let hr = heartRate {
            prompt += "Current heart rate: \(Int(hr)) BPM\n"
        }

        if let hrv = insights[.heartRateVariability] {
            let scoreText = hrv.score.map { String(format: "%.0f", $0 * 100) } ?? "unknown"
            prompt += "SCI focus score: \(scoreText)%, trend: \(hrv.trend.rawValue), status: \(hrv.status.rawValue)\n"
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
        let lang = preferredLanguageCode() == "fr" ? "French" : "English"
        var prompt = "Write in \(lang). "
        + "You are a wellness coach for the NATURaL chair yoga app. "
        + "Write a 3-4 sentence summary of this completed workout session. "
        + "Be encouraging, mention specific achievements, and suggest one "
        + "thing to try next time. Do not give medical advice. "
        + "Processing is on-device only.\n\n"

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

    /// Deterministic summary when Foundation Model is unavailable.
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

    /// SCI / HR-aware static pose cue when the on-device model is unavailable.
    private func generatePoseCueWithTemplates(
        pose: Pose,
        insights: [SignalType: AnalysisInsight],
        heartRate: Double?
    ) -> String {
        let base = pose.voiceCueText.localized.trimmingCharacters(in: .whitespacesAndNewlines)
        let fallback = base.isEmpty ? pose.breathingPattern.localized : base
        guard !fallback.isEmpty else { return pose.description.localized }

        let sci = insights[.heartRateVariability]?.score
        let trend = insights[.heartRateVariability]?.trend

        if let sci, sci < 0.35 {
            let tip = LocalizedString(
                en: "Soften your breath — focus is low (\(Int(sci * 100))% SCI).",
                fr: "Adoucissez le souffle — concentration basse (\(Int(sci * 100)) % SCI)."
            ).localized
            return "\(fallback) \(tip)"
        }

        if let sci, sci > 0.75, trend == .improving {
            let tip = LocalizedString(
                en: "Strong focus (\(Int(sci * 100))% SCI) — hold with ease.",
                fr: "Belle concentration (\(Int(sci * 100)) % SCI) — maintenez avec aisance."
            ).localized
            return "\(fallback) \(tip)"
        }

        if let hr = heartRate, hr > 120 {
            let tip = LocalizedString(
                en: "Heart rate is elevated (\(Int(hr)) BPM) — ease intensity if needed.",
                fr: "Fréquence élevée (\(Int(hr)) BPM) — allégez si besoin."
            ).localized
            return "\(fallback) \(tip)"
        }

        return fallback
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

    // MARK: - Helpers

    /// Strip wrapping quotes / excess whitespace from model output.
    private static func sanitizeCue(_ raw: String) -> String {
        var text = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        if (text.hasPrefix("\"") && text.hasSuffix("\""))
            || (text.hasPrefix("«") && text.hasSuffix("»"))
            || (text.hasPrefix("'") && text.hasSuffix("'")) {
            text = String(text.dropFirst().dropLast()).trimmingCharacters(in: .whitespacesAndNewlines)
        }
        // Collapse multi-line model chatter into a single spoken cue.
        text = text
            .replacingOccurrences(of: "\n+", with: " ", options: .regularExpression)
            .trimmingCharacters(in: .whitespacesAndNewlines)
        return text
    }
}
