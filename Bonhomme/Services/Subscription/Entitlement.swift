import Foundation

/// Subscription tiers for the app.
///
/// - free: 5 beginner poses, 1 guided session, basic metrics
/// - premium: Full pose library, unlimited sessions, MusicKit, SharePlay, advanced metrics
enum Entitlement: String, Sendable {
    case free
    case premium
}
