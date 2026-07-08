import SwiftUI

@main
struct MDECKApp: App {
    @StateObject private var engine = AudioEngine()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(engine)
                .background(Theme.bg)
                .preferredColorScheme(.dark)
        }
        .windowStyle(.hiddenTitleBar)
        .windowResizability(.contentSize)
        .commands {
            CommandGroup(replacing: .newItem) {
                Button("Open Files…") { NotificationCenter.default.post(name: .openFiles, object: nil) }
                    .keyboardShortcut("o", modifiers: .command)
            }
            CommandMenu("Controls") {
                Button("Toggle Play/Pause") { engine.togglePlay() }
                    .keyboardShortcut(.space, modifiers: [])
            }
        }
    }
}

extension Notification.Name {
    static let openFiles = Notification.Name("MDECK.openFiles")
}
