import XCTest
@testable import BonhommeCore

final class PoseCatalogTests: XCTestCase {

    // MARK: - Catalog Integrity

    func testAllPosesNotEmpty() {
        XCTAssertFalse(PoseCatalog.allPoses.isEmpty)
        XCTAssertGreaterThanOrEqual(PoseCatalog.allPoses.count, 26,
            "Expected 26 poses, got \(PoseCatalog.allPoses.count)")
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
        XCTAssertGreaterThanOrEqual(PoseCatalog.freePoses.count, 10,
            "Expected 10+ free poses, got \(PoseCatalog.freePoses.count)")
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
        XCTAssertTrue(categories.contains(.fullBody), "No fullBody poses")
        XCTAssertTrue(categories.contains(.balance), "No balance poses")
    }

    // MARK: - Position Coverage

    func testAllPositionsAreSeated() {
        // Chair yoga app — all poses are seated
        for pose in PoseCatalog.allPoses {
            XCTAssertEqual(pose.position, .seated,
                "Pose \(pose.id) should be seated (chair yoga)")
        }
    }

    // MARK: - Style Coverage

    func testAllStylesHaveAtLeastOnePlan() {
        for style in YogaStyle.allCases {
            let plans = PoseCatalog.plans(for: style)
            XCTAssertFalse(plans.isEmpty, "Style \(style.rawValue) has no plans")
        }
    }

    func testAllStylesHaveFreePlan() {
        for style in YogaStyle.allCases {
            let freePlans = PoseCatalog.plans(for: style).filter(\.isFree)
            XCTAssertFalse(freePlans.isEmpty, "Style \(style.rawValue) has no free plan")
        }
    }

    func testStyleFilterReturnsCorrectPlans() {
        for style in YogaStyle.allCases {
            let plans = PoseCatalog.plans(for: style)
            for plan in plans {
                XCTAssertEqual(plan.style, style,
                    "Plan \(plan.id) has style \(plan.style.rawValue) but was returned for \(style.rawValue)")
            }
        }
    }

    func testNoDuplicatePoseIdsAcrossStyles() {
        var seenIds = Set<String>()
        for pose in PoseCatalog.allPoses {
            XCTAssertFalse(seenIds.contains(pose.id), "Duplicate pose ID: \(pose.id)")
            seenIds.insert(pose.id)
        }
    }

    // MARK: - Per-Style Plan Counts

    func testChairYogaPlansExist() {
        XCTAssertGreaterThanOrEqual(PoseCatalog.chairYogaPlans.count, 1)
    }

    func testVinyasaPlansExist() {
        XCTAssertGreaterThanOrEqual(PoseCatalog.vinyasaPlans.count, 1)
    }

    func testHathaPlansExist() {
        XCTAssertGreaterThanOrEqual(PoseCatalog.hathaPlans.count, 1)
    }

    func testYinPlansExist() {
        XCTAssertGreaterThanOrEqual(PoseCatalog.yinPlans.count, 1)
    }

    func testRestorativePlansExist() {
        XCTAssertGreaterThanOrEqual(PoseCatalog.restorativePlans.count, 1)
    }

    func testPowerPlansExist() {
        XCTAssertGreaterThanOrEqual(PoseCatalog.powerPlans.count, 1)
    }

    func testStandingBalancePlansExist() {
        XCTAssertGreaterThanOrEqual(PoseCatalog.standingBalancePlans.count, 1)
    }

    func testPrenatalPlansExist() {
        XCTAssertGreaterThanOrEqual(PoseCatalog.prenatalPlans.count, 1)
    }

    func testPranayamaPlansExist() {
        XCTAssertGreaterThanOrEqual(PoseCatalog.pranayamaPlans.count, 1)
    }

    // MARK: - Workout Plans

    func testAllPlansNotEmpty() {
        XCTAssertFalse(PoseCatalog.allPlans.isEmpty)
        XCTAssertGreaterThanOrEqual(PoseCatalog.allPlans.count, 9,
            "Expected 9+ plans across all styles, got \(PoseCatalog.allPlans.count)")
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

    func testBeginnerFlowContainsPoses() {
        XCTAssertFalse(PoseCatalog.beginnerFlow.poses.isEmpty, "Beginner flow has no poses")
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

    func testAllPosesAreUsedInAtLeastOnePlan() {
        let allPlanPoses = PoseCatalog.allPlans.flatMap(\.poses)
        let usedIds = Set(allPlanPoses.map(\.id))
        for pose in PoseCatalog.allPoses {
            XCTAssertTrue(usedIds.contains(pose.id), "Pose \(pose.id) is not used in any plan")
        }
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
