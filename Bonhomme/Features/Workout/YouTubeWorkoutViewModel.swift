// Bonhomme/Features/Workout/YouTubeWorkoutViewModel.swift
import SwiftUI
import Observation
import BonhommeCore
import HealthKit

@Observable
@MainActor
final class YouTubeWorkoutViewModel {

    enum SessionState: Equatable {
        case idle, active, paused, complete
    }

    private(set) var sessionState: SessionState = .idle
    private(set) var playerState: YouTubePlayerState = .idle
    private(set) var currentTime: TimeInterval = 0
    private(set) var currentPhase: ProgramPhase?
    private(set) var heartRate: Double?
    private(set) var activeCalories: Double = 0
    private(set) var entropyIndex: Double = 0
    private(set) var elapsedWorkoutTime: TimeInterval = 0

    let program: YouTubeWorkoutProgram
    let recorder = WorkoutRecorder()
    let feedbackEngine: FeedbackEngine

    private var sessionStartDate: Date?

    init(program: YouTubeWorkoutProgram, feedbackEngine: FeedbackEngine = FeedbackEngine()) {
        self.program = program
        self.feedbackEngine = feedbackEngine
    }

    // MARK: - Player Events

    func handlePlayerState(_ state: YouTubePlayerState) {
        playerState = state
        switch state {
        case .playing where sessionState == .idle:   startSession()
        case .playing where sessionState == .paused: resumeSession()
        case .paused  where sessionState == .active: pauseSession()
        case .ended:                                  endSession()
        default: break
        }
    }

    func handleTimeUpdate(_ time: TimeInterval) {
        currentTime = time
        updateCurrentPhase(at: time)
        if let start = sessionStartDate { elapsedWorkoutTime = Date().timeIntervalSince(start) }
        heartRate = recorder.currentHeartRate
        activeCalories = recorder.activeCalories
        if let insight = feedbackEngine.latestInsight(for: .heartRateVariability) {
            entropyIndex = insight.score
        }
    }

    // MARK: - Session Lifecycle

    private func startSession() {
        sessionState = .active
        sessionStartDate = Date()
        Task {
            do { try await recorder.start(style: .chairYoga) }
            catch { print("\u{26A0}\u{FE0F} YouTubeWorkout: HealthKit start failed: \(error)") }
        }
    }

    private func pauseSession()  { sessionState = .paused;  recorder.pause() }
    private func resumeSession() { sessionState = .active;  recorder.resume() }

    func endSession() {
        guard sessionState != .complete else { return }
        sessionState = .complete
        let sciScore = feedbackEngine.latestInsight(for: .heartRateVariability)?.score
        let metadata = WorkoutMetadata(planId: program.id.uuidString, planName: program.title, styleName: "YouTube", sciScore: sciScore)
        Task { try? await recorder.end(metadata: metadata) }
    }

    // MARK: - Phase Tracking

    private func updateCurrentPhase(at time: TimeInterval) {
        currentPhase = program.phases.first { $0.startTime <= time && time < $0.endTime }
    }

    // MARK: - HRV Ingest

    func ingestHRVSample(sdnn: Double, rmssd: Double, rrIntervals: [Double] = []) {
        let signal = HRVSignal(timestamp: Date(), sdnn: sdnn, rmssd: rmssd, rrIntervals: rrIntervals)
        feedbackEngine.ingest(signal)
    }

    var isInTargetSCIRange: Bool {
        guard let range = currentPhase?.targetSCIRange else { return true }
        return range.contains(entropyIndex)
    }
}
