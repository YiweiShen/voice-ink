import SwiftUI

/// A reusable info tip component that displays helpful information in a popover
struct InfoTip: View {
    // Content configuration
    var title: String
    var message: String
    var learnMoreLink: URL?
    var learnMoreText: String = "Learn More"
    
    // Appearance customization
    var iconName: String = "info.circle"
    var iconSize: Image.Scale = .small
    var iconColor: Color = Color.primary.opacity(0.35)
    var width: CGFloat = 300
    
    // State
    @State private var isShowingTip: Bool = false
    
    var body: some View {
        Image(systemName: iconName)
            .imageScale(iconSize)
            .foregroundColor(iconColor)
            .fontWeight(.semibold)
            .padding(5)
            .contentShape(Rectangle())
            .popover(isPresented: $isShowingTip) {
                VStack(alignment: .leading, spacing: 8) {
                    Text(title)
                        .font(.system(size: 13, weight: .semibold))

                    Text(message)
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)
                        .frame(width: width)
                        .fixedSize(horizontal: false, vertical: true)
                        .padding(.bottom, learnMoreLink != nil ? 4 : 0)

                    if let url = learnMoreLink {
                        Button(learnMoreText) {
                            NSWorkspace.shared.open(url)
                        }
                        .font(.system(size: 12))
                        .foregroundColor(.accentColor)
                    }
                }
                .padding(12)
            }
            .onTapGesture {
                isShowingTip.toggle()
            }
    }
}

// MARK: - Convenience initializers

extension InfoTip {
    /// Creates an InfoTip with just title and message
    init(title: String, message: String) {
        self.title = title
        self.message = message
        self.learnMoreLink = nil
    }
    
    /// Creates an InfoTip with a learn more link
    init(title: String, message: String, learnMoreURL: String) {
        self.title = title
        self.message = message
        self.learnMoreLink = URL(string: learnMoreURL)
    }
}
