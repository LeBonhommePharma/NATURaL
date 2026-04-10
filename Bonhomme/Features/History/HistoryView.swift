import SwiftUI
import HealthKit

/// Blended workout history showing both NATURaL and Fitness+ yoga sessions
/// in a unified timeline.
struct HistoryView: View {
    @State private var sessions: [WorkoutHistoryItem] = []
    @State private var isLoading = true

    private let fitnessPlusReader = FitnessPlusReader()

    var body: some View {
        Group {
            if isLoading {
                ProgressView("Loading history...")
            } else if sessions.isEmpty {
                ContentUnavailableView(
                    "No Yoga Sessions",
                    systemImage: "figure.yoga",
                    description: Text("Complete a workout to see your history here.")
                )
            } else {
                List(sessions) { item in
                    historyRow(item)
                }
            }
        }
        .navigationTitle("History")
        .task { await loadHistory() }
    }

    private func historyRow(_ item: WorkoutHistoryItem) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(item.date, style: .date)
                    .font(.system(size: 16, weight: .semibold))

                HStack(spacing: 12) {
                    Label(item.formattedDuration, systemImage: "clock")
                    if let cal = item.calories {
                        Label("\(Int(cal)) cal", systemImage: "flame.fill")
                    }
                }
                .font(.system(size: 13))
                .foregroundStyle(.secondary)
            }

            Spacer()

            Text(item.source.displayName)
                .font(.system(size: 12, weight: .medium))
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(item.source.color.opacity(0.15), in: Capsule())
                .foregroundStyle(item.source.color)
        }
        .padding(.vertical, 4)
    }

    private func loadHistory() async {
        isLoading = true
        defer { isLoading = false }

        let thirtyDaysAgo = Calendar.current.date(byAdding: .day, value: -30, to: Date()) ?? Date()

        do {
            let allWorkouts = try await fitnessPlusReader.fetchAllYogaSessions(
                from: thirtyDaysAgo,
                to: Date()
            )

            sessions = allWorkouts.map { workout in
                let isApple = [
                    "com.apple.health.workout-app",
                    "com.apple.Health",
                    "com.apple.workout",
                ].contains(workout.sourceRevision.source.bundleIdentifier)

                let activeEnergyType = HKQuantityType(.activeEnergyBurned)
                let calories = workout.statistics(for: activeEnergyType)?
                    .sumQuantity()?
                    .doubleValue(for: .kilocalorie())

                return WorkoutHistoryItem(
                    id: workout.uuid.uuidString,
                    date: workout.startDate,
                    duration: workout.duration,
                    calories: calories,
                    source: isApple ? .fitnessPlus : .natural
                )
            }
        } catch {
            sessions = []
        }
    }
}

struct WorkoutHistoryItem: Identifiable {
    let id: String
    let date: Date
    let duration: TimeInterval
    let calories: Double?
    let source: WorkoutSource

    var formattedDuration: String {
        let minutes = Int(duration) / 60
        return "\(minutes) min"
    }

    enum WorkoutSource {
        case natural
        case fitnessPlus

        var displayName: String {
            switch self {
            case .natural: return "NATURaL"
            case .fitnessPlus: return "Fitness+"
            }
        }

        var color: Color {
            switch self {
            case .natural: return .cyan
            case .fitnessPlus: return .green
            }
        }
    }
}
