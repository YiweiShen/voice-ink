import SwiftUI

// Style Constants
struct StyleConstants {
    static let cornerRadius: CGFloat = 10

    static let buttonGradient = LinearGradient(
        colors: [Color.accentColor, Color.accentColor.opacity(0.85)],
        startPoint: .leading,
        endPoint: .trailing
    )
}

// Flat card background — clean 1px border, no gradients or heavy shadows
struct CardBackground: View {
    var isSelected: Bool
    var cornerRadius: CGFloat = StyleConstants.cornerRadius
    var useAccentGradientWhenSelected: Bool = false

    var body: some View {
        RoundedRectangle(cornerRadius: cornerRadius)
            .fill(Color(NSColor.controlBackgroundColor))
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .stroke(
                        isSelected && useAccentGradientWhenSelected
                            ? Color.accentColor.opacity(0.35)
                            : Color.primary.opacity(0.08),
                        lineWidth: 1
                    )
            )
    }
}
