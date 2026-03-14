import XCTest
@testable import BonhommeCore

final class WorkoutResultTests: XCTestCase {

    func testWorkoutResultCodable() throws {
        let result = WorkoutResult(
            workoutPlanId: "beginner-chair-flow",
            workoutPlanName: "Gentle Chair Flow",
            startDate: Date(timeIntervalSince1970: 1700000000),
            endDate: Date(timeIntervalSince1970: 1700000300),
            totalDuration: 300,
            posesCompleted: 5,
            totalPoses: 7,
            activeCalories: 45.5,
            averageHeartRate: 78,
            maxHeartRate: 95,
            heartRateSamples: [
                HeartRateSample(bpm: 72, timestamp: Date(timeIntervalSince1970: 1700000060)),
                HeartRateSample(bpm: 78, timestamp: Date(timeIntervalSince1970: 1700000120)),
                HeartRateSample(bpm: 95, timestamp: Date(timeIntervalSince1970: 1700000180)),
            ]
        )

        let data = try JSONEncoder().encode(result)
        let decoded = try JSONDecoder().decode(WorkoutResult.self, from: data)

        XCTAssertEqual(decoded.workoutPlanId, "beginner-chair-flow")
        XCTAssertEqual(decoded.totalDuration, 300)
        XCTAssertEqual(decoded.posesCompleted, 5)
        XCTAssertEqual(decoded.totalPoses, 7)
        XCTAssertEqual(decoded.activeCalories, 45.5)
        XCTAssertEqual(decoded.averageHeartRate, 78)
        XCTAssertEqual(decoded.maxHeartRate, 95)
        XCTAssertEqual(decoded.heartRateSamples.count, 3)
    }

    func testWorkoutResultWithNilHeartRate() throws {
        let result = WorkoutResult(
            workoutPlanId: "test",
            workoutPlanName: "Test",
            startDate: Date(),
            endDate: Date(),
            totalDuration: 60,
            posesCompleted: 1,
            totalPoses: 1,
            activeCalories: 10,
            averageHeartRate: nil,
            maxHeartRate: nil,
            heartRateSamples: []
        )

        let data = try JSONEncoder().encode(result)
        let decoded = try JSONDecoder().decode(WorkoutResult.self, from: data)

        XCTAssertNil(decoded.averageHeartRate)
        XCTAssertNil(decoded.maxHeartRate)
        XCTAssertTrue(decoded.heartRateSamples.isEmpty)
    }

    func testHeartRateSampleCodable() throws {
        let sample = HeartRateSample(bpm: 85.5, timestamp: Date(timeIntervalSince1970: 1700000000))
        let data = try JSONEncoder().encode(sample)
        let decoded = try JSONDecoder().decode(HeartRateSample.self, from: data)
        XCTAssertEqual(decoded.bpm, 85.5)
    }
}
