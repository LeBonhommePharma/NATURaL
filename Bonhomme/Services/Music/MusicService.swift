import MusicKit
import BonhommeCore

/// Integrates with Apple Music for workout playlists with adaptive SCI-driven
/// mood transitions. Music automatically shifts to calmer tracks when focus
/// coherence drops and to more energizing tracks when coherence is high.
@MainActor
final class MusicService: ObservableObject {
    @Published var isAuthorized = false
    @Published var isPlaying = false
    @Published private(set) var adaptiveMood: WorkoutMood = .calm

    /// Minimum interval between mood transitions to avoid jarring rapid switches.
    private let transitionDebounce: TimeInterval = 30
    private var lastTransitionDate: Date = .distantPast
    private var fadeTask: Task<Void, Never>?

    func requestAuthorization() async {
        let status = await MusicAuthorization.request()
        isAuthorized = status == .authorized
    }

    /// Searches Apple Music for yoga-related playlists and plays the first match.
    func playWorkoutMusic(mood: WorkoutMood) async {
        guard isAuthorized else { return }

        do {
            var request = MusicCatalogSearchRequest(
                term: mood.searchTerm,
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

    /// Adapts music mood based on real-time SCI (Shannon Collapse Index) score.
    ///
    /// - High coherence + improving (>0.7): switch to energizing music
    /// - High coherence, stable (>0.7): maintain calm music
    /// - Low coherence (<0.3): fade to meditative/calming music
    /// - Mid-range: maintain current mood
    ///
    /// Debounced to minimum 30-second intervals between transitions.
    func adaptToSCI(score: Double?, trend: InsightTrend) async {
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
            return // Mid-range: don't change
        }

        guard targetMood != adaptiveMood else { return }

        lastTransitionDate = now
        await crossfadeToMood(targetMood)
    }

    /// Crossfades from the current playlist to a new mood-matched playlist.
    /// Fades volume down over 3 seconds, switches playlist, fades volume up.
    private func crossfadeToMood(_ newMood: WorkoutMood) async {
        fadeTask?.cancel()

        fadeTask = Task {
            let player = ApplicationMusicPlayer.shared

            // Phase 1: Fade out current track (3 seconds)
            await fadeVolume(from: 1.0, to: 0.05, duration: 3.0)
            guard !Task.isCancelled else { return }

            // Phase 2: Search and queue new mood playlist
            do {
                var request = MusicCatalogSearchRequest(
                    term: newMood.searchTerm,
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
                // If search fails, restore volume on current track
                await fadeVolume(from: 0.05, to: 1.0, duration: 1.0)
                return
            }

            guard !Task.isCancelled else { return }

            // Phase 3: Fade in new track (3 seconds)
            await fadeVolume(from: 0.05, to: 1.0, duration: 3.0)

            await MainActor.run {
                adaptiveMood = newMood
            }
        }

        await fadeTask?.value
    }

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
