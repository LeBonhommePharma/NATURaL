import WidgetKit
import SwiftUI

/// Widget showing the user's current workout streak count.
struct StreakWidget: Widget {
    let kind = "StreakWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: StreakTimelineProvider()) { entry in
            StreakWidgetView(entry: entry)
                .containerBackground(.fill.tertiary, for: .widget)
        }
        .configurationDisplayName("Yoga Streak")
        .description("Track your consecutive days of practice.")
        .supportedFamilies([.systemSmall])
    }
}

struct StreakEntry: TimelineEntry {
    let date: Date
    let streakDays: Int
    let lastWorkoutDate: Date?
}

struct StreakTimelineProvider: TimelineProvider {
    func placeholder(in context: Context) -> StreakEntry {
        StreakEntry(date: .now, streakDays: 7, lastWorkoutDate: .now)
    }

    func getSnapshot(in context: Context, completion: @escaping (StreakEntry) -> Void) {
        let entry = StreakEntry(
            date: .now,
            streakDays: loadStreak(),
            lastWorkoutDate: loadLastWorkoutDate()
        )
        completion(entry)
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<StreakEntry>) -> Void) {
        let entry = StreakEntry(
            date: .now,
            streakDays: loadStreak(),
            lastWorkoutDate: loadLastWorkoutDate()
        )
        // Refresh at midnight
        let midnight = Calendar.current.startOfDay(for: Date().addingTimeInterval(86400))
        let timeline = Timeline(entries: [entry], policy: .after(midnight))
        completion(timeline)
    }

    private func loadStreak() -> Int {
        let defaults = UserDefaults(suiteName: "group.com.bonhomme.natural")
        return defaults?.integer(forKey: "streakDays") ?? 0
    }

    private func loadLastWorkoutDate() -> Date? {
        let defaults = UserDefaults(suiteName: "group.com.bonhomme.natural")
        return defaults?.object(forKey: "lastWorkoutDate") as? Date
    }
}

struct StreakWidgetView: View {
    let entry: StreakEntry

    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: "flame.fill")
                .font(.system(size: 28))
                .foregroundStyle(.orange)

            Text("\(entry.streakDays)")
                .font(.system(size: 36, weight: .bold, design: .rounded))
                .monospacedDigit()

            Text(entry.streakDays == 1 ? "day" : "days")
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(.secondary)
        }
    }
}
