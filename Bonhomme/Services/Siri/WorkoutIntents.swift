import AppIntents

/// App Intent enabling "Hey Siri, start my chair yoga" and Shortcuts integration.
struct StartChairYogaIntent: AppIntent {
    static let title: LocalizedStringResource = "Start Chair Yoga"
    static let description: IntentDescription = "Begin a chair yoga session"
    static let openAppWhenRun = true

    @Parameter(title: "Duration")
    var duration: DurationStyle?

    enum DurationStyle: String, AppEnum {
        case fiveMinutes
        case tenMinutes
        case twentyMinutes
        case thirtyMinutes

        static let typeDisplayRepresentation = TypeDisplayRepresentation(name: "Duration")
        static let caseDisplayRepresentations: [Self: DisplayRepresentation] = [
            .fiveMinutes: "5 minutes",
            .tenMinutes: "10 minutes",
            .twentyMinutes: "20 minutes",
            .thirtyMinutes: "30 minutes",
        ]
    }

    func perform() async throws -> some IntentResult {
        // The app will open and navigate to the workout flow
        // based on the selected duration via deep linking or notification
        return .result()
    }
}

struct AppShortcuts: AppShortcutsProvider {
    static var appShortcuts: [AppShortcut] {
        AppShortcut(
            intent: StartChairYogaIntent(),
            phrases: [
                "Start my chair yoga in \(.applicationName)",
                "Begin a \(.applicationName) session",
                "Start \(.applicationName)",
            ],
            shortTitle: "Chair Yoga",
            systemImageName: "figure.yoga"
        )
    }
}
