import SwiftUI

@main
struct MDeckApp: App {
    @StateObject private var engine = AudioEngine()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(engine)
                .frame(minWidth: 880, minHeight: 560)
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
    static let openFiles = Notification.Name("MDeck.openFiles")
}
