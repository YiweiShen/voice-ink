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
            case .spellings:
                return "character.book.closed.fill"
            case .replacements:
                return "arrow.2.squarepath"
            }
        }
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                heroSection
                mainContent
            }
        }
        .frame(minWidth: 600, minHeight: 500)
        .background(Color(NSColor.controlBackgroundColor))
    }
    
    private var heroSection: some View {
        VStack(spacing: 24) {
            Image(systemName: "brain.filled.head.profile")
                .font(.system(size: 40))
                .foregroundStyle(.blue)
                .padding(20)
                .background(Circle()
                    .fill(Color(.windowBackgroundColor).opacity(0.9))
                    .shadow(color: .black.opacity(0.1), radius: 10, y: 5))
            
            VStack(spacing: 8) {
                Text("Custom Dictionary")
                    .font(.system(size: 28, weight: .bold))
                Text("Teach VoiceInk your special words and phrases for better transcription")
                    .font(.system(size: 15))
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: 400)
            }
        }
        .padding(.vertical, 40)
        .frame(maxWidth: .infinity)
    }
    
    private var mainContent: some View {
        VStack(spacing: 40) {
            bothSectionsContent
        }
        .padding(.horizontal, 32)
        .padding(.vertical, 40)
    }
    
    private var bothSectionsContent: some View {
        VStack(spacing: 32) {
            // Word Replacements Section (Top)
            VStack(alignment: .leading, spacing: 16) {
                SectionHeader(section: .replacements)
                WordReplacementView()
                    .background(CardBackground(isSelected: false))
            }
            
            // Correct Spellings Section (Bottom)
            VStack(alignment: .leading, spacing: 16) {
                SectionHeader(section: .spellings)
                DictionaryView(whisperPrompt: whisperPrompt)
                    .background(CardBackground(isSelected: false))
            }
        }
    }
}

struct SectionHeader: View {
    let section: DictionarySettingsView.DictionarySection
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: section.icon)
                .font(.system(size: 20))
                .symbolRenderingMode(.hierarchical)
                .foregroundStyle(.blue)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(section.rawValue)
                    .font(.title2)
                    .fontWeight(.semibold)
                
                Text(section.description)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            
            Spacer()
        }
        .padding(.vertical, 8)
    }
} 
