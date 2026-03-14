#if canImport(UIKit)
import UIKit
import AVRouting
import SwiftUI

/// Manages AirPlay route detection and provides UI state for showing/hiding
/// the AirPlay picker button in the workout flow.
@MainActor
final class AirPlaySecondScreenManager: ObservableObject {
    @Published var routesAvailable = false

    private let routeDetector = AVRouteDetector()
    private var observation: NSObjectProtocol?

    func startDetecting() {
        routeDetector.isRouteDetectionEnabled = true
        routesAvailable = routeDetector.multipleRoutesDetected

        observation = NotificationCenter.default.addObserver(
            forName: AVRouteDetector.multipleRoutesDetectedDidChangeNotification,
            object: routeDetector,
            queue: .main
        ) { [weak self] _ in
            self?.routesAvailable = self?.routeDetector.multipleRoutesDetected ?? false
        }
    }

    func stopDetecting() {
        routeDetector.isRouteDetectionEnabled = false
        if let observation {
            NotificationCenter.default.removeObserver(observation)
        }
        observation = nil
    }
}

/// SwiftUI view that conditionally shows the AirPlay picker when routes are available.
struct AirPlayButtonView: View {
    @StateObject private var manager = AirPlaySecondScreenManager()

    var body: some View {
        Group {
            if manager.routesAvailable {
                AirPlayRoutePickerView()
                    .frame(width: 44, height: 44)
            }
        }
        .onAppear { manager.startDetecting() }
        .onDisappear { manager.stopDetecting() }
    }
}
#endif
