import Foundation

/// A complete workout plan consisting of multiple yoga poses.
public struct WorkoutPlan: Identifiable, Codable, Sendable {
    public let id: UUID
    public let name: LocalizedString
    public let description: LocalizedString
    public let style: YogaStyle
    public let poses: [YogaPose]
    
    public init(
        id: UUID = UUID(),
        name: LocalizedString,
        description: LocalizedString,
        style: YogaStyle,
        poses: [YogaPose],
    ) {
        self.id = id
        self.name = name
        self.description = description
        self.style = style
        self.poses = poses
    }
    
    public var poseCount: Int {
        poses.count
    }
    
    public var totalDuration: TimeInterval {
        poses.reduce(0) { $0 + $1.durationSeconds }
    }
}
