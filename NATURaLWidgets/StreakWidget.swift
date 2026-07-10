import WidgetKit
import SwiftUI

/// Widget showing practice streak plus latest SCI / HR / breath when App Group has data.
struct StreakWidget: Widget {
    let kind = "StreakWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: StreakTimelineProvider()) { entry in
            StreakWidgetView(entry: entry)
                .containerBackground(.fill.tertiary, for: .widget)
        }
        .configurationDisplayName("Yoga Streak")
        .description("Track consecutive practice days, SCI, and last session vitals.")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}

struct StreakEntry: TimelineEntry {
    let date: Date
    let streakDays: Int
    let longestStreak: Int
    let lastWorkoutDate: Date?
    let sciScore: Double?
    let heartRate: Int?
    let breathRate: Double?
}

struct StreakTimelineProvider: TimelineProvider {
    func placeholder(in context: Context) -> StreakEntry {
        StreakEntry(
            date: .now,
            streakDays: 7,
            longestStreak: 14,
            lastWorkoutDate: .now,
            sciScore: 0.72,
            heartRate: 68,
            breathRate: 6
        )
    }

    func getSnapshot(in context: Context, completion: @escaping (StreakEntry) -> Void) {
        // Prefer real App Group data over gallery placeholders when available.
        completion(loadEntry(date: .now))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<StreakEntry>) -> Void) {
        let entry = loadEntry(date: .now)
        let midnight = Calendar.current.startOfDay(for: Date().addingTimeInterval(86400))
        completion(Timeline(entries: [entry], policy: .after(midnight)))
    }

    private func loadEntry(date: Date) -> StreakEntry {
        StreakEntry(
            date: date,
            streakDays: AppGroupStore.streakDays(),
            longestStreak: AppGroupStore.longestStreak(),
            lastWorkoutDate: AppGroupStore.lastWorkoutDate(),
            sciScore: AppGroupStore.latestSCI(),
            heartRate: AppGroupStore.latestHeartRate(),
            breathRate: AppGroupStore.latestBreathRate()
        )
    }
}

struct StreakWidgetView: View {
    let entry: StreakEntry
    @Environment(\.widgetFamily) private var family

    var body: some View {
        switch family {
        case .systemMedium:
            mediumBody
        default:
            smallBody
        }
    }

    private var smallBody: some View {
        VStack(spacing: 6) {
            Image(systemName: "flame.fill")
                .font(.system(size: 24))
                .foregroundStyle(.orange)

            Text("\(entry.streakDays)")
                .font(.system(size: 32, weight: .bold, design: .rounded))
                .monospacedDigit()

            Text(entry.streakDays == 1 ? "day" : "days")
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(.secondary)

            if let sci = entry.sciScore {
                Text("SCI \(Int((sci * 100).rounded()))%")
                    .font(.system(size: 11, weight: .semibold, design: .rounded))
                    .foregroundStyle(.cyan)
            }
        }
    }

    private var mediumBody: some View {
        HStack(spacing: 16) {
            VStack(spacing: 4) {
                Image(systemName: "flame.fill")
                    .font(.system(size: 22))
                    .foregroundStyle(.orange)
                Text("\(entry.streakDays)")
                    .font(.system(size: 34, weight: .bold, design: .rounded))
                    .monospacedDigit()
                Text("day streak")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(.secondary)
                if entry.longestStreak > 0 {
                    Text("Best \(entry.longestStreak)")
                        .font(.system(size: 11))
                        .foregroundStyle(.secondary)
                }
            }
            .frame(maxWidth: .infinity)

            VStack(alignment: .leading, spacing: 8) {
                metricRow(
                    icon: "waveform.path.ecg",
                    tint: .cyan,
                    title: "SCI",
                    value: entry.sciScore.map { "\(Int(($0 * 100).rounded()))%" } ?? "—"
                )
                metricRow(
                    icon: "heart.fill",
                    tint: .red,
                    title: "HR",
                    value: entry.heartRate.map { "\($0)" } ?? "—"
                )
                metricRow(
                    icon: "wind",
                    tint: .mint,
                    title: "Breath",
                    value: entry.breathRate.map { String(format: "%.0f/min", $0) } ?? "—"
                )
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    private func metricRow(icon: String, tint: Color, title: String, value: String) -> some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(tint)
                .frame(width: 16)
            Text(title)
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(.secondary)
            Spacer(minLength: 4)
            Text(value)
                .font(.system(size: 14, weight: .bold, design: .rounded))
                .monospacedDigit()
        }
    }
}
