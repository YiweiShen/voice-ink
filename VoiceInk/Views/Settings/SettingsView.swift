import SwiftUI
import Cocoa
import KeyboardShortcuts
import LaunchAtLogin
import AVFoundation

struct SettingsView: View {
    @EnvironmentObject private var menuBarManager: MenuBarManager
    @EnvironmentObject private var hotkeyManager: HotkeyManager
    @EnvironmentObject private var whisperState: WhisperState
    @EnvironmentObject private var enhancementService: AIEnhancementService
    @ObservedObject private var mediaController = MediaController.shared
    @State private var isCustomCancelEnabled = false
    @State private var launchAtLoginEnabled = LaunchAtLogin.isEnabled

    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // MARK: - Recording & Shortcuts
                SettingsSection(
                    icon: "command.circle",
                    title: "Recording & Shortcuts",
                    subtitle: "Keyboard shortcuts for recording and pasting transcriptions"
                ) {
                    VStack(alignment: .leading, spacing: 16) {
                        // Recording Hotkeys
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Recording Hotkeys")
                                .font(.system(size: 15, weight: .semibold))
                                .foregroundColor(.primary)
                            
                            hotkeyView(
                                title: "Primary Hotkey",
                                binding: $hotkeyManager.selectedHotkey1,
                                shortcutName: .toggleMiniRecorder
                            )

                            if hotkeyManager.selectedHotkey2 != .none {
                                hotkeyView(
                                    title: "Secondary Hotkey",
                                    binding: $hotkeyManager.selectedHotkey2,
                                    shortcutName: .toggleMiniRecorder2,
                                    isRemovable: true,
                                    onRemove: {
                                        withAnimation { hotkeyManager.selectedHotkey2 = .none }
                                    }
                                )
                            }

                            if hotkeyManager.selectedHotkey1 != .none && hotkeyManager.selectedHotkey2 == .none {
                                HStack {
                                    Spacer()
                                    Button(action: {
                                        withAnimation { hotkeyManager.selectedHotkey2 = .rightOption }
                                    }) {
                                        Label("Add secondary hotkey", systemImage: "plus.circle")
                                            .font(.system(size: 13))
                                    }
                                    .buttonStyle(.plain)
                                    .foregroundColor(.accentColor)
                                }
                            }
                        }
                        
                        Divider()
                        
                        // Cancel Recording
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Toggle(isOn: $isCustomCancelEnabled) {
                                    Text("Custom cancel shortcut")
                                }
                                .toggleStyle(.switch)
                                .onChange(of: isCustomCancelEnabled) { _, newValue in
                                    if !newValue {
                                        KeyboardShortcuts.setShortcut(nil, for: .cancelRecorder)
                                    }
                                }
                                
                                InfoTip(
                                    title: "Custom Cancel Shortcut",
                                    message: "Use a custom shortcut instead of double-pressing Escape. Great for Vim users."
                                )
                                
                                Spacer()
                            }
                            
                            if isCustomCancelEnabled {
                                HStack(spacing: 12) {
                                    Text("Cancel Shortcut")
                                        .font(.system(size: 13, weight: .medium))
                                        .foregroundColor(.secondary)
                                    
                                    KeyboardShortcuts.Recorder(for: .cancelRecorder)
                                        .controlSize(.small)
                                    
                                    Spacer()
                                }
                                .padding(.leading, 16)
                                .transition(.opacity.combined(with: .move(edge: .top)))
                            }
                        }
                        
                        Divider()
                        
                        // Quick Paste
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Quick Paste")
                                .font(.system(size: 15, weight: .semibold))
                                .foregroundColor(.primary)
                            
                            HStack(spacing: 12) {
                                Text("Paste Shortcut")
                                    .font(.system(size: 13, weight: .medium))
                                    .foregroundColor(.secondary)
                                
                                KeyboardShortcuts.Recorder(for: .pasteLastTranscription)
                                    .controlSize(.small)
                                
                                InfoTip(
                                    title: "Quick Paste",
                                    message: "Paste your most recent transcription anywhere in macOS without opening VoiceInk."
                                )
                                
                                Spacer()
                            }
                        }
                        
                        Text("Quick press: Start recording, press again to stop. Hold down: Record while pressed, release to stop.")
                            .font(.system(size: 12))
                            .foregroundColor(.secondary)
                            .fixedSize(horizontal: false, vertical: true)
                            .padding(.top, 4)
                    }
                }

                // MARK: - Audio & Feedback
                SettingsSection(
                    icon: "speaker.wave.2.bubble.left.fill",
                    title: "Audio & Feedback",
                    subtitle: "Sound settings and audio behavior during recording"
                ) {
                    VStack(alignment: .leading, spacing: 14) {
                        SettingsToggleRow(
                            title: "Recording sounds",
                            binding: .init(
                                get: { SoundManager.shared.isEnabled },
                                set: { SoundManager.shared.isEnabled = $0 }
                            ),
                            infoTitle: "Recording Sounds",
                            infoMessage: "Play audio feedback when recording starts and stops."
                        )

                        SettingsToggleRow(
                            title: "Mute other apps while recording",
                            binding: $mediaController.isSystemMuteEnabled,
                            infoTitle: "System Audio Muting",
                            infoMessage: "Automatically mute other apps' audio to improve transcription accuracy."
                        )

                        SettingsToggleRow(
                            title: "Keep transcription in clipboard",
                            binding: Binding(
                                get: { UserDefaults.standard.bool(forKey: "preserveTranscriptInClipboard") },
                                set: { UserDefaults.standard.set($0, forKey: "preserveTranscriptInClipboard") }
                            ),
                            infoTitle: "Clipboard Management",
                            infoMessage: "Leave transcriptions in clipboard instead of restoring previous content."
                        )
                    }
                }


                // MARK: - Interface & Behavior
                SettingsSection(
                    icon: "rectangle.on.rectangle",
                    title: "Interface & Behavior",
                    subtitle: "Customize how VoiceInk appears and behaves"
                ) {
                    VStack(alignment: .leading, spacing: 16) {
                        // Recorder Style
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Text("Recorder Style")
                                    .font(.system(size: 15, weight: .semibold))
                                    .foregroundColor(.primary)
                                
                                InfoTip(
                                    title: "Recorder Styles",
                                    message: "Notch: Dynamic Island-style recorder at the top. Mini: Moveable floating window."
                                )
                                
                                Spacer()
                            }
                            
                            Picker("Recorder Style", selection: $whisperState.recorderType) {
                                Text("Notch Recorder").tag("notch")
                                Text("Mini Recorder").tag("mini")
                            }
                            .pickerStyle(.radioGroup)
                            .padding(.leading, 8)
                        }
                        
                        Divider()
                        
                        // App Behavior
                        VStack(alignment: .leading, spacing: 10) {
                            Text("App Behavior")
                                .font(.system(size: 15, weight: .semibold))
                                .foregroundColor(.primary)
                            
                            SettingsToggleRow(
                                title: "Menu bar only (hide dock icon)",
                                binding: $menuBarManager.isMenuBarOnly,
                                infoTitle: "Menu Bar Only Mode",
                                infoMessage: "Hide from Dock and run only from menu bar to keep your Dock clean."
                            )
                            
                            SettingsToggleRow(
                                title: "Use AppleScript for pasting",
                                binding: Binding(
                                    get: { UserDefaults.standard.bool(forKey: "UseAppleScriptPaste") },
                                    set: { UserDefaults.standard.set($0, forKey: "UseAppleScriptPaste") }
                                ),
                                infoTitle: "Paste Method",
                                infoMessage: "Use AppleScript for pasting. Enable if you have paste issues or non-standard keyboard layout."
                            )
                        }
                    }
                }

                // MARK: - Privacy & Data
                SettingsSection(
                    icon: "lock.shield",
                    title: "Privacy & Data",
                    subtitle: "Control transcript storage and automatic data cleanup"
                ) {
                    VStack(alignment: .leading, spacing: 16) {
                        AudioCleanupSettingsView()
                        
                        Divider()
                        
                        // Startup Settings
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Startup")
                                .font(.system(size: 15, weight: .semibold))
                                .foregroundColor(.primary)
                            
                            SettingsToggleRow(
                                title: "Launch at login",
                                binding: Binding(
                                    get: { launchAtLoginEnabled },
                                    set: { newValue in
                                        launchAtLoginEnabled = newValue
                                        LaunchAtLogin.isEnabled = newValue
                                    }
                                ),
                                infoTitle: "Launch at Login",
                                infoMessage: "Start VoiceInk automatically when you log into your Mac."
                            )
                        }
                    }
                }
                


                // MARK: - Advanced & System
                SettingsSection(
                    icon: "arrow.up.arrow.down.circle",
                    title: "Advanced & System",
                    subtitle: "Import/export settings and system configuration"
                ) {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Back up your VoiceInk configuration or transfer settings between devices.")
                            .settingsDescription()

                        HStack(spacing: 12) {
                            Button {
                                ImportExportService.shared.importSettings(
                                    enhancementService: enhancementService, 
                                    whisperPrompt: whisperState.whisperPrompt, 
                                    hotkeyManager: hotkeyManager, 
                                    menuBarManager: menuBarManager, 
                                    mediaController: MediaController.shared, 
                                    soundManager: SoundManager.shared,
                                    whisperState: whisperState
                                )
                            } label: {
                                Label("Import Settings", systemImage: "arrow.down.doc")
                                    .frame(maxWidth: .infinity)
                            }
                            .buttonStyle(.bordered)
                            .controlSize(.regular)

                            Button {
                                ImportExportService.shared.exportSettings(
                                    enhancementService: enhancementService, 
                                    whisperPrompt: whisperState.whisperPrompt, 
                                    hotkeyManager: hotkeyManager, 
                                    menuBarManager: menuBarManager, 
                                    mediaController: MediaController.shared, 
                                    soundManager: SoundManager.shared,
                                    whisperState: whisperState
                                )
                            } label: {
                                Label("Export Settings", systemImage: "arrow.up.doc")
                                    .frame(maxWidth: .infinity)
                            }
                            .buttonStyle(.bordered)
                            .controlSize(.regular)
                        }
                        
                        Text("API keys and personal data are not included in exports for security.")
                            .font(.system(size: 11))
                            .foregroundStyle(.tertiary)
                    }
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 12)
        }
        .background(Color(NSColor.controlBackgroundColor))
        .onAppear {
            isCustomCancelEnabled = KeyboardShortcuts.getShortcut(for: .cancelRecorder) != nil
        }
    }
    
    @ViewBuilder
    private func hotkeyView(
        title: String,
        binding: Binding<HotkeyManager.HotkeyOption>,
        shortcutName: KeyboardShortcuts.Name,
        isRemovable: Bool = false,
        onRemove: (() -> Void)? = nil
    ) -> some View {
        HStack(spacing: 12) {
            Text(title)
                .font(.system(size: 13, weight: .medium))
                .foregroundColor(.secondary)
            
            Menu {
                ForEach(HotkeyManager.HotkeyOption.allCases, id: \.self) { option in
                    Button(action: {
                        binding.wrappedValue = option
                    }) {
                        HStack {
                            Text(option.displayName)
                            if binding.wrappedValue == option {
                                Spacer()
                                Image(systemName: "checkmark")
                            }
                        }
                    }
                }
            } label: {
                HStack(spacing: 8) {
                    Text(binding.wrappedValue.displayName)
                        .foregroundColor(.primary)
                    Image(systemName: "chevron.up.chevron.down")
                        .font(.system(size: 10))
                        .foregroundColor(.secondary)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(Color(NSColor.controlBackgroundColor))
                .cornerRadius(6)
                .overlay(
                    RoundedRectangle(cornerRadius: 6)
                        .stroke(Color.secondary.opacity(0.3), lineWidth: 1)
                )
            }
            .menuStyle(.borderlessButton)
            
            if binding.wrappedValue == .custom {
                KeyboardShortcuts.Recorder(for: shortcutName)
                    .controlSize(.small)
            }
            
            Spacer()
            
            if isRemovable {
                Button(action: {
                    onRemove?()
                }) {
                    Image(systemName: "minus.circle.fill")
                        .foregroundColor(.red)
                }
                .buttonStyle(.plain)
            }
        }
    }
}

struct SettingsSection<Content: View>: View {
    let icon: String
    let title: String
    let subtitle: String
    let content: Content
    var showWarning: Bool = false
    
    init(icon: String, title: String, subtitle: String, showWarning: Bool = false, @ViewBuilder content: () -> Content) {
        self.icon = icon
        self.title = title
        self.subtitle = subtitle
        self.showWarning = showWarning
        self.content = content()
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.system(size: 20))
                    .foregroundColor(showWarning ? .red : .accentColor)
                    .frame(width: 24, height: 24)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.headline)
                    Text(subtitle)
                        .font(.subheadline)
                        .foregroundColor(showWarning ? .red : .secondary)
                }
                
                if showWarning {
                    Spacer()
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundColor(.red)
                        .help("Permission required for VoiceInk to function properly")
                }
            }
            
            Divider()
                .padding(.vertical, 4)
            
            content
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(CardBackground(isSelected: showWarning, useAccentGradientWhenSelected: true))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(showWarning ? Color.red.opacity(0.5) : Color.clear, lineWidth: 1)
        )
    }
}

// MARK: - Helper Components
struct SettingsToggleRow: View {
    let title: String
    let binding: Binding<Bool>
    let infoTitle: String
    let infoMessage: String
    
    var body: some View {
        HStack {
            Toggle(title, isOn: binding)
                .toggleStyle(.switch)
            
            InfoTip(title: infoTitle, message: infoMessage)
            
            Spacer()
        }
    }
}

// Add this extension for consistent description text styling
extension Text {
    func settingsDescription() -> some View {
        self
            .font(.system(size: 13))
            .foregroundColor(.secondary)
            .fixedSize(horizontal: false, vertical: true)
    }
}


