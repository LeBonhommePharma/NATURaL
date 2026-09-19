import Foundation
import Combine
import Network
import BonhommeCore

/// One explicitly paired TLS connection. Never discovers or selects a television.
@MainActor
final class NativeCompanionClient: ObservableObject {
    @Published private(set) var isConnected = false
    @Published private(set) var isConnecting = false
    var stateChanged: (() -> Void)?
    var becameReady: (() -> Void)?
    private var connection: NWConnection?
    private var endpoint: NWEndpoint?
    private var pairing: TVRelayPairing?
    private var generation = 0
    private var retryCount = 0
    private var retryTask: Task<Void, Never>?
    private var deadlineTask: Task<Void, Never>?
    private var buffer = TVRelayLatestFrameBuffer()
    private var closing = false

    func connect(to endpoint: NWEndpoint, pairing: TVRelayPairing) {
        disconnect()
        self.endpoint = endpoint; self.pairing = pairing; retryCount = 0
        beginAttempt()
    }

    func disconnect() {
        generation += 1
        retryTask?.cancel(); retryTask = nil
        deadlineTask?.cancel(); deadlineTask = nil
        connection?.stateUpdateHandler = nil
        connection?.cancel(); connection = nil
        endpoint = nil; pairing = nil; closing = false
        buffer.reset(); isConnected = false; isConnecting = false
        stateChanged?()
    }

    private func beginAttempt() {
        guard let endpoint, let pairing, !closing else { return }
        generation += 1
        let token = generation
        connection?.cancel(); buffer.reset()
        let connection = NWConnection(to: endpoint, using: pairing.parameters())
        self.connection = connection
        isConnecting = true; isConnected = false; stateChanged?()
        connection.stateUpdateHandler = { [weak self, weak connection] state in
            Task { @MainActor in
                guard let self, let connection, self.generation == token, self.connection === connection else { return }
                switch state {
                case .ready:
                    self.deadlineTask?.cancel(); self.deadlineTask = nil
                    self.isConnecting = false; self.isConnected = true; self.retryCount = 0
                    self.stateChanged?(); self.becameReady?(); self.drain()
                    self.monitorClosure(connection, generation: token)
                case .failed, .cancelled: self.failed(generation: token)
                default: break
                }
            }
        }
        connection.start(queue: .main)
        deadlineTask?.cancel()
        deadlineTask = Task { [weak self] in
            do { try await Task.sleep(for: .seconds(8)) } catch { return }
            self?.failed(generation: token)
        }
    }

    private func monitorClosure(_ connection: NWConnection, generation: Int) {
        connection.receive(minimumIncompleteLength: 1, maximumLength: 1) { [weak self] _, _, _, _ in
            Task { @MainActor in self?.failed(generation: generation) }
        }
    }

    private func failed(generation token: Int) {
        guard token == generation else { return }
        generation += 1
        connection?.stateUpdateHandler = nil; connection?.cancel(); connection = nil
        deadlineTask?.cancel(); deadlineTask = nil
        buffer.reset(); isConnected = false; isConnecting = false; stateChanged?()
        guard !closing, endpoint != nil, pairing != nil, retryCount < 3 else { return }
        let delay = [2, 4, 8][retryCount]
        retryCount += 1
        retryTask?.cancel()
        retryTask = Task { [weak self] in
            do { try await Task.sleep(for: .seconds(delay)) } catch { return }
            guard !Task.isCancelled else { return }
            self?.beginAttempt()
        }
    }

    func send(_ message: TVRelayMessage) {
        guard isConnected, !closing, let data = try? JSONEncoder().encode(message),
              let frame = TVRelayFraming.encodeLengthPrefixed(data) else { return }
        buffer.offer(frame); drain()
    }

    /// Deliver end after the in-flight state, with a short bounded flush deadline.
    func finish(with message: TVRelayMessage) {
        guard isConnected else { disconnect(); return }
        send(message)
        closing = true
        retryTask?.cancel()
        let token = generation
        deadlineTask?.cancel()
        deadlineTask = Task { [weak self] in
            do { try await Task.sleep(for: .seconds(2)) } catch { return }
            guard let self, self.generation == token else { return }
            self.disconnect()
        }
    }

    private func drain() {
        guard isConnected, let connection else { return }
        guard let frame = buffer.takeNext() else {
            if closing && !buffer.isSending { disconnect() }
            return
        }
        let token = generation
        connection.send(content: frame, completion: .contentProcessed { [weak self] error in
            Task { @MainActor in
                guard let self, self.generation == token else { return }
                if error != nil { self.failed(generation: token); return }
                self.buffer.completed(); self.drain()
            }
        })
    }
}
