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
            .map(Self.entity(from:))
    }

    func suggestedEntities() async throws -> [WorkoutPlanEntity] {
        PoseCatalog.allPlans.map(Self.entity(from:))
    }

    func defaultResult() async -> WorkoutPlanEntity? {
        Self.entity(from: PoseCatalog.beginnerFlow)
    }

    static func entity(from plan: WorkoutPlan) -> WorkoutPlanEntity {
        WorkoutPlanEntity(
            id: plan.id,
            name: plan.name.localized,
            poseCount: plan.poseCount,
            isFree: plan.isFree
        )
    }
}

extension WorkoutPlanQuery: EntityStringQuery {
    func entities(matching string: String) async throws -> [WorkoutPlanEntity] {
        let query = string.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !query.isEmpty else { return try await suggestedEntities() }

        return PoseCatalog.allPlans
            .filter { plan in
                plan.id.localizedCaseInsensitiveContains(query)
                    || plan.name.en.localizedCaseInsensitiveContains(query)
                    || plan.name.fr.localizedCaseInsensitiveContains(query)
                    || plan.name.localized.localizedCaseInsensitiveContains(query)
            }
            .map(Self.entity(from:))
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

    static var parameterSummary: some ParameterSummary {
        Summary("Start \(\.$plan)")
    }

    func perform() async throws -> some IntentResult & ProvidesDialog {
        await MainActor.run {
            IntentBridge.shared.requestStartPlan(id: plan.id)
        }
        let dialog = LocalizedString(
            en: "Starting \(plan.name).",
            fr: "Démarrage de \(plan.name)."
        ).localized
        return .result(dialog: IntentDialog(stringLiteral: dialog))
    }
}

/// General "start chair yoga" intent — picks a plan by optional duration.
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

        var minutes: Int {
            switch self {
            case .fiveMinutes: return 5
            case .tenMinutes: return 10
            case .twentyMinutes: return 20
            case .thirtyMinutes: return 30
            }
        }
    }

    static var parameterSummary: some ParameterSummary {
        Summary("Start chair yoga") {
            \.$duration
        }
    }

    func perform() async throws -> some IntentResult & ProvidesDialog {
        let selected = await MainActor.run {
            let plan = IntentBridge.shared.planMatching(durationMinutes: duration?.minutes)
            IntentBridge.shared.requestStartPlan(id: plan.id)
            return plan
        }
        let name = selected.name.localized
        let dialog = LocalizedString(
            en: "Starting \(name).",
            fr: "Démarrage de \(name)."
        ).localized
        return .result(dialog: IntentDialog(stringLiteral: dialog))
    }
}

/// Query the current focus score (SCI) via Siri.
struct GetFocusScoreIntent: AppIntent {
    static let title: LocalizedStringResource = "Get Focus Score"
    static let description: IntentDescription = "Check your current Shannon Collapse Index focus score"

    func perform() async throws -> some IntentResult & ProvidesDialog & ReturnsValue<Double?> {
        let (dialog, score) = await MainActor.run {
            let snap = IntentBridge.shared.currentFocusSnapshot()
            return (IntentBridge.shared.focusDialog(), snap.score.map { $0 * 100 })
        }
        return .result(value: score, dialog: IntentDialog(stringLiteral: dialog))
    }
}

/// Show medication adherence via Siri (real score from dose events / FeedbackEngine).
struct GetAdherenceIntent: AppIntent {
    static let title: LocalizedStringResource = "Get Medication Adherence"
    static let description: IntentDescription = "Check your medication adherence score"

    func perform() async throws -> some IntentResult & ProvidesDialog & ReturnsValue<Double?> {
        let (dialog, score) = await MainActor.run {
            let snap = IntentBridge.shared.currentAdherenceSnapshot()
            return (IntentBridge.shared.adherenceDialog(), snap.score.map { $0 * 100 })
        }
        return .result(value: score, dialog: IntentDialog(stringLiteral: dialog))
    }
}

/// Last drug-response analysis (ΔH / SCI entropy change after a dose).
struct GetLastDrugResponseIntent: AppIntent {
    static let title: LocalizedStringResource = "Get Last Drug Response"
    static let description: IntentDescription =
        "Report the last post-dose HRV entropy response (ΔH) and binding signal"

    func perform() async throws -> some IntentResult & ProvidesDialog & ReturnsValue<Double?> {
        let (dialog, deltaH) = await MainActor.run {
            let snap = IntentBridge.shared.lastDrugResponseSnapshot()
            return (IntentBridge.shared.drugResponseDialog(), snap.peakDeltaH)
        }
        return .result(value: deltaH, dialog: IntentDialog(stringLiteral: dialog))
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
                "Begin \(\.$plan) workout in \(.applicationName)",
            ],
            shortTitle: "Start Plan",
            systemImageName: "list.bullet"
        )

        AppShortcut(
            intent: GetFocusScoreIntent(),
            phrases: [
                "What's my focus score in \(.applicationName)",
                "Show my \(.applicationName) focus",
                "What's my SCI in \(.applicationName)",
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

        AppShortcut(
            intent: GetLastDrugResponseIntent(),
            phrases: [
                "What's my last drug response in \(.applicationName)",
                "Show my last dose response in \(.applicationName)",
                "Check my \(.applicationName) drug response",
            ],
            shortTitle: "Drug Response",
            systemImageName: "waveform.path.ecg"
        )
    }
}
