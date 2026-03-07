import SwiftUI
import KeyboardShortcuts
import LaunchAtLogin

struct SettingsView: View {
    @EnvironmentObject private var hotkeyManager: HotkeyManager
    @EnvironmentObject private var whisperState: WhisperState
    @StateObject private var permissionManager = PermissionManager()
    @State private var launchAtLoginEnabled = LaunchAtLogin.isEnabled

    @State private var isShowingDeleteAlert = false
    @State private var deleteAlertTitle = ""
    @State private var deleteAlertMessage = ""
    @State private var deleteActionClosure: () -> Void = {}

    private var allPermissionsGranted: Bool {
        hotkeyManager.selectedHotkey1 != .none &&
        permissionManager.audioPermissionStatus == .authorized &&
        permissionManager.isAccessibilityEnabled
    }

    private var noModelDownloaded: Bool {
        whisperState.currentTranscriptionModel == nil
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // MARK: - Transcription Models
                SettingsSection(icon: "cpu", title: "Transcription Models", showWarning: noModelDownloaded, style: .list) {
                    VStack(alignment: .leading, spacing: 8) {
                        ForEach(localTranscriptionModels, id: \.name) { model in
                            ModelCardRowView(
                                model: model,
                                whisperState: whisperState,
                                isDownloaded: whisperState.availableModels.contains { $0.name == model.name },
                                isCurrent: whisperState.currentTranscriptionModel?.name == model.name,
                                downloadProgress: whisperState.downloadProgress,
                                modelURL: whisperState.availableModels.first { $0.name == model.name }?.url,
                                deleteAction: {
                                    if let downloaded = whisperState.availableModels.first(where: { $0.name == model.name }) {
                                        deleteAlertTitle = "Delete Model"
                                        deleteAlertMessage = "Are you sure you want to delete '\(downloaded.name)'?"
                                        deleteActionClosure = {
                                            Task { await whisperState.deleteModel(downloaded) }
                                        }
                                        isShowingDeleteAlert = true
                                    }
                                },
                                setDefaultAction: {
                                    Task { whisperState.setDefaultTranscriptionModel(model) }
                                },
                                downloadAction: {
                                    if let localModel = model as? LocalModel {
                                        Task { await whisperState.downloadModel(localModel) }
                                    }
                                }
                            )
                        }
                    }
                }

                // MARK: - Permissions
                SettingsSection(icon: "shield", title: "Permissions", showWarning: !allPermissionsGranted) {
                    VStack(spacing: 0) {
                        PermissionRow(
                            icon: "keyboard",
                            title: "Keyboard Shortcut",
                            description: "Start recording from any app",
                            isGranted: hotkeyManager.selectedHotkey1 != .none,
                            keyBadge: "Right Option (⌥)",
                            badge: "Default",
                            buttonTitle: "Set Up",
                            buttonAction: {},
                            checkPermission: {}
                        )
                        Divider()
                        PermissionRow(
                            icon: "mic",
                            title: "Microphone Access",
                            description: "Converts your speech to text",
                            isGranted: permissionManager.audioPermissionStatus == .authorized,
                            buttonTitle: permissionManager.audioPermissionStatus == .notDetermined ? "Request" : "Open Settings",
                            buttonAction: {
                                if permissionManager.audioPermissionStatus == .notDetermined {
                                    permissionManager.requestAudioPermission()
                                } else {
                                    if let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Microphone") {
                                        NSWorkspace.shared.open(url)
                                    }
                                }
                            },
                            checkPermission: { permissionManager.checkAudioPermissionStatus() }
                        )
                        Divider()
                        PermissionRow(
                            icon: "hand.raised",
                            title: "Text Pasting",
                            description: "Auto-paste transcription where you're typing",
                            isGranted: permissionManager.isAccessibilityEnabled,
                            buttonTitle: "Open Settings",
                            buttonAction: {
                                if let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility") {
                                    NSWorkspace.shared.open(url)
                                }
                            },
                            checkPermission: { permissionManager.checkAccessibilityPermissions() }
                        )
                    }
                }

                // MARK: - Startup
                SettingsSection(icon: "power", title: "Startup", showWarning: !launchAtLoginEnabled) {
                    ConfigRow(
                        icon: "power",
                        title: "Launch at Login",
                        description: "Start VoiceInk automatically when you log in",
                        isConfigured: launchAtLoginEnabled
                    ) {
                        Toggle("", isOn: Binding(
                            get: { launchAtLoginEnabled },
                            set: { newValue in
                                launchAtLoginEnabled = newValue
                                LaunchAtLogin.isEnabled = newValue
                            }
                        ))
                        .toggleStyle(.switch)
                        .controlSize(.small)
                        .labelsHidden()
                    }
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 14)
        }
        .background(Color(NSColor.controlBackgroundColor))
        .alert(isPresented: $isShowingDeleteAlert) {
            Alert(
                title: Text(deleteAlertTitle),
                message: Text(deleteAlertMessage),
                primaryButton: .destructive(Text("Delete"), action: deleteActionClosure),
                secondaryButton: .cancel()
            )
        }
        .onAppear {
            permissionManager.checkAllPermissions()
        }
    }

    private var localTranscriptionModels: [any TranscriptionModel] {
        whisperState.allAvailableModels.filter {
            $0.provider == .local || $0.provider == .nativeApple || $0.provider == .parakeet
        }
    }

}

// MARK: - SettingsSection

struct SettingsSection<Content: View>: View {
    let icon: String
    let title: String
    let content: Content
    var showWarning: Bool = false
    var style: SectionStyle = .grouped

    enum SectionStyle: Equatable { case grouped, list }

    init(icon: String, title: String, showWarning: Bool = false, style: SectionStyle = .grouped, @ViewBuilder content: () -> Content) {
        self.icon = icon
        self.title = title
        self.showWarning = showWarning
        self.style = style
        self.content = content()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            // Compact one-line section label
            HStack(spacing: 5) {
                Image(systemName: icon)
                    .font(.system(size: 10, weight: .medium))
                    .foregroundColor(showWarning ? Color.orange : Color.primary.opacity(0.3))
                Text(title)
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundColor(showWarning ? Color.orange : Color.primary.opacity(0.5))
                if showWarning {
                    Image(systemName: "exclamationmark.circle.fill")
                        .font(.system(size: 10))
                        .foregroundColor(.orange)
                }
            }

            // Content area
            if style == .grouped {
                VStack(alignment: .leading, spacing: 0) {
                    content
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(
                    RoundedRectangle(cornerRadius: StyleConstants.cornerRadius)
                        .fill(Color(NSColor.controlBackgroundColor))
                        .overlay(
                            RoundedRectangle(cornerRadius: StyleConstants.cornerRadius)
                                .stroke(
                                    showWarning ? Color.orange.opacity(0.35) : Color.primary.opacity(0.08),
                                    lineWidth: 1
                                )
                        )
                )
            } else {
                VStack(alignment: .leading, spacing: 0) {
                    content
                }
            }
        }
    }
}

// MARK: - PermissionRow

struct PermissionRow: View {
    let icon: String
    let title: String
    let description: String
    let isGranted: Bool
    var keyBadge: String? = nil
    var badge: String? = nil
    let buttonTitle: String
    let buttonAction: () -> Void
    let checkPermission: () -> Void
    @State private var isRefreshing = false

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: icon)
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(isGranted ? Color.green : Color.primary.opacity(0.35))
                .frame(width: 14, alignment: .center)

            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 6) {
                    Text(title)
                        .font(.system(size: 13, weight: .medium))
                    if let badge {
                        Text(badge)
                            .font(.system(size: 10, weight: .semibold))
                            .foregroundColor(.secondary)
                            .padding(.horizontal, 5)
                            .padding(.vertical, 1)
                            .background(RoundedRectangle(cornerRadius: 3).fill(Color.primary.opacity(0.07)))
                    }
                }
                Text(description)
                    .font(.system(size: 11))
                    .foregroundColor(.secondary)
            }

            Spacer()

            if isGranted {
                HStack(spacing: 6) {
                    if let keyBadge {
                        Text(keyBadge)
                            .font(.system(size: 11))
                            .foregroundColor(.secondary)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color(NSColor.windowBackgroundColor))
                            .cornerRadius(5)
                            .overlay(RoundedRectangle(cornerRadius: 5).stroke(Color.primary.opacity(0.12), lineWidth: 1))
                    }
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 13))
                        .foregroundColor(Color.green.opacity(0.8))
                }
            } else {
                HStack(spacing: 7) {
                    Button {
                        withAnimation(.easeInOut(duration: 0.4)) { isRefreshing = true }
                        checkPermission()
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                            withAnimation { isRefreshing = false }
                        }
                    } label: {
                        Image(systemName: "arrow.clockwise")
                            .font(.system(size: 10))
                            .foregroundColor(Color.primary.opacity(0.3))
                            .rotationEffect(.degrees(isRefreshing ? 360 : 0))
                            .animation(isRefreshing ? .linear(duration: 0.4) : .default, value: isRefreshing)
                    }
                    .buttonStyle(.plain)

                    Button(action: buttonAction) {
                        Text(buttonTitle)
                            .font(.system(size: 12))
                            .frame(minWidth: 88)
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.small)
                }
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
    }
}

// MARK: - ConfigRow

struct ConfigRow<Trailing: View>: View {
    let icon: String
    let title: String
    let description: String
    let isConfigured: Bool
    var showWarning: Bool = false
    let trailing: Trailing

    init(icon: String, title: String, description: String, isConfigured: Bool, showWarning: Bool = false, @ViewBuilder trailing: () -> Trailing) {
        self.icon = icon
        self.title = title
        self.description = description
        self.isConfigured = isConfigured
        self.showWarning = showWarning
        self.trailing = trailing()
    }

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: icon)
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(showWarning ? Color.orange : (isConfigured ? Color.green : Color.primary.opacity(0.35)))
                .frame(width: 14, alignment: .center)

            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 4) {
                    Text(title)
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(showWarning ? Color.orange : Color(.labelColor))
                    if showWarning {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .font(.system(size: 10))
                            .foregroundColor(.orange)
                    }
                }
                Text(description)
                    .font(.system(size: 11))
                    .foregroundColor(.secondary)
            }

            Spacer()

            trailing
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
    }
}

// MARK: - Text extension

extension Text {
    func settingsDescription() -> some View {
        self
            .font(.system(size: 13))
            .foregroundColor(.secondary)
            .fixedSize(horizontal: false, vertical: true)
    }
}

