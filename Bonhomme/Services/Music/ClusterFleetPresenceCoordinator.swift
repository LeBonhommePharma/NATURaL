import Foundation
import BonhommeCore

#if canImport(UIKit)
import UIKit
#endif
#if canImport(AppKit) && !targetEnvironment(macCatalyst)
import AppKit
#endif

// MARK: - Presence coordinator (local host + Watch)

/// Keeps `ClusterFleet` membership on this device only:
///
/// 1. **Watch** — auto-upsert from `PhoneConnectivityBridge` (paired / reachable)
/// 2. **Buffer samples** — accepts continuous measurements from
///    `LowLatencyAudioRouter` while the engine runs
///
/// Does not publish presence off this device.
/// Does not own `UniversalBeatSync`. Start once from `AppState`.
@MainActor
final class ClusterFleetPresenceCoordinator {
    static let shared = ClusterFleetPresenceCoordinator()

    private var started = false
    private var lastPublishedBufferMs: Double = 0

    private let fleet: ClusterFleet
    private let defaults: UserDefaults

    /// Stable id for this install (persisted in UserDefaults on this device).
    private(set) lazy var localDeviceId: String = {
        FleetLocalIdentity.stableDeviceId(
            stored: defaults.string(forKey: FleetLocalIdentity.userDefaultsKey)
        ) { id in
            defaults.set(id, forKey: FleetLocalIdentity.userDefaultsKey)
        }
    }()

    init(fleet: ClusterFleet = .shared, defaults: UserDefaults = .standard) {
        self.fleet = fleet
        self.defaults = defaults
    }

    // MARK: - Lifecycle

    func start() {
        guard !started else { return }
        started = true
        Task { await ensureLocalHostInFleet() }
    }

    func stop() {
        started = false
    }

    // MARK: - Watch auto-upsert

    /// Call from `PhoneConnectivityBridge` on activation / reachability changes.
    ///
    /// - Paired + reachable → active Watch companion
    /// - Paired + unreachable → membership kept, inactive
    /// - Not paired → inactive
    func syncWatchCompanion(isPaired: Bool, isReachable: Bool, watchName: String? = nil) {
        let id = "watch-companion"
        let name = watchName ?? "Apple Watch"
        Task {
            if !isPaired {
                await fleet.upsertCompanion(
                    id: id,
                    kind: .watchCompanion,
                    displayName: name,
                    active: false,
                    platform: .watchOS
                )
                return
            }
            await fleet.upsertCompanion(
                id: id,
                kind: .watchCompanion,
                displayName: name,
                latencyMs: FleetDeviceKind.watchCompanion.defaultLatencyMs,
                active: isReachable,
                platform: .watchOS
            )
        }
    }

    // MARK: - Buffer sample (from LowLatencyAudioRouter loop)

    /// Hot path: engine loop already wrote fleet latency; refresh local membership when buffer moves.
    func noteEngineBufferSample(ms: Double) async {
        guard ms > 0 else { return }
        if abs(ms - lastPublishedBufferMs) < 0.25, lastPublishedBufferMs > 0 {
            return
        }
        lastPublishedBufferMs = ms
        await publishLocalPresence()
    }

    // MARK: - Platform identity

    var currentPlatform: FleetPlatform {
        #if os(macOS)
        return .macOS
        #elseif os(watchOS)
        return .watchOS
        #elseif os(tvOS)
        return .tvOS
        #elseif os(visionOS)
        return .visionOS
        #elseif os(iOS)
        #if targetEnvironment(macCatalyst)
        return .macOS
        #else
        #if canImport(UIKit)
        if UIDevice.current.userInterfaceIdiom == .pad { return .iPadOS }
        #endif
        return .iOS
        #endif
        #else
        return .unknown
        #endif
    }

    var localDisplayName: String {
        #if canImport(UIKit)
        return FleetLocalIdentity.defaultDisplayName(
            platform: currentPlatform,
            systemName: UIDevice.current.name
        )
        #elseif canImport(AppKit) && !targetEnvironment(macCatalyst)
        return FleetLocalIdentity.defaultDisplayName(
            platform: .macOS,
            systemName: Host.current().localizedName
        )
        #else
        return FleetLocalIdentity.defaultDisplayName(platform: currentPlatform, systemName: nil)
        #endif
    }

    // MARK: - Private

    private func ensureLocalHostInFleet() async {
        await fleet.ensureLocalHost(
            id: localDeviceId,
            platform: currentPlatform,
            displayName: localDisplayName
        )
    }

    private func publishLocalPresence() async {
        let bufferMs = LowLatencyAudioRouter.shared.achievedIOBufferDuration * 1000.0
        let buffer = bufferMs > 0 ? bufferMs : (lastPublishedBufferMs > 0 ? lastPublishedBufferMs : nil)
        await fleet.ensureLocalHost(
            id: localDeviceId,
            platform: currentPlatform,
            displayName: localDisplayName,
            bufferLatencyMs: buffer
        )
    }
}
