import Foundation
import Combine
import Network
import BonhommeCore

/// Handles the NWConnection from the iOS side to the tvOS companion app.
/// Used as a focused connection helper (reconnect + framed send).
/// Prefer `TVDisplayCoordinator` for full discovery + AirPlay fallback.
///
/// This is a thin wrapper that provides connection state observation
/// and handles reconnection attempts when the connection drops.
@MainActor
final class NativeCompanionClient: ObservableObject {
    @Published var isConnected = false

    private var connection: NWConnection?
    private var lastEndpoint: NWEndpoint?
    private let encoder = JSONEncoder()
    private var reconnectTask: Task<Void, Never>?
    /// Bumps on disconnect/connect so stale state handlers are ignored.
    private var generation = 0
    private var isConnecting = false

    func connect(to endpoint: NWEndpoint) {
        lastEndpoint = endpoint
        reconnectTask?.cancel()
        generation += 1
        let generation = self.generation
        isConnecting = true

        connection?.cancel()
        let conn = NWConnection(to: endpoint, using: .tcp)

        conn.stateUpdateHandler = { [weak self] state in
            Task { @MainActor in
                guard let self, generation == self.generation else { return }
                switch state {
                case .ready:
                    self.isConnecting = false
                    self.isConnected = true
                    self.connection = conn
                    self.reconnectTask?.cancel()
                    self.reconnectTask = nil
                case .failed:
                    self.isConnecting = false
                    self.isConnected = false
                    self.connection = nil
                    self.scheduleReconnect(to: endpoint)
                case .cancelled:
                    self.isConnecting = false
                    self.isConnected = false
                    self.connection = nil
                default:
                    break
                }
            }
        }

        conn.start(queue: .main)
        // Assign only after start; readiness still gated by isConnected for send().
        connection = conn
    }

    func disconnect() {
        reconnectTask?.cancel()
        reconnectTask = nil
        generation += 1
        isConnecting = false
        connection?.cancel()
        connection = nil
        lastEndpoint = nil
        isConnected = false
    }

    func send(payload: TVDisplayPayload) {
        guard let connection, isConnected,
              let data = try? encoder.encode(payload),
              let frame = TVRelayFraming.encodeLengthPrefixed(data) else { return }

        connection.send(content: frame, completion: .contentProcessed { [weak self] error in
            if error != nil {
                Task { @MainActor in
                    guard let self else { return }
                    self.isConnected = false
                    self.connection = nil
                    if let endpoint = self.lastEndpoint {
                        self.scheduleReconnect(to: endpoint)
                    }
                }
            }
        })
    }

    /// Attempts reconnection with exponential backoff (2s, 4s, 8s).
    private func scheduleReconnect(to endpoint: NWEndpoint) {
        reconnectTask?.cancel()
        reconnectTask = Task { [weak self] in
            for delay in [2, 4, 8] {
                try? await Task.sleep(for: .seconds(delay))
                guard let self, !Task.isCancelled else { return }
                guard !self.isConnected, !self.isConnecting else { return }
                self.connect(to: endpoint)
                try? await Task.sleep(for: .seconds(2))
                if self.isConnected { return }
            }
        }
    }
}
