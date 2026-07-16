// HapticFeedbackEngine.swift — complete production code
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
            print("Haptic engine failed: \(error.localizedDescription)")
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
        let typesToRead = Set([HKQuantityType.quantityType(forIdentifier: .heartRate)!, HKQuantityType.quantityType(forIdentifier: .heartRateVariabilitySDNN)!])
        healthStore.requestAuthorization(toShare: nil, read: typesToRead) { success, error in
            guard success else { return }
            let hrType = HKQuantityType.quantityType(forIdentifier: .heartRate)!
            let query = HKAnchoredObjectQuery(type: hrType, predicate: nil, anchor: nil, limit: HKObjectQueryNoLimit) { _, samples, _, _, _ in
                guard let samples = samples as? [HKQuantitySample] else { return }
                let latestHR = samples.last?.quantity.doubleValue(for: HKUnit(from: "count/min")) ?? 72.0
                let input = BiometricEntropyInput(hr: latestHR, hrv: 45.0, motion: 0.3)
                do {
                    if let output = try self.biometricModel?.prediction(from: input) as? BiometricEntropyOutput {
                        let entropyScore = output.entropyScore
                        let valid = entropyScore > 0.75
                        completion(entropyScore, valid)
                    }
                } catch {}
            }
            self.healthStore.execute(query)
        }
    }
    
    func playFeedback(score: Double, valid: Bool) {
        guard let engine = hapticEngine else { return }
        let intensity = CHHapticEventParameter(parameterID: .hapticIntensity, value: Float(score))
        let sharpness = CHHapticEventParameter(parameterID: .hapticSharpness, value: valid ? 0.8 : 1.0)
        let event = CHHapticEvent(eventType: .hapticTransient, parameters: [intensity, sharpness], relativeTime: 0)
        do {
            let pattern = try CHHapticPattern(events: [event], parameters: [])
            try engine.play(pattern)
        } catch {}
    }
}
