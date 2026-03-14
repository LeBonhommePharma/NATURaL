import XCTest
@testable import BonhommeCore

final class PoseCatalogTests: XCTestCase {

    // MARK: - Catalog Integrity

    func testAllPosesNotEmpty() {
        XCTAssertFalse(PoseCatalog.allPoses.isEmpty)
        XCTAssertGreaterThanOrEqual(PoseCatalog.allPoses.count, 16)
    }

    func testAllPoseIdsAreUnique() {
        let ids = PoseCatalog.allPoses.map(\.id)
        let uniqueIds = Set(ids)
        XCTAssertEqual(ids.count, uniqueIds.count, "Duplicate pose IDs found")
    }

    func testAllPoseImageNamesAreUnique() {
        let imageNames = PoseCatalog.allPoses.map(\.imageName)
        let unique = Set(imageNames)
        XCTAssertEqual(imageNames.count, unique.count, "Duplicate image names found")
    }

    func testAllPosesHaveBothLanguages() {
        for pose in PoseCatalog.allPoses {
            XCTAssertFalse(pose.name.en.isEmpty, "Pose \(pose.id) missing English name")
            XCTAssertFalse(pose.name.fr.isEmpty, "Pose \(pose.id) missing French name")
            XCTAssertFalse(pose.description.en.isEmpty, "Pose \(pose.id) missing English description")
            XCTAssertFalse(pose.description.fr.isEmpty, "Pose \(pose.id) missing French description")
            XCTAssertFalse(pose.voiceCueText.en.isEmpty, "Pose \(pose.id) missing English voice cue")
            XCTAssertFalse(pose.voiceCueText.fr.isEmpty, "Pose \(pose.id) missing French voice cue")
            XCTAssertFalse(pose.breathingPattern.en.isEmpty, "Pose \(pose.id) missing English breathing")
            XCTAssertFalse(pose.breathingPattern.fr.isEmpty, "Pose \(pose.id) missing French breathing")
        }
    }

    func testAllPosesHaveModifications() {
        for pose in PoseCatalog.allPoses {
            XCTAssertFalse(pose.modifications.en.isEmpty, "Pose \(pose.id) missing English modifications")
            XCTAssertFalse(pose.modifications.fr.isEmpty, "Pose \(pose.id) missing French modifications")
            // Same number of modifications in both languages
            XCTAssertEqual(
                pose.modifications.en.count,
                pose.modifications.fr.count,
                "Pose \(pose.id) has mismatched modification counts"
            )
        }
    }

    func testAllPosesHavePositiveDuration() {
        for pose in PoseCatalog.allPoses {
            XCTAssertGreaterThan(pose.durationSeconds, 0, "Pose \(pose.id) has zero/negative duration")
        }
    }

    func testContraindicationsMatchCounts() {
        for pose in PoseCatalog.allPoses {
            XCTAssertEqual(
                pose.contraindications.en.count,
                pose.contraindications.fr.count,
                "Pose \(pose.id) has mismatched contraindication counts"
            )
        }
    }

    // MARK: - Free/Premium Split

    func testFreePosesExist() {
        XCTAssertFalse(PoseCatalog.freePoses.isEmpty)
        XCTAssertGreaterThanOrEqual(PoseCatalog.freePoses.count, 5)
    }

    func testPremiumPosesExist() {
        XCTAssertFalse(PoseCatalog.premiumPoses.isEmpty)
    }

    func testFreePlusAndPremiumEqualsAll() {
        let totalCount = PoseCatalog.freePoses.count + PoseCatalog.premiumPoses.count
        XCTAssertEqual(totalCount, PoseCatalog.allPoses.count)
    }

    func testAllFreePosesMarkedFree() {
        for pose in PoseCatalog.freePoses {
            XCTAssertTrue(pose.isFree, "Pose \(pose.id) in freePoses but isFree=false")
        }
    }

    func testAllPremiumPosesNotFree() {
        for pose in PoseCatalog.premiumPoses {
            XCTAssertFalse(pose.isFree, "Pose \(pose.id) in premiumPoses but isFree=true")
        }
    }

    // MARK: - Difficulty Distribution

    func testHasBeginnerPoses() {
        let beginners = PoseCatalog.allPoses.filter { $0.difficulty == .beginner }
        XCTAssertFalse(beginners.isEmpty)
    }

    func testHasIntermediatePoses() {
        let intermediate = PoseCatalog.allPoses.filter { $0.difficulty == .intermediate }
        XCTAssertFalse(intermediate.isEmpty)
    }

    func testHasAdvancedPoses() {
        let advanced = PoseCatalog.allPoses.filter { $0.difficulty == .advanced }
        XCTAssertFalse(advanced.isEmpty)
    }

    // MARK: - Category Coverage

    func testCategoryCoverage() {
        let categories = Set(PoseCatalog.allPoses.map(\.category))
        XCTAssertTrue(categories.contains(.spine), "No spine poses")
        XCTAssertTrue(categories.contains(.hips), "No hip poses")
        XCTAssertTrue(categories.contains(.shoulders), "No shoulder poses")
        XCTAssertTrue(categories.contains(.neck), "No neck poses")
        XCTAssertTrue(categories.contains(.breathing), "No breathing poses")
    }

    // MARK: - Workout Plans

    func testAllPlansNotEmpty() {
        XCTAssertFalse(PoseCatalog.allPlans.isEmpty)
        XCTAssertGreaterThanOrEqual(PoseCatalog.allPlans.count, 4)
    }

    func testAllPlanIdsAreUnique() {
        let ids = PoseCatalog.allPlans.map(\.id)
        let unique = Set(ids)
        XCTAssertEqual(ids.count, unique.count, "Duplicate plan IDs found")
    }

    func testAllPlansHaveBothLanguages() {
        for plan in PoseCatalog.allPlans {
            XCTAssertFalse(plan.name.en.isEmpty, "Plan \(plan.id) missing English name")
            XCTAssertFalse(plan.name.fr.isEmpty, "Plan \(plan.id) missing French name")
            XCTAssertFalse(plan.description.en.isEmpty, "Plan \(plan.id) missing English description")
            XCTAssertFalse(plan.description.fr.isEmpty, "Plan \(plan.id) missing French description")
        }
    }

    func testBeginnerFlowIsFree() {
        XCTAssertTrue(PoseCatalog.beginnerFlow.isFree)
    }

    func testBeginnerFlowContainsOnlyFreePoses() {
        for pose in PoseCatalog.beginnerFlow.poses {
            XCTAssertTrue(pose.isFree, "Beginner flow contains non-free pose: \(pose.id)")
        }
    }

    func testAllPlansHavePoses() {
        for plan in PoseCatalog.allPlans {
            XCTAssertFalse(plan.poses.isEmpty, "Plan \(plan.id) has no poses")
        }
    }

    func testAllPlansHavePositiveTransitionTime() {
        for plan in PoseCatalog.allPlans {
            XCTAssertGreaterThan(plan.transitionSeconds, 0, "Plan \(plan.id) has zero transition time")
        }
    }

    func testTotalDurationCalculation() {
        let plan = PoseCatalog.beginnerFlow
        let poseDuration = plan.poses.reduce(0) { $0 + $1.durationSeconds }
        let transitions = TimeInterval(max(0, plan.poses.count - 1)) * plan.transitionSeconds
        XCTAssertEqual(plan.totalDuration, poseDuration + transitions)
    }

    func testFullBodyPlanContainsAllPoses() {
        XCTAssertEqual(PoseCatalog.fullBody.poses.count, PoseCatalog.allPoses.count)
    }

    // MARK: - Specific Poses

    func testSeatedMountainProperties() {
        let pose = PoseCatalog.seatedMountain
        XCTAssertEqual(pose.id, "seated-mountain")
        XCTAssertEqual(pose.difficulty, .beginner)
        XCTAssertEqual(pose.category, .spine)
        XCTAssertTrue(pose.isFree)
        XCTAssertEqual(pose.name.en, "Seated Mountain")
        XCTAssertEqual(pose.name.fr, "Montagne assise")
    }

    func testSeatedMeditationIsLongest() {
        let meditation = PoseCatalog.seatedMeditation
        XCTAssertEqual(meditation.durationSeconds, 60)
        XCTAssertEqual(meditation.category, .breathing)
    }
}
