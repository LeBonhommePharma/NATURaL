import Foundation

/// Difficulty levels for chair yoga poses.
public enum PoseDifficulty: String, Codable, Sendable, CaseIterable {
    case beginner
    case intermediate
    case advanced
}

/// A single chair yoga pose with metadata for guided instruction.
public struct Pose: Codable, Sendable, Identifiable, Hashable {
    public let id: String
    public let name: String
    public let description: String
    public let durationSeconds: TimeInterval
    public let difficulty: PoseDifficulty
    public let imageName: String
    public let voiceCueText: String
    public let modifications: [String]
    public let isFree: Bool

    public init(
        id: String,
        name: String,
        description: String,
        durationSeconds: TimeInterval,
        difficulty: PoseDifficulty,
        imageName: String,
        voiceCueText: String,
        modifications: [String],
        isFree: Bool
    ) {
        self.id = id
        self.name = name
        self.description = description
        self.durationSeconds = durationSeconds
        self.difficulty = difficulty
        self.imageName = imageName
        self.voiceCueText = voiceCueText
        self.modifications = modifications
        self.isFree = isFree
    }
}
