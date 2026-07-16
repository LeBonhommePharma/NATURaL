// Production Haptic Feedback Engine for NATURaL

import CoreHaptics

class HapticFeedbackEngine {
    private var engine: CHHapticEngine?
    
    init() {
        do {
            engine = try CHHapticEngine()
            try engine?.start()
        } catch {
            print("Haptic engine failed to start")
        }
    }
    
    func playValidationHaptic(valid: Bool, intensity: Float = 1.0) {
        let sharpness = valid ? 0.8 : 0.3
        let events = [
            CHHapticEvent(eventType: .hapticTransient, parameters: [
                CHHapticEventParameter(parameterID: .hapticIntensity, value: intensity),
                CHHapticEventParameter(parameterID: .hapticSharpness, value: sharpness)
            ], relativeTime: 0)
        ]
        do {
            let pattern = try CHHapticPattern(events: events, parameters: [])
            try engine?.play(pattern)
        } catch {}
    }
    
    // Modulated by biometrics
    func playBiometricModulatedHaptic(hr: Double, score: Double) {
        // Implementation based on HR and Shannon score
        let intensity = Float(min(1.0, hr / 180.0))
        playValidationHaptic(valid: score > 0.75, intensity: intensity)
    }
}
