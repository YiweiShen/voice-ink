import SwiftUI

struct DictionarySettingsView: View {
    let whisperPrompt: WhisperPrompt

    var body: some View {
        DictionaryView(whisperPrompt: whisperPrompt)
            .background(CardBackground(isSelected: false))
    }
}
