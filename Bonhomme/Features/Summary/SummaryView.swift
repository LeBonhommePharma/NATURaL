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
                }
                shareSection
                doneButton
            }
        }
        .background(Color(.systemBackground))
        .task {
            guard !hasPersisted else { return }
            hasPersisted = true
            await persistWorkoutResult()
            ringData = try? await ringService.todaySummary()
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
                        standProgress: rings.standProgress,
                        moveDelta: "+\(Int(result.activeCalories)) cal",
                        exerciseDelta: "+\(Int(result.totalDuration / 60)) min"
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
            shareCardImage = await card.renderPNGData()
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

        // 3. Record CareKit completion if this was a prescribed workout
        if appState.careKitBridge.hasPrescriptions {
            try? await appState.careKitBridge.recordCompletion(
                planId: result.workoutPlanId,
                result: result,
                sciScore: sciScore
            )
        }

        // 4. Save mindful session to HealthKit (especially for pranayama/meditation)
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

    private func formattedDuration(_ duration: TimeInterval) -> String {
        let minutes = Int(duration) / 60
        let seconds = Int(duration) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
}
