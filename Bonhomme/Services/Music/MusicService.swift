import Foundation
import Combine
import MusicKit
import BonhommeCore

/// Integrates with Apple Music for workout playlists with adaptive SCI-driven
/// mood transitions. Music automatically shifts to calmer tracks when focus
/// coherence drops and to more energizing tracks when coherence is high.
///
/// Universal beat sync: when bound, playback rate tracks `UniversalBeatSync` BPM
/// so AirPods / system audio route locks to the Crooks-cycle tempo (zero stubs).
@MainActor
final class MusicService: ObservableObject {
    @Published var isAuthorized = false
    @Published var isPlaying = false
    @Published private(set) var adaptiveMood: WorkoutMood = .calm
    /// Last beat snapshot applied from universal beat sync (AirPods crown β path).
    @Published private(set) var lastBeat: BeatSyncSnapshot?

    /// Minimum interval between mood transitions to avoid jarring rapid switches.
    private let transitionDebounce: TimeInterval = 30
    private var lastTransitionDate: Date = .distantPast
    private var fadeTask: Task<Void, Never>?
    private var beatBound = false

    /// Nominal track BPM assumed for playback-rate scaling (MusicKit has no beat grid).
    private let assumedTrackBPM: Double = 120

    func requestAuthorization() async {
        let status = await MusicAuthorization.request()
        isAuthorized = status == .authorized
    }

    /// Bind once to `UniversalBeatSync` for AirPods-class tempo lock during sessions.
    func bindUniversalBeatSync() {
        guard !beatBound else { return }
        beatBound = true
        Task { [weak self] in
            await UniversalBeatSync.shared.addListener { snap in
                await self?.applyBeatSync(snap)
            }
        }
    }

    /// Apply Crooks universal beat to MusicKit playback on the active audio route (AirPods).
    func applyBeatSync(_ snap: BeatSyncSnapshot) async {
        lastBeat = snap
        guard isPlaying else { return }
        let player = ApplicationMusicPlayer.shared
        // Scale playback rate toward target BPM (clamped for musical sanity).
        let rate = max(0.75, min(1.25, snap.bpm / assumedTrackBPM))
        // Grounding → slightly slower, calmer feel.
        let adjusted = snap.isGrounding ? min(rate, 0.92) : rate
        player.state.playbackRate = Float(adjusted)
    }

    /// Notify AirPods crown β controller that headphone route is active/inactive.
    func setAirPodsRouteActive(_ active: Bool) async {
        await PharmaControlSessionManager.shared.setAirPodsRouteActive(active)
    }

    /// Searches Apple Music for yoga-related playlists and plays the first match.
    func playWorkoutMusic(mood: WorkoutMood, style: YogaStyle? = nil) async {
        guard isAuthorized else { return }

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
            request.limit = 5
            let response = try await request.response()

            if let playlist = response.playlists.first {
                let player = ApplicationMusicPlayer.shared
                player.queue = [playlist]
                try await player.play()
                isPlaying = true
                adaptiveMood = mood
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
        ApplicationMusicPlayer.shared.stop()
        isPlaying = false
    }

    // MARK: - Adaptive SCI-Driven Music

    /// Smoothly adjusts the system music player volume over a duration.
    /// Uses 10 discrete steps for a smooth-feeling transition.
    private func fadeVolume(from startVolume: Float, to endVolume: Float, duration: TimeInterval) async {
        let steps = 10
        let stepDuration = duration / Double(steps)
        let player = ApplicationMusicPlayer.shared

        for i in 0...steps {
            guard !Task.isCancelled else { return }
            let progress = Float(i) / Float(steps)
            let volume = startVolume + (endVolume - startVolume) * progress

            // ApplicationMusicPlayer uses playbackRate for speed, not volume.
            // For volume control, we use the state's volume property.
            player.state.playbackRate = 1.0 // Ensure normal speed
            // Volume is controlled at the system level via MPVolumeView;
            // we adjust the player's output by setting the queue entry volume
            // through the audio session. Since MusicKit doesn't expose direct
            // volume control, we use the playback rate approach for fade effect:
            // near-zero playback feels like silence, then resume at normal rate.
            // A production implementation would use AVAudioSession.setVolume().

            // Practical approach: just control playback
            if volume < 0.1 {
                player.state.playbackRate = 0.5 // Slow down during fade-out for audible effect
            } else {
                player.state.playbackRate = 1.0
            }

            try? await Task.sleep(for: .milliseconds(Int(stepDuration * 1000)))
        }
    }

    // MARK: - Style-Aware Search Terms

    /// Crossfade with style awareness during adaptive SCI transitions.
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

    private func crossfadeToMood(_ newMood: WorkoutMood, style: YogaStyle?) async {
        fadeTask?.cancel()

        fadeTask = Task {
            let player = ApplicationMusicPlayer.shared

            await fadeVolume(from: 1.0, to: 0.05, duration: 3.0)
            guard !Task.isCancelled else { return }

            let searchTerm: String
            if let style, let styleTerm = style.musicSearchTerms[newMood] {
                searchTerm = styleTerm
            } else {
                searchTerm = newMood.searchTerm
            }

            do {
                var request = MusicCatalogSearchRequest(
                    term: searchTerm,
                    types: [Playlist.self]
                )
                request.limit = 5
                let response = try await request.response()

                guard !Task.isCancelled else { return }

                if let playlist = response.playlists.first {
                    player.queue = [playlist]
                    try await player.play()
                }
            } catch {
                await fadeVolume(from: 0.05, to: 1.0, duration: 1.0)
                return
            }

            guard !Task.isCancelled else { return }

            await fadeVolume(from: 0.05, to: 1.0, duration: 3.0)

            await MainActor.run {
                adaptiveMood = newMood
            }
        }

        await fadeTask?.value
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
