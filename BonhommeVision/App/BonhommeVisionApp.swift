import SwiftUI
import BonhommeCore

/// visionOS spatial app entry point for NATURaL Chair Yoga.
/// Provides a 2D window for workout flow control and an immersive space
/// with 3D pose visualization using RealityKit.
@main
struct BonhommeVisionApp: App {
    @State private var selectedPlan: WorkoutPlan?
    @State private var isImmersiveSpaceOpen = false

    var body: some Scene {
        WindowGroup {
            SpatialPoseView(
                selectedPlan: $selectedPlan,
                isImmersiveSpaceOpen: $isImmersiveSpaceOpen
            )
        }
        .windowStyle(.automatic)

        ImmersiveSpace(id: "poseSpace") {
            ImmersivePoseSpace(selectedPlan: selectedPlan)
        }
        .immersionStyle(selection: .constant(.mixed), in: .mixed)
    }
}
