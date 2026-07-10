import Network
import SwiftUI
import BonhommeCore

/// Advertises a Bonjour service on the local network and listens for
/// incoming NWConnections from the iOS companion app. Receives length-prefixed
/// JSON TVDisplayPayload messages.
@MainActor
final class CompanionListener: ObservableObject {
    static let serviceType = "_bonhomme._tcp"

    @Published var latestPayload: TVDisplayPayload?
    @Published var isConnected = false
    @Published var isAdvertising = false

    private var listener: NWListener?
    private var activeConnection: NWConnection?
    private let decoder = JSONDecoder()
    /// Ignores receive callbacks from superseded connections.
    private var connectionGeneration = 0

    func startAdvertising() {
        guard listener == nil else { return }

        do {
            let params = NWParameters.tcp
            params.includePeerToPeer = true
            let listener = try NWListener(using: params)

            listener.service = NWListener.Service(
                name: "BonhommeTV",
                type: Self.serviceType
            )

            listener.stateUpdateHandler = { [weak self] state in
                Task { @MainActor in
                    switch state {
                    case .ready:
                        self?.isAdvertising = true
                    case .failed, .cancelled:
                        self?.isAdvertising = false
                    default:
                        break
                    }
                }
            }

            listener.newConnectionHandler = { [weak self] connection in
                Task { @MainActor in
                    self?.handleNewConnection(connection)
                }
            }

            listener.start(queue: .main)
            self.listener = listener
            isAdvertising = true
        } catch {
            isAdvertising = false
        }
    }

    func stopAdvertising() {
        connectionGeneration += 1
        listener?.cancel()
        listener = nil
        activeConnection?.cancel()
        activeConnection = nil
        isAdvertising = false
        isConnected = false
        latestPayload = nil
    }

    // MARK: - Connection Handling

    private func handleNewConnection(_ connection: NWConnection) {
        // Cancel any existing connection (single client only)
        connectionGeneration += 1
        let generation = connectionGeneration
        activeConnection?.cancel()
        activeConnection = connection

        connection.stateUpdateHandler = { [weak self] state in
            Task { @MainActor in
                guard let self, generation == self.connectionGeneration else { return }
                switch state {
                case .ready:
                    self.isConnected = true
                case .failed, .cancelled:
                    self.isConnected = false
                    // Keep last payload on screen briefly? Clear so idle UI shows disconnect.
                    self.latestPayload = nil
                    if self.activeConnection === connection {
                        self.activeConnection = nil
                    }
                default:
                    break
                }
            }
        }

        connection.start(queue: .main)
        receiveHeader(on: connection, generation: generation)
    }

    // MARK: - Length-Prefixed Framing

    /// Reads a 4-byte big-endian length header, then the payload body.
    private func receiveHeader(on connection: NWConnection, generation: Int) {
        connection.receive(minimumIncompleteLength: 4, maximumLength: 4) { [weak self] data, _, isComplete, error in
            Task { @MainActor in
                guard let self, generation == self.connectionGeneration else { return }

                if error != nil || isComplete {
                    self.markDisconnected(connection)
                    return
                }

                guard let data,
                      let length = TVRelayFraming.decodeBodyLength(fromHeader: data) else {
                    // Oversized or malformed header — drop connection rather than allocate.
                    connection.cancel()
                    self.markDisconnected(connection)
                    return
                }

                self.receiveBody(on: connection, length: length, generation: generation)
            }
        }
    }

    private func receiveBody(on connection: NWConnection, length: Int, generation: Int) {
        connection.receive(minimumIncompleteLength: length, maximumLength: length) { [weak self] data, _, isComplete, error in
            Task { @MainActor in
                guard let self, generation == self.connectionGeneration else { return }

                if let error {
                    _ = error
                    self.markDisconnected(connection)
                    return
                }

                if let data, data.count == length {
                    // Nil / partial biofeedback fields are valid — decode must not require HR.
                    if let payload = try? self.decoder.decode(TVDisplayPayload.self, from: data) {
                        self.latestPayload = payload
                    }
                }

                if isComplete {
                    self.markDisconnected(connection)
                } else {
                    // Continue reading next message
                    self.receiveHeader(on: connection, generation: generation)
                }
            }
        }
    }

    private func markDisconnected(_ connection: NWConnection) {
        isConnected = false
        if activeConnection === connection {
            activeConnection = nil
        }
    }
}
