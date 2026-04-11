import HealthKit
import BonhommeCore

extension YogaStyle {
    /// Maps yoga style to the most appropriate HealthKit workout activity type.
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
