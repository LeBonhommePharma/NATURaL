import StoreKit
import Observation

/// Manages StoreKit 2 subscriptions and entitlement checking.
/// Uses Transaction.currentEntitlements for launch checks and
/// Transaction.updates for real-time renewal/cancellation monitoring.
@Observable
@MainActor
final class SubscriptionManager {
    private(set) var entitlement: Entitlement = .free
    private(set) var isLoading = true

    private var updateListenerTask: Task<Void, Never>?

    /// Product identifiers configured in App Store Connect.
    static let monthlyProductId = "com.bonhomme.natural.monthly"
    static let yearlyProductId = "com.bonhomme.natural.yearly"
    static let subscriptionGroupId = "natural_premium"

    func start() {
        Task { await checkEntitlement() }
        listenForUpdates()
    }

    /// Checks current entitlement status by iterating verified transactions.
    func checkEntitlement() async {
        isLoading = true
        defer { isLoading = false }

        for await result in Transaction.currentEntitlements {
            if case .verified(let transaction) = result {
                if transaction.productID == Self.monthlyProductId ||
                   transaction.productID == Self.yearlyProductId {
                    entitlement = .premium
                    return
                }
            }
        }
        entitlement = .free
    }

    /// Listens for transaction updates (renewals, cancellations, refunds).
    private func listenForUpdates() {
        updateListenerTask?.cancel()
        updateListenerTask = Task(priority: .background) { [weak self] in
            for await result in Transaction.updates {
                if case .verified(let transaction) = result {
                    await transaction.finish()
                    guard let self else { return }
                    await self.checkEntitlement()
                }
            }
        }
    }

    /// Restores purchases explicitly (rarely needed with StoreKit 2).
    func restore() async {
        try? await AppStore.sync()
        await checkEntitlement()
    }

}
