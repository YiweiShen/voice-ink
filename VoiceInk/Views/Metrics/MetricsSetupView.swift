import SwiftUI
import KeyboardShortcuts

struct MetricsSetupView: View {
    @EnvironmentObject private var whisperState: WhisperState
    @EnvironmentObject private var hotkeyManager: HotkeyManager
    @State private var isAccessibilityEnabled = AXIsProcessTrusted()
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Header
                VStack(spacing: 8) {
                    AppIconView()
                        .frame(width: 52, height: 52)
                        .padding(.bottom, 4)

                    Text("Welcome to VoiceInk")
                        .font(.system(size: 22, weight: .bold))
                        .multilineTextAlignment(.center)

                    Text("Complete these steps to get started")
                        .font(.system(size: 13))
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                .padding(.top, 32)
                .padding(.bottom, 16)
                
                // Setup Steps
                VStack(alignment: .leading, spacing: 0) {
                    ForEach(0..<3) { index in
                        setupStep(for: index)
                        if index < 2 {
                            Divider().padding(.leading, 56)
                        }
                    }
                }
                .background(CardBackground(isSelected: false))
                .padding(.horizontal)
                
                Spacer(minLength: 20)
                
                // Action Button
                actionButton
                    .frame(maxWidth: 400)
                
                // Help Text
                helpText
            }
            .padding()
        }
        .frame(minWidth: 500, minHeight: 600)
        .background(Color(NSColor.controlBackgroundColor))
    }
    
    private func setupStep(for index: Int) -> some View {
        let stepInfo: (isCompleted: Bool, icon: String, title: String, description: String)
        
        switch index {
        case 0:
            stepInfo = (
                isCompleted: hotkeyManager.selectedHotkey1 != .none,
                icon: "command",
                title: "Choose Your Shortcut",
                description: "Set up a keyboard shortcut to quickly start recording from anywhere."
            )
        case 1:
            stepInfo = (
                isCompleted: isAccessibilityEnabled,
                icon: "hand.raised.fill",
                title: "Allow Text Pasting",
                description: "Let VoiceInk automatically paste your transcription where you're typing."
            )
        default:
            stepInfo = (
                isCompleted: whisperState.currentTranscriptionModel != nil,
                icon: "arrow.down.to.line",
                title: "Get Your AI Model",
                description: "Download the AI model that will convert your speech to text."
            )
        }
        
        return HStack(spacing: 14) {
            Image(systemName: stepInfo.isCompleted ? "checkmark.circle.fill" : stepInfo.icon)
                .font(.system(size: 15, weight: .medium))
                .foregroundColor(stepInfo.isCompleted ? .green : Color.primary.opacity(0.45))
                .frame(width: 24, alignment: .center)

            VStack(alignment: .leading, spacing: 2) {
                Text(stepInfo.title)
                    .font(.system(size: 13, weight: .semibold))
                Text(stepInfo.description)
                    .font(.system(size: 12))
                    .foregroundColor(.secondary)
            }

            Spacer()

            if !stepInfo.isCompleted {
                Image(systemName: "chevron.right")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundColor(Color.primary.opacity(0.2))
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
    }
    
    private var actionButton: some View {
        Button(action: handleActionButton) {
            HStack(spacing: 6) {
                Text(getActionButtonTitle())
                    .font(.system(size: 13, weight: .semibold))
                Image(systemName: "arrow.right")
                    .font(.system(size: 11, weight: .semibold))
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 10)
            .background(Color.accentColor)
            .foregroundColor(.white)
            .cornerRadius(8)
        }
        .buttonStyle(.plain)
    }
    
    private func handleActionButton() {
        if isShortcutAndAccessibilityGranted {
            openModelManagement()
        } else {
            // Handle different permission requests based on which one is missing
            if hotkeyManager.selectedHotkey1 == .none {
                openSettings()
            } else if !AXIsProcessTrusted() {
                if let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility") {
                    NSWorkspace.shared.open(url)
                }
            }
        }
    }
    
    private func getActionButtonTitle() -> String {
        if hotkeyManager.selectedHotkey1 == .none {
            return "Set Up Shortcut"
        } else if !AXIsProcessTrusted() {
            return "Allow Text Pasting"
        } else if whisperState.currentTranscriptionModel == nil {
            return "Get AI Model"
        }
        return "Get Started"
    }
    
    private var helpText: some View {
        Text("Need help? Look for the Help menu in your menu bar")
            .font(.caption)
            .foregroundColor(.secondary)
    }
    
    private var isShortcutAndAccessibilityGranted: Bool {
        hotkeyManager.selectedHotkey1 != .none &&
        AXIsProcessTrusted()
    }
    
    private func openSettings() {
        NotificationCenter.default.post(
            name: .navigateToDestination,
            object: nil,
            userInfo: ["destination": "Settings"]
        )
    }
    
    private func openModelManagement() {
        NotificationCenter.default.post(
            name: .navigateToDestination,
            object: nil,
            userInfo: ["destination": "AI Models"]
        )
    }
}


