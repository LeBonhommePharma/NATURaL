import Foundation
import BonhommeCore

#if canImport(UIKit)
import UIKit
#endif
#if canImport(AppKit) && !targetEnvironment(macCatalyst)
import AppKit
#endif

// MARK: - Presence coordinator (Watch auto-upsert + iCloud peers)

/// Keeps `ClusterFleet` membership live across the Apple ecosystem:
///
/// 1. **Watch** — auto-upsert from `PhoneConnectivityBridge` (paired / reachable)
/// 2. **iCloud peers** — iPhone / iPad / Mac on the **same Apple ID** via
///    `NSUbiquitousKeyValueStore` heartbeats (`FleetPresenceRecord`)
/// 3. **Buffer samples** — accepts continuous measurements from
///    `LowLatencyAudioRouter` while the engine runs
///
/// Does not own `UniversalBeatSync`. Start once from `AppState`.
@MainActor
final class ClusterFleetPresenceCoordinator {
    static let shared = ClusterFleetPresenceCoordinator()

    /// How often we write our presence + re-read peers.
    var heartbeatInterval: TimeInterval = 15

    private var heartbeatTask: Task<Void, Never>?
    private var kvsObserver: NSObjectProtocol?
    private var started = false
    private var lastPublishedBufferMs: Double = 0

    private let fleet: ClusterFleet
    private let defaults: UserDefaults

    /// Stable id for this install (persisted in UserDefaults).
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

        Task {
            await ensureLocalHostInFleet()
            await publishLocalPresence(sessionActive: false)
            await pullRemotePresence()
        }

        startHeartbeatLoop()
        observeUbiquitousStore()
        NSUbiquitousKeyValueStore.default.synchronize()
    }

    func stop() {
        started = false
        heartbeatTask?.cancel()
        heartbeatTask = nil
        if let kvsObserver {
            NotificationCenter.default.removeObserver(kvsObserver)
            self.kvsObserver = nil
        }
        Task {
            await publishLocalPresence(sessionActive: false, isActive: false)
        }
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

    /// Hot path: engine loop already wrote fleet latency; refresh presence when buffer moves.
    func noteEngineBufferSample(ms: Double) async {
        guard ms > 0 else { return }
        // Avoid spamming KVS every second if unchanged within 0.25 ms.
        if abs(ms - lastPublishedBufferMs) < 0.25, lastPublishedBufferMs > 0 {
            return
        }
        lastPublishedBufferMs = ms
        await publishLocalPresence(sessionActive: true)
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

    private func startHeartbeatLoop() {
        heartbeatTask?.cancel()
        heartbeatTask = Task { [weak self] in
            while !Task.isCancelled {
                guard let self else { return }
                let sessionActive = LowLatencyAudioRouter.shared.isRunning
                await self.publishLocalPresence(sessionActive: sessionActive)
                await self.pullRemotePresence()
                await self.fleet.pruneStaleCompanions()
                try? await Task.sleep(for: .seconds(self.heartbeatInterval))
            }
        }
    }

    private func observeUbiquitousStore() {
        kvsObserver = NotificationCenter.default.addObserver(
            forName: NSUbiquitousKeyValueStore.didChangeExternallyNotification,
            object: NSUbiquitousKeyValueStore.default,
            queue: .main
        ) { [weak self] _ in
            Task { @MainActor in
                await self?.pullRemotePresence()
            }
        }
    }

    private func publishLocalPresence(
        sessionActive: Bool,
        isActive: Bool = true
    ) async {
        let bufferMs = LowLatencyAudioRouter.shared.achievedIOBufferDuration * 1000.0
        let buffer = bufferMs > 0 ? bufferMs : (lastPublishedBufferMs > 0 ? lastPublishedBufferMs : nil)
        let record = FleetPresenceRecord(
            deviceId: localDeviceId,
            displayName: localDisplayName,
            platform: currentPlatform,
            bufferLatencyMs: buffer,
            pathLatencyMs: buffer,
            isActive: isActive,
            sessionActive: sessionActive,
            updatedAt: Date()
        )
        await fleet.ensureLocalHost(
            id: localDeviceId,
            platform: currentPlatform,
            displayName: localDisplayName,
            bufferLatencyMs: buffer
        )
        guard let data = try? FleetPresenceCodec.encode(record) else { return }
        let store = NSUbiquitousKeyValueStore.default
        store.set(data, forKey: FleetPresenceRecord.kvsKey(for: localDeviceId))
        store.synchronize()
    }

    private func pullRemotePresence() async {
        let store = NSUbiquitousKeyValueStore.default
        var map: [String: Data] = [:]
        for key in store.dictionaryRepresentation.keys {
            guard key.hasPrefix(FleetPresenceRecord.kvsKeyPrefix),
                  let data = store.data(forKey: key) else { continue }
            map[key] = data
        }
        let records = FleetPresenceCodec.decodeAll(from: map)
        await fleet.applyPresenceRecords(records, localDeviceId: localDeviceId)
    }
}
