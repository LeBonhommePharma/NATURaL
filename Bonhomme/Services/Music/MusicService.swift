import Foundation
import Combine
import AVFoundation
import MusicKit
import BonhommeCore

/// Apple Music workout playlists with SCI-driven mood transitions.
///
/// Coherence high → energizing; coherence low → meditative. Debounced (30s).
///
/// # Crossfade architecture (read before changing)
///
/// ## Hard constraints
/// - MusicKit exposes a **single** `ApplicationMusicPlayer.shared` — you cannot run two
///   independent Apple Music queues. Dual MusicKit playback is impossible.
/// - `MusicPlayer.State` has `playbackRate` but **no volume** API on current SDKs.
/// - **Tempo:** only `applyBeatSync` may write `playbackRate`. Never use rate as a volume fader.
/// - **`isCrossfading`:** must suspend beat-rate updates for the whole transition.
/// - **Do not** ramp system volume / `MPVolumeView` — AirPods volume rocker drives
///   crown-β (`AirPodsCrownBeta`); system-volume fades would corrupt control state.
///
/// ## Paths (best available)
/// 1. **Local dual engine** (`LocalDualCrossfadeEngine`): true overlapping volume
///    crossfade via two `AVAudioPlayerNode`s + mixer gains. Used when playing local
///    file URLs (non-MusicKit assets).
/// 2. **MusicKit iOS 18+**: `ApplicationMusicPlayer.transition = .crossfade(duration:)`.
///    Mood switch = insert next playlist after current entry + `skipToNextEntry()`.
///    Apple’s player performs a real internal volume crossfade into the new content.
///    Playlist cache + search `limit = 1` keep the insert hot-path offline.
/// 3. **MusicKit fallback** (iOS 17, no current entry, or insert/skip failure):
///    prefetch-backed queue replace with a short silent gap. Per-player volume fade-out
///    is unavailable without a volume API; gap is minimized by cache-first resolve.
///
/// Playlist cache, search `limit = 1`, and `prefetchPlaylists` are retained on all paths.
@MainActor
final class MusicService: ObservableObject {
    @Published var isAuthorized = false
    @Published var isPlaying = false
    @Published private(set) var adaptiveMood: WorkoutMood = .calm
    /// Last snapshot from universal beat sync.
    @Published private(set) var lastBeat: BeatSyncSnapshot?
    /// True while a mood transition is in flight — beat-rate updates are suspended.
    @Published private(set) var isCrossfading = false

    /// Volume crossfade length (seconds). Matches product copy (“3s crossfade”).
    static let crossfadeDuration: TimeInterval = 3.0

    /// Minimum interval between mood transitions to avoid jarring rapid switches.
    /// Sole debounce owner for adaptive music (callers must not layer a second 30s gate).
    private let transitionDebounce: TimeInterval = 30
    private var lastTransitionDate: Date = .distantPast
    private var fadeTask: Task<Void, Never>?
    private var beatBound = false
    private var routeObserver: NSObjectProtocol?

    /// Playlist cache keyed by (mood rawValue, style rawValue or "default").
    private var playlistCache: [String: Playlist] = [:]

    /// Active playback backend.
    private var backend: PlaybackBackend = .musicKit
    /// True dual-player engine for local (non-MusicKit) assets only.
    private var localEngine: LocalDualCrossfadeEngine?

    /// Nominal track BPM assumed for playback-rate scaling (MusicKit has no beat grid).
    private let assumedTrackBPM: Double = 120

    private enum PlaybackBackend {
        case musicKit
        case localDual
    }

    // MARK: - Authorization / beat

    func requestAuthorization() async {
        let status = await MusicAuthorization.request()
        isAuthorized = status == .authorized
    }

    /// Bind once to `UniversalBeatSync` for session tempo lock and start AirPods route observer.
    /// Safe to call again after `stop()` (which resets `beatBound` and clears listeners).
    ///
    /// ## Tempo authority (listener-only — issue #11)
    /// Architecture is **listener-only**, not VM-direct:
    /// 1. Control tick → `BeatSyncActuatorChannel` → `UniversalBeatSync.broadcast` (once)
    /// 2. This install is the **sole** MusicKit listener → private `applyBeatSync`
    /// 3. `WorkoutFlowViewModel.tickPharmaControl` must **not** call rate APIs
    /// 4. Watch crown / AirPods mutate β only on the bus path (no phone `playbackRate`)
    /// 5. First-play / post-crossfade re-apply via the same private method (restore, not a second owner)
    /// 6. Same broadcast also updates `ClusterFleet` spatial/tempo state (not a second beat authority)
    func bindUniversalBeatSync() {
        guard !beatBound else { return }
        beatBound = true
        startAudioRouteObserver()
        Task { [weak self] in
            // Session-scoped: replace so we never stack listeners across rebinds.
            await UniversalBeatSync.shared.replaceListeners([
                { snap in await self?.applyBeatSync(snap) }
            ])
            // Warm low-latency session from current fleet quality profile.
            // `apply` also starts continuous buffer → fleet publish while running.
            try? await LowLatencyAudioRouter.shared.applyFromFleet()
            // Ensure iCloud presence / Watch membership loops are live for the session.
            ClusterFleetPresenceCoordinator.shared.start()
        }
    }

    /// Sole writer of MusicKit `playbackRate` (listener + first-play / post-crossfade restore).
    /// `private` so control ticks / crown / AirPods cannot reintroduce a second rate path (#11).
    /// Skipped while crossfading so volume transitions do not race tempo.
    /// Local dual-engine path has no MusicKit rate control (nodes stay at rate 1.0).
    private func applyBeatSync(_ snap: BeatSyncSnapshot) async {
        lastBeat = snap
        // Fleet adopts tempo/β for spatial + latency plan (listener path only).
        await ClusterFleet.shared.adoptBeat(snap)
        let fleetSnap = await ClusterFleet.shared.snapshot()
        LowLatencyAudioRouter.shared.applySpatialState(
            yawDegrees: fleetSnap.listenerYawDegrees,
            depth: fleetSnap.spatialDepth
        )
        guard isPlaying, !isCrossfading else { return }
        guard backend == .musicKit else { return }
        let player = ApplicationMusicPlayer.shared
        let rate = max(0.75, min(1.25, snap.bpm / assumedTrackBPM))
        // Grounding: slightly slower, calmer feel.
        let adjusted = snap.isGrounding ? min(rate, 0.92) : rate
        player.state.playbackRate = Float(adjusted)
    }

    /// Report headphone route presence to the pharma-control AirPods dial.
    func setAirPodsRouteActive(_ active: Bool) async {
        await PharmaControlSessionManager.shared.setAirPodsRouteActive(active)
    }

    // MARK: - AirPods / headphone route

    /// Observe AVAudioSession route changes and publish headphone presence.
    func startAudioRouteObserver() {
        guard routeObserver == nil else {
            Task { await publishCurrentAudioRoute() }
            return
        }
        routeObserver = NotificationCenter.default.addObserver(
            forName: AVAudioSession.routeChangeNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            Task { @MainActor in
                await self?.publishCurrentAudioRoute()
            }
        }
        Task { await publishCurrentAudioRoute() }
    }

    func stopAudioRouteObserver() {
        if let routeObserver {
            NotificationCenter.default.removeObserver(routeObserver)
            self.routeObserver = nil
        }
    }

    private func publishCurrentAudioRoute() async {
        let session = AVAudioSession.sharedInstance()
        let outputs = session.currentRoute.outputs
        let headphonesActive = outputs.contains { port in
            switch port.portType {
            case .headphones, .bluetoothA2DP, .bluetoothHFP, .bluetoothLE:
                return true
            default:
                // AirPods often report as bluetoothA2DP; also match name heuristics.
                let name = port.portName.lowercased()
                return name.contains("airpods") || name.contains("headphone")
            }
        }
        await setAirPodsRouteActive(headphonesActive)

        // ClusterFleet: real route ports → fleet devices (single shared session).
        let ports = outputs.map { port in
            FleetRoutePort(
                uid: port.uid,
                portType: port.portType.rawValue,
                portName: port.portName
            )
        }
        await ClusterFleet.shared.refreshAudioRoutes(ports)
        // Re-apply quality profile when route changes (AirPods ↔ speaker).
        try? await LowLatencyAudioRouter.shared.applyFromFleet()
        if let first = ports.first {
            await LowLatencyAudioRouter.shared.publishLocalLatency(
                to: .shared,
                deviceId: first.uid.isEmpty ? first.portName : first.uid
            )
        }
    }

    // MARK: - Playback

    /// Prefetch playlists for all moods × style so adaptive switches avoid network on the hot path.
    func prefetchPlaylists(style: YogaStyle?) async {
        guard isAuthorized else { return }
        for mood in WorkoutMood.allCases {
            if playlistCache[cacheKey(mood: mood, style: style)] != nil { continue }
            if let playlist = await searchPlaylist(mood: mood, style: style) {
                playlistCache[cacheKey(mood: mood, style: style)] = playlist
            }
        }
    }

    /// Searches Apple Music for yoga-related playlists and plays the first match.
    func playWorkoutMusic(mood: WorkoutMood, style: YogaStyle? = nil) async {
        guard isAuthorized else { return }

        // Leave any local dual session before MusicKit play.
        tearDownLocalEngine()
        backend = .musicKit

        // Fire prefetch for remaining moods in parallel with first play.
        Task { await prefetchPlaylists(style: style) }

        do {
            let playlist = try await resolvePlaylist(mood: mood, style: style)
            let player = ApplicationMusicPlayer.shared
            enableMusicKitNativeCrossfadeIfAvailable(on: player)
            player.queue = [playlist]
            try await player.play()
            isPlaying = true
            adaptiveMood = mood
            // Re-apply beat rate after play starts.
            if let beat = lastBeat {
                await applyBeatSync(beat)
            }
        } catch {
            isPlaying = false
        }
    }

    /// Play a local audio file with the dual-engine path (true volume crossfade on later switches).
    /// Use for non-MusicKit assets only. Stops MusicKit if it was active.
    func playLocalAsset(url: URL, mood: WorkoutMood = .calm) async {
        fadeTask?.cancel()
        isCrossfading = false
        ApplicationMusicPlayer.shared.stop()

        let engine = ensureLocalEngine()
        backend = .localDual
        do {
            try engine.play(url: url)
            isPlaying = true
            adaptiveMood = mood
        } catch {
            isPlaying = false
        }
    }

    /// Crossfade to another local file (dual `AVAudioPlayerNode` volume ramps).
    func crossfadeToLocalAsset(url: URL, mood: WorkoutMood) async {
        guard backend == .localDual, let engine = localEngine, engine.isRunning else {
            await playLocalAsset(url: url, mood: mood)
            return
        }
        fadeTask?.cancel()
        fadeTask = Task {
            isCrossfading = true
            defer { isCrossfading = false }
            do {
                try await engine.crossfade(to: url, duration: Self.crossfadeDuration)
                guard !Task.isCancelled else { return }
                isPlaying = true
                adaptiveMood = mood
            } catch {
                // Leave prior local stream if still audible.
                isPlaying = engine.isRunning
            }
        }
        await fadeTask?.value
    }

    func pause() {
        switch backend {
        case .musicKit:
            ApplicationMusicPlayer.shared.pause()
        case .localDual:
            localEngine?.pause()
        }
        isPlaying = false
    }

    func stop() {
        fadeTask?.cancel()
        isCrossfading = false
        stopAudioRouteObserver()
        LowLatencyAudioRouter.shared.stop()
        // Reset so the next session can rebind the beat listener + route observer.
        beatBound = false
        Task {
            await UniversalBeatSync.shared.removeAllListeners()
        }
        ApplicationMusicPlayer.shared.stop()
        tearDownLocalEngine()
        backend = .musicKit
        isPlaying = false
        lastBeat = nil
    }

    // MARK: - Adaptive SCI-Driven Music

    /// Crossfade with style awareness during adaptive SCI transitions.
    /// Debounce lives here only — callers should not gate again.
    func adaptToSCI(score: Double?, trend: InsightTrend, style: YogaStyle?) async {
        guard isPlaying, isAuthorized else { return }
        // Adaptive SCI mood switches only apply to MusicKit playlists.
        guard backend == .musicKit else { return }

        let now = Date()
        guard now.timeIntervalSince(lastTransitionDate) >= transitionDebounce else { return }

        let currentScore = score ?? 0.5
        let targetMood: WorkoutMood

        switch (currentScore, trend) {
        case (0.7..., .improving):
            targetMood = .energizing
        case (0.7..., _):
            targetMood = .calm
        case (..<0.3, _):
            targetMood = .meditative
        default:
            return
        }

        guard targetMood != adaptiveMood else { return }

        lastTransitionDate = now
        await crossfadeToMood(targetMood, style: style)
    }

    /// Best-available mood transition for MusicKit (see type-level docs).
    /// Does **not** use `playbackRate` as a volume fader.
    private func crossfadeToMood(_ newMood: WorkoutMood, style: YogaStyle?) async {
        fadeTask?.cancel()

        fadeTask = Task {
            isCrossfading = true
            defer {
                // Always release the gate (cancel / early return / success).
                isCrossfading = false
            }

            // Resolve while crossfading so cache hits stay off the audio gap.
            let playlist: Playlist
            do {
                playlist = try await resolvePlaylist(mood: newMood, style: style)
            } catch {
                return
            }
            guard !Task.isCancelled else { return }

            let player = ApplicationMusicPlayer.shared
            enableMusicKitNativeCrossfadeIfAvailable(on: player)

            let usedNative = await musicKitNativeCrossfadeIfPossible(player: player, playlist: playlist)
            if !usedNative {
                await musicKitPrefetchBackedSwap(player: player, playlist: playlist)
            }

            guard !Task.isCancelled else { return }
            isPlaying = true
            adaptiveMood = newMood

            // Drop the gate before re-applying rate so `applyBeatSync` is sole owner of playbackRate.
            isCrossfading = false
            if let beat = lastBeat {
                await applyBeatSync(beat)
            }
        }

        await fadeTask?.value
    }

    /// iOS 18+: insert next playlist after current entry and skip — Apple volume crossfade.
    /// Returns `false` when the API is unavailable or the operation fails (caller falls back).
    private func musicKitNativeCrossfadeIfPossible(
        player: ApplicationMusicPlayer,
        playlist: Playlist
    ) async -> Bool {
        if #available(iOS 18.0, *) {
            // Need an active current entry for insert-after + skip to crossfade from.
            guard player.queue.currentEntry != nil,
                  player.state.playbackStatus == .playing
                    || player.state.playbackStatus == .paused
            else {
                return false
            }

            do {
                player.transition = .crossfade(duration: Self.crossfadeDuration)
                try await player.queue.insert(playlist, position: .afterCurrentEntry)
                guard !Task.isCancelled else { return true }
                try await player.skipToNextEntry()
                // Hold isCrossfading for the full audio fade so beat rate cannot fight it.
                try await Task.sleep(for: .seconds(Self.crossfadeDuration))
                return true
            } catch is CancellationError {
                // Mid-flight cancel must not fall through to a hard queue replace.
                return true
            } catch {
                return false
            }
        }
        return false
    }

    /// Single-player swap: cache-first resolve already done; minimize gap only.
    ///
    /// Limitation: `ApplicationMusicPlayer` has no per-player volume, so a true
    /// fade-out → fade-in envelope is impossible without system volume (forbidden).
    /// Prefetch + limit=1 keeps this path short.
    private func musicKitPrefetchBackedSwap(
        player: ApplicationMusicPlayer,
        playlist: Playlist
    ) async {
        player.pause()
        // Tiny settle so pause is audible as a soft cut rather than a glitch.
        try? await Task.sleep(for: .milliseconds(80))
        guard !Task.isCancelled else { return }

        do {
            player.queue = [playlist]
            try await player.prepareToPlay()
            guard !Task.isCancelled else { return }
            try await player.play()
        } catch {
            try? await player.play()
        }
    }

    /// Enable Apple’s queue-item crossfade when the SDK supports it (in-playlist tracks too).
    private func enableMusicKitNativeCrossfadeIfAvailable(on player: ApplicationMusicPlayer) {
        if #available(iOS 18.0, *) {
            player.transition = .crossfade(duration: Self.crossfadeDuration)
        }
    }

    // MARK: - Local dual engine lifecycle

    private func ensureLocalEngine() -> LocalDualCrossfadeEngine {
        if let localEngine { return localEngine }
        let engine = LocalDualCrossfadeEngine()
        localEngine = engine
        return engine
    }

    private func tearDownLocalEngine() {
        localEngine?.stop()
        localEngine = nil
    }

    // MARK: - Playlist cache / search

    private func cacheKey(mood: WorkoutMood, style: YogaStyle?) -> String {
        "\(mood.rawValue)|\(style?.rawValue ?? "default")"
    }

    private func resolvePlaylist(mood: WorkoutMood, style: YogaStyle?) async throws -> Playlist {
        let key = cacheKey(mood: mood, style: style)
        if let cached = playlistCache[key] {
            return cached
        }
        if let found = await searchPlaylist(mood: mood, style: style) {
            playlistCache[key] = found
            return found
        }
        throw MusicServiceError.playlistNotFound
    }

    private func searchPlaylist(mood: WorkoutMood, style: YogaStyle?) async -> Playlist? {
        let searchTerm: String
        if let style, let styleTerm = style.musicSearchTerms[mood] {
            searchTerm = styleTerm
        } else {
            searchTerm = mood.searchTerm
        }
        do {
            var request = MusicCatalogSearchRequest(
                term: searchTerm,
                types: [Playlist.self]
            )
            // Only the first result is used.
            request.limit = 1
            let response = try await request.response()
            return response.playlists.first
        } catch {
            return nil
        }
    }

    // MARK: - Mood Types

    enum WorkoutMood: String, CaseIterable, Codable {
        case calm
        case energizing
        case meditative

        var searchTerm: String {
            switch self {
            case .calm: return "calm workout music"
            case .energizing: return "energizing workout playlist"
            case .meditative: return "meditation ambient"
            }
        }

        var displayName: String {
            switch self {
            case .calm: return "Calm"
            case .energizing: return "Energizing"
            case .meditative: return "Meditative"
            }
        }

        var localizedDisplayName: LocalizedString {
            switch self {
            case .calm: return LocalizedString(en: "Calm", fr: "Calme")
            case .energizing: return LocalizedString(en: "Energizing", fr: "Énergisant")
            case .meditative: return LocalizedString(en: "Meditative", fr: "Méditatif")
            }
        }

        var icon: String {
            switch self {
            case .calm: return "leaf.fill"
            case .energizing: return "bolt.fill"
            case .meditative: return "moon.fill"
            }
        }
    }

    private enum MusicServiceError: Error {
        case playlistNotFound
    }
}

// MARK: - Local dual-player volume crossfade (AVAudioEngine)

/// True dual-player volume crossfade for **local file URLs only**.
///
/// MusicKit cannot feed two simultaneous application players; this engine is the
/// only path where we own two independent gain stages and can overlap fade-out/fade-in
/// without touching `playbackRate` or system volume.
@MainActor
private final class LocalDualCrossfadeEngine {
    private let engine = AVAudioEngine()
    private let playerA = AVAudioPlayerNode()
    private let playerB = AVAudioPlayerNode()
    private let mixerA = AVAudioMixerNode()
    private let mixerB = AVAudioMixerNode()

    /// `true` → A is the audible primary; B is the standby lane.
    private var primaryIsA = true
    private var started = false

    var isRunning: Bool { started && engine.isRunning }

    init() {
        engine.attach(playerA)
        engine.attach(playerB)
        engine.attach(mixerA)
        engine.attach(mixerB)
        engine.connect(playerA, to: mixerA, format: nil)
        engine.connect(playerB, to: mixerB, format: nil)
        engine.connect(mixerA, to: engine.mainMixerNode, format: nil)
        engine.connect(mixerB, to: engine.mainMixerNode, format: nil)
        mixerA.outputVolume = 1
        mixerB.outputVolume = 0
    }

    func play(url: URL) throws {
        try activateSession()
        if !engine.isRunning {
            try engine.start()
        }
        stopNode(playerA)
        stopNode(playerB)
        mixerA.outputVolume = 1
        mixerB.outputVolume = 0
        primaryIsA = true
        try schedule(url: url, on: playerA)
        playerA.play()
        started = true
    }

    /// Overlapping volume crossfade onto `url` using the standby player node.
    func crossfade(to url: URL, duration: TimeInterval) async throws {
        try activateSession()
        if !engine.isRunning {
            try engine.start()
        }

        let fromMixer = primaryIsA ? mixerA : mixerB
        let toMixer = primaryIsA ? mixerB : mixerA
        let fromPlayer = primaryIsA ? playerA : playerB
        let toPlayer = primaryIsA ? playerB : playerA

        stopNode(toPlayer)
        toMixer.outputVolume = 0
        try schedule(url: url, on: toPlayer)
        toPlayer.play()

        let steps = max(12, Int(duration * 30)) // ~30 Hz ramp
        let stepSleep = duration / Double(steps)
        for step in 0...steps {
            if Task.isCancelled {
                // Prefer the new source if cancel arrives mid-fade.
                fromMixer.outputVolume = 0
                toMixer.outputVolume = 1
                stopNode(fromPlayer)
                primaryIsA.toggle()
                return
            }
            let t = Float(step) / Float(steps)
            // Equal-power-ish cosine crossfade for constant perceived loudness.
            let angle = t * .pi / 2
            fromMixer.outputVolume = cos(angle)
            toMixer.outputVolume = sin(angle)
            if step < steps {
                try await Task.sleep(for: .seconds(stepSleep))
            }
        }

        stopNode(fromPlayer)
        fromMixer.outputVolume = 0
        toMixer.outputVolume = 1
        primaryIsA.toggle()
        started = true
    }

    func pause() {
        playerA.pause()
        playerB.pause()
    }

    func stop() {
        stopNode(playerA)
        stopNode(playerB)
        if engine.isRunning {
            engine.stop()
        }
        started = false
    }

    private func schedule(url: URL, on player: AVAudioPlayerNode) throws {
        let file = try AVAudioFile(forReading: url)
        player.scheduleFile(file, at: nil, completionHandler: nil)
    }

    private func stopNode(_ player: AVAudioPlayerNode) {
        player.stop()
        player.reset()
    }

    private func activateSession() throws {
        let session = AVAudioSession.sharedInstance()
        try session.setCategory(.playback, mode: .default, options: [.allowAirPlay, .allowBluetoothA2DP])
        try session.setActive(true)
    }
}

// MARK: - Style-Aware Music Search Terms

extension YogaStyle {
    /// Style/kind-specific search terms for each workout mood, providing curated
    /// playlist discovery that matches the energy and pace of the session.
    var musicSearchTerms: [MusicService.WorkoutMood: String] {
        switch self {
        case .chairYoga:
            return [
                .calm: "gentle chair yoga music",
                .energizing: "uplifting yoga flow",
                .meditative: "seated meditation ambient",
            ]
        case .matYoga:
            return [
                .calm: "mat yoga ambient",
                .energizing: "yoga flow playlist",
                .meditative: "yoga nidra meditation",
            ]
        case .vinyasa:
            return [
                .calm: "vinyasa flow yoga",
                .energizing: "power vinyasa beats",
                .meditative: "yoga cooldown ambient",
            ]
        case .hatha:
            return [
                .calm: "hatha yoga relaxation",
                .energizing: "yoga flow upbeat",
                .meditative: "yoga nidra ambient",
            ]
        case .yin:
            return [
                .calm: "yin yoga ambient",
                .energizing: "gentle yoga",
                .meditative: "deep relaxation meditation",
            ]
        case .restorative:
            return [
                .calm: "restorative yoga",
                .energizing: "gentle yoga flow",
                .meditative: "sleep meditation ambient",
            ]
        case .power:
            return [
                .calm: "power yoga warm up",
                .energizing: "intense workout beats",
                .meditative: "yoga cooldown",
            ]
        case .standingBalance:
            return [
                .calm: "balance yoga music",
                .energizing: "focused workout music",
                .meditative: "mindfulness meditation",
            ]
        case .prenatal:
            return [
                .calm: "prenatal yoga relaxation",
                .energizing: "gentle prenatal movement",
                .meditative: "pregnancy meditation",
            ]
        case .pranayama:
            return [
                .calm: "pranayama breathing music",
                .energizing: "energizing breathwork",
                .meditative: "meditation singing bowls",
            ]
        case .strength:
            return [
                .calm: "strength training warm up",
                .energizing: "gym workout motivation",
                .meditative: "post workout cool down",
            ]
        case .cardio:
            return [
                .calm: "cardio cool down music",
                .energizing: "high energy workout playlist",
                .meditative: "breathing recovery ambient",
            ]
        case .mobility:
            return [
                .calm: "mobility stretch music",
                .energizing: "dynamic stretching playlist",
                .meditative: "body scan meditation",
            ]
        case .meditation:
            return [
                .calm: "guided meditation music",
                .energizing: "focus ambient music",
                .meditative: "meditation singing bowls",
            ]
        case .general:
            return [
                .calm: "workout warm up chill",
                .energizing: "fitness workout playlist",
                .meditative: "cool down stretch ambient",
            ]
        }
    }
}
