import Foundation
import CoreGraphics
import XCTest
@testable import BonhommeCore

final class MotionCoachPlaybackTests: XCTestCase {
    func testPauseFreezesAnimationAcrossExternalUpdatesAndResumesWithoutJump() {
        let start = Date(timeIntervalSinceReferenceDate: 100)
        var clock = MotionCoachPlaybackClock(now: start)
        clock.setPaused(true, at: start.addingTimeInterval(3))
        XCTAssertEqual(clock.time(at: start.addingTimeInterval(300)), 3)
        // Repeated pause notifications must not reset the freeze point.
        clock.setPaused(true, at: start.addingTimeInterval(500))
        XCTAssertEqual(clock.time(at: start.addingTimeInterval(600)), 3)
        clock.setPaused(false, at: start.addingTimeInterval(600))
        XCTAssertEqual(clock.time(at: start.addingTimeInterval(602)), 5)
        clock.setPaused(true, at: start.addingTimeInterval(603))
        clock.setPaused(false, at: start.addingTimeInterval(700))
        XCTAssertEqual(clock.time(at: start.addingTimeInterval(701)), 7)
    }

    func testAnimationPhaseHandlesShortAndInvalidDurations() {
        for duration in [0, 0.2, 1, 5, 30, .infinity, .nan] {
            for elapsed in [0, 0.1, 2, 5, 30, .infinity, .nan] {
                let state = AnimationPhaseState.compute(elapsed: elapsed, duration: duration)
                for value in [state.progress, state.poseBlend, state.oscillationBlend] {
                    XCTAssertTrue(value.isFinite)
                    XCTAssertTrue((0...1).contains(value))
                }
            }
        }
        XCTAssertEqual(AnimationPhaseState.compute(elapsed: 1, duration: 1).poseBlend, 0)
        XCTAssertEqual(AnimationPhaseState.compute(elapsed: 30, duration: 30, setupDuration: 0, releaseDuration: 0).poseBlend, 0)
    }

    func testReducedMotionKeepsAllPoseJointsAndDepthStatic() {
        for pose in PoseCatalog.allPoses {
            let profile = StickFigureMotionProfile(category: pose.category, difficulty: pose.difficulty, phase: .active)
            let first = SkeletonPose(profile: profile, kinematics: pose.kinematics, phaseState: .still,
                                     smooth: 0.1, t: 1, size: 200, center: .zero)
            let later = SkeletonPose(profile: profile, kinematics: pose.kinematics, phaseState: .still,
                                     smooth: 0.85, t: 456, size: 200, center: .zero)
            XCTAssertEqual(points(first), points(later), pose.id)
            XCTAssertEqual(first.armDepthPhase, later.armDepthPhase, pose.id)
            XCTAssertTrue(points(first).allSatisfy { $0.x.isFinite && $0.y.isFinite }, pose.id)
        }
    }

    func testZeroHoldOscillationAlsoFreezesAllPoseJoints() {
        for pose in PoseCatalog.allPoses {
            var kinematics = pose.kinematics
            kinematics.holdOscillationScale = 0
            let profile = StickFigureMotionProfile(category: pose.category, difficulty: pose.difficulty, phase: .active)
            let state = AnimationPhaseState.compute(elapsed: 6, duration: 30)
            let first = SkeletonPose(profile: profile, kinematics: kinematics, phaseState: state,
                                     smooth: 0.1, t: 1, size: 200, center: .zero)
            let later = SkeletonPose(profile: profile, kinematics: kinematics, phaseState: state,
                                     smooth: 0.7, t: 22, size: 200, center: .zero)
            XCTAssertEqual(points(first), points(later), pose.id)
        }
    }

    private func points(_ pose: SkeletonPose) -> [CGPoint] {
        [pose.pelvis, pose.spineMid, pose.neck, pose.headCenter, pose.leftShoulder, pose.rightShoulder,
         pose.leftHip, pose.rightHip, pose.leftElbow, pose.rightElbow, pose.leftHand, pose.rightHand,
         pose.leftKnee, pose.rightKnee, pose.leftFoot, pose.rightFoot]
    }
}
