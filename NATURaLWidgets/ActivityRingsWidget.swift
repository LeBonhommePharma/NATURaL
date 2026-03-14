import WidgetKit
import SwiftUI

/// Lock screen accessory widget showing today's activity ring progress.
struct ActivityRingsWidget: Widget {
    let kind = "ActivityRingsWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: RingsTimelineProvider()) { entry in
            RingsWidgetView(entry: entry)
                .containerBackground(.fill.tertiary, for: .widget)
        }
        .configurationDisplayName("Activity Rings")
        .description("See your ring progress at a glance.")
        .supportedFamilies([.accessoryCircular, .systemSmall])
    }
}

struct RingsEntry: TimelineEntry {
    let date: Date
    let moveProgress: Double
    let exerciseProgress: Double
    let standProgress: Double
}

struct RingsTimelineProvider: TimelineProvider {
    func placeholder(in context: Context) -> RingsEntry {
        RingsEntry(date: .now, moveProgress: 0.6, exerciseProgress: 0.4, standProgress: 0.8)
    }

    func getSnapshot(in context: Context, completion: @escaping (RingsEntry) -> Void) {
        completion(placeholder(in: context))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<RingsEntry>) -> Void) {
        let defaults = UserDefaults(suiteName: "group.com.bonhomme.natural")
        let entry = RingsEntry(
            date: .now,
            moveProgress: defaults?.double(forKey: "moveProgress") ?? 0,
            exerciseProgress: defaults?.double(forKey: "exerciseProgress") ?? 0,
            standProgress: defaults?.double(forKey: "standProgress") ?? 0
        )
        let timeline = Timeline(entries: [entry], policy: .after(
            Date().addingTimeInterval(900) // Refresh every 15 min
        ))
        completion(timeline)
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
                Circle().trim(from: 0, to: entry.moveProgress)
                    .stroke(.red, style: StrokeStyle(lineWidth: 3, lineCap: .round))
                    .rotationEffect(.degrees(-90))

                Image(systemName: "figure.yoga")
                    .font(.system(size: 12))
            }
        default:
            VStack {
                ActivityRingsView(
                    moveProgress: entry.moveProgress,
                    exerciseProgress: entry.exerciseProgress,
                    standProgress: entry.standProgress
                )
                Text("Today")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(.secondary)
            }
        }
    }
}
