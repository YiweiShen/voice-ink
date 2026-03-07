import SwiftUI
import AppKit

struct ContentView: View {
    @EnvironmentObject private var whisperState: WhisperState

    var body: some View {
        SettingsView()
            .environmentObject(whisperState)
            .frame(minWidth: 720, minHeight: 600)
            .toolbar(.hidden, for: .automatic)
    }
}
