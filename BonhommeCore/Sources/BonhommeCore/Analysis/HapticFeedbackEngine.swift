import CoreHaptics
import HealthKit
import CoreML

final class HapticFeedbackEngine {
    private var hapticEngine: CHHapticEngine?
    private let healthStore = HKHealthStore()
    private var biometricModel: MLModel?
    
    init() {
        do {
            hapticEngine = try CHHapticEngine()
            try hapticEngine?.start()
        } catch {
            print("Haptic engine failed to start: \(error.localizedDescription)")
        }
        
        if let modelURL = Bundle.main.url(forResource: "BiometricEntropy", withExtension: "mlmodelc") {
            do {
                biometricModel = try MLModel(contentsOf: modelURL)
            } catch {
                print("CoreML model load failed: \(error.localizedDescription)")
            }
        }
    }
    
    func startBiometricMonitoring(completion: @escaping (Double, Bool) -> Void) {
        guard HKHealthStore.isHealthDataAvailable() else { return }
        let typesToRead = Set([HKQuantityType.quantityType(forIdentifier: .heartRate)!])
        healthStore.requestAuthorization(toShare: nil, read: typesToRead) { success, error in
            guard success else { return }
            let hrType = HKQuantityType.quantityType(forIdentifier: .heartRate)!
            let query = HKAnchoredObjectQuery(type: hrType, predicate: nil, anchor: nil, limit: HKObjectQueryNoLimit) { _, samples, _, _, _ in
                guard let samples = samples as? [HKQuantitySample], let latest = samples.last else { return }
                let hr = latest.quantity.doubleValue(for: HKUnit(from: "count/min"))
                // CoreML prediction stubbed for now but real structure
                let entropyScore = min(1.0, hr / 180.0) // real model would be used
                completion(entropyScore, entropyScore > 0.75)
            }
            healthStore.execute(query)
        }
    }
    
    func playFeedback(score: Double, valid: Bool) {
        guard let engine = hapticEngine else { return }
        let event = CHHapticEvent(eventType: .hapticTransient, parameters: [
            CHHapticEventParameter(parameterID: .hapticIntensity, value: Float(score)),
            CHHapticEventParameter(parameterID: .hapticSharpness, value: valid ? 0.8 : 1.0)
        ], relativeTime: 0)
        do {
            let pattern = try CHHapticPattern(events: [event], parameters: [])
            try engine.play(pattern)
        } catch {}
    }
}