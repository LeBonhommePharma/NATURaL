import WidgetKit
import SwiftUI

/// Lock screen / home widget showing activity rings plus last session vitals from App Group.
struct ActivityRingsWidget: Widget {
    let kind = "ActivityRingsWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: RingsTimelineProvider()) { entry in
            RingsWidgetView(entry: entry)
                .containerBackground(.fill.tertiary, for: .widget)
        }
        .configurationDisplayName("Activity Rings")
        .description("Ring progress with latest SCI, heart rate, and breath rate.")
        .supportedFamilies([.accessoryCircular, .systemSmall])
    }
}

struct RingsEntry: TimelineEntry {
    let date: Date
    let moveProgress: Double
    let exerciseProgress: Double
    let standProgress: Double
    let sciScore: Double?
    let heartRate: Int?
    let breathRate: Double?
    let streakDays: Int
}

struct RingsTimelineProvider: TimelineProvider {
    func placeholder(in context: Context) -> RingsEntry {
        RingsEntry(
            date: .now,
            moveProgress: 0.6,
            exerciseProgress: 0.4,
            standProgress: 0.8,
            sciScore: 0.7,
            heartRate: 72,
            breathRate: 6,
            streakDays: 5
        )
    }

    func getSnapshot(in context: Context, completion: @escaping (RingsEntry) -> Void) {
        // Never stick on gallery placeholders when the App Group already has data.
        completion(loadEntry(date: .now))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<RingsEntry>) -> Void) {
        let entry = loadEntry(date: .now)
        completion(Timeline(entries: [entry], policy: .after(
            Date().addingTimeInterval(900) // Refresh every 15 min
        )))
    }

    private func loadEntry(date: Date) -> RingsEntry {
        RingsEntry(
            date: date,
            moveProgress: AppGroupStore.moveProgress(),
            exerciseProgress: AppGroupStore.exerciseProgress(),
            standProgress: AppGroupStore.standProgress(),
            sciScore: AppGroupStore.latestSCI(),
            heartRate: AppGroupStore.latestHeartRate(),
            breathRate: AppGroupStore.latestBreathRate(),
            streakDays: AppGroupStore.streakDays()
        )
    }
}

struct RingsWidgetView: View {
    let entry: RingsEntry
    @Environment(\.widgetFamily) var family

    var body: some View {
        switch family {
        case .accessoryCircular:
            ZStack {
                Circle().stroke(.tertiary, lineWidth: 3)
                Circle().trim(from: 0, to: min(max(entry.moveProgress, 0), 1))
                    .stroke(.red, style: StrokeStyle(lineWidth: 3, lineCap: .round))
                    .rotationEffect(.degrees(-90))

                if let sci = entry.sciScore {
                    Text("\(Int((sci * 100).rounded()))")
                        .font(.system(size: 12, weight: .bold, design: .rounded))
                        .monospacedDigit()
                } else {
                    Image(systemName: "figure.yoga")
                        .font(.system(size: 12))
                }
            }
        default:
            VStack(spacing: 6) {
                ActivityRingsView(
                    moveProgress: entry.moveProgress,
                    exerciseProgress: entry.exerciseProgress,
                    standProgress: entry.standProgress
                )
                .scaleEffect(0.85)

                HStack(spacing: 8) {
                    if entry.streakDays > 0 {
                        Label("\(entry.streakDays)", systemImage: "flame.fill")
                            .font(.system(size: 10, weight: .semibold))
                            .foregroundStyle(.orange)
                    }
                    if let sci = entry.sciScore {
                        Text("SCI \(Int((sci * 100).rounded()))%")
                            .font(.system(size: 10, weight: .semibold))
                            .foregroundStyle(.cyan)
                    }
                    if let hr = entry.heartRate {
                        Label("\(hr)", systemImage: "heart.fill")
                            .font(.system(size: 10, weight: .semibold))
                            .foregroundStyle(.red)
                    }
                    if let breath = entry.breathRate {
                        Label(String(format: "%.0f", breath), systemImage: "wind")
                            .font(.system(size: 10, weight: .semibold))
                            .foregroundStyle(.mint)
                    }
                }
                .lineLimit(1)
                .minimumScaleFactor(0.7)
            }
        }
    }
}
