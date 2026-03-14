import SwiftUI
import StoreKit

/// Paywall screen using the native SubscriptionStoreView for a
/// fully Apple-designed subscription purchase flow.
struct PaywallView: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        SubscriptionStoreView(groupID: SubscriptionManager.subscriptionGroupId) {
            VStack(spacing: 16) {
                Image(systemName: "figure.yoga")
                    .font(.system(size: 64))
                    .foregroundStyle(.cyan)

                Text("Unlock Full Chair Yoga")
                    .font(.system(size: 28, weight: .bold, design: .rounded))

                Text("Access all poses, Apple Music integration, SharePlay group sessions, and advanced biofeedback metrics.")
                    .font(.system(size: 16))
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)

                featureList
            }
            .padding(.top, 32)
        }
        .subscriptionStoreControlStyle(.prominentPicker)
        .storeButton(.visible, for: .restorePurchases)
        .subscriptionStoreButtonLabel(.multiline)
    }

    private var featureList: some View {
        VStack(alignment: .leading, spacing: 12) {
            featureRow(icon: "figure.yoga", text: "Full pose library (10+ poses)")
            featureRow(icon: "music.note", text: "Apple Music workout playlists")
            featureRow(icon: "person.2.fill", text: "SharePlay group sessions")
            featureRow(icon: "heart.text.square.fill", text: "Advanced biofeedback & SCI")
            featureRow(icon: "tv", text: "TV display with AirPlay")
        }
        .padding(.horizontal, 32)
        .padding(.top, 8)
    }

    private func featureRow(icon: String, text: String) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 18))
                .foregroundStyle(.cyan)
                .frame(width: 28)

            Text(text)
                .font(.system(size: 15))
        }
    }
}
