import Network
import AVRouting
import Combine
import SwiftUI
import BonhommeCore

/// Orchestrates TV display delivery: prefers native tvOS companion via NWConnection,
/// falls back to AirPlay 2 second-screen via UIScene when unavailable.
///
/// State machine:
///   .idle → .searching → .nativeTV | .airplayAvailable → .airplaySecondScreen
@MainActor
final class TVDisplayCoordinator: ObservableObject {

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
    private let routeDetector = AVRouteDetector()
    private var searchTimeoutTask: Task<Void, Never>?
    private var cancellables = Set<AnyCancellable>()
    private let encoder = JSONEncoder()

    init() {
        // Observe external display connection from ExternalDisplaySceneDelegate
        $externalDisplayConnected
            .receive(on: DispatchQueue.main)
            .sink { [weak self] connected in
                guard let self else { return }
                if connected {
                    self.mode = .airplaySecondScreen
                } else if self.mode == .airplaySecondScreen {
                    self.mode = .idle
                }
            }
            .store(in: &cancellables)
    }

    // MARK: - Discovery

    /// Call when a workout session begins to start looking for TV displays.
    func beginTVDiscovery() {
        mode = .searching
        startBrowsingForNativeTV()
        routeDetector.isRouteDetectionEnabled = true

        // 3-second timeout: if no tvOS app, check AirPlay
        searchTimeoutTask = Task {
            try? await Task.sleep(for: .seconds(3))
            guard !Task.isCancelled, mode == .searching else { return }

            if routeDetector.multipleRoutesDetected {
                mode = .airplayAvailable
            } else {
                mode = .idle
            }
        }
    }

    /// Call when the workout ends or the user navigates away.
    func stopTVDiscovery() {
        searchTimeoutTask?.cancel()
        browser?.cancel()
        browser = nil
        nativeConnection?.cancel()
        nativeConnection = nil
        routeDetector.isRouteDetectionEnabled = false
        mode = .idle
        currentPayload = nil
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
        browser = NWBrowser(for: .bonjour(type: "_bonhomme._tcp", domain: nil), using: params)

        browser?.browseResultsChangedHandler = { [weak self] results, _ in
            guard let self, let result = results.first else { return }
            Task { @MainActor in
                self.searchTimeoutTask?.cancel()
                self.connectToNativeTV(endpoint: result.endpoint)
            }
        }

        browser?.start(queue: .main)
    }

    private func connectToNativeTV(endpoint: NWEndpoint) {
        let connection = NWConnection(to: endpoint, using: .tcp)

        connection.stateUpdateHandler = { [weak self] state in
            Task { @MainActor in
                guard let self else { return }
                switch state {
                case .ready:
                    self.mode = .nativeTV
                    self.nativeConnection = connection
                case .failed:
                    self.nativeConnection = nil
                    // Fall back to AirPlay if available
                    if self.routeDetector.multipleRoutesDetected {
                        self.mode = .airplayAvailable
                    } else {
                        self.mode = .idle
                    }
                default:
                    break
                }
            }
        }

        connection.start(queue: .main)
        nativeConnection = connection
    }

    // MARK: - Length-Prefixed NWConnection Sending

    private func sendOverNWConnection(_ payload: TVDisplayPayload) {
        guard let connection = nativeConnection,
              let data = try? encoder.encode(payload) else { return }

        // Length-prefixed framing: 4-byte big-endian length + JSON body
        var length = UInt32(data.count).bigEndian
        let header = Data(bytes: &length, count: 4)

        connection.send(content: header + data, completion: .contentProcessed { error in
            if error != nil {
                // Connection may be broken; will be caught by stateUpdateHandler
            }
        })
    }
}
