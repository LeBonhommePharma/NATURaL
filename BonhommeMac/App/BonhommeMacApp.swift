import SwiftUI
import BonhommeCore

@main
struct BonhommeMacApp: App {
    var body: some Scene {
        WindowGroup {
            MacRootView()
        }
        .windowStyle(.automatic)
        .defaultSize(width: 780, height: 560)
        .commands {
            CommandGroup(replacing: .newItem) { }
        }
    }
}
