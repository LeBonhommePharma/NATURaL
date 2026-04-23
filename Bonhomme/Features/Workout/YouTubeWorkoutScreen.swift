// Bonhomme/Features/Workout/YouTubeWorkoutScreen.swift
#if canImport(UIKit)
import SwiftUI
import BonhommeCore

struct YouTubeWorkoutScreen: View {

    @State private var viewModel: YouTubeWorkoutViewModel
    @Environment(\.dismiss) private var dismiss

    init(program: YouTubeWorkoutProgram) {
        _viewModel = State(initialValue: YouTubeWorkoutViewModel(program: program))
    }

    var body: some View {
        ZStack(alignment: .bottom) {
            Color.black.ignoresSafeArea()
            VStack(spacing: 0) {
                headerBar
                playerStack
                phaseTimeline
                metricsBar
            }
        }
        .statusBarHidden(viewModel.sessionState == .active)
        .onDisappear { viewModel.endSession() }
    }

    private var headerBar: some View {
        HStack {
            Button(action: { dismiss() }) {
                Image(systemName: "xmark")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(.white)
                    .frame(width: 36, height: 36)
                    .background(.ultraThinMaterial)
                    .clipShape(Circle())
            }
            Spacer()
            Text(viewModel.program.title)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.white)
            Spacer()
            Color.clear.frame(width: 36, height: 36)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .background(.black)
    }

    private var playerStack: some View {
        ZStack(alignment: .topLeading) {
            YouTubePlayerView(
                videoID: viewModel.program.youtubeID,
                autoplay: false,
                onStateChange: { [weak viewModel] state in viewModel?.handlePlayerState(state) },
                onTimeUpdate:  { [weak viewModel] time  in viewModel?.handleTimeUpdate(time) }
            )
            .aspectRatio(16.0 / 9.0, contentMode: .fit)

            VStack(alignment: .trailing, spacing: 6) {
                if let hr = viewModel.heartRate {
                    MetricBadge(icon: "heart.fill",  value: "\(Int(hr))", unit: "bpm",  tint: .red)
                }
                MetricBadge(icon: "bolt.fill", value: String(format: "%.0f", viewModel.activeCalories), unit: "kcal", tint: .orange)
                SCIGaugeBadge(sci: viewModel.entropyIndex, inRange: viewModel.isInTargetSCIRange)
            }
            .padding(10)
            .frame(maxWidth: .infinity, alignment: .trailing)
        }
    }

    private var phaseTimeline: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 6) {
                ForEach(viewModel.program.phases) { phase in
                    PhasePill(phase: phase, currentTime: viewModel.currentTime,
                              isActive: viewModel.currentPhase?.id == phase.id)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
        }
        .background(.black)
    }

    private var metricsBar: some View {
        HStack(spacing: 0) {
            MetricsCell(label: "ELAPSED", value: viewModel.elapsedWorkoutTime.formattedMMSS)
            Divider().frame(height: 28).background(.white.opacity(0.3))
            MetricsCell(label: "PHASE",   value: viewModel.currentPhase?.name ?? "\u{2014}")
            Divider().frame(height: 28).background(.white.opacity(0.3))
            MetricsCell(label: "SCI",     value: String(format: "%.2f", viewModel.entropyIndex))
        }
        .padding(.vertical, 10)
        .background(.black)
        .foregroundStyle(.white)
    }
}

// MARK: - Sub-views

private struct MetricBadge: View {
    let icon: String; let value: String; let unit: String; let tint: Color
    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: icon).foregroundStyle(tint).font(.caption2.weight(.semibold))
            Text(value).font(.caption.weight(.bold).monospacedDigit()).foregroundStyle(.white)
            Text(unit).font(.caption2).foregroundStyle(.white.opacity(0.7))
        }
        .padding(.horizontal, 8).padding(.vertical, 4)
        .background(.black.opacity(0.65)).clipShape(Capsule())
    }
}

private struct SCIGaugeBadge: View {
    let sci: Double; let inRange: Bool
    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: "waveform.path.ecg").foregroundStyle(inRange ? .green : .yellow).font(.caption2.weight(.semibold))
            Text(String(format: "SCI %.2f", sci)).font(.caption.weight(.bold).monospacedDigit()).foregroundStyle(.white)
        }
        .padding(.horizontal, 8).padding(.vertical, 4)
        .background(.black.opacity(0.65)).clipShape(Capsule())
    }
}

private struct PhasePill: View {
    let phase: ProgramPhase; let currentTime: TimeInterval; let isActive: Bool
    private var progress: Double {
        guard phase.duration > 0 else { return 0 }
        return max(0, min(currentTime - phase.startTime, phase.duration)) / phase.duration
    }
    var body: some View {
        VStack(alignment: .leading, spacing: 3) {
            Text(phase.name).font(.caption2.weight(.semibold)).foregroundStyle(isActive ? .white : .white.opacity(0.5))
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule().fill(.white.opacity(0.2))
                    Capsule().fill(isActive ? Color.green : Color.white.opacity(0.4))
                        .frame(width: geo.size.width * (isActive ? progress : (currentTime >= phase.endTime ? 1 : 0)))
                }
            }
            .frame(height: 4)
        }
        .frame(width: 90)
        .padding(.horizontal, 8).padding(.vertical, 6)
        .background(isActive ? Color.white.opacity(0.12) : Color.clear)
        .clipShape(RoundedRectangle(cornerRadius: 8))
        .overlay(RoundedRectangle(cornerRadius: 8).stroke(isActive ? Color.white.opacity(0.3) : Color.clear, lineWidth: 1))
        .animation(.easeInOut(duration: 0.2), value: isActive)
    }
}

private struct MetricsCell: View {
    let label: String; let value: String
    var body: some View {
        VStack(spacing: 2) {
            Text(label).font(.system(size: 9, weight: .semibold)).foregroundStyle(.white.opacity(0.5)).kerning(0.8)
            Text(value).font(.system(size: 13, weight: .semibold).monospacedDigit()).foregroundStyle(.white)
        }
        .frame(maxWidth: .infinity)
    }
}

private extension TimeInterval {
    var formattedMMSS: String {
        let m = Int(self) / 60; let s = Int(self) % 60
        return String(format: "%d:%02d", m, s)
    }
}
#endif
