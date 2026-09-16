import SwiftUI
import SwiftData
import HealthKit
import BonhommeCore

/// Local sessions are always visible, even when Health permission is unavailable.
struct HistoryView: View {
    @Query(sort: \WorkoutRecord.startDate, order: .reverse) private var savedSessions: [WorkoutRecord]
    @State private var healthSessions: [HKWorkout] = []
    @State private var isLoading = false
    @State private var healthError = false
    private let fitnessPlusReader = FitnessPlusReader()

    var body: some View {
        List {
            Section(LocalizedString(en: "Your practice", fr: "Votre pratique").localized) {
                if savedSessions.isEmpty {
                    ContentUnavailableView(
                        LocalizedString(en: "Your next chapter starts here", fr: "Votre prochaine étape commence ici").localized,
                        systemImage: "leaf",
                        description: Text(LocalizedString(en: "Complete a session and it will appear here, even without Apple Health.", fr: "Terminez une séance pour la retrouver ici, même sans Apple Santé.").localized)
                    )
                }
                ForEach(savedSessions) { item in
                    VStack(alignment: .leading, spacing: 8) {
                        Text(item.planName).font(.headline)
                        Text(item.startDate, style: .date).foregroundStyle(.secondary)
                        Label("\(Int(item.totalDuration) / 60) min", systemImage: "clock")
                            .font(.subheadline).foregroundStyle(BrandColor.aqua)
                    }
                    .padding(.vertical, 6)
                    .accessibilityElement(children: .combine)
                    .accessibilityIdentifier("history.session")
                }
            }
            Section(LocalizedString(en: "From Apple Health · last 30 days", fr: "Apple Santé · 30 derniers jours").localized) {
                if isLoading { ProgressView() }
                if healthError {
                    Text(LocalizedString(en: "Health history could not load. Your local sessions are still available.", fr: "L’historique Santé n’a pas pu être chargé. Vos séances locales restent disponibles.").localized)
                }
                ForEach(healthSessions, id: \.uuid) { workout in
                    VStack(alignment: .leading, spacing: 6) {
                        Text(workout.startDate, style: .date).font(.headline)
                        Text("\(Int(workout.duration) / 60) min · \(workout.sourceRevision.source.name)")
                            .font(.subheadline).foregroundStyle(.secondary)
                    }
                }
                if !isLoading && !healthError && healthSessions.isEmpty {
                    Text(LocalizedString(en: "No additional shared yoga sessions. You can manage Health access in About & Privacy.", fr: "Aucune autre séance de yoga partagée. Gérez les accès Santé dans À propos et confidentialité.").localized)
                        .foregroundStyle(.secondary)
                }
                Button(LocalizedString(en: "Refresh Health history", fr: "Actualiser l’historique Santé").localized) {
                    Task { await loadHistory() }
                }
                .disabled(isLoading)
            }
        }
        .navigationTitle(LocalizedString(en: "History", fr: "Historique").localized)
        .listStyle(.insetGrouped)
        .task { await loadHistory() }
        .refreshable { await loadHistory() }
    }

    @MainActor private func loadHistory() async {
        guard !isLoading else { return }
        isLoading = true
        healthError = false
        defer { isLoading = false }
        guard HKHealthStore.isHealthDataAvailable() else { return }
        let from = Calendar.current.date(byAdding: .day, value: -30, to: Date()) ?? Date()
        do {
            let workouts = try await fitnessPlusReader.fetchAllYogaSessions(from: from, to: Date())
            // Use source identity; an Apple Watch workout is not necessarily Fitness+.
            healthSessions = workouts.filter {
                !$0.sourceRevision.source.bundleIdentifier.hasPrefix("com.natural.Bonhomme")
            }.sorted { $0.startDate > $1.startDate }
        } catch {
            healthError = true
        }
    }
}
