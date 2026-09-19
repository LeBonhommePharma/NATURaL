import SwiftUI
import UIKit
import ARKit
import RealityKit
import BonhommeCore

/// ARKit world-tracking coach. Caller falls back to `MotionCoachView` when unsupported.
struct ARPoseCoachView: View {
    let pose: Pose
    var phase: MotionCoachPhase = .active
    var poseElapsed: TimeInterval = 0
    var isPaused: Bool = false
    var reduceMotion: Bool = false
    var onReady: () -> Void = {}
    var onUnavailable: () -> Void = {}

    var body: some View {
        ARPoseCoachRepresentable(
            pose: pose,
            phase: phase,
            poseElapsed: poseElapsed,
            isPaused: isPaused,
            reduceMotion: reduceMotion,
            onReady: onReady,
            onUnavailable: onUnavailable
        )
        .clipShape(SessionRadius.cardShape())
        .overlay(
            SessionRadius.cardShape()
                .strokeBorder(BrandColor.hairlineStrong, lineWidth: 1)
        )
        .accessibilityLabel(Text(SessionHUDCopy.arCoach.localized))
        .accessibilityValue(Text(([pose.name.localized, pose.description.localized] + pose.kinematics.setupSteps.map { $0.localized }).joined(separator: ". ")))
    }
}

private struct ARPoseCoachRepresentable: UIViewRepresentable {
    var pose: Pose
    var phase: MotionCoachPhase
    var poseElapsed: TimeInterval
    var isPaused: Bool
    var reduceMotion: Bool
    var onReady: () -> Void
    var onUnavailable: () -> Void

    func makeUIView(context: Context) -> ARView {
        let view = ARView(frame: .zero)
        view.automaticallyConfigureSession = false
        view.environment.background = .cameraFeed()
        context.coordinator.onUnavailable = onUnavailable
        context.coordinator.onReady = onReady
        view.session.delegate = context.coordinator
        if ARWorldTrackingConfiguration.isSupported {
            let config = ARWorldTrackingConfiguration()
            config.planeDetection = [.horizontal]
            config.worldAlignment = .gravity
            view.session.run(config, options: [.resetTracking, .removeExistingAnchors])
        } else {
            DispatchQueue.main.async { onUnavailable() }
        }
        context.coordinator.install(in: view, pose: pose)
        return view
    }

    func updateUIView(_ uiView: ARView, context: Context) {
        context.coordinator.onUnavailable = onUnavailable
        context.coordinator.onReady = onReady
        context.coordinator.setPaused(isPaused, in: uiView)
        guard !isPaused else { return }
        context.coordinator.update(pose: pose, elapsed: poseElapsed, phase: phase, reduceMotion: reduceMotion)
    }

    static func dismantleUIView(_ uiView: ARView, coordinator: Coordinator) {
        uiView.session.pause()
        uiView.session.delegate = nil
        uiView.scene.anchors.removeAll()
    }

    func makeCoordinator() -> Coordinator { Coordinator() }

    final class Coordinator: NSObject, ARSessionDelegate {
        var onUnavailable: () -> Void = {}
        var onReady: () -> Void = {}
        private var announcedPlane = false
        private var paused = false
        private var figure: Entity?
        private var lastPoseId: String?

        func install(in view: ARView, pose: Pose) {
            let anchor = AnchorEntity(plane: .horizontal, minimumBounds: [0.2, 0.2])
            let root = makeFigure(from: pose)
            figure = root
            lastPoseId = pose.id
            anchor.addChild(root)
            view.scene.addAnchor(anchor)
        }

        func update(pose: Pose, elapsed: TimeInterval, phase: MotionCoachPhase, reduceMotion: Bool) {
            guard let figure else { return }
            if lastPoseId != pose.id {
                retint(figure, pose: pose)
                lastPoseId = pose.id
            }
            applyKinematics(to: figure, pose: pose, elapsed: elapsed, phase: phase, reduceMotion: reduceMotion)
        }

        func session(_ session: ARSession, didFailWithError error: Error) {
            _ = error
            DispatchQueue.main.async { [onUnavailable] in
                onUnavailable()
            }
        }

        func setPaused(_ value: Bool, in view: ARView) {
            guard value != paused else { return }
            paused = value
            if value { view.session.pause() }
            else if let configuration = view.session.configuration { view.session.run(configuration) }
        }

        func session(_ session: ARSession, didAdd anchors: [ARAnchor]) { acquired(anchors) }
        func session(_ session: ARSession, didUpdate anchors: [ARAnchor]) { acquired(anchors) }

        private func acquired(_ anchors: [ARAnchor]) {
            guard !announcedPlane, anchors.contains(where: {
                guard let plane = $0 as? ARPlaneAnchor else { return false }
                return plane.extent.x >= 0.2 && plane.extent.z >= 0.2
            }) else { return }
            announcedPlane = true
            DispatchQueue.main.async { [onReady] in onReady() }
        }

        func sessionWasInterrupted(_ session: ARSession) {
            DispatchQueue.main.async { [onUnavailable] in onUnavailable() }
        }

        /// Each limb rotates about its proximal joint; its distal joint and children
        /// inherit that transform. Mesh centers are offset from the joint pivot.
        private func makeFigure(from pose: Pose) -> Entity {
            let root = Entity()
            root.name = "pose-figure"
            let tint = categoryTint(pose)
            let mint = UIColor(red: 69 / 255, green: 224 / 255, blue: 168 / 255, alpha: 1)
            let pelvis = Entity()
            pelvis.name = "pelvisJoint"
            pelvis.position = [0, 0.43, 0]
            root.addChild(pelvis)
            pelvis.addChild(box(name: "pelvis", size: [0.18, 0.06, 0.10], color: tint))

            let spine = Entity()
            spine.name = "spineJoint"
            pelvis.addChild(spine)
            let torso = box(name: "torso", size: [0.16, 0.28, 0.09], color: tint)
            torso.position = [0, 0.14, 0]
            spine.addChild(torso)
            let neck = Entity()
            neck.name = "neckJoint"
            neck.position = [0, 0.30, 0]
            spine.addChild(neck)
            let head = box(name: "head", size: [0.10, 0.12, 0.10], color: mint)
            head.position = [0, 0.06, 0]
            neck.addChild(head)

            for (side, sign) in [("left", Float(-1)), ("right", Float(1))] {
                let shoulder = limb(name: side + "Upper", length: 0.18, width: 0.05, color: tint)
                shoulder.position = [sign * 0.12, 0.25, 0]
                spine.addChild(shoulder)
                let elbow = limb(name: side + "Fore", length: 0.16, width: 0.04, color: mint)
                elbow.position = [0, -0.18, 0]
                shoulder.addChild(elbow)
                let hand = box(name: side + "Hand", size: [0.05, 0.05, 0.025], color: mint)
                hand.position = [0, -0.18, 0]
                elbow.addChild(hand)
                let hip = limb(name: side + "Thigh", length: 0.20, width: 0.06, color: tint)
                hip.position = [sign * 0.07, 0, 0]
                pelvis.addChild(hip)
                let knee = limb(name: side + "Shin", length: 0.20, width: 0.05, color: mint)
                knee.position = [0, -0.20, 0]
                hip.addChild(knee)
                let foot = box(name: side + "Foot", size: [0.07, 0.03, 0.12], color: mint)
                foot.position = [0, -0.20, 0.04]
                knee.addChild(foot)
            }
            let seat = box(name: "chairSeat", size: [0.36, 0.03, 0.36], color: .darkGray)
            seat.position = [0, 0.40, 0]
            root.addChild(seat)
            let back = box(name: "chairBack", size: [0.36, 0.32, 0.03], color: .darkGray)
            back.position = [0, 0.56, -0.18]
            root.addChild(back)
            for x in [Float(-0.15), Float(0.15)] {
                for z in [Float(-0.15), Float(0.15)] {
                    let leg = box(name: "chairLeg", size: [0.025, 0.40, 0.025], color: .darkGray)
                    leg.position = [x, 0.20, z]
                    root.addChild(leg)
                }
            }
            applyKinematics(to: root, pose: pose, elapsed: 0, phase: .preview, reduceMotion: false)
            return root
        }

        private func limb(name: String, length: Float, width: Float, color: UIColor) -> Entity {
            let joint = Entity()
            joint.name = name + "Joint"
            let mesh = box(name: name, size: [width, length, width], color: color)
            mesh.position = [0, -length / 2, 0]
            joint.addChild(mesh)
            return joint
        }

        private func box(name: String, size: SIMD3<Float>, color: UIColor) -> ModelEntity {
            var material = SimpleMaterial()
            material.color = .init(tint: color.withAlphaComponent(0.92), texture: nil)
            material.roughness = 0.35
            material.metallic = 0.05
            let mesh = MeshResource.generateBox(size: size, cornerRadius: 0.008)
            let entity = ModelEntity(mesh: mesh, materials: [material])
            entity.name = name
            return entity
        }

        private func categoryTint(_ pose: Pose) -> UIColor {
            UIColor(
                hue: CGFloat(pose.category.accentHue),
                saturation: 0.55,
                brightness: 0.85,
                alpha: 1
            )
        }

        private func retint(_ root: Entity, pose: Pose) {
            let tint = categoryTint(pose)
            for name in ["pelvis", "torso", "leftUpper", "rightUpper", "leftThigh", "rightThigh"] {
                if let model = root.findEntity(named: name) as? ModelEntity {
                    var material = SimpleMaterial()
                    material.color = .init(tint: tint.withAlphaComponent(0.92), texture: nil)
                    material.roughness = 0.35
                    model.model?.materials = [material]
                }
            }
        }

        private func applyKinematics(to root: Entity, pose: Pose, elapsed: TimeInterval,
                                     phase: MotionCoachPhase, reduceMotion: Bool) {
            let k = pose.kinematics
            let state = reduceMotion ? AnimationPhaseState.still : AnimationPhaseState.compute(
                elapsed: elapsed, duration: pose.durationSeconds, phase: phase)
            let blend = Float(state.poseBlend)
            // Session elapsed is frozen while paused. Reduced Motion uses the still
            // target, independent of elapsed time. No idle motion changes the pose.
            func joint(_ name: String, _ rotation: simd_quatf) {
                root.findEntity(named: name + "Joint")?.orientation = rotation
            }
            joint("spine", simd_quatf(angle: Float(k.forwardLean + k.spineArch * 0.25) * blend, axis: [1, 0, 0])
                  * simd_quatf(angle: -Float(k.sideLean) * blend, axis: [0, 0, 1]))
            joint("neck", simd_quatf(angle: Float(k.headTilt) * blend, axis: [0, 0, 1]))
            for (side, sign, upper, fore, cross, thigh, spread, shin) in [
                ("left", Float(-1), k.leftUpperArmAngle, k.leftForearmBend, k.leftArmCross,
                 k.leftThighOffset, k.leftKneeSpread, k.leftShinOffset),
                ("right", Float(1), k.rightUpperArmAngle, k.rightForearmBend, k.rightArmCross,
                 k.rightThighOffset, k.rightKneeSpread, k.rightShinOffset)
            ] {
                let upperAngle = Float(PoseKinematics.neutral.leftUpperArmAngle) + Float(upper - PoseKinematics.neutral.leftUpperArmAngle) * blend
                joint(side + "Upper", simd_quatf(angle: sign * (.pi / 2 - upperAngle), axis: [0, 0, 1])
                      * simd_quatf(angle: -Float(cross) * blend, axis: [1, 0, 0]))
                let elbowAngle = Float(PoseKinematics.neutral.leftForearmBend) + Float(fore - PoseKinematics.neutral.leftForearmBend) * blend
                joint(side + "Fore", simd_quatf(angle: -.pi + elbowAngle, axis: [1, 0, 0]))
                joint(side + "Thigh", simd_quatf(angle: -.pi / 2 + Float(thigh) * blend, axis: [1, 0, 0])
                      * simd_quatf(angle: sign * Float(spread) * blend, axis: [0, 0, 1]))
                joint(side + "Shin", simd_quatf(angle: .pi / 2 + Float(shin) * blend, axis: [1, 0, 0]))
            }
        }
    }
}
