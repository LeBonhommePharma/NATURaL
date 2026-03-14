import SwiftUI
import Charts
import BonhommeCore

/// Post-workout summary screen showing stats, HR chart, and activity ring progress.
struct SummaryView: View {
    let result: WorkoutResult
    let onDismiss: () -> Void

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Checkmark animation
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 72))
                    .foregroundStyle(.green)
                    .padding(.top, 32)

                Text("Session Complete!")
                    .font(.system(size: 28, weight: .bold, design: .rounded))

                // Stat cards
                LazyVGrid(columns: [.init(), .init()], spacing: 16) {
                    statCard(
                        icon: "clock",
                        value: formattedDuration(result.totalDuration),
                        label: "Duration",
                        color: .cyan
                    )
                    statCard(
                        icon: "flame.fill",
                        value: "\(Int(result.activeCalories))",
                        label: "Calories",
                        color: .orange
                    )
                    statCard(
                        icon: "heart.fill",
                        value: result.averageHeartRate.map { "\(Int($0))" } ?? "--",
                        label: "Avg HR",
                        color: .red
                    )
                    statCard(
                        icon: "figure.yoga",
                        value: "\(result.posesCompleted)/\(result.totalPoses)",
                        label: "Poses",
                        color: .purple
                    )
                }
                .padding(.horizontal)

                // Heart rate chart
                if !result.heartRateSamples.isEmpty {
                    hrChartView
                        .padding(.horizontal)
                }

                // Done button
                Button {
                    onDismiss()
                } label: {
                    Text("Done")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundStyle(.black)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(.cyan, in: RoundedRectangle(cornerRadius: 14))
                }
                .padding(.horizontal, 40)
                .padding(.bottom, 32)
            }
        }
        .background(Color(.systemBackground))
    }

    private func statCard(icon: String, value: String, label: String, color: Color) -> some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 24))
                .foregroundStyle(color)

            Text(value)
                .font(.system(size: 24, weight: .bold, design: .rounded))
                .monospacedDigit()

            Text(label)
                .font(.system(size: 13))
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))
    }

    private var hrChartView: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Heart Rate")
                .font(.system(size: 16, weight: .semibold))

            Chart(result.heartRateSamples, id: \.timestamp) { sample in
                LineMark(
                    x: .value("Time", sample.timestamp),
                    y: .value("BPM", sample.bpm)
                )
                .foregroundStyle(.red.gradient)
                .interpolationMethod(.catmullRom)

                AreaMark(
                    x: .value("Time", sample.timestamp),
                    y: .value("BPM", sample.bpm)
                )
                .foregroundStyle(.red.opacity(0.1).gradient)
                .interpolationMethod(.catmullRom)
            }
            .chartYAxis {
                AxisMarks(position: .leading)
            }
            .frame(height: 160)
        }
        .padding()
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))
    }

    private func formattedDuration(_ duration: TimeInterval) -> String {
        let minutes = Int(duration) / 60
        let seconds = Int(duration) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
}
