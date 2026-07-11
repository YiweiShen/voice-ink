import Foundation

enum PromptIcon: String, Codable, CaseIterable {
    // Document & Text
    case documentFill = "doc.text.fill"
    case textbox = "textbox"
    case sealedFill = "checkmark.seal.fill"
    
    // Communication
    case chatFill = "bubble.left.and.bubble.right.fill"
    case messageFill = "message.fill"
    case emailFill = "envelope.fill"
    
    // Professional
    case meetingFill = "person.2.fill"
    case presentationFill = "person.wave.2.fill"
    case briefcaseFill = "briefcase.fill"
    
    // Technical
    case codeFill = "curlybraces"
    case terminalFill = "terminal.fill"
    case gearFill = "gearshape.fill"
    
    // Content
    case blogFill = "doc.text.image.fill"
    case notesFill = "note"
    case bookFill = "book.fill"
    case bookmarkFill = "bookmark.fill"
    case pencilFill = "pencil.circle.fill"
    
    // Media & Creative
    case videoFill = "video.fill"
    case micFill = "mic.fill"
    case musicFill = "music.note"
    case photoFill = "photo.fill"
    case brushFill = "paintbrush.fill"
    
    var title: String {
        switch self {
        // Document & Text
        case .documentFill: return "Document"
        case .textbox: return "Textbox"
        case .sealedFill: return "Sealed"
            
        // Communication
        case .chatFill: return "Chat"
        case .messageFill: return "Message"
        case .emailFill: return "Email"
            
        // Professional
        case .meetingFill: return "Meeting"
        case .presentationFill: return "Presentation"
        case .briefcaseFill: return "Briefcase"
            
        // Technical
        case .codeFill: return "Code"
        case .terminalFill: return "Terminal"
        case .gearFill: return "Settings"
            
        // Content
        case .blogFill: return "Blog"
        case .notesFill: return "Notes"
        case .bookFill: return "Book"
        case .bookmarkFill: return "Bookmark"
        case .pencilFill: return "Edit"
            
        // Media & Creative
        case .videoFill: return "Video"
        case .micFill: return "Audio"
        case .musicFill: return "Music"
        case .photoFill: return "Photo"
        case .brushFill: return "Design"
        }
    }
}

struct CustomPrompt: Identifiable, Codable, Equatable {
    let id: UUID
    let title: String
    let promptText: String
    var isActive: Bool
    let icon: PromptIcon
    let description: String?
    let isPredefined: Bool
    let triggerWords: [String]
    
    init(
        id: UUID = UUID(),
        title: String,
        promptText: String,
        isActive: Bool = false,
        icon: PromptIcon = .documentFill,
        description: String? = nil,
        isPredefined: Bool = false,
        triggerWords: [String] = []
    ) {
        self.id = id
        self.title = title
        self.promptText = promptText
        self.isActive = isActive
        self.icon = icon
        self.description = description
        self.isPredefined = isPredefined
        self.triggerWords = triggerWords
    }
}

