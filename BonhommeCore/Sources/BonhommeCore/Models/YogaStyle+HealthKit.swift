#if canImport(HealthKit)
import HealthKit

extension YogaStyle {
    /// Maps workout kind to the most appropriate HealthKit activity type.
    public var healthKitActivityType: HKWorkoutActivityType {
        switch self {
        case .pranayama, .meditation:
            return .mindAndBody
        case .strength:
            return .traditionalStrengthTraining
        case .cardio:
            return .mixedCardio
        case .mobility:
            return .flexibility
        case .general:
            return .other
        case .chairYoga, .matYoga, .vinyasa, .hatha, .yin, .restorative,
             .power, .standingBalance, .prenatal:
            return .yoga
        }
    }
}
#endif
