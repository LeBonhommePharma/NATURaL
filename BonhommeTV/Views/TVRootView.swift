import SwiftUI
import BonhommeCore

/// Root view for the tvOS companion app. Shows the shared TVDisplayView
/// when connected to the iOS app, or an idle waiting screen otherwise.
struct TVRootView: View {
    @StateObject private var listener = CompanionListener()
    @FocusState private var idleFocused: Bool

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
                    .focusable()
                    .focused($idleFocused)
                    .onAppear { idleFocused = true }
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
        HStack(spacing: SessionSpacing.xs) {
            Circle()
                .fill(listener.isAdvertising ? Color.green : Color.gray)
                .frame(width: 12, height: 12)
                .accessibilityHidden(true)

            Text(listener.isAdvertising
                 ? LocalizedString(
                    en: "Discoverable on this network",
                    fr: "Visible sur ce réseau",
                    es: "Visible en esta red",
                    ja: "このネットワークで検出可能",
                    zh: "可在此网络上被发现",
                    ko: "이 네트워크에서 검색 가능",
                    ru: "Виден в этой сети",
                    de: "Im Netzwerk sichtbar",
                    ar: "قابل للاكتشاف على هذه الشبكة"
                 ).localized
                 : LocalizedString(
                    en: "Not advertising",
                    fr: "Non publié",
                    es: "No visible",
                    ja: "未公開",
                    zh: "未广播",
                    ko: "광고 안 함",
                    ru: "Не объявляется",
                    de: "Nicht sichtbar",
                    ar: "غير معلن"
                 ).localized)
                .font(.title3)
                .foregroundStyle(.white.opacity(0.55))
        }
        .padding(.horizontal, SessionSpacing.lg)
        .padding(.vertical, SessionSpacing.sm)
        .background(.ultraThinMaterial, in: Capsule(style: .continuous))
        .accessibilityElement(children: .combine)
    }
}
