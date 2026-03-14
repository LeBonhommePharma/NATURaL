import SwiftUI
import Observation

@Observable
final class AppState {
    var isWorkoutActive = false
    var isPremium = true
    var healthKitAuthorized = false

    let healthKitManager = HealthKitManager()
    let subscriptionManager = SubscriptionManager()
    let tvDisplayCoordinator = TVDisplayCoordinator()
}
