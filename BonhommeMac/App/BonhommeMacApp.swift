import SwiftUI
import BonhommeCore

@main
struct BonhommeMacApp: App {
    var body: some Scene {
        WindowGroup {
            MacRootView()
        }
        .windowStyle(.automatic)
        .windowResizability(.contentMinSize)
        .defaultSize(width: 780, height: 560)
        .commands {
            CommandGroup(replacing: .newItem) { }
        }
    }
}
