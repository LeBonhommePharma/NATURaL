import GroupActivities
import Combine
import Dispatch

/// Coordinates workout state across SharePlay participants using GroupSessionMessenger.
///
/// Lifecycle:
/// - `activate` — publish activity into FaceTime / system SharePlay UI
/// - `configureSession` — wire messenger + join (replaces any prior session)
/// - `leave` — leave group, cancel message loop, clear published state
@MainActor
final class SessionCoordinator: ObservableObject {
    @Published var isSharePlayActive = false
    @Published var participantCount = 0

    private var groupSession: GroupSession<ChairYogaActivity>?
    private var messenger: GroupSessionMessenger?
    private var cancellables = Set<AnyCancellable>()
    private var messageHandler: ((WorkoutSyncMessage) -> Void)?
    /// Message stream task — must be cancelled on leave to avoid leaks / races.
    private var messageTask: Task<Void, Never>?
    /// Session state observation task (if any async stream used later).
    private var sessionTasks: [Task<Void, Never>] = []

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
    /// Tears down any existing session first so reconfigure is race-free.
    func configureSession(
        _ session: GroupSession<ChairYogaActivity>,
        onMessage: @escaping (WorkoutSyncMessage) -> Void
    ) {
        // Replace-in-place: drop prior messenger/tasks before attaching new session.
        teardownSession(leaveGroup: true)

        groupSession = session
        messageHandler = onMessage

        let messenger = GroupSessionMessenger(session: session)
        self.messenger = messenger

        session.$state
            .receive(on: DispatchQueue.main)
            .sink { [weak self] state in
                guard let self else { return }
                // GroupSession.State.invalidated carries an associated reason (SDK change).
                if case .joined = state {
                    self.isSharePlayActive = true
                } else {
                    self.isSharePlayActive = false
                }
                // System invalidation / leave — full local cleanup without re-leave.
                if case .invalidated = state {
                    self.teardownSession(leaveGroup: false)
                }
            }
            .store(in: &cancellables)

        session.$activeParticipants
            .receive(on: DispatchQueue.main)
            .sink { [weak self] participants in
                self?.participantCount = participants.count
            }
            .store(in: &cancellables)

        // Listen for messages from other participants (cancelled in leave/teardown).
        messageTask = Task { [weak self] in
            for await (message, _) in messenger.messages(of: WorkoutSyncMessage.self) {
                guard !Task.isCancelled else { return }
                await MainActor.run {
                    self?.messageHandler?(message)
                }
            }
        }

        session.join()
    }

    /// Sends a workout state update to all participants.
    func send(_ message: WorkoutSyncMessage) async {
        guard isSharePlayActive, let messenger else { return }
        do {
            try await messenger.send(message)
        } catch {
            // Message delivery failure; non-critical for workout flow
        }
    }

    /// Ends SharePlay participation and clears all session state.
    func leave() {
        teardownSession(leaveGroup: true)
    }

    // MARK: - Cleanup

    /// Cancels message loop, Combine sinks, and optionally leaves the group.
    private func teardownSession(leaveGroup: Bool) {
        messageTask?.cancel()
        messageTask = nil
        for task in sessionTasks { task.cancel() }
        sessionTasks.removeAll()

        cancellables.removeAll()
        messageHandler = nil
        messenger = nil

        if leaveGroup {
            groupSession?.leave()
        }
        groupSession = nil

        isSharePlayActive = false
        participantCount = 0
    }
}
