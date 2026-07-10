import Foundation
import Combine
import AVFoundation
import MusicKit
import BonhommeCore

/// Apple Music workout playlists with SCI-driven mood transitions.
///
/// Coherence high → energizing; coherence low → meditative. Debounced (30s)
/// with a short gap crossfade that does **not** touch `playbackRate`.
/// Tempo is owned exclusively by `applyBeatSync` via `UniversalBeatSync`.
@MainActor
final class MusicService: ObservableObject {
    @Published var isAuthorized = false
    @Published var isPlaying = false
    @Published private(set) var adaptiveMood: WorkoutMood = .calm
    /// Last snapshot from universal beat sync.
    @Published private(set) var lastBeat: BeatSyncSnapshot?
    /// True while a mood transition is in flight — beat-rate updates are suspended.
    @Published private(set) var isCrossfading = false

    /// Minimum interval between mood transitions to avoid jarring rapid switches.
    /// Sole debounce owner for adaptive music (callers must not layer a second 30s gate).
    private let transitionDebounce: TimeInterval = 30
    private var lastTransitionDate: Date = .distantPast
    private var fadeTask: Task<Void, Never>?
    private var beatBound = false
    private var routeObserver: NSObjectProtocol?

    /// Playlist cache keyed by (mood rawValue, style rawValue or "default").
    private var playlistCache: [String: Playlist] = [:]

    /// Nominal track BPM assumed for playback-rate scaling (MusicKit has no beat grid).
    private let assumedTrackBPM: Double = 120

    func requestAuthorization() async {
        let status = await MusicAuthorization.request()
        isAuthorized = status == .authorized
    }

    /// Bind once to `UniversalBeatSync` for session tempo lock and start AirPods route observer.
    func bindUniversalBeatSync() {
        guard !beatBound else { return }
        beatBound = true
        startAudioRouteObserver()
        Task { [weak self] in
            await UniversalBeatSync.shared.addListener { snap in
                await self?.applyBeatSync(snap)
            }
        }
    }

    /// Apply Crooks BPM to MusicKit playback rate on the active audio route.
    /// Skipped while crossfading so gap transitions do not race tempo.
    func applyBeatSync(_ snap: BeatSyncSnapshot) async {
        lastBeat = snap
        guard isPlaying, !isCrossfading else { return }
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

        // Fire prefetch for remaining moods in parallel with first play.
        Task { await prefetchPlaylists(style: style) }

        do {
            let playlist = try await resolvePlaylist(mood: mood, style: style)
            let player = ApplicationMusicPlayer.shared
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

    func pause() {
        ApplicationMusicPlayer.shared.pause()
        isPlaying = false
    }

    func stop() {
        fadeTask?.cancel()
        isCrossfading = false
        stopAudioRouteObserver()
        ApplicationMusicPlayer.shared.stop()
        isPlaying = false
    }

    // MARK: - Adaptive SCI-Driven Music

    /// Crossfade with style awareness during adaptive SCI transitions.
    /// Debounce lives here only — callers should not gate again.
    func adaptToSCI(score: Double?, trend: InsightTrend, style: YogaStyle?) async {
        guard isPlaying, isAuthorized else { return }

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

    /// Short gap transition: suspend beat rate, swap playlist (prefer cache), resume.
    /// Does **not** use `playbackRate` as a volume fader.
    private func crossfadeToMood(_ newMood: WorkoutMood, style: YogaStyle?) async {
        fadeTask?.cancel()

        fadeTask = Task {
            isCrossfading = true
            defer {
                isCrossfading = false
            }

            let player = ApplicationMusicPlayer.shared

            // Brief gap: pause → queue swap → play (real dual-player not available via MusicKit).
            player.pause()
            try? await Task.sleep(for: .milliseconds(350))
            guard !Task.isCancelled else { return }

            do {
                // Overlap search with gap when cache miss.
                let playlist = try await resolvePlaylist(mood: newMood, style: style)
                guard !Task.isCancelled else { return }

                player.queue = [playlist]
                try await player.play()
                isPlaying = true
                adaptiveMood = newMood

                // Restore beat-owned tempo after crossfade.
                if let beat = lastBeat {
                    let rate = max(0.75, min(1.25, beat.bpm / assumedTrackBPM))
                    let adjusted = beat.isGrounding ? min(rate, 0.92) : rate
                    player.state.playbackRate = Float(adjusted)
                }
            } catch {
                // Resume prior queue if still playable.
                try? await player.play()
                isPlaying = true
            }
        }

        await fadeTask?.value
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
            case .calm: return "gentle yoga music"
            case .energizing: return "energizing yoga flow"
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

// MARK: - Style-Aware Music Search Terms

extension YogaStyle {
    /// Style-specific search terms for each workout mood, providing curated
    /// playlist discovery that matches the energy and pace of each yoga style.
    var musicSearchTerms: [MusicService.WorkoutMood: String] {
        switch self {
        case .chairYoga:
            return [
                .calm: "gentle chair yoga music",
                .energizing: "uplifting yoga flow",
                .meditative: "seated meditation ambient",
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
        }
    }
}
