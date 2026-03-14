import SwiftUI
import BonhommeCore

/// Root view for the tvOS companion app. Shows the shared TVDisplayView
/// when connected to the iOS app, or an idle waiting screen otherwise.
struct TVRootView: View {
    @StateObject private var listener = CompanionListener()

    var body: some View {
        Group {
            if let payload = listener.latestPayload {
                TVDisplayView(payload: payload)
            } else {
                TVIdleView()
                    .overlay(alignment: .bottom) {
                        connectionStatus
                            .padding(.bottom, 48)
                    }
            }
        }
        .onAppear {
            listener.startAdvertising()
        }
        .onDisappear {
            listener.stopAdvertising()
        }
    }

    private var connectionStatus: some View {
        HStack(spacing: 8) {
            Circle()
                .fill(listener.isAdvertising ? .green : .gray)
                .frame(width: 8, height: 8)

            Text(listener.isAdvertising ? "Discoverable on network" : "Not advertising")
                .font(.system(size: 16))
                .foregroundStyle(.white.opacity(0.5))
        }
    }
}
