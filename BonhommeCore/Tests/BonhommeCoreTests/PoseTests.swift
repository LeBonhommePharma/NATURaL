import XCTest
@testable import BonhommeCore

final class PoseTests: XCTestCase {

    // MARK: - Pose Model

    func testPoseInitialization() {
        let pose = makePose(id: "test-pose", isFree: true)
        XCTAssertEqual(pose.id, "test-pose")
        XCTAssertEqual(pose.name.en, "Test Pose")
        XCTAssertEqual(pose.name.fr, "Posture test")
        XCTAssertEqual(pose.durationSeconds, 30)
        XCTAssertEqual(pose.difficulty, .beginner)
        XCTAssertEqual(pose.category, .spine)
        XCTAssertTrue(pose.isFree)
    }

    func testPoseIdentifiable() {
        let a = makePose(id: "pose-a")
        let b = makePose(id: "pose-b")
        XCTAssertNotEqual(a.id, b.id)
    }

    func testPoseCodable() throws {
        let original = makePose(id: "codable-test")
        let data = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(Pose.self, from: data)
        XCTAssertEqual(decoded.id, original.id)
        XCTAssertEqual(decoded.name, original.name)
        XCTAssertEqual(decoded.difficulty, original.difficulty)
        XCTAssertEqual(decoded.category, original.category)
        XCTAssertEqual(decoded.durationSeconds, original.durationSeconds)
        XCTAssertEqual(decoded.isFree, original.isFree)
    }

    func testPoseHashable() {
        let a = makePose(id: "same-id")
        let b = makePose(id: "same-id")
        XCTAssertEqual(a, b)

        var set = Set<Pose>()
        set.insert(a)
        set.insert(b)
        XCTAssertEqual(set.count, 1)
    }

    // MARK: - PoseDifficulty

    func testPoseDifficultyAllCases() {
        XCTAssertEqual(PoseDifficulty.allCases.count, 3)
        XCTAssertTrue(PoseDifficulty.allCases.contains(.beginner))
        XCTAssertTrue(PoseDifficulty.allCases.contains(.intermediate))
        XCTAssertTrue(PoseDifficulty.allCases.contains(.advanced))
    }

    func testPoseDifficultyLocalizedName() {
        XCTAssertEqual(PoseDifficulty.beginner.localizedName.en, "Beginner")
        XCTAssertEqual(PoseDifficulty.beginner.localizedName.fr, "Débutant")
        XCTAssertEqual(PoseDifficulty.intermediate.localizedName.en, "Intermediate")
        XCTAssertEqual(PoseDifficulty.advanced.localizedName.fr, "Avancé")
    }

    func testPoseDifficultyCodable() throws {
        for difficulty in PoseDifficulty.allCases {
            let data = try JSONEncoder().encode(difficulty)
            let decoded = try JSONDecoder().decode(PoseDifficulty.self, from: data)
            XCTAssertEqual(decoded, difficulty)
        }
    }

    // MARK: - PoseCategory

    func testPoseCategoryAllCases() {
        XCTAssertEqual(PoseCategory.allCases.count, 7)
    }

    func testPoseCategoryLocalizedName() {
        XCTAssertEqual(PoseCategory.spine.localizedName.en, "Spine")
        XCTAssertEqual(PoseCategory.spine.localizedName.fr, "Colonne vertébrale")
        XCTAssertEqual(PoseCategory.hips.localizedName.en, "Hips")
        XCTAssertEqual(PoseCategory.hips.localizedName.fr, "Hanches")
    }

    // MARK: - Helpers

    private func makePose(id: String, isFree: Bool = false) -> Pose {
        Pose(
            id: id,
            name: LocalizedString(en: "Test Pose", fr: "Posture test"),
            description: LocalizedString(en: "A test pose", fr: "Une posture test"),
            durationSeconds: 30,
            difficulty: .beginner,
            category: .spine,
            imageName: "pose.test",
            voiceCueText: LocalizedString(en: "Do the pose", fr: "Faites la posture"),
            modifications: LocalizedStringArray(en: ["Mod A"], fr: ["Mod A-FR"]),
            contraindications: LocalizedStringArray(en: [], fr: []),
            breathingPattern: LocalizedString(en: "Breathe", fr: "Respirez"),
            isFree: isFree
        )
    }
}
