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

    /// Every WorkoutKind must ship with ≥1 free plan (catalog freemium gate).
    func testFreePlanCoverageAcrossAllKinds() {
        var coverage: [(kind: String, total: Int, free: Int)] = []
        for style in YogaStyle.allCases {
            let plans = PoseCatalog.plans(for: style)
            let free = plans.filter(\.isFree)
            coverage.append((style.rawValue, plans.count, free.count))
            XCTAssertGreaterThanOrEqual(
                free.count, 1,
                "Kind \(style.rawValue) missing free plan (total=\(plans.count))"
            )
            for plan in free {
                XCTAssertFalse(plan.name.en.isEmpty, "Free plan \(plan.id) missing EN name")
                XCTAssertFalse(plan.name.fr.isEmpty, "Free plan \(plan.id) missing FR name")
                XCTAssertFalse(plan.poses.isEmpty, "Free plan \(plan.id) has no poses")
            }
        }
        let report = coverage
            .map { "\($0.kind): \($0.free)/\($0.total) free" }
            .joined(separator: ", ")
        XCTAssertEqual(coverage.count, YogaStyle.allCases.count, "Coverage incomplete: \(report)")
    }

    /// Sparse kinds (historically single-plan) must include a dedicated free starter.
    func testSparseKindsHaveFreeStarterPlans() {
        let sparseStarterIDs: [YogaStyle: String] = [
            .power: "power-starter",
            .standingBalance: "standing-balance-starter",
            .prenatal: "prenatal-starter",
            .pranayama: "pranayama-starter",
            .hatha: "hatha-starter",
            .yin: "yin-starter",
            .matYoga: "mat-starter",
            .strength: "strength-starter",
            .cardio: "cardio-starter",
            .mobility: "mobility-starter",
            .meditation: "meditation-starter",
            .general: "general-starter",
        ]
        for (style, starterID) in sparseStarterIDs {
            let plans = PoseCatalog.plans(for: style)
            guard let starter = plans.first(where: { $0.id == starterID }) else {
                XCTFail("Sparse kind \(style.rawValue) missing starter plan id=\(starterID)")
                continue
            }
            XCTAssertTrue(starter.isFree, "Starter \(starterID) must be free")
            XCTAssertEqual(starter.style, style)
            XCTAssertFalse(starter.name.en.isEmpty)
            XCTAssertFalse(starter.name.fr.isEmpty)
            XCTAssertFalse(starter.poses.isEmpty)
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
        XCTAssertGreaterThanOrEqual(PoseCatalog.hathaPlans.count, 2)
        XCTAssertTrue(PoseCatalog.hathaPlans.contains { $0.isFree })
    }

    func testNonYogaSamplePlansExist() {
        XCTAssertGreaterThanOrEqual(PoseCatalog.strengthPlans.count, 2)
        XCTAssertGreaterThanOrEqual(PoseCatalog.cardioPlans.count, 2)
        XCTAssertGreaterThanOrEqual(PoseCatalog.mobilityPlans.count, 2)
        XCTAssertGreaterThanOrEqual(PoseCatalog.meditationPlans.count, 2)
        XCTAssertGreaterThanOrEqual(PoseCatalog.matYogaPlans.count, 2)
        XCTAssertGreaterThanOrEqual(PoseCatalog.generalPlans.count, 2)
        XCTAssertEqual(PoseCatalog.strengthPlans.first?.style, .strength)
        XCTAssertEqual(PoseCatalog.cardioPlans.first?.style, .cardio)
        XCTAssertTrue(PoseCatalog.strengthPlans.contains { $0.isFree })
        XCTAssertTrue(PoseCatalog.cardioPlans.contains { $0.isFree })
        XCTAssertTrue(PoseCatalog.mobilityPlans.contains { $0.isFree })
        XCTAssertTrue(PoseCatalog.meditationPlans.contains { $0.isFree })
        XCTAssertTrue(PoseCatalog.matYogaPlans.contains { $0.isFree })
        XCTAssertTrue(PoseCatalog.generalPlans.contains { $0.isFree })
    }

    func testGenericBuilderProducesKindPlan() {
        let plan = PoseCatalog.genericBuilder(
            id: "generic-test",
            kind: .general,
            name: LocalizedString(en: "Generic", fr: "Générique"),
            description: LocalizedString(en: "Test", fr: "Test")
        )
        XCTAssertEqual(plan.style, .general)
        XCTAssertTrue(plan.isFree)
        XCTAssertFalse(plan.poses.isEmpty)
    }

    func testYinPlansExist() {
        XCTAssertGreaterThanOrEqual(PoseCatalog.yinPlans.count, 2)
        XCTAssertTrue(PoseCatalog.yinPlans.contains { $0.isFree })
    }

    func testRestorativePlansExist() {
        XCTAssertGreaterThanOrEqual(PoseCatalog.restorativePlans.count, 1)
        XCTAssertTrue(PoseCatalog.restorativePlans.contains { $0.isFree })
    }

    func testPowerPlansExist() {
        XCTAssertGreaterThanOrEqual(PoseCatalog.powerPlans.count, 2)
        XCTAssertTrue(PoseCatalog.powerPlans.contains { $0.isFree })
    }

    func testStandingBalancePlansExist() {
        XCTAssertGreaterThanOrEqual(PoseCatalog.standingBalancePlans.count, 2)
        XCTAssertTrue(PoseCatalog.standingBalancePlans.contains { $0.isFree })
    }

    func testPrenatalPlansExist() {
        XCTAssertGreaterThanOrEqual(PoseCatalog.prenatalPlans.count, 2)
        XCTAssertTrue(PoseCatalog.prenatalPlans.contains { $0.isFree })
    }

    func testPranayamaPlansExist() {
        XCTAssertGreaterThanOrEqual(PoseCatalog.pranayamaPlans.count, 2)
        XCTAssertTrue(PoseCatalog.pranayamaPlans.contains { $0.isFree })
    }

    // MARK: - Workout Plans

    func testAllPlansNotEmpty() {
        XCTAssertFalse(PoseCatalog.allPlans.isEmpty)
        // 15 kinds × ≥1 plan; sparse starters raise floor well above legacy 9
        XCTAssertGreaterThanOrEqual(PoseCatalog.allPlans.count, YogaStyle.allCases.count,
            "Expected ≥1 plan per kind (\(YogaStyle.allCases.count)+), got \(PoseCatalog.allPlans.count)")
        XCTAssertGreaterThanOrEqual(PoseCatalog.allPlans.count, 27,
            "Expected 27+ plans after sparse starters, got \(PoseCatalog.allPlans.count)")
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

    // MARK: - PoseKinematics

    func testAllPosesHaveKinematics() {
        for pose in PoseCatalog.allPoses {
            let k = pose.kinematics
            XCTAssertFalse(k.highlightedRegions.isEmpty,
                           "Pose \(pose.id) has no highlighted regions")
        }
    }

    func testKinematicsCatalogCoversAllPoses() {
        for pose in PoseCatalog.allPoses {
            let k = PoseKinematicsCatalog.kinematics(for: pose.id)
            let neutral = PoseKinematics.neutral
            let isDifferent = k.forwardLean != neutral.forwardLean
                || k.leftUpperArmAngle != neutral.leftUpperArmAngle
                || k.rightUpperArmAngle != neutral.rightUpperArmAngle
                || k.leftForearmBend != neutral.leftForearmBend
                || k.rightForearmBend != neutral.rightForearmBend
                || k.sideLean != neutral.sideLean
                || k.leftThighOffset != neutral.leftThighOffset
                || k.rightThighOffset != neutral.rightThighOffset
                || k.leftKneeSpread != neutral.leftKneeSpread
                || k.rightKneeSpread != neutral.rightKneeSpread
            XCTAssertTrue(isDifferent,
                          "Pose \(pose.id) returned neutral kinematics (likely unmapped)")
        }
    }

    func testPoseKinematicsHasSetupSteps() {
        for pose in PoseCatalog.allPoses {
            let k = pose.kinematics
            XCTAssertFalse(k.setupSteps.isEmpty,
                           "Pose \(pose.id) has no setup steps")
            for step in k.setupSteps {
                XCTAssertFalse(step.en.isEmpty, "Pose \(pose.id) has empty EN step")
                XCTAssertFalse(step.fr.isEmpty, "Pose \(pose.id) has empty FR step")
            }
        }
    }

    func testKinematicsHoldOscillationScale() {
        for pose in PoseCatalog.allPoses {
            let k = pose.kinematics
            XCTAssertGreaterThanOrEqual(k.holdOscillationScale, 0)
            XCTAssertLessThanOrEqual(k.holdOscillationScale, 1.0)
        }
    }

    func testAnimationPhaseStateSetup() {
        let state = AnimationPhaseState.compute(elapsed: 0, duration: 30)
        XCTAssertEqual(state.phase, .setup)
        XCTAssertEqual(state.poseBlend, 0)
    }

    func testAnimationPhaseStateHold() {
        let state = AnimationPhaseState.compute(elapsed: 10, duration: 30)
        XCTAssertEqual(state.phase, .hold)
        XCTAssertEqual(state.poseBlend, 1.0)
        XCTAssertEqual(state.oscillationBlend, 1.0)
    }

    func testAnimationPhaseStateRelease() {
        let state = AnimationPhaseState.compute(elapsed: 29, duration: 30)
        XCTAssertEqual(state.phase, .release)
        XCTAssertLessThan(state.poseBlend, 1.0)
        XCTAssertGreaterThan(state.poseBlend, 0)
    }

    func testAnimationPhaseStatePreview() {
        let state = AnimationPhaseState.compute(elapsed: 0, duration: 30, phase: .preview)
        XCTAssertEqual(state.phase, .hold)
        XCTAssertLessThan(state.poseBlend, 1.0)
    }

    func testKinematicsBlending() {
        let a = PoseKinematics.neutral
        let b = PoseKinematics(forwardLean: 0.5, leftUpperArmAngle: 0.0)
        let mid = b.blended(with: a, factor: 0.5)
        XCTAssertEqual(mid.forwardLean, 0.25, accuracy: 0.001)
        XCTAssertEqual(mid.leftUpperArmAngle, (.pi * 0.55 + 0.0) / 2.0, accuracy: 0.001)
    }
}
