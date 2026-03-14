#if canImport(UIKit)
import UIKit
import SwiftUI
import BonhommeCore

/// UIWindowSceneDelegate for the AirPlay 2 second-screen experience.
/// Creates a UIWindow on the external display showing the shared TVDisplayView.
///
/// Requires Info.plist configuration:
///   UIApplicationSceneManifest > UISceneConfigurations >
///     UIWindowSceneSessionRoleExternalDisplayNonInteractive:
///       - UISceneConfigurationName: "External Display"
///         UISceneDelegateClassName: "$(PRODUCT_MODULE_NAME).ExternalDisplaySceneDelegate"
final class ExternalDisplaySceneDelegate: UIResponder, UIWindowSceneDelegate {
    var window: UIWindow?

    func scene(
        _ scene: UIScene,
        willConnectTo session: UISceneSession,
        options connectionOptions: UIScene.ConnectionOptions
    ) {
        guard session.role == .windowExternalDisplayNonInteractive,
              let windowScene = scene as? UIWindowScene else { return }

        let coordinator = TVDisplayCoordinator.shared
        let rootView = AirPlayTVDisplayRoot(coordinator: coordinator)

        let window = UIWindow(windowScene: windowScene)
        window.rootViewController = UIHostingController(rootView: rootView)
        window.makeKeyAndVisible()
        self.window = window

        coordinator.externalDisplayConnected = true
    }

    func sceneDidDisconnect(_ scene: UIScene) {
        TVDisplayCoordinator.shared.externalDisplayConnected = false
        window = nil
    }
}

/// SwiftUI view hosted on the AirPlay external display.
/// Observes the coordinator's currentPayload and renders the shared TVDisplayView.
struct AirPlayTVDisplayRoot: View {
    @ObservedObject var coordinator: TVDisplayCoordinator

    var body: some View {
        if let payload = coordinator.currentPayload {
            TVDisplayView(payload: payload)
        } else {
            TVIdleView()
        }
    }
}

// MARK: - Singleton for UIScene access

extension TVDisplayCoordinator {
    @MainActor static let shared = TVDisplayCoordinator()
}
#endif
