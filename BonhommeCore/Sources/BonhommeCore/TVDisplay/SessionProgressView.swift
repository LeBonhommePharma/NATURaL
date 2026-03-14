import SwiftUI

/// Shows current position in the workout sequence and elapsed time.
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
        VStack(spacing: 12) {
            // Pose progress dots
            HStack(spacing: 6) {
                ForEach(0..<total, id: \.self) { i in
                    Circle()
                        .fill(i < index ? .white : (i == index ? .cyan : .white.opacity(0.2)))
                        .frame(width: 8, height: 8)
                        .scaleEffect(i == index ? 1.3 : 1.0)
                        .animation(.easeInOut(duration: 0.3), value: index)
                }
            }

            Text("Pose \(index + 1) of \(total)")
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(.white.opacity(0.5))

            Text(formattedTime)
                .font(.system(size: 20, weight: .semibold, design: .rounded))
                .monospacedDigit()
                .foregroundStyle(.white.opacity(0.7))
        }
    }

    private var formattedTime: String {
        let minutes = Int(elapsed) / 60
        let seconds = Int(elapsed) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
}
