import Foundation
#if canImport(WidgetKit)
import WidgetKit
#endif

/// Shared App Group keys + helpers for widgets and the main app.
/// Suite must match `com.apple.security.application-groups` in entitlements
/// (`group.com.natural.Bonhomme`).
enum AppGroupStore {

    static let suiteName = "group.com.natural.Bonhomme"

    enum Key {
        static let streakDays = "streakDays"
        static let longestStreak = "longestStreak"
        static let lastWorkoutDate = "lastWorkoutDate"
        static let moveProgress = "moveProgress"
        static let exerciseProgress = "exerciseProgress"
        static let standProgress = "standProgress"
        /// Shannon Collapse Index in 0…1 (same scale as FeedbackEngine insights).
        static let latestSCI = "latestSCI"
        static let latestHeartRate = "latestHeartRate"
        static let latestBreathRate = "latestBreathRate"
        static let lastMetricsDate = "lastMetricsDate"
    }

    static var defaults: UserDefaults? {
        UserDefaults(suiteName: suiteName)
    }

    // MARK: - Read

    static func streakDays() -> Int {
        defaults?.integer(forKey: Key.streakDays) ?? 0
    }

    static func longestStreak() -> Int {
        defaults?.integer(forKey: Key.longestStreak) ?? 0
    }

    static func lastWorkoutDate() -> Date? {
        defaults?.object(forKey: Key.lastWorkoutDate) as? Date
    }

    /// `UserDefaults.double` is 0 when the key is missing, which paints closed 0% rings.
    static func moveProgress() -> Double? {
        optionalDouble(for: Key.moveProgress)
    }

    static func exerciseProgress() -> Double? {
        optionalDouble(for: Key.exerciseProgress)
    }

    static func standProgress() -> Double? {
        optionalDouble(for: Key.standProgress)
    }

    /// Latest SCI (0…1) if the app has written one.
    static func latestSCI() -> Double? {
        guard let defaults, defaults.object(forKey: Key.latestSCI) != nil else { return nil }
        return defaults.double(forKey: Key.latestSCI)
    }

    static func latestHeartRate() -> Int? {
        guard let defaults, defaults.object(forKey: Key.latestHeartRate) != nil else { return nil }
        let v = defaults.integer(forKey: Key.latestHeartRate)
        return v > 0 ? v : nil
    }

    static func latestBreathRate() -> Double? {
        guard let defaults, defaults.object(forKey: Key.latestBreathRate) != nil else { return nil }
        let v = defaults.double(forKey: Key.latestBreathRate)
        return v > 0 ? v : nil
    }

    private static func optionalDouble(for key: String) -> Double? {
        guard let defaults, defaults.object(forKey: key) != nil else { return nil }
        let value = defaults.double(forKey: key)
        return value.isFinite ? value : nil
    }

    // MARK: - Write

    static func writeStreak(current: Int, longest: Int, lastSession: Date?) {
        guard let defaults else { return }
        defaults.set(current, forKey: Key.streakDays)
        defaults.set(longest, forKey: Key.longestStreak)
        if let lastSession {
            defaults.set(lastSession, forKey: Key.lastWorkoutDate)
        }
        defaults.synchronize()
        reloadWidgets()
    }

    static func writeRingProgress(move: Double, exercise: Double, stand: Double) {
        guard let defaults else { return }
        defaults.set(move, forKey: Key.moveProgress)
        defaults.set(exercise, forKey: Key.exerciseProgress)
        defaults.set(stand, forKey: Key.standProgress)
        defaults.synchronize()
        reloadWidgets()
    }

    /// Publishes live / post-session biofeedback for home-screen widgets.
    static func writeSessionMetrics(sci: Double?, heartRate: Int?, breathRate: Double?) {
        guard let defaults else { return }
        if let sci, sci.isFinite {
            defaults.set(min(1, max(0, sci)), forKey: Key.latestSCI)
        }
        if let heartRate, heartRate > 0 {
            defaults.set(heartRate, forKey: Key.latestHeartRate)
        }
        if let breathRate, breathRate.isFinite, breathRate > 0 {
            defaults.set(breathRate, forKey: Key.latestBreathRate)
        }
        defaults.set(Date(), forKey: Key.lastMetricsDate)
        defaults.synchronize()
        // Avoid WidgetCenter thrash during 1 Hz Live Activity ticks — callers
        // that need an immediate refresh pass `reload: true` via `writeSessionMetricsAndReload`.
    }

    static func writeSessionMetricsAndReload(sci: Double?, heartRate: Int?, breathRate: Double?) {
        writeSessionMetrics(sci: sci, heartRate: heartRate, breathRate: breathRate)
        reloadWidgets()
    }

    static func reloadWidgets() {
        #if canImport(WidgetKit)
        #if os(iOS)
        WidgetCenter.shared.reloadAllTimelines()
        #endif
        #endif
    }
}
