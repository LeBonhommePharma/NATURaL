import SwiftUI
import SwiftData
import Charts
import BonhommeCore

/// Post-workout summary screen mirroring the Apple Fitness+ aesthetic.
/// Shows celebration header, activity rings, stat cards, HR chart, and share card.
/// Persists the workout result to SwiftData and records CareKit completion.
struct SummaryView: View {
    let result: WorkoutResult
    var sciScore: Double? = nil
    var drugResponse: DrugResponseResult? = nil
    let onDismiss: () -> Void

    @Environment(\.modelContext) private var modelContext
    @Environment(AppState.self) private var appState
    @State private var hasPersisted = false
    @State private var ringData: ActivityRingService.RingData?
    @State private var shareCardImage: Data?

    private let ringService = ActivityRingService()

    private var accentColor: Color {
        Color(hue: result.yogaStyle.accentHue, saturation: 0.6, brightness: 0.7)
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                celebrationHeader
                activityRingsCard
                statGrid
                if !result.heartRateSamples.isEmpty {
                    hrChartView
                        .padding(.horizontal)
                }

                // Drug response card (shown only when medication data exists)
                if let response = drugResponse {
                    drugResponseCard(response)
                        .padding(.horizontal)
                }

                shareSection
                doneButton
            }
        }
        .safeAreaInset(edge: .bottom) {
            // Ensures Done button is fully scrollable even on smaller screens
            Color.clear.frame(height: 20)
        }
        .background(Color(.systemBackground))
        .task {
            guard !hasPersisted else { return }
            hasPersisted = true
            await persistWorkoutResult()
            ringData = try? await ringService.todaySummary()
            if let rings = ringData {
                AppGroupStore.writeRingProgress(
                    move: rings.moveProgress,
                    exercise: rings.exerciseProgress,
                    stand: rings.standProgress
                )
            }
        }
    }

    // MARK: - Celebration Header

    private var celebrationHeader: some View {
        VStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(accentColor.opacity(0.15))
                    .frame(width: 88, height: 88)
                Image(systemName: result.yogaStyle.symbolName)
                    .font(.system(size: 40))
                    .foregroundStyle(accentColor)
            }
            .padding(.top, 32)

            Text(LocalizedString(
                en: "Great \(result.yogaStyleName) Session!",
                fr: "Excellente séance de \(result.yogaStyleName)!"
            ).localized)
            .font(.system(size: 24, weight: .bold, design: .rounded))
            .multilineTextAlignment(.center)

            Text(result.workoutPlanName)
                .font(.system(size: 16))
                .foregroundStyle(.secondary)
        }
    }

    // MARK: - Activity Rings

    private var activityRingsCard: some View {
        Group {
            if let rings = ringData {
                VStack(spacing: 12) {
                    Text(LocalizedString(en: "Activity", fr: "Activité").localized)
                        .font(.system(size: 16, weight: .semibold))
                        .frame(maxWidth: .infinity, alignment: .leading)

                    ActivityRingsView(
                        moveProgress: rings.moveProgress,
                        exerciseProgress: rings.exerciseProgress,
                        standProgress: rings.standProgress
                    )
                }
                .padding()
                .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))
                .padding(.horizontal)
            }
        }
    }

    // MARK: - Stat Grid

    private var statGrid: some View {
        LazyVGrid(columns: [.init(), .init()], spacing: 16) {
            statCard(
                icon: "clock",
                value: formattedDuration(result.totalDuration),
                label: LocalizedString(en: "Duration", fr: "Durée").localized,
                color: .cyan
            )
            statCard(
                icon: "flame.fill",
                value: "\(Int(result.activeCalories))",
                label: LocalizedString(en: "Calories", fr: "Calories").localized,
                color: .orange
            )
            statCard(
                icon: "heart.fill",
                value: result.averageHeartRate.map { "\(Int($0))" } ?? "--",
                label: LocalizedString(en: "Avg HR", fr: "FC moy.").localized,
                color: .red
            )
            statCard(
                icon: "figure.yoga",
                value: "\(result.posesCompleted)/\(result.totalPoses)",
                label: LocalizedString(en: "Poses", fr: "Postures").localized,
                color: accentColor
            )
        }
        .padding(.horizontal)
    }

    // MARK: - Heart Rate Chart

    private var hrChartView: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(LocalizedString(en: "Heart Rate", fr: "Fréquence cardiaque").localized)
                    .font(.system(size: 16, weight: .semibold))
                Spacer()
                if let min = result.heartRateSamples.map(\.bpm).min(),
                   let max = result.heartRateSamples.map(\.bpm).max() {
                    Text("\(Int(min))–\(Int(max)) bpm")
                        .font(.system(size: 13, design: .rounded))
                        .foregroundStyle(.secondary)
                }
            }

            Chart(result.heartRateSamples, id: \.timestamp) { sample in
                LineMark(
                    x: .value("Time", sample.timestamp),
                    y: .value("BPM", sample.bpm)
                )
                .foregroundStyle(.red.gradient)
                .interpolationMethod(.catmullRom)

                AreaMark(
                    x: .value("Time", sample.timestamp),
                    y: .value("BPM", sample.bpm)
                )
                .foregroundStyle(.red.opacity(0.1).gradient)
                .interpolationMethod(.catmullRom)
            }
            .chartYAxis {
                AxisMarks(position: .leading)
            }
            .frame(height: 160)

            // Avg HR annotation
            if let avg = result.averageHeartRate {
                HStack(spacing: 4) {
                    Image(systemName: "heart.fill")
                        .font(.system(size: 10))
                        .foregroundStyle(.red)
                    Text(LocalizedString(
                        en: "Avg \(Int(avg)) bpm",
                        fr: "Moy. \(Int(avg)) bpm"
                    ).localized)
                    .font(.system(size: 12))
                    .foregroundStyle(.secondary)

                    if let max = result.maxHeartRate {
                        Text("·")
                            .foregroundStyle(.secondary)
                        Text(LocalizedString(
                            en: "Max \(Int(max)) bpm",
                            fr: "Max \(Int(max)) bpm"
                        ).localized)
                        .font(.system(size: 12))
                        .foregroundStyle(.secondary)
                    }
                }
            }
        }
        .padding()
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))
        .padding(.horizontal)
    }

    // MARK: - Share

    private var shareSection: some View {
        VStack(spacing: 12) {
            let card = WorkoutShareCard(result: result)

            card
                .padding(.horizontal)

            if let imageData = shareCardImage, let uiImage = UIImage(data: imageData) {
                ShareLink(
                    item: Image(uiImage: uiImage),
                    preview: SharePreview("NATURaL Workout", image: Image(uiImage: uiImage))
                ) {
                    Label(
                        LocalizedString(en: "Share Workout", fr: "Partager la séance").localized,
                        systemImage: "square.and.arrow.up"
                    )
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(accentColor)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(accentColor.opacity(0.12), in: RoundedRectangle(cornerRadius: 12))
                }
                .padding(.horizontal)
            }
        }
        .task {
            let card = WorkoutShareCard(result: result)
            shareCardImage = await MainActor.run { card.renderPNGData() }
        }
    }

    // MARK: - Done Button

    private var doneButton: some View {
        Button {
            onDismiss()
        } label: {
            Text(LocalizedString(en: "Done", fr: "Terminé").localized)
                .font(.system(size: 18, weight: .semibold))
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(accentColor, in: RoundedRectangle(cornerRadius: 14))
        }
        .padding(.horizontal, 40)
        .padding(.bottom, 32)
    }

    // MARK: - Persistence

    /// Saves the workout to SwiftData and records CareKit completion.
    private func persistWorkoutResult() async {
        // 1. Save to SwiftData for history and CloudKit sync
        let record = WorkoutRecord(from: result, sciScore: sciScore)
        modelContext.insert(record)
        try? modelContext.save()

        // 2. Update session streak
        let streakDescriptor = FetchDescriptor<SessionStreak>()
        let streaks = (try? modelContext.fetch(streakDescriptor)) ?? []
        let streak = streaks.first ?? SessionStreak()
        if streaks.isEmpty {
            modelContext.insert(streak)
        }
        streak.recordSession()
        try? modelContext.save()

        // 2b. Push streak + session vitals into App Group for widgets.
        AppGroupStore.writeStreak(
            current: streak.currentStreak,
            longest: streak.longestStreak,
            lastSession: streak.lastSessionDate
        )
        AppGroupStore.writeSessionMetricsAndReload(
            sci: sciScore,
            heartRate: result.maxHeartRate.map { Int($0.rounded()) },
            breathRate: nil
        )

        // 3. CareKit yoga adherence — no-ops when this plan is not prescribed
        try? await appState.careKitBridge.recordCompletion(
            planId: result.workoutPlanId,
            result: result,
            sciScore: sciScore
        )

        // 4. Save drug response record if available
        if let response = drugResponse {
            let record = DrugResponseRecord(
                medicationId: response.doseEvent.medicationId,
                medicationName: response.doseEvent.name,
                doseValue: response.doseEvent.doseValue,
                doseUnit: response.doseEvent.doseUnit,
                doseTimestamp: response.doseEvent.timestamp,
                baselineEntropy: response.baselineEntropy,
                peakDeltaH: response.peakDeltaH,
                peakTimeMinutes: response.peakTimeMinutes,
                responseDirection: response.responseDirection.rawValue,
                effectSize: response.effectSize,
                deltaHAUC: response.deltaHAUC,
                bindingDetected: response.bindingDetected,
                profileMatchId: response.profileMatch?.profile.substanceId,
                profileMatchConfidence: response.profileMatch?.confidence
            )
            modelContext.insert(record)
            try? modelContext.save()
        }

        // 5. Save mindful session to HealthKit
        try? await appState.healthKitManager.saveMindfulSession(
            start: result.startDate,
            end: result.endDate
        )
    }

    // MARK: - Helpers

    private func statCard(icon: String, value: String, label: String, color: Color) -> some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 24))
                .foregroundStyle(color)

            Text(value)
                .font(.system(size: 24, weight: .bold, design: .rounded))
                .monospacedDigit()

            Text(label)
                .font(.system(size: 13))
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))
    }

    private func drugResponseCard(_ response: DrugResponseResult) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: "pill.fill")
                    .foregroundStyle(.cyan)
                Text(LocalizedString(en: "Drug Response", fr: "Réponse médicamenteuse").localized)
                    .font(.system(size: 16, weight: .semibold))
            }

            HStack(spacing: 16) {
                VStack(spacing: 4) {
                    Text(response.bindingDetected
                        ? (response.peakDeltaH < 0 ? "↓" : "↑")
                        : "→")
                        .font(.system(size: 32))
                    Text(String(format: "%+.2f bits", response.peakDeltaH))
                        .font(.system(size: 14, weight: .medium, design: .monospaced))
                    Text("ΔH")
                        .font(.system(size: 11))
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity)

                VStack(spacing: 4) {
                    Text(String(format: "%.0f%%", response.effectSize * 100))
                        .font(.system(size: 24, weight: .bold, design: .rounded))
                    Text(LocalizedString(en: "Effect", fr: "Effet").localized)
                        .font(.system(size: 11))
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity)

                VStack(spacing: 4) {
                    Text(String(format: "+%.0f min", response.peakTimeMinutes))
                        .font(.system(size: 18, weight: .medium, design: .rounded))
                    Text(LocalizedString(en: "Peak", fr: "Pic").localized)
                        .font(.system(size: 11))
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity)
            }

            if let match = response.profileMatch {
                Text(String(format: "%@ (%.0f%%)",
                    match.profile.name.localized,
                    match.confidence * 100))
                    .font(.system(size: 13))
                    .foregroundStyle(.secondary)
            }
        }
        .padding()
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))
    }

    private func formattedDuration(_ duration: TimeInterval) -> String {
        let minutes = Int(duration) / 60
        let seconds = Int(duration) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
}
