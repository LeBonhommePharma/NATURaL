import Foundation
import Network
import AVFoundation
import AVRouting
import Combine
import SwiftUI
import BonhommeCore

/// Orchestrates TV display delivery: prefers native tvOS companion via NWConnection,
/// falls back to AirPlay 2 second-screen via UIScene when unavailable.
///
/// State machine:
///   .idle → .searching → .nativeTV | .airplayAvailable → .airplaySecondScreen
///
/// Use `TVDisplayCoordinator.shared` so AirPlay external display (UIScene) and
/// the in-app workout path observe the same payload stream.
@MainActor
final class TVDisplayCoordinator: ObservableObject {

    /// Process-wide singleton — AppState + ExternalDisplaySceneDelegate must share this.
    static let shared = TVDisplayCoordinator()

    // MARK: - Display Mode

    enum DisplayMode: Equatable {
        case idle
        case searching
        case nativeTV
        case airplayAvailable
        case airplaySecondScreen
    }

    // MARK: - Published State

    @Published var mode: DisplayMode = .idle
    @Published var currentPayload: TVDisplayPayload?
    @Published var externalDisplayConnected = false

    // MARK: - Private

    private var browser: NWBrowser?
    private var nativeConnection: NWConnection?
    /// Endpoint of the last successful/attempted native TV — used for reconnect.
    private var lastNativeEndpoint: NWEndpoint?
    private let routeDetector = AVRouteDetector()
    private var searchTimeoutTask: Task<Void, Never>?
    private var reconnectTask: Task<Void, Never>?
    private var cancellables = Set<AnyCancellable>()
    private let encoder = JSONEncoder()
    /// Serializes connect/reconnect so browse bursts don't open multiple sockets.
    private var isConnecting = false
    /// Generation token: cancel in-flight state handlers after stop / replace.
    private var connectionGeneration = 0

    init() {
        // Observe external display connection from ExternalDisplaySceneDelegate
        $externalDisplayConnected
            .receive(on: DispatchQueue.main)
            .sink { [weak self] connected in
                guard let self else { return }
                if connected {
                    self.mode = .airplaySecondScreen
                } else if self.mode == .airplaySecondScreen {
                    // Prefer native if still up; otherwise idle/search.
                    self.mode = (self.nativeConnection != nil) ? .nativeTV : .idle
                }
            }
            .store(in: &cancellables)
    }

    // MARK: - Discovery

    /// Call when a workout session begins to start looking for TV displays.
    func beginTVDiscovery() {
        // Idempotent restart: tear down prior browser/connection first.
        stopNetworking(clearPayload: false)
        mode = .searching
        startBrowsingForNativeTV()
        routeDetector.isRouteDetectionEnabled = true

        // 3-second timeout: if no tvOS app, check AirPlay
        searchTimeoutTask = Task { [weak self] in
            try? await Task.sleep(for: .seconds(3))
            guard let self, !Task.isCancelled, self.mode == .searching else { return }

            if self.routeDetector.multipleRoutesDetected {
                self.mode = .airplayAvailable
            } else {
                self.mode = .idle
            }
        }
    }

    /// Call when the workout ends or the user navigates away.
    func stopTVDiscovery() {
        stopNetworking(clearPayload: true)
        mode = .idle
    }

    // MARK: - Data Relay

    /// Routes the payload to whichever TV display is active.
    func send(payload: TVDisplayPayload) {
        currentPayload = payload

        switch mode {
        case .nativeTV:
            sendOverNWConnection(payload)
        case .airplaySecondScreen:
            // No network send needed — ExternalDisplaySceneDelegate observes
            // currentPayload via this coordinator directly.
            break
        default:
            break
        }
    }

    // MARK: - Native tvOS Discovery (NWBrowser + Bonjour)

    private func startBrowsingForNativeTV() {
        let params = NWParameters.tcp
        // Local-only companion; disable proxying.
        params.includePeerToPeer = true
        let browser = NWBrowser(for: .bonjour(type: "_bonhomme._tcp", domain: nil), using: params)

        browser.browseResultsChangedHandler = { [weak self] results, _ in
            Task { @MainActor in
                guard let self else { return }
                // Already native-connected or connecting — ignore churn.
                guard self.mode != .nativeTV, !self.isConnecting else { return }
                guard let result = results.first else { return }
                self.searchTimeoutTask?.cancel()
                self.connectToNativeTV(endpoint: result.endpoint)
            }
        }

        browser.start(queue: .main)
        self.browser = browser
    }

    private func connectToNativeTV(endpoint: NWEndpoint) {
        isConnecting = true
        lastNativeEndpoint = endpoint
        connectionGeneration += 1
        let generation = connectionGeneration

        // Drop previous socket before opening a new one (avoids duplicate sends).
        nativeConnection?.cancel()
        nativeConnection = nil

        let connection = NWConnection(to: endpoint, using: .tcp)

        connection.stateUpdateHandler = { [weak self] state in
            Task { @MainActor in
                guard let self, generation == self.connectionGeneration else { return }
                switch state {
                case .ready:
                    self.isConnecting = false
                    self.nativeConnection = connection
                    self.mode = .nativeTV
                    self.reconnectTask?.cancel()
                    self.reconnectTask = nil
                    // Resend last payload so TV catches up after reconnect.
                    if let payload = self.currentPayload {
                        self.sendOverNWConnection(payload)
                    }
                case .failed, .cancelled:
                    self.handleNativeDisconnect(wasFailure: true)
                case .waiting:
                    // Transient (e.g. path down) — schedule reconnect without clearing mode yet.
                    break
                default:
                    break
                }
            }
        }

        connection.start(queue: .main)
        // Intentionally do NOT assign nativeConnection until .ready
        // so send() never writes to a half-open socket.
    }

    /// Connection dropped while we still want TV relay — fall back or reconnect.
    private func handleNativeDisconnect(wasFailure: Bool) {
        isConnecting = false
        nativeConnection = nil

        guard mode != .idle else { return }

        if externalDisplayConnected {
            mode = .airplaySecondScreen
            return
        }

        if routeDetector.multipleRoutesDetected {
            mode = .airplayAvailable
        } else {
            mode = .searching
        }

        if wasFailure, let endpoint = lastNativeEndpoint {
            scheduleReconnect(to: endpoint)
        }
    }

    /// Exponential backoff reconnect: 2s, 4s, 8s (mirrors NativeCompanionClient).
    private func scheduleReconnect(to endpoint: NWEndpoint) {
        reconnectTask?.cancel()
        reconnectTask = Task { [weak self] in
            for delay in [2, 4, 8] {
                try? await Task.sleep(for: .seconds(delay))
                guard let self, !Task.isCancelled else { return }
                // Stop if user ended session or already reconnected.
                guard self.mode != .idle, self.nativeConnection == nil else { return }
                self.connectToNativeTV(endpoint: endpoint)
                try? await Task.sleep(for: .seconds(2))
                if self.mode == .nativeTV { return }
            }
        }
    }

    private func stopNetworking(clearPayload: Bool) {
        searchTimeoutTask?.cancel()
        searchTimeoutTask = nil
        reconnectTask?.cancel()
        reconnectTask = nil
        connectionGeneration += 1
        isConnecting = false
        browser?.cancel()
        browser = nil
        nativeConnection?.cancel()
        nativeConnection = nil
        lastNativeEndpoint = nil
        routeDetector.isRouteDetectionEnabled = false
        if clearPayload {
            currentPayload = nil
        }
    }

    // MARK: - Length-Prefixed NWConnection Sending

    private func sendOverNWConnection(_ payload: TVDisplayPayload) {
        guard let connection = nativeConnection else { return }
        guard let data = try? encoder.encode(payload) else { return }
        // Bound frame size — oversized encode is dropped rather than fragmenting badly.
        guard let frame = TVRelayFraming.encodeLengthPrefixed(data) else { return }

        connection.send(content: frame, completion: .contentProcessed { [weak self] error in
            if error != nil {
                Task { @MainActor in
                    // stateUpdateHandler may also fire; force a reconnect attempt.
                    self?.handleNativeDisconnect(wasFailure: true)
                }
            }
        })
    }
}
