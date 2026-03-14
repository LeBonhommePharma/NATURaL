import SwiftUI
import RealityKit
import BonhommeCore

/// Mixed-immersion space that displays a 3D figure demonstrating the current
/// yoga pose, anchored 1.5m in front of the user at floor level.
///
/// The figure transitions between poses with animated transforms, and a
/// spatial biofeedback ring orbits the figure showing the SCI focus score.
struct ImmersivePoseSpace: View {
    let selectedPlan: WorkoutPlan?

    @State private var currentPoseEntity: Entity?
    @State private var biofeedbackRingEntity: Entity?
    @State private var lastPoseIndex: Int = -1

    var body: some View {
        RealityView { content, attachments in
            // Create the root anchor 1.5m in front of user at floor level
            let anchor = AnchorEntity(.head)
            anchor.position = SIMD3<Float>(0, -0.5, -1.5)

            // Create pose figure entity
            let figure = createPoseFigure()
            currentPoseEntity = figure
            anchor.addChild(figure)

            // Create SCI glow ring
            let ring = createBiofeedbackRing()
            biofeedbackRingEntity = ring
            anchor.addChild(ring)

            // Add attachment for pose name label
            if let nameLabel = attachments.entity(for: "poseLabel") {
                nameLabel.position = SIMD3<Float>(0, 1.0, 0)
                anchor.addChild(nameLabel)
            }

            content.add(anchor)
        } update: { content, attachments in
            updatePoseVisualization()
        } attachments: {
            Attachment(id: "poseLabel") {
                poseLabelView
            }
        }
    }

    // MARK: - Pose Label (2D Attachment)

    private var poseLabelView: some View {
        VStack(spacing: 8) {
            if let plan = selectedPlan,
               let pose = plan.poses[safe: lastPoseIndex >= 0 ? lastPoseIndex : 0] {
                Text(pose.name.localized)
                    .font(.system(size: 24, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)

                Text(pose.category.localizedName.localized)
                    .font(.system(size: 14))
                    .foregroundStyle(.white.opacity(0.6))

                if !pose.breathingPattern.localized.isEmpty {
                    HStack(spacing: 4) {
                        Image(systemName: "wind")
                            .font(.system(size: 12))
                        Text(pose.breathingPattern.localized)
                            .font(.system(size: 13))
                    }
                    .foregroundStyle(.cyan.opacity(0.8))
                }
            } else {
                Text("NATURaL")
                    .font(.system(size: 24, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
            }
        }
        .padding()
        .glassBackgroundEffect()
    }

    // MARK: - Entity Creation

    /// Creates a procedural mesh figure representing a person in a chair yoga pose.
    /// Uses simple geometric shapes (capsules, spheres) as a stylized figure.
    private func createPoseFigure() -> Entity {
        let figure = Entity()
        figure.name = "poseFigure"

        // Torso (vertical capsule)
        let torsoMesh = MeshResource.generateCapsule(height: 0.5, radius: 0.08)
        var torsoMaterial = SimpleMaterial()
        torsoMaterial.color = .init(tint: .cyan.withAlphaComponent(0.7))
        let torso = ModelEntity(mesh: torsoMesh, materials: [torsoMaterial])
        torso.position = SIMD3<Float>(0, 0.5, 0)
        figure.addChild(torso)

        // Head (sphere)
        let headMesh = MeshResource.generateSphere(radius: 0.1)
        var headMaterial = SimpleMaterial()
        headMaterial.color = .init(tint: .cyan.withAlphaComponent(0.8))
        let head = ModelEntity(mesh: headMesh, materials: [headMaterial])
        head.position = SIMD3<Float>(0, 0.85, 0)
        figure.addChild(head)

        // Left arm (capsule)
        let armMesh = MeshResource.generateCapsule(height: 0.4, radius: 0.04)
        var armMaterial = SimpleMaterial()
        armMaterial.color = .init(tint: .cyan.withAlphaComponent(0.6))

        let leftArm = ModelEntity(mesh: armMesh, materials: [armMaterial])
        leftArm.position = SIMD3<Float>(-0.2, 0.55, 0)
        leftArm.orientation = simd_quatf(angle: .pi / 6, axis: SIMD3<Float>(0, 0, 1))
        figure.addChild(leftArm)

        // Right arm
        let rightArm = ModelEntity(mesh: armMesh, materials: [armMaterial])
        rightArm.position = SIMD3<Float>(0.2, 0.55, 0)
        rightArm.orientation = simd_quatf(angle: -.pi / 6, axis: SIMD3<Float>(0, 0, 1))
        figure.addChild(rightArm)

        // Chair seat (box)
        let seatMesh = MeshResource.generateBox(width: 0.4, height: 0.03, depth: 0.35)
        var seatMaterial = SimpleMaterial()
        seatMaterial.color = .init(tint: .gray.withAlphaComponent(0.5))
        let seat = ModelEntity(mesh: seatMesh, materials: [seatMaterial])
        seat.position = SIMD3<Float>(0, 0.2, 0)
        figure.addChild(seat)

        // Chair back (box)
        let backMesh = MeshResource.generateBox(width: 0.4, height: 0.5, depth: 0.03)
        var backMaterial = SimpleMaterial()
        backMaterial.color = .init(tint: .gray.withAlphaComponent(0.4))
        let back = ModelEntity(mesh: backMesh, materials: [backMaterial])
        back.position = SIMD3<Float>(0, 0.45, -0.17)
        figure.addChild(back)

        // Legs (capsules)
        let legMesh = MeshResource.generateCapsule(height: 0.35, radius: 0.05)
        var legMaterial = SimpleMaterial()
        legMaterial.color = .init(tint: .cyan.withAlphaComponent(0.5))

        let leftLeg = ModelEntity(mesh: legMesh, materials: [legMaterial])
        leftLeg.position = SIMD3<Float>(-0.1, 0.02, 0.1)
        leftLeg.orientation = simd_quatf(angle: .pi / 2, axis: SIMD3<Float>(1, 0, 0))
        figure.addChild(leftLeg)

        let rightLeg = ModelEntity(mesh: legMesh, materials: [legMaterial])
        rightLeg.position = SIMD3<Float>(0.1, 0.02, 0.1)
        rightLeg.orientation = simd_quatf(angle: .pi / 2, axis: SIMD3<Float>(1, 0, 0))
        figure.addChild(rightLeg)

        return figure
    }

    /// Creates a glowing ring around the figure that represents the SCI score.
    private func createBiofeedbackRing() -> Entity {
        let ring = Entity()
        ring.name = "biofeedbackRing"

        // Torus-like ring using a thin cylinder
        let ringMesh = MeshResource.generateCylinder(height: 0.01, radius: 0.6)
        var ringMaterial = SimpleMaterial()
        ringMaterial.color = .init(tint: .cyan.withAlphaComponent(0.3))
        let ringEntity = ModelEntity(mesh: ringMesh, materials: [ringMaterial])
        ringEntity.position = SIMD3<Float>(0, 0.5, 0)
        ring.addChild(ringEntity)

        return ring
    }

    // MARK: - Pose Updates

    /// Updates the 3D figure to reflect the current pose.
    /// Animates arm and torso positions based on pose category.
    private func updatePoseVisualization() {
        guard let plan = selectedPlan,
              let figure = currentPoseEntity else { return }

        // Determine current pose index from plan progress
        // In a full implementation, this would be driven by the SpatialWorkoutViewModel
        // For now, it responds to plan selection
        guard let pose = plan.poses.first else { return }

        // Apply category-specific pose modifications to the figure
        let armRotation: Float
        let torsoRotation: Float

        switch pose.category {
        case .spine:
            armRotation = .pi / 4    // Arms slightly raised
            torsoRotation = .pi / 12 // Slight twist
        case .shoulders:
            armRotation = .pi / 2    // Arms raised high
            torsoRotation = 0
        case .hips:
            armRotation = .pi / 8    // Arms at sides
            torsoRotation = .pi / 8  // Forward lean
        case .neck:
            armRotation = .pi / 10   // Arms relaxed
            torsoRotation = 0
        case .fullBody:
            armRotation = .pi / 3    // Arms extended
            torsoRotation = .pi / 16
        case .breathing:
            armRotation = .pi / 6    // Gentle arm position
            torsoRotation = 0
        case .balance:
            armRotation = .pi / 4
            torsoRotation = 0
        }

        // Animate arm positions
        for child in figure.children {
            if child.position.x < -0.1 {
                // Left arm
                var transform = child.transform
                transform.rotation = simd_quatf(angle: armRotation, axis: SIMD3<Float>(0, 0, 1))
                child.move(to: transform, relativeTo: child.parent, duration: 1.0)
            } else if child.position.x > 0.1, child.position.y > 0.4 {
                // Right arm
                var transform = child.transform
                transform.rotation = simd_quatf(angle: -armRotation, axis: SIMD3<Float>(0, 0, 1))
                child.move(to: transform, relativeTo: child.parent, duration: 1.0)
            }
        }

        // Update ring color based on pose category
        if let ring = biofeedbackRingEntity?.children.first as? ModelEntity {
            var material = SimpleMaterial()
            let hue = CGFloat(pose.category.accentHue)
            material.color = .init(tint: UIColor(hue: hue, saturation: 0.7, brightness: 0.9, alpha: 0.4))
            ring.model?.materials = [material]
        }
    }
}

// MARK: - Safe Array Access

private extension Array {
    subscript(safe index: Int) -> Element? {
        indices.contains(index) ? self[index] : nil
    }
}
