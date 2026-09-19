import Foundation
import Network
import AVFoundation
import Combine
import BonhommeCore

/// Consent-led native TLS relay plus the system AirPlay/HDMI external scene.
/// Discovery lists televisions; only an explicit pair call authorizes transmission.
@MainActor
final class TVDisplayCoordinator: ObservableObject {
    static let shared = TVDisplayCoordinator()
    enum DisplayMode: Equatable { case idle, searching, nativeTV, airplayAvailable, airplaySecondScreen }
    struct DiscoveredTV: Identifiable {
        let id: UUID
        let name: String
        fileprivate let endpoint: NWEndpoint
    }
    enum PairingError: LocalizedError {
        case televisionNotFound
        var errorDescription: String? { TVRelayCopy.notFound.localized }
    }
    @Published var displayEnabled = false
    @Published private(set) var mode: DisplayMode = .idle
    @Published private(set) var currentPayload: TVDisplayPayload?
    @Published private(set) var discoveredTVs: [DiscoveredTV] = []
    @Published private(set) var nativeConnected = false
    @Published private(set) var nativeConnecting = false
    @Published private(set) var discoveryUnavailable = false
    @Published var externalDisplayConnected = false { didSet { refreshMode() } }
    private let native = NativeCompanionClient()
    private let routeDetector = AVRouteDetector()
    private var routeObservation: NSObjectProtocol?
    private var browser: NWBrowser?
    private var generation = 0
    private var heartbeat: Task<Void, Never>?
    private var sessionID = UUID()
    private var sequence: UInt64 = 0
    private var lastPayloadAt: TimeInterval?
    private var isDiscovering = false

    init() {
        native.stateChanged = { [weak self] in
            guard let self else { return }
            self.nativeConnected = self.native.isConnected
            self.nativeConnecting = self.native.isConnecting
            self.refreshMode()
        }
        native.becameReady = { [weak self] in self?.sendHeartbeat() }
    }

    func beginTVDiscovery() {
        guard !isDiscovering else { return }
        isDiscovering = true; discoveryUnavailable = false
        generation += 1
        let token = generation
        routeDetector.isRouteDetectionEnabled = true
        routeObservation = NotificationCenter.default.addObserver(
            forName: Notification.Name.AVRouteDetectorMultipleRoutesDetectedDidChange,
            object: routeDetector, queue: .main) { [weak self] _ in
                Task { @MainActor in self?.refreshMode() }
            }
        let parameters = NWParameters.tcp
        parameters.includePeerToPeer = true
        let browser = NWBrowser(for: .bonjour(type: TVRelayPairing.serviceType, domain: nil), using: parameters)
        browser.browseResultsChangedHandler = { [weak self] results, _ in
            Task { @MainActor in
                guard let self, self.generation == token else { return }
                self.discoveredTVs = results.compactMap { result in
                    guard case .service(let name, _, _, _) = result.endpoint,
                          let id = TVRelayPairing.identifier(serviceName: name) else { return nil }
                    return DiscoveredTV(id: id, name: "NATURaL TV · " + id.uuidString.prefix(8), endpoint: result.endpoint)
                }.sorted { $0.name < $1.name }
                self.refreshMode()
            }
        }
        browser.stateUpdateHandler = { [weak self] state in
            Task { @MainActor in
                guard let self, self.generation == token else { return }
                switch state {
                case .failed, .waiting: self.discoveryUnavailable = true
                case .ready: self.discoveryUnavailable = false
                default: break
                }
            }
        }
        self.browser = browser
        browser.start(queue: .main)
        heartbeat = Task { [weak self] in
            while !Task.isCancelled {
                do { try await Task.sleep(for: .seconds(1)) } catch { return }
                guard !Task.isCancelled, let self else { return }
                self.sendHeartbeat()
            }
        }
        refreshMode()
    }

    /// Call only after the user selects this television and confirms sharing.
    func pair(with televisionID: UUID, key: String) throws {
        let pairing = try TVRelayPairing(id: televisionID, code: key)
        guard let television = discoveredTVs.first(where: { $0.id == televisionID }) else {
            throw PairingError.televisionNotFound
        }
        native.connect(to: television.endpoint, pairing: pairing)
    }

    /// Parsing a URL does not connect; the caller presents consent before this call.
    func pair(invitationURL: URL) throws {
        let invitation = try TVRelayPairing(url: invitationURL)
        try pair(with: invitation.id, key: invitation.code)
    }

    func disconnectNativeTV() {
        native.finish(with: message(.end))
    }

    func stopTVDiscovery() {
        displayEnabled = false
        native.finish(with: message(.end))
        generation += 1; isDiscovering = false
        browser?.cancel(); browser = nil; discoveredTVs = []
        heartbeat?.cancel(); heartbeat = nil
        if let routeObservation { NotificationCenter.default.removeObserver(routeObservation) }
        routeObservation = nil
        routeDetector.isRouteDetectionEnabled = false
        currentPayload = nil; lastPayloadAt = nil
        sessionID = UUID(); sequence = 0
        refreshMode()
    }

    /// Publish only while the user has opted into TV display. Health data remains
    /// local unless an authenticated native television has explicitly been paired.
    func send(payload: TVDisplayPayload) {
        guard displayEnabled else { clearPayload(); return }
        currentPayload = payload; lastPayloadAt = TVRelayClock.now
        native.send(message(.state, payload: payload))
    }

    /// Remove the pose during transitions, completion, or other non-display phases.
    func clearPayload() {
        currentPayload = nil; lastPayloadAt = nil
        native.send(message(.clear))
    }

    private func sendHeartbeat() {
        if let lastPayloadAt, TVRelayClock.now - lastPayloadAt > 3 {
            currentPayload = nil; self.lastPayloadAt = nil
        }
        if let currentPayload { native.send(message(.state, payload: currentPayload)) }
        else { native.send(message(.clear)) }
    }

    private func message(_ kind: TVRelayMessage.Kind, payload: TVDisplayPayload? = nil) -> TVRelayMessage {
        sequence += 1
        return TVRelayMessage(sessionID: sessionID, sequence: sequence, kind: kind, payload: payload)
    }

    private func refreshMode() {
        if externalDisplayConnected { mode = .airplaySecondScreen }
        else if native.isConnected { mode = .nativeTV }
        else if routeDetector.multipleRoutesDetected { mode = .airplayAvailable }
        else { mode = isDiscovering ? .searching : .idle }
    }
}
