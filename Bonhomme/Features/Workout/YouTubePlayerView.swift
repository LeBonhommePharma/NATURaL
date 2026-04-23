// Bonhomme/Features/Workout/YouTubePlayerView.swift
#if canImport(UIKit)
import SwiftUI
import WebKit

// MARK: - Player State

enum YouTubePlayerState: Equatable {
    case idle, loading, ready, playing, paused, ended, error
}

// MARK: - YouTubePlayerView

/// WKWebView-backed YouTube iframe player wrapped for SwiftUI.
struct YouTubePlayerView: UIViewRepresentable {

    let videoID: String
    var autoplay: Bool = false
    var onStateChange: ((YouTubePlayerState) -> Void)?
    var onTimeUpdate: ((TimeInterval) -> Void)?

    func makeCoordinator() -> Coordinator {
        Coordinator(onStateChange: onStateChange, onTimeUpdate: onTimeUpdate)
    }

    func makeUIView(context: Context) -> WKWebView {
        let config = WKWebViewConfiguration()
        config.allowsInlineMediaPlayback = true
        config.mediaTypesRequiringUserActionForPlayback = autoplay ? [] : [.all]
        let prefs = WKWebpagePreferences()
        prefs.allowsContentJavaScript = true
        config.defaultWebpagePreferences = prefs
        config.userContentController.add(context.coordinator, name: "playerBridge")
        let webView = WKWebView(frame: .zero, configuration: config)
        webView.scrollView.isScrollEnabled = false
        webView.backgroundColor = .black
        webView.isOpaque = true
        webView.navigationDelegate = context.coordinator
        context.coordinator.webView = webView
        return webView
    }

    func updateUIView(_ uiView: WKWebView, context: Context) {
        context.coordinator.load(videoID: videoID, autoplay: autoplay, into: uiView)
    }

    // MARK: - Coordinator

    final class Coordinator: NSObject, WKNavigationDelegate, WKScriptMessageHandler {

        var onStateChange: ((YouTubePlayerState) -> Void)?
        var onTimeUpdate: ((TimeInterval) -> Void)?
        weak var webView: WKWebView?
        private var loadedVideoID: String?

        init(onStateChange: ((YouTubePlayerState) -> Void)?, onTimeUpdate: ((TimeInterval) -> Void)?) {
            self.onStateChange = onStateChange
            self.onTimeUpdate = onTimeUpdate
        }

        func load(videoID: String, autoplay: Bool, into webView: WKWebView) {
            guard videoID != loadedVideoID else { return }
            loadedVideoID = videoID
            let autoplayParam = autoplay ? 1 : 0
            let html = """
            <!DOCTYPE html>
            <html>
            <head>
              <meta name="viewport" content="width=device-width, initial-scale=1">
              <style>
                * { margin:0; padding:0; box-sizing:border-box; background:#000; }
                body { width:100vw; height:100vh; overflow:hidden; }
                iframe { width:100%; height:100%; border:none; }
              </style>
            </head>
            <body>
              <div id="player"></div>
              <script>
                var tag = document.createElement('script');
                tag.src = "https://www.youtube.com/iframe_api";
                document.head.appendChild(tag);
                var player;
                function onYouTubeIframeAPIReady() {
                  player = new YT.Player('player', {
                    videoId: '\(videoID)',
                    playerVars: { 'playsinline': 1, 'autoplay': \(autoplayParam), 'controls': 1, 'rel': 0, 'modestbranding': 1 },
                    events: { 'onReady': onPlayerReady, 'onStateChange': onPlayerStateChange, 'onError': onPlayerError }
                  });
                }
                function onPlayerReady(event) {
                  window.webkit.messageHandlers.playerBridge.postMessage({type:'state', value:'ready'});
                  setInterval(function() {
                    if (player && player.getCurrentTime) {
                      window.webkit.messageHandlers.playerBridge.postMessage({type:'time', value:player.getCurrentTime()});
                    }
                  }, 500);
                }
                function onPlayerStateChange(event) {
                  var states = {'-1':'idle','0':'ended','1':'playing','2':'paused','3':'loading','5':'ready'};
                  window.webkit.messageHandlers.playerBridge.postMessage({type:'state', value:states[String(event.data)]||'idle'});
                }
                function onPlayerError(event) {
                  window.webkit.messageHandlers.playerBridge.postMessage({type:'state', value:'error'});
                }
              </script>
            </body>
            </html>
            """
            webView.loadHTMLString(html, baseURL: URL(string: "https://www.youtube.com"))
        }

        func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
            guard let body = message.body as? [String: Any], let type = body["type"] as? String else { return }
            DispatchQueue.main.async { [weak self] in
                switch type {
                case "state":
                    let raw = body["value"] as? String ?? ""
                    self?.onStateChange?(YouTubePlayerState(rawValue: raw))
                case "time":
                    let t = body["value"] as? Double ?? 0
                    self?.onTimeUpdate?(t)
                default: break
                }
            }
        }
    }
}

private extension YouTubePlayerState {
    init(rawValue: String) {
        switch rawValue {
        case "ready":   self = .ready
        case "playing": self = .playing
        case "paused":  self = .paused
        case "ended":   self = .ended
        case "loading": self = .loading
        case "error":   self = .error
        default:        self = .idle
        }
    }
}
#endif
