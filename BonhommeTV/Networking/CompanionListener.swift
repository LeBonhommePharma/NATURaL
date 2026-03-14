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

    func startAdvertising() {
        guard listener == nil else { return }

        do {
            let params = NWParameters.tcp
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
        listener?.cancel()
        listener = nil
        activeConnection?.cancel()
        activeConnection = nil
        isAdvertising = false
        isConnected = false
    }

    // MARK: - Connection Handling

    private func handleNewConnection(_ connection: NWConnection) {
        // Cancel any existing connection (single client only)
        activeConnection?.cancel()
        activeConnection = connection

        connection.stateUpdateHandler = { [weak self] state in
            Task { @MainActor in
                switch state {
                case .ready:
                    self?.isConnected = true
                case .failed, .cancelled:
                    self?.isConnected = false
                    self?.latestPayload = nil
                default:
                    break
                }
            }
        }

        connection.start(queue: .main)
        receiveHeader(on: connection)
    }

    // MARK: - Length-Prefixed Framing

    /// Reads a 4-byte big-endian length header, then the payload body.
    private func receiveHeader(on connection: NWConnection) {
        connection.receive(minimumIncompleteLength: 4, maximumLength: 4) { [weak self] data, _, isComplete, error in
            guard let self, let data, data.count == 4 else {
                if isComplete {
                    Task { @MainActor in
                        self?.isConnected = false
                    }
                }
                return
            }

            let length = data.withUnsafeBytes { $0.load(as: UInt32.self).bigEndian }
            self.receiveBody(on: connection, length: Int(length))
        }
    }

    private func receiveBody(on connection: NWConnection, length: Int) {
        connection.receive(minimumIncompleteLength: length, maximumLength: length) { [weak self] data, _, isComplete, error in
            guard let self else { return }

            if let data {
                Task { @MainActor in
                    if let payload = try? self.decoder.decode(TVDisplayPayload.self, from: data) {
                        self.latestPayload = payload
                    }
                }
            }

            if isComplete {
                Task { @MainActor in
                    self.isConnected = false
                }
            } else {
                // Continue reading next message
                self.receiveHeader(on: connection)
            }
        }
    }
}
