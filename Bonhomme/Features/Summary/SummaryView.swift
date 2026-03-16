import SwiftUI
import SwiftData
import Charts
import BonhommeCore

/// Post-workout summary screen showing stats, HR chart, and activity ring progress.
/// Persists the workout result to SwiftData and records CareKit completion.
struct SummaryView: View {
    let result: WorkoutResult
    var sciScore: Double? = nil
    var drugResponse: DrugResponseResult? = nil
    let onDismiss: () -> Void

    @Environment(\.modelContext) private var modelContext
    @Environment(AppState.self) private var appState
    @State private var hasPersisted = false

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Checkmark animation
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 72))
                    .foregroundStyle(.green)
                    .padding(.top, 32)

                Text(LocalizedString(en: "Session Complete!", fr: "Séance terminée!").localized)
                    .font(.system(size: 28, weight: .bold, design: .rounded))

                // Stat cards
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
                        color: .purple
                    )
                }
                .padding(.horizontal)

                // Heart rate chart
                if !result.heartRateSamples.isEmpty {
                    hrChartView
                        .padding(.horizontal)
                }

                // Drug response card (shown only when medication data exists)
                if let response = drugResponse {
                    drugResponseCard(response)
                        .padding(.horizontal)
                }

                // Done button
                Button {
                    onDismiss()
                } label: {
                    Text(LocalizedString(en: "Done", fr: "Terminé").localized)
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundStyle(.black)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(.cyan, in: RoundedRectangle(cornerRadius: 14))
                }
                .padding(.horizontal, 40)
                .padding(.bottom, 32)
            }
        }
        .background(Color(.systemBackground))
        .task {
            guard !hasPersisted else { return }
            hasPersisted = true
            await persistWorkoutResult()
        }
    }

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

        // 3. Record CareKit completion if this was a prescribed workout
        if appState.careKitBridge.hasPrescriptions {
            try? await appState.careKitBridge.recordCompletion(
                planId: result.workoutPlanId,
                result: result,
                sciScore: sciScore
            )
        }

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

    private var hrChartView: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(LocalizedString(en: "Heart Rate", fr: "Fréquence cardiaque").localized)
                .font(.system(size: 16, weight: .semibold))

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
        }
        .padding()
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
