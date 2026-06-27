import SwiftUI

@main
struct SuperRightApp: App {
    var body: some Scene {
        Window("superRight", id: "main") {
            SettingsView()
        }
        .windowResizability(.contentSize)
    }
}
