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
    var onUnavailable: () -> Void = {}

    var body: some View {
        ARPoseCoachRepresentable(
            pose: pose,
            phase: phase,
            poseElapsed: poseElapsed,
            onUnavailable: onUnavailable
        )
        .clipShape(SessionRadius.cardShape())
        .overlay(
            SessionRadius.cardShape()
                .strokeBorder(BrandColor.hairlineStrong, lineWidth: 1)
        )
        .accessibilityLabel(Text(SessionHUDCopy.arCoach.localized))
        .accessibilityValue(Text(pose.name.localized))
    }
}

private struct ARPoseCoachRepresentable: UIViewRepresentable {
    var pose: Pose
    var phase: MotionCoachPhase
    var poseElapsed: TimeInterval
    var onUnavailable: () -> Void

    func makeUIView(context: Context) -> ARView {
        let view = ARView(frame: .zero)
        view.automaticallyConfigureSession = false
        view.environment.background = .color(.black)
        context.coordinator.onUnavailable = onUnavailable
        view.session.delegate = context.coordinator
        if ARWorldTrackingConfiguration.isSupported {
            let config = ARWorldTrackingConfiguration()
            config.planeDetection = [.horizontal]
            config.worldAlignment = .gravity
            view.session.run(config, options: [.resetTracking, .removeExistingAnchors])
        } else {
            onUnavailable()
        }
        context.coordinator.install(in: view, pose: pose)
        return view
    }

    func updateUIView(_ uiView: ARView, context: Context) {
        context.coordinator.onUnavailable = onUnavailable
        context.coordinator.update(pose: pose, elapsed: poseElapsed, phase: phase)
    }

    static func dismantleUIView(_ uiView: ARView, coordinator: Coordinator) {
        uiView.session.pause()
        uiView.session.delegate = nil
        uiView.scene.anchors.removeAll()
    }

    func makeCoordinator() -> Coordinator { Coordinator() }

    final class Coordinator: NSObject, ARSessionDelegate {
        var onUnavailable: () -> Void = {}
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

        func update(pose: Pose, elapsed: TimeInterval, phase: MotionCoachPhase) {
            guard let figure else { return }
            if lastPoseId != pose.id {
                retint(figure, pose: pose)
                lastPoseId = pose.id
            }
            applyKinematics(to: figure, pose: pose, elapsed: elapsed, phase: phase)
        }

        func session(_ session: ARSession, didFailWithError error: Error) {
            _ = error
            DispatchQueue.main.async { [onUnavailable] in
                onUnavailable()
            }
        }

        private func makeFigure(from pose: Pose) -> Entity {
            let root = Entity()
            root.name = "pose-figure"
            let tint = categoryTint(pose)
            let mint = UIColor(red: 69 / 255, green: 224 / 255, blue: 168 / 255, alpha: 1)

            let pelvis = box(name: "pelvis", size: [0.18, 0.06, 0.10], color: tint)
            let torso = box(name: "torso", size: [0.16, 0.28, 0.09], color: tint)
            torso.position = [0, 0.18, 0]
            let head = box(name: "head", size: [0.10, 0.12, 0.10], color: mint)
            head.position = [0, 0.38, 0]

            let leftUpper = box(name: "leftUpper", size: [0.05, 0.18, 0.05], color: tint)
            leftUpper.position = [-0.14, 0.22, 0]
            let rightUpper = box(name: "rightUpper", size: [0.05, 0.18, 0.05], color: tint)
            rightUpper.position = [0.14, 0.22, 0]
            let leftFore = box(name: "leftFore", size: [0.04, 0.16, 0.04], color: mint)
            leftFore.position = [-0.14, 0.04, 0]
            let rightFore = box(name: "rightFore", size: [0.04, 0.16, 0.04], color: mint)
            rightFore.position = [0.14, 0.04, 0]

            let leftThigh = box(name: "leftThigh", size: [0.06, 0.20, 0.08], color: tint)
            leftThigh.position = [-0.07, -0.12, 0.02]
            let rightThigh = box(name: "rightThigh", size: [0.06, 0.20, 0.08], color: tint)
            rightThigh.position = [0.07, -0.12, 0.02]
            let leftShin = box(name: "leftShin", size: [0.05, 0.18, 0.06], color: mint)
            leftShin.position = [-0.07, -0.30, 0.04]
            let rightShin = box(name: "rightShin", size: [0.05, 0.18, 0.06], color: mint)
            rightShin.position = [0.07, -0.30, 0.04]

            for child in [pelvis, torso, head, leftUpper, rightUpper, leftFore, rightFore, leftThigh, rightThigh, leftShin, rightShin] {
                root.addChild(child)
            }
            root.position = [0, 0.35, -0.6]
            applyKinematics(to: root, pose: pose, elapsed: 0, phase: .preview)
            return root
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

        private func applyKinematics(to root: Entity, pose: Pose, elapsed: TimeInterval, phase: MotionCoachPhase) {
            let k = pose.kinematics
            let hold = Float(k.holdOscillationScale)
            let breath = Float(sin(elapsed * 1.2) * 0.02) * (phase == .preview ? 0.4 : 1)
            let osc = Float(sin(elapsed * 2.1) * 0.03) * hold

            if let torso = root.findEntity(named: "torso") {
                torso.orientation = simd_quatf(angle: Float(k.forwardLean) * 0.4 + osc * 0.2, axis: [1, 0, 0])
                    * simd_quatf(angle: Float(k.sideLean) * 0.4, axis: [0, 0, 1])
                    * simd_quatf(angle: Float(k.spineArch) * 0.25, axis: [1, 0, 0])
                torso.position.y = 0.18 + breath
            }
            if let head = root.findEntity(named: "head") {
                head.orientation = simd_quatf(angle: Float(k.headTilt) * 0.5, axis: [0, 0, 1])
                head.position.y = 0.38 + breath * 0.6
            }
            if let leftUpper = root.findEntity(named: "leftUpper") {
                leftUpper.orientation = simd_quatf(angle: Float(k.leftUpperArmAngle - .pi * 0.55), axis: [1, 0, 0])
                    * simd_quatf(angle: Float(k.leftArmCross) * 0.35, axis: [0, 1, 0])
            }
            if let rightUpper = root.findEntity(named: "rightUpper") {
                rightUpper.orientation = simd_quatf(angle: Float(k.rightUpperArmAngle - .pi * 0.55), axis: [1, 0, 0])
                    * simd_quatf(angle: Float(k.rightArmCross) * 0.35, axis: [0, 1, 0])
            }
            if let leftFore = root.findEntity(named: "leftFore") {
                leftFore.orientation = simd_quatf(angle: Float(k.leftForearmBend - 0.95), axis: [1, 0, 0])
            }
            if let rightFore = root.findEntity(named: "rightFore") {
                rightFore.orientation = simd_quatf(angle: Float(k.rightForearmBend - 0.95), axis: [1, 0, 0])
            }
            if let leftThigh = root.findEntity(named: "leftThigh") {
                leftThigh.orientation = simd_quatf(angle: Float(k.leftThighOffset) * 0.45, axis: [1, 0, 0])
                leftThigh.position.x = -0.07 + Float(k.leftKneeSpread) * 0.08
            }
            if let rightThigh = root.findEntity(named: "rightThigh") {
                rightThigh.orientation = simd_quatf(angle: Float(k.rightThighOffset) * 0.45, axis: [1, 0, 0])
                rightThigh.position.x = 0.07 + Float(k.rightKneeSpread) * 0.08
            }
            if let leftShin = root.findEntity(named: "leftShin") {
                leftShin.orientation = simd_quatf(angle: Float(k.leftShinOffset) * 0.4, axis: [1, 0, 0])
            }
            if let rightShin = root.findEntity(named: "rightShin") {
                rightShin.orientation = simd_quatf(angle: Float(k.rightShinOffset) * 0.4, axis: [1, 0, 0])
            }
        }
    }
}
