import SwiftUI

// Enhancement Prompt Popover for recorder views
struct EnhancementPromptPopover: View {
    @EnvironmentObject var enhancementService: AIEnhancementService
    @State private var selectedPrompt: CustomPrompt?
    
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            // Enhancement Toggle at the top
            HStack(spacing: 8) {
                Toggle("Enhancement", isOn: $enhancementService.isEnhancementEnabled)
                    .foregroundColor(.white.opacity(0.85))
                    .font(.system(size: 13, weight: .medium))
                    .lineLimit(1)
                Spacer()
            }
            .padding(.horizontal, 12)
            .padding(.top, 10)

            Divider()
                .background(Color.white.opacity(0.1))
            
            ScrollView {
                VStack(alignment: .leading, spacing: 2) {
                    ForEach(enhancementService.allPrompts) { prompt in
                        EnhancementPromptRow(
                            prompt: prompt,
                            isSelected: selectedPrompt?.id == prompt.id,
                            isDisabled: !enhancementService.isEnhancementEnabled,
                            action: {
                                enhancementService.setActivePrompt(prompt)
                                selectedPrompt = prompt
                            }
                        )
                    }
                }
                .padding(.horizontal, 6)
            }
        }
        .frame(width: 200)
        .frame(maxHeight: 280)
        .padding(.bottom, 8)
        .background(Color(red: 0.1, green: 0.1, blue: 0.1))
        .environment(\.colorScheme, .dark)
        .onAppear {
            // Set the initially selected prompt
            selectedPrompt = enhancementService.activePrompt
        }
        .onChange(of: enhancementService.selectedPromptId) { oldValue, newValue in
            selectedPrompt = enhancementService.activePrompt
        }
    }
}

// Row view for each enhancement prompt in the popover
struct EnhancementPromptRow: View {
    let prompt: CustomPrompt
    let isSelected: Bool
    let isDisabled: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                Image(systemName: prompt.icon.rawValue)
                    .font(.system(size: 12))
                    .foregroundColor(isDisabled ? .white.opacity(0.2) : .white.opacity(0.6))
                    .frame(width: 14)

                Text(prompt.title)
                    .foregroundColor(isDisabled ? .white.opacity(0.3) : .white.opacity(0.85))
                    .font(.system(size: 12))
                    .lineLimit(1)

                Spacer()

                if isSelected {
                    Image(systemName: "checkmark")
                        .foregroundColor(isDisabled ? .green.opacity(0.3) : .green)
                        .font(.system(size: 10, weight: .semibold))
                }
            }
            .contentShape(Rectangle())
            .padding(.vertical, 5)
            .padding(.horizontal, 8)
            .background(
                RoundedRectangle(cornerRadius: 5)
                    .fill(isSelected ? Color.white.opacity(0.1) : Color.clear)
            )
        }
        .buttonStyle(.plain)
        .disabled(isDisabled)
    }
} 