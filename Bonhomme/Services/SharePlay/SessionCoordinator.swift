import GroupActivities
import Combine
import Dispatch

/// Coordinates workout state across SharePlay participants using GroupSessionMessenger.
@MainActor
final class SessionCoordinator: ObservableObject {
    @Published var isSharePlayActive = false
    @Published var participantCount = 0

    private var groupSession: GroupSession<ChairYogaActivity>?
    private var messenger: GroupSessionMessenger?
    private var cancellables = Set<AnyCancellable>()
    private var messageHandler: ((WorkoutSyncMessage) -> Void)?

    /// Activates a SharePlay session for the given workout plan.
    func activate(planId: String, planName: String) async {
        let activity = ChairYogaActivity(
            workoutPlanId: planId,
            workoutPlanName: planName
        )

        do {
            _ = try await activity.activate()
        } catch {
            // SharePlay not available (e.g., not in FaceTime)
        }
    }

    /// Configures the session when received from the system.
    func configureSession(
        _ session: GroupSession<ChairYogaActivity>,
        onMessage: @escaping (WorkoutSyncMessage) -> Void
    ) {
        groupSession = session
        messageHandler = onMessage

        let messenger = GroupSessionMessenger(session: session)
        self.messenger = messenger

        session.$state
            .receive(on: DispatchQueue.main)
            .sink { [weak self] state in
                self?.isSharePlayActive = (state == .joined)
            }
            .store(in: &cancellables)

        session.$activeParticipants
            .receive(on: DispatchQueue.main)
            .sink { [weak self] participants in
                self?.participantCount = participants.count
            }
            .store(in: &cancellables)

        // Listen for messages from other participants
        Task {
            for await (message, _) in messenger.messages(of: WorkoutSyncMessage.self) {
                onMessage(message)
            }
        }

        session.join()
    }

    /// Sends a workout state update to all participants.
    func send(_ message: WorkoutSyncMessage) async {
        guard let messenger else { return }
        do {
            try await messenger.send(message)
        } catch {
            // Message delivery failure; non-critical for workout flow
        }
    }

    func leave() {
        groupSession?.leave()
        groupSession = nil
        messenger = nil
        cancellables.removeAll()
        isSharePlayActive = false
    }
}
