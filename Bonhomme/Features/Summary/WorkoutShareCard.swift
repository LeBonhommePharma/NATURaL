import SwiftUI
import BonhommeCore

/// Generates a styled share image for post-workout sharing via the system share sheet.
/// Mirrors the Fitness+ workout share card aesthetic with style icon, stats, and branding.
struct WorkoutShareCard: View {
    let result: WorkoutResult

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Image(systemName: "leaf.fill")
                    .font(.system(size: 16, weight: .semibold))
                Text("NATURaL")
                    .font(.system(size: 16, weight: .bold, design: .rounded))
                Spacer()
            }
            .foregroundStyle(.white.opacity(0.8))
            .padding(.bottom, 20)

            // Style and plan name
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 8) {
                    Image(systemName: result.yogaStyle.symbolName)
                        .font(.system(size: 28))
                    Text(result.yogaStyleName)
                        .font(.system(size: 28, weight: .bold, design: .rounded))
                }
                Text(result.workoutPlanName)
                    .font(.system(size: 17, weight: .medium))
                    .foregroundStyle(.white.opacity(0.7))
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.bottom, 24)

            // Stats row
            HStack(spacing: 0) {
                statColumn(
                    value: formattedDuration(result.totalDuration),
                    unit: "min",
                    icon: "clock"
                )
                Spacer()
                statColumn(
                    value: result.averageHeartRate.map { "\(Int($0))" } ?? "--",
                    unit: "avg bpm",
                    icon: "heart.fill"
                )
                Spacer()
                statColumn(
                    value: "\(Int(result.activeCalories))",
                    unit: "cal",
                    icon: "flame.fill"
                )
            }
            .padding(.bottom, 20)

            // Date
            Text(result.endDate.formatted(date: .long, time: .omitted))
                .font(.system(size: 13))
                .foregroundStyle(.white.opacity(0.5))
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(24)
        .foregroundStyle(.white)
        .background(
            LinearGradient(
                colors: [accentColor, accentColor.opacity(0.7)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .clipShape(RoundedRectangle(cornerRadius: 20))
    }

    private var accentColor: Color {
        Color(hue: result.yogaStyle.accentHue, saturation: 0.6, brightness: 0.5)
    }

    private func statColumn(value: String, unit: String, icon: String) -> some View {
        VStack(spacing: 4) {
            Image(systemName: icon)
                .font(.system(size: 14))
                .foregroundStyle(.white.opacity(0.7))
            Text(value)
                .font(.system(size: 22, weight: .bold, design: .rounded))
                .monospacedDigit()
            Text(unit)
                .font(.system(size: 12))
                .foregroundStyle(.white.opacity(0.6))
        }
    }

    private func formattedDuration(_ duration: TimeInterval) -> String {
        let minutes = Int(duration) / 60
        let seconds = Int(duration) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }

    /// Renders the share card as a UIImage for sharing via ShareLink.
    @MainActor
    func renderImage() -> Image? {
        let renderer = ImageRenderer(content: self.frame(width: 340))
        renderer.scale = 3.0
        guard let uiImage = renderer.uiImage else { return nil }
        return Image(uiImage: uiImage)
    }

    /// Renders to a transferable Data for ShareLink.
    @MainActor
    func renderPNGData() -> Data? {
        let renderer = ImageRenderer(content: self.frame(width: 340))
        renderer.scale = 3.0
        return renderer.uiImage?.pngData()
    }
}
