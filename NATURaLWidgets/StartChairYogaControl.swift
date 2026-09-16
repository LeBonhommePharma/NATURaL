import AppIntents
import SwiftUI
import WidgetKit

/// Thin Control Center / Lock Screen control. Writes the App Group key that
/// `IntentBridge` already reads — do not compile full `WorkoutIntents` here.
@available(iOS 18.0, *)
struct StartChairYogaControlIntent: AppIntent {
    static let title: LocalizedStringResource = "Start Chair Yoga"
    static let description: IntentDescription = "Begin the beginner chair yoga flow"
    static let openAppWhenRun = true

    private static let suiteName = "group.com.natural.Bonhomme"
    private static let pendingPlanKey = "intent.pendingPlanId"
    private static let beginnerPlanId = "beginner-flow"

    func perform() async throws -> some IntentResult {
        let defaults = UserDefaults(suiteName: Self.suiteName) ?? .standard
        defaults.set(Self.beginnerPlanId, forKey: Self.pendingPlanKey)
        return .result()
    }
}

@available(iOS 18.0, *)
struct StartChairYogaControl: ControlWidget {
    static let kind = "com.natural.Bonhomme.control.startChairYoga"

    var body: some ControlWidgetConfiguration {
        StaticControlConfiguration(kind: Self.kind) {
            ControlWidgetButton(action: StartChairYogaControlIntent()) {
                Label("Chair Yoga", systemImage: "figure.yoga")
            }
        }
        .displayName("Start Chair Yoga")
        .description("Begin a beginner chair yoga session")
    }
}
