#if canImport(UIKit)
import SwiftUI
import AVKit

/// UIViewRepresentable wrapper for AVRoutePickerView since no native
/// SwiftUI AirPlay picker exists as of iOS 18.
///
/// Shows the AirPlay icon. Tapping presents the system route picker
/// for selecting AirPlay destinations (Apple TV, smart TVs, etc.).
struct AirPlayRoutePickerView: UIViewRepresentable {
    var tintColor: UIColor = .white
    var activeTintColor: UIColor = .systemGreen

    func makeUIView(context: Context) -> AVRoutePickerView {
        let picker = AVRoutePickerView()
        picker.tintColor = tintColor
        picker.activeTintColor = activeTintColor
        picker.prioritizesVideoDevices = true
        return picker
    }

    func updateUIView(_ uiView: AVRoutePickerView, context: Context) {
        uiView.tintColor = tintColor
        uiView.activeTintColor = activeTintColor
    }
}
#endif
