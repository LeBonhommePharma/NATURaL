import HealthKit
import BonhommeCore

extension YogaStyle {
    /// Maps yoga style to the most appropriate HKWorkoutActivityType.
    /// All yoga styles map to `.yoga` except pranayama which maps to `.mindAndBody`,
    /// mirroring Apple Fitness+ categorization.
    var healthKitActivityType: HKWorkoutActivityType {
        switch self {
        case .pranayama:
            return .mindAndBody
        case .chairYoga, .vinyasa, .hatha, .yin, .restorative,
             .power, .standingBalance, .prenatal:
            return .yoga
        }
    }
}
