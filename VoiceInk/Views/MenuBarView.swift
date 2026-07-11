import SwiftUI

struct MenuBarView: View {
    @EnvironmentObject var menuBarManager: MenuBarManager

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
