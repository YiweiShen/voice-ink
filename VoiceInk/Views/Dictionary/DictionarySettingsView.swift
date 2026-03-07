import SwiftUI

struct DictionarySettingsView: View {
    let whisperPrompt: WhisperPrompt

    enum DictionarySection: String, CaseIterable {
        case replacements = "Text Shortcuts"
        case spellings = "Custom Words"

        var description: String {
            switch self {
            case .spellings:
                return "Add names, technical terms, and specialized words that VoiceInk should know"
            case .replacements:
                return "Create shortcuts that automatically expand into longer text (like 'btw' → 'by the way')"
            }
        }

        var icon: String {
            switch self {
            case .spellings: return "character.book.closed"
            case .replacements: return "arrow.2.squarepath"
            }
        }
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                Text("Dictionary")
                    .font(.system(size: 20, weight: .bold))

                VStack(alignment: .leading, spacing: 24) {
                    // Word Replacements Section
                    VStack(alignment: .leading, spacing: 10) {
                        SectionHeader(section: .replacements)
                        WordReplacementView()
                            .background(CardBackground(isSelected: false))
                    }

                    // Custom Words Section
                    VStack(alignment: .leading, spacing: 10) {
                        SectionHeader(section: .spellings)
                        DictionaryView(whisperPrompt: whisperPrompt)
                            .background(CardBackground(isSelected: false))
                    }
                }
            }
            .padding(24)
        }
        .frame(minWidth: 600, minHeight: 500)
        .background(Color(NSColor.controlBackgroundColor))
    }
}

struct SectionHeader: View {
    let section: DictionarySettingsView.DictionarySection

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: section.icon)
                .font(.system(size: 13, weight: .medium))
                .foregroundColor(Color.primary.opacity(0.45))
                .frame(width: 18, alignment: .center)

            VStack(alignment: .leading, spacing: 2) {
                Text(section.rawValue)
                    .font(.system(size: 13, weight: .semibold))
                Text(section.description)
                    .font(.system(size: 12))
                    .foregroundColor(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer()
        }
    }
}
