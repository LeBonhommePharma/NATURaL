import MusicKit

/// Integrates with Apple Music for workout playlists.
/// Falls back gracefully when the user has no Apple Music subscription.
@MainActor
final class MusicService: ObservableObject {
    @Published var isAuthorized = false
    @Published var isPlaying = false

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
        ApplicationMusicPlayer.shared.stop()
        isPlaying = false
    }

    enum WorkoutMood: String, CaseIterable {
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

        var icon: String {
            switch self {
            case .calm: return "leaf.fill"
            case .energizing: return "bolt.fill"
            case .meditative: return "moon.fill"
            }
        }
    }
}
