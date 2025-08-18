import SwiftUI
import LaunchAtLogin

struct MenuBarView: View {
    @EnvironmentObject var whisperState: WhisperState
    @EnvironmentObject var hotkeyManager: HotkeyManager
    @EnvironmentObject var menuBarManager: MenuBarManager
    @EnvironmentObject var enhancementService: AIEnhancementService
    @EnvironmentObject var aiService: AIService
    @State private var launchAtLoginEnabled = LaunchAtLogin.isEnabled
    @State private var menuRefreshTrigger = false  // Added to force menu updates
    @State private var isHovered = false

    var body: some View {
        VStack {
            Button("Settings") {
                menuBarManager.openMainWindowAndNavigate(to: "Settings")
            }

            Button("Quit") {
                NSApplication.shared.terminate(nil)
            }
        }
    }
}
