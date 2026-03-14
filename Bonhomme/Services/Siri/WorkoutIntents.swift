import AppIntents
import BonhommeCore

// MARK: - Entities

/// Exposes workout plans to Siri and Shortcuts as resolvable entities.
struct WorkoutPlanEntity: AppEntity {
    static let typeDisplayRepresentation = TypeDisplayRepresentation(name: "Workout Plan")
    static let defaultQuery = WorkoutPlanQuery()

    let id: String
    let name: String
    let poseCount: Int
    let isFree: Bool

    var displayRepresentation: DisplayRepresentation {
        DisplayRepresentation(
            title: "\(name)",
            subtitle: "\(poseCount) poses",
            image: .init(systemName: isFree ? "figure.yoga" : "lock.fill")
        )
    }
}

struct WorkoutPlanQuery: EntityQuery {
    func entities(for identifiers: [String]) async throws -> [WorkoutPlanEntity] {
        PoseCatalog.allPlans
            .filter { identifiers.contains($0.id) }
            .map { plan in
                WorkoutPlanEntity(
                    id: plan.id,
                    name: plan.name.localized,
                    poseCount: plan.poseCount,
                    isFree: plan.isFree
                )
            }
    }

    func suggestedEntities() async throws -> [WorkoutPlanEntity] {
        PoseCatalog.allPlans.map { plan in
            WorkoutPlanEntity(
                id: plan.id,
                name: plan.name.localized,
                poseCount: plan.poseCount,
                isFree: plan.isFree
            )
        }
    }

    func defaultResult() async -> WorkoutPlanEntity? {
        let plan = PoseCatalog.beginnerFlow
        return WorkoutPlanEntity(
            id: plan.id,
            name: plan.name.localized,
            poseCount: plan.poseCount,
            isFree: plan.isFree
        )
    }
}

/// Exposes individual poses to Siri and Shortcuts.
struct PoseEntity: AppEntity {
    static let typeDisplayRepresentation = TypeDisplayRepresentation(name: "Yoga Pose")
    static let defaultQuery = PoseQuery()

    let id: String
    let name: String
    let category: String
    let difficulty: String

    var displayRepresentation: DisplayRepresentation {
        DisplayRepresentation(
            title: "\(name)",
            subtitle: "\(category) · \(difficulty)"
        )
    }
}

struct PoseQuery: EntityQuery {
    func entities(for identifiers: [String]) async throws -> [PoseEntity] {
        PoseCatalog.allPoses
            .filter { identifiers.contains($0.id) }
            .map { pose in
                PoseEntity(
                    id: pose.id,
                    name: pose.name.localized,
                    category: pose.category.localizedName.localized,
                    difficulty: pose.difficulty.localizedName.localized
                )
            }
    }

    func suggestedEntities() async throws -> [PoseEntity] {
        PoseCatalog.allPoses.map { pose in
            PoseEntity(
                id: pose.id,
                name: pose.name.localized,
                category: pose.category.localizedName.localized,
                difficulty: pose.difficulty.localizedName.localized
            )
        }
    }
}

// MARK: - Intents

/// Start a specific workout plan via Siri or Shortcuts.
struct StartWorkoutPlanIntent: AppIntent {
    static let title: LocalizedStringResource = "Start Workout Plan"
    static let description: IntentDescription = "Begin a specific chair yoga workout plan"
    static let openAppWhenRun = true

    @Parameter(title: "Workout Plan")
    var plan: WorkoutPlanEntity

    func perform() async throws -> some IntentResult & ProvidesDialog {
        return .result(dialog: "Starting \(plan.name).")
    }
}

/// General "start chair yoga" intent — picks the default beginner plan.
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

    func perform() async throws -> some IntentResult & ProvidesDialog {
        return .result(dialog: "Starting your chair yoga session.")
    }
}

/// Query the current focus score (SCI) via Siri.
struct GetFocusScoreIntent: AppIntent {
    static let title: LocalizedStringResource = "Get Focus Score"
    static let description: IntentDescription = "Check your current Shannon Collapse Index focus score"

    func perform() async throws -> some IntentResult & ProvidesDialog {
        // In production, read from FeedbackEngine.latestInsight(for: .heartRateVariability)
        return .result(dialog: "Your focus score is available in the NATURaL app.")
    }
}

/// Show medication adherence via Siri.
struct GetAdherenceIntent: AppIntent {
    static let title: LocalizedStringResource = "Get Medication Adherence"
    static let description: IntentDescription = "Check your medication adherence score"

    func perform() async throws -> some IntentResult & ProvidesDialog {
        return .result(dialog: "Your medication adherence is available in the NATURaL app.")
    }
}

// MARK: - App Shortcuts

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

        AppShortcut(
            intent: StartWorkoutPlanIntent(),
            phrases: [
                "Start \(\.$plan) in \(.applicationName)",
                "Begin \(\.$plan) workout",
            ],
            shortTitle: "Start Plan",
            systemImageName: "list.bullet"
        )

        AppShortcut(
            intent: GetFocusScoreIntent(),
            phrases: [
                "What's my focus score in \(.applicationName)",
                "Show my \(.applicationName) focus",
            ],
            shortTitle: "Focus Score",
            systemImageName: "brain.head.profile"
        )

        AppShortcut(
            intent: GetAdherenceIntent(),
            phrases: [
                "How's my medication adherence in \(.applicationName)",
                "Check my \(.applicationName) adherence",
            ],
            shortTitle: "Adherence",
            systemImageName: "pills.fill"
        )
    }
}
