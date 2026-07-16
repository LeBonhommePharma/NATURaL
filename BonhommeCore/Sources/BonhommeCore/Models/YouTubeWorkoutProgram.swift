// BonhommeCore/Sources/BonhommeCore/Models/YouTubeWorkoutProgram.swift
import Foundation
import HealthKit

// MARK: - ProgramPhase

/// A timestamped segment of a YouTube-backed workout.
/// `startTime` / `endTime` map to seconds in the video timeline.
public struct ProgramPhase: Codable, Sendable, Identifiable {
    public let id: UUID
    public let name: String
    public let startTime: TimeInterval
    public let endTime: TimeInterval
    public let targetSCIRange: ClosedRange<Double>?

    public var duration: TimeInterval { endTime - startTime }

    public init(
        id: UUID = UUID(),
        name: String,
        startTime: TimeInterval,
        endTime: TimeInterval,
        targetSCIRange: ClosedRange<Double>? = nil
    ) {
        self.id = id
        self.name = name
        self.startTime = startTime
        self.endTime = endTime
        self.targetSCIRange = targetSCIRange
    }

    private enum CodingKeys: String, CodingKey {
        case id, name, startTime, endTime, targetSCILower, targetSCIUpper
    }

    public init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = try c.decode(UUID.self, forKey: .id)
        name = try c.decode(String.self, forKey: .name)
        startTime = try c.decode(TimeInterval.self, forKey: .startTime)
        endTime = try c.decode(TimeInterval.self, forKey: .endTime)
        if let lo = try c.decodeIfPresent(Double.self, forKey: .targetSCILower),
           let hi = try c.decodeIfPresent(Double.self, forKey: .targetSCIUpper) {
            targetSCIRange = lo...hi
        } else {
            targetSCIRange = nil
        }
    }

    public func encode(to encoder: Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        try c.encode(id, forKey: .id)
        try c.encode(name, forKey: .name)
        try c.encode(startTime, forKey: .startTime)
        try c.encode(endTime, forKey: .endTime)
        try c.encodeIfPresent(targetSCIRange?.lowerBound, forKey: .targetSCILower)
        try c.encodeIfPresent(targetSCIRange?.upperBound, forKey: .targetSCIUpper)
    }
}

// MARK: - YouTubeWorkoutProgram

public struct YouTubeWorkoutProgram: Codable, Sendable, Identifiable {
    public let id: UUID
    public let title: String
    public let youtubeID: String
    public let expectedDuration: TimeInterval
    public let activityType: HKWorkoutActivityType
    public let locationType: HKWorkoutSessionLocationType
    public let phases: [ProgramPhase]
    public let programDescription: String

    public init(
        id: UUID = UUID(),
        title: String,
        youtubeID: String,
        expectedDuration: TimeInterval,
        activityType: HKWorkoutActivityType = .yoga,
        locationType: HKWorkoutSessionLocationType = .indoor,
        phases: [ProgramPhase] = [],
        programDescription: String = ""
    ) {
        self.id = id
        self.title = title
        self.youtubeID = youtubeID
        self.expectedDuration = expectedDuration
        self.activityType = activityType
        self.locationType = locationType
        self.phases = phases
        self.programDescription = programDescription
    }

    private enum CodingKeys: String, CodingKey {
        case id, title, youtubeID, expectedDuration
        case activityTypeRaw, locationTypeRaw
        case phases, programDescription
    }

    public init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = try c.decode(UUID.self, forKey: .id)
        title = try c.decode(String.self, forKey: .title)
        youtubeID = try c.decode(String.self, forKey: .youtubeID)
        expectedDuration = try c.decode(TimeInterval.self, forKey: .expectedDuration)
        let activityRaw = try c.decode(UInt.self, forKey: .activityTypeRaw)
        activityType = HKWorkoutActivityType(rawValue: activityRaw) ?? .other
        let locationRaw = try c.decode(Int.self, forKey: .locationTypeRaw)
        locationType = HKWorkoutSessionLocationType(rawValue: locationRaw) ?? .unknown
        phases = try c.decode([ProgramPhase].self, forKey: .phases)
        programDescription = try c.decode(String.self, forKey: .programDescription)
    }

    public func encode(to encoder: Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        try c.encode(id, forKey: .id)
        try c.encode(title, forKey: .title)
        try c.encode(youtubeID, forKey: .youtubeID)
        try c.encode(expectedDuration, forKey: .expectedDuration)
        try c.encode(activityType.rawValue, forKey: .activityTypeRaw)
        try c.encode(locationType.rawValue, forKey: .locationTypeRaw)
        try c.encode(phases, forKey: .phases)
        try c.encode(programDescription, forKey: .programDescription)
    }
}

// MARK: - Catalog

public struct YouTubeProgramCatalog {
    public static let programs: [YouTubeWorkoutProgram] = [
        YouTubeWorkoutProgram(
            title: "Chair Yoga – 20 min",
            youtubeID: "M7lc1UVf-VE",
            expectedDuration: 1200,
            activityType: .yoga,
            locationType: .indoor,
            phases: [
                ProgramPhase(name: "Warm-up",   startTime: 0,   endTime: 180,  targetSCIRange: 0.4...0.7),
                ProgramPhase(name: "Main flow", startTime: 180, endTime: 960,  targetSCIRange: 0.5...0.85),
                ProgramPhase(name: "Cool-down", startTime: 960, endTime: 1200, targetSCIRange: 0.2...0.5)
            ],
            programDescription: "Seated chair yoga — gentle full-body flow."
        ),
        YouTubeWorkoutProgram(
            title: "Mindful Breathwork – 10 min",
            youtubeID: "inpok4MKVLM",
            expectedDuration: 600,
            activityType: .mindAndBody,
            locationType: .indoor,
            phases: [
                ProgramPhase(name: "Centering",   startTime: 0,   endTime: 120),
                ProgramPhase(name: "Box breath",  startTime: 120, endTime: 480, targetSCIRange: 0.1...0.45),
                ProgramPhase(name: "Integration", startTime: 480, endTime: 600)
            ],
            programDescription: "Guided box-breathing to collapse SCI entropy."
        )
    ]
}
