import XCTest
import SwiftUI
@testable import BonhommeCore

final class MotionCoachProfileTests: XCTestCase {

    // MARK: - Helpers

    private func makePose(
        category: PoseCategory = .spine,
        difficulty: PoseDifficulty = .beginner,
        breathingPattern: String = "Inhale slowly",
        voiceCueText: String = "Lift arms",
        description: String = "A gentle stretch"
    ) -> Pose {
        Pose(
            id: "test-\(category.rawValue)-\(difficulty.rawValue)",
            name: LocalizedString(en: "Test Pose", fr: "Posture test"),
            description: LocalizedString(en: description, fr: description),
            durationSeconds: 30,
            difficulty: difficulty,
            category: category,
            imageName: "pose.test",
            voiceCueText: LocalizedString(en: voiceCueText, fr: voiceCueText),
            modifications: LocalizedStringArray(en: [], fr: []),
            breathingPattern: LocalizedString(en: breathingPattern, fr: breathingPattern),
            isFree: false
        )
    }

    // MARK: - limbOffset: All categories non-crashing

    func testLimbOffsetAllCategoriesReturnNonCrashing() {
        for category in PoseCategory.allCases {
            for dotCount in 1...3 {
                let diff: PoseDifficulty = dotCount == 1 ? .beginner : dotCount == 2 ? .intermediate : .advanced
                let pose = makePose(category: category, difficulty: diff)
                let profile = MotionCoachProfile(pose: pose)
                let (x, y, rot) = profile.limbOffset(smooth: 0.5, wave: 1.0)
                // All values must be finite
                XCTAssertTrue(x.isFinite, "\(category) x not finite at dotCount \(dotCount)")
                XCTAssertTrue(y.isFinite, "\(category) y not finite at dotCount \(dotCount)")
                XCTAssertTrue(rot.isFinite, "\(category) rot not finite at dotCount \(dotCount)")
            }
        }
    }

    // MARK: - limbOffset: Spine is vertical-dominant

    func testLimbOffsetSpineIsVerticalDominant() {
        let pose = makePose(category: .spine, difficulty: .intermediate)
        let profile = MotionCoachProfile(pose: pose)
        let (x, y, _) = profile.limbOffset(smooth: 0.5, wave: 1.0)
        XCTAssertEqual(x, 0, "Spine should have zero horizontal offset")
        XCTAssertNotEqual(y, 0, "Spine should have vertical displacement")
    }

    // MARK: - limbOffset: Neck is rotation-only

    func testLimbOffsetNeckIsRotationOnly() {
        let pose = makePose(category: .neck, difficulty: .intermediate)
        let profile = MotionCoachProfile(pose: pose)
        let (x, y, rot) = profile.limbOffset(smooth: 0.5, wave: 1.0)
        XCTAssertEqual(x, 0, "Neck should have zero horizontal offset")
        XCTAssertEqual(y, 0, "Neck should have zero vertical offset")
        XCTAssertNotEqual(rot, 0, "Neck should have rotation")
    }

    // MARK: - limbOffset: Breathing has zero rotation

    func testLimbOffsetBreathingHasZeroRotation() {
        let pose = makePose(category: .breathing, difficulty: .intermediate)
        let profile = MotionCoachProfile(pose: pose)
        let (x, y, rot) = profile.limbOffset(smooth: 0.5, wave: 1.0)
        XCTAssertEqual(x, 0, "Breathing should have zero horizontal offset")
        XCTAssertEqual(rot, 0, "Breathing should have zero rotation")
        XCTAssertNotEqual(y, 0, "Breathing should have vertical float")
    }

    // MARK: - limbOffset: Difficulty scaling increases amplitude

    func testLimbOffsetDifficultyScaling() {
        for category in PoseCategory.allCases {
            let poseBeginner = makePose(category: category, difficulty: .beginner)
            let poseAdvanced = makePose(category: category, difficulty: .advanced)
            let profileB = MotionCoachProfile(pose: poseBeginner)
            let profileA = MotionCoachProfile(pose: poseAdvanced)

            let (xB, yB, rotB) = profileB.limbOffset(smooth: 0.5, wave: 1.0)
            let (xA, yA, rotA) = profileA.limbOffset(smooth: 0.5, wave: 1.0)

            let magnitudeB = abs(xB) + abs(yB) + abs(rotB)
            let magnitudeA = abs(xA) + abs(yA) + abs(rotA)

            XCTAssertTrue(magnitudeA >= magnitudeB,
                "\(category): advanced magnitude (\(magnitudeA)) should be >= beginner (\(magnitudeB))")
        }
    }

    // MARK: - limbArcPath: Non-empty for all categories

    func testLimbArcPathNonEmptyForAllCategories() {
        let emptyPath = Path()
        for category in PoseCategory.allCases {
            let pose = makePose(category: category)
            let profile = MotionCoachProfile(pose: pose)
            let path = profile.limbArcPath(size: 200, progress: 0.5)
            XCTAssertNotEqual(path.description, emptyPath.description,
                "\(category) arc path should not be empty")
        }
    }

    // MARK: - limbArcPath: Balance is a closed loop

    func testLimbArcPathBalanceIsClosedLoop() {
        let pose = makePose(category: .balance)
        let profile = MotionCoachProfile(pose: pose)
        let path = profile.limbArcPath(size: 200, progress: 0.5)
        // Balance uses two addQuadCurve calls forming a loop;
        // the description should contain "q" (quad curve) exactly twice
        let curveCount = path.description.filter { $0 == "q" }.count
        XCTAssertGreaterThanOrEqual(curveCount, 2,
            "Balance arc should have at least 2 quad curve segments (closed loop)")
    }

    // MARK: - Cue selection priority: breathing > voice cue > description

    func testMotionCoachProfileCueSelectionPriority() {
        // When breathing pattern is non-empty, it wins
        let poseWithBreathing = makePose(
            breathingPattern: "Inhale 4s, Exhale 6s",
            voiceCueText: "Lift arms",
            description: "A stretch"
        )
        let profileBreathing = MotionCoachProfile(pose: poseWithBreathing)
        XCTAssertEqual(profileBreathing.cue, "Inhale 4s, Exhale 6s",
            "Breathing pattern should take priority")

        // When breathing is empty, voice cue wins
        let poseWithVoice = makePose(
            breathingPattern: "",
            voiceCueText: "Lift arms slowly",
            description: "A stretch"
        )
        let profileVoice = MotionCoachProfile(pose: poseWithVoice)
        XCTAssertEqual(profileVoice.cue, "Lift arms slowly",
            "Voice cue should be used when breathing is empty")

        // When both are empty, description wins
        let poseWithDesc = makePose(
            breathingPattern: "",
            voiceCueText: "",
            description: "Gentle forward fold"
        )
        let profileDesc = MotionCoachProfile(pose: poseWithDesc)
        XCTAssertEqual(profileDesc.cue, "Gentle forward fold",
            "Description should be used when breathing and voice cue are empty")
    }
}
