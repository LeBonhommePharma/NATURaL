import Network
import BonhommeCore

/// Handles the NWConnection from the iOS side to the tvOS companion app.
/// Used by TVDisplayCoordinator when mode is .nativeTV.
///
/// This is a thin wrapper that provides connection state observation
/// and handles reconnection attempts when the connection drops.
@MainActor
final class NativeCompanionClient: ObservableObject {
    @Published var isConnected = false

    private var connection: NWConnection?
    private let encoder = JSONEncoder()
    private var reconnectTask: Task<Void, Never>?

    func connect(to endpoint: NWEndpoint) {
        connection?.cancel()
        let conn = NWConnection(to: endpoint, using: .tcp)

        conn.stateUpdateHandler = { [weak self] state in
            Task { @MainActor in
                guard let self else { return }
                switch state {
                case .ready:
                    self.isConnected = true
                case .failed:
                    self.isConnected = false
                    self.scheduleReconnect(to: endpoint)
                case .cancelled:
                    self.isConnected = false
                default:
                    break
                }
            }
        }

        conn.start(queue: .main)
        connection = conn
    }

    func disconnect() {
        reconnectTask?.cancel()
        connection?.cancel()
        connection = nil
        isConnected = false
    }

    func send(payload: TVDisplayPayload) {
        guard let connection, isConnected,
              let data = try? encoder.encode(payload) else { return }

        var length = UInt32(data.count).bigEndian
        let header = Data(bytes: &length, count: 4)

        connection.send(content: header + data, completion: .contentProcessed { _ in })
    }

    /// Attempts reconnection with exponential backoff (2s, 4s, 8s).
    private func scheduleReconnect(to endpoint: NWEndpoint) {
        reconnectTask?.cancel()
        reconnectTask = Task {
            for delay in [2, 4, 8] {
                try? await Task.sleep(for: .seconds(delay))
                guard !Task.isCancelled else { return }
                connect(to: endpoint)
                try? await Task.sleep(for: .seconds(2))
                if isConnected { return }
            }
        }
    }
}
