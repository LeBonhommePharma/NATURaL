import SwiftUI

/// Shows the session progress: which pose in the sequence and total elapsed time.
/// Used in both the iOS workout view and the TV display biofeedback panel.
public struct SessionProgressView: View {
    public let index: Int
    public let total: Int
    public let elapsed: TimeInterval

    public init(index: Int, total: Int, elapsed: TimeInterval) {
        self.index = index
        self.total = total
        self.elapsed = elapsed
    }

    public var body: some View {
        VStack(spacing: 8) {
            // Pose counter
            Text("\(index + 1) / \(total)")
                .font(.system(size: 20, weight: .semibold, design: .rounded))
                .monospacedDigit()
                .foregroundStyle(.white)

            // Progress bar
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.white.opacity(0.1))
                        .frame(height: 6)

                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.cyan)
                        .frame(width: total > 0 ? geo.size.width * CGFloat(index + 1) / CGFloat(total) : 0, height: 6)
                        .animation(.easeInOut(duration: 0.4), value: index)
                }
            }
            .frame(height: 6)

            // Elapsed time
            Text(elapsedString)
                .font(.system(size: 14, weight: .medium, design: .rounded))
                .monospacedDigit()
                .foregroundStyle(.white.opacity(0.5))
        }
        .padding(.horizontal, 16)
    }

    private var elapsedString: String {
        let totalSeconds = Int(elapsed)
        let minutes = totalSeconds / 60
        let seconds = totalSeconds % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
}
