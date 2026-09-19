import Network
import SwiftUI
import BonhommeCore

/// Explicit, ephemeral TV pairing. No listener exists before the user asks to pair.
@MainActor
final class CompanionListener: ObservableObject {
    @Published private(set) var latestPayload: TVDisplayPayload?
    @Published private(set) var isConnected = false
    @Published private(set) var isAdvertising = false
    @Published private(set) var invitation: TVRelayPairing?
    @Published private(set) var failedToStart = false
    private var credential: TVRelayPairing?
    private var expiresAt: TimeInterval = 0
    private var listener: NWListener?
    private var activeConnection: NWConnection?
    private var candidates: [ObjectIdentifier: NWConnection] = [:]
    private var candidateDeadlines: [ObjectIdentifier: Task<Void, Never>] = [:]
    private var lifetimeTask: Task<Void, Never>?
    private var freshnessTask: Task<Void, Never>?
    private var listenerGeneration = 0
    private var connectionGeneration = 0
    private var received = TVRelayReceiveState()
    private var lastActivity: TimeInterval = 0

    func startAdvertising() {
        stopAdvertising()
        do {
            let credential = try TVRelayPairing.generate()
            let listener = try NWListener(using: credential.parameters())
            self.credential = credential; invitation = credential
            expiresAt = TVRelayClock.now + TVRelayPairing.lifetime
            listenerGeneration += 1
            let token = listenerGeneration
            listener.service = NWListener.Service(name: credential.serviceName, type: TVRelayPairing.serviceType)
            listener.stateUpdateHandler = { [weak self] state in
                Task { @MainActor in
                    guard let self, self.listenerGeneration == token else { return }
                    switch state {
                    case .ready: self.isAdvertising = true
                    case .failed:
                        self.failedToStart = true; self.stopAccepting()
                    case .cancelled: self.isAdvertising = false
                    default: break
                    }
                }
            }
            listener.newConnectionHandler = { [weak self] connection in
                Task { @MainActor in
                    guard let self, self.listenerGeneration == token else { connection.cancel(); return }
                    self.acceptCandidate(connection, listenerGeneration: token)
                }
            }
            self.listener = listener
            listener.start(queue: .main)
            lifetimeTask = Task { [weak self] in
                do { try await Task.sleep(for: .seconds(TVRelayPairing.lifetime)) } catch { return }
                self?.stopAccepting()
            }
        } catch {
            failedToStart = true; stopAccepting()
        }
    }

    func stopAdvertising() {
        stopAccepting()
        endActiveConnection()
        failedToStart = false
    }

    private func stopAccepting() {
        listenerGeneration += 1
        lifetimeTask?.cancel(); lifetimeTask = nil
        listener?.stateUpdateHandler = nil; listener?.cancel(); listener = nil
        for connection in candidates.values { connection.stateUpdateHandler = nil; connection.cancel() }
        candidates.removeAll()
        for deadline in candidateDeadlines.values { deadline.cancel() }
        candidateDeadlines.removeAll()
        credential = nil; invitation = nil; isAdvertising = false
    }

    private func acceptCandidate(_ connection: NWConnection, listenerGeneration token: Int) {
        guard activeConnection == nil, candidates.count < 2, TVRelayClock.now < expiresAt else {
            connection.cancel(); return
        }
        let id = ObjectIdentifier(connection)
        candidates[id] = connection
        connection.stateUpdateHandler = { [weak self, weak connection] state in
            Task { @MainActor in
                guard let self, let connection else { return }
                if self.activeConnection === connection {
                    if case .failed = state { self.endActiveConnection() }
                    if case .cancelled = state { self.endActiveConnection() }
                    return
                }
                guard self.listenerGeneration == token, self.candidates[id] === connection else { return }
                switch state {
                case .ready:
                    guard self.activeConnection == nil, TVRelayClock.now < self.expiresAt else {
                        self.removeCandidate(id); return
                    }
                    self.candidates.removeValue(forKey: id)
                    self.candidateDeadlines.removeValue(forKey: id)?.cancel()
                    for other in Array(self.candidates.keys) { self.removeCandidate(other) }
                    self.connectionGeneration += 1
                    self.activeConnection = connection; self.isConnected = true; self.invitation = nil
                    self.received = TVRelayReceiveState(); self.lastActivity = TVRelayClock.now
                    self.receiveHeader(on: connection, generation: self.connectionGeneration)
                    self.startFreshnessChecks()
                case .failed, .cancelled: self.removeCandidate(id)
                default: break
                }
            }
        }
        candidateDeadlines[id] = Task { [weak self] in
            do { try await Task.sleep(for: .seconds(8)) } catch { return }
            self?.removeCandidate(id)
        }
        connection.start(queue: .main)
    }

    private func removeCandidate(_ id: ObjectIdentifier) {
        candidateDeadlines.removeValue(forKey: id)?.cancel()
        if let connection = candidates.removeValue(forKey: id) {
            connection.stateUpdateHandler = nil; connection.cancel()
        }
    }

    private func startFreshnessChecks() {
        freshnessTask?.cancel()
        freshnessTask = Task { [weak self] in
            while !Task.isCancelled {
                do { try await Task.sleep(for: .seconds(1)) } catch { return }
                guard let self else { return }
                self.checkFreshness()
            }
        }
    }

    private func checkFreshness() {
        guard activeConnection != nil else { return }
        if TVRelayClock.now - lastActivity > TVRelayReceiveState.freshnessTimeout {
            endActiveConnection()
        }
    }

    private func receiveHeader(on connection: NWConnection, generation: Int) {
        connection.receive(minimumIncompleteLength: 4, maximumLength: 4) { [weak self] data, _, complete, error in
            Task { @MainActor in
                guard let self, self.connectionGeneration == generation, self.activeConnection === connection else { return }
                guard error == nil, !complete, let data,
                      let length = TVRelayFraming.decodeBodyLength(fromHeader: data) else {
                    self.endActiveConnection(); return
                }
                self.receiveBody(on: connection, length: length, generation: generation)
            }
        }
    }

    private func receiveBody(on connection: NWConnection, length: Int, generation: Int) {
        connection.receive(minimumIncompleteLength: length, maximumLength: length) { [weak self] data, _, complete, error in
            Task { @MainActor in
                guard let self, self.connectionGeneration == generation, self.activeConnection === connection else { return }
                guard error == nil, let data, data.count == length,
                      let message = try? JSONDecoder().decode(TVRelayMessage.self, from: data),
                      self.received.accept(message, at: TVRelayClock.now) else {
                    self.endActiveConnection(); return
                }
                self.lastActivity = TVRelayClock.now
                self.latestPayload = self.received.payload
                if complete || self.received.ended { self.endActiveConnection() }
                else { self.receiveHeader(on: connection, generation: generation) }
            }
        }
    }

    private func endActiveConnection() {
        connectionGeneration += 1
        freshnessTask?.cancel(); freshnessTask = nil
        activeConnection?.stateUpdateHandler = nil; activeConnection?.cancel(); activeConnection = nil
        received = TVRelayReceiveState(); latestPayload = nil; isConnected = false
        invitation = isAdvertising && TVRelayClock.now < expiresAt ? credential : nil
    }
}
