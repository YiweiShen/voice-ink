import SwiftUI

struct AnimatedCopyButton: View {
    let textToCopy: String
    @State private var isCopied: Bool = false

    var body: some View {
        Button {
            copyToClipboard()
        } label: {
            HStack(spacing: 4) {
                Image(systemName: isCopied ? "checkmark" : "doc.on.doc")
                    .font(.system(size: 11, weight: isCopied ? .semibold : .regular))
                Text(isCopied ? "Copied" : "Copy")
                    .font(.system(size: 12, weight: .medium))
            }
            .foregroundColor(isCopied ? .green : Color.primary.opacity(0.6))
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(
                RoundedRectangle(cornerRadius: 5)
                    .fill(isCopied ? Color.green.opacity(0.1) : Color.primary.opacity(0.06))
                    .overlay(
                        RoundedRectangle(cornerRadius: 5)
                            .stroke(isCopied ? Color.green.opacity(0.25) : Color.primary.opacity(0.08), lineWidth: 1)
                    )
            )
        }
        .buttonStyle(.plain)
        .animation(.spring(response: 0.25, dampingFraction: 0.8), value: isCopied)
    }

    private func copyToClipboard() {
        let _ = ClipboardManager.copyToClipboard(textToCopy)
        withAnimation { isCopied = true }
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            withAnimation { isCopied = false }
        }
    }
}
