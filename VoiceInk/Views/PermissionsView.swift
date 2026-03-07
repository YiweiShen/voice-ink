import SwiftUI
import AVFoundation
import Cocoa
import KeyboardShortcuts

class PermissionManager: ObservableObject {
    @Published var audioPermissionStatus = AVCaptureDevice.authorizationStatus(for: .audio)
    @Published var isAccessibilityEnabled = false
    @Published var isKeyboardShortcutSet = false

    init() {
        setupNotificationObservers()
        checkAllPermissions()
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    private func setupNotificationObservers() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(applicationDidBecomeActive),
            name: NSApplication.didBecomeActiveNotification,
            object: nil
        )
    }

    @objc private func applicationDidBecomeActive() {
        checkAllPermissions()
    }

    func checkAllPermissions() {
        checkAccessibilityPermissions()
        checkAudioPermissionStatus()
        checkKeyboardShortcut()
    }

    func checkAccessibilityPermissions() {
        let options: NSDictionary = [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: false]
        let accessibilityEnabled = AXIsProcessTrustedWithOptions(options)
        DispatchQueue.main.async {
            self.isAccessibilityEnabled = accessibilityEnabled
        }
    }

    func checkAudioPermissionStatus() {
        DispatchQueue.main.async {
            self.audioPermissionStatus = AVCaptureDevice.authorizationStatus(for: .audio)
        }
    }

    func requestAudioPermission() {
        AVCaptureDevice.requestAccess(for: .audio) { granted in
            DispatchQueue.main.async {
                self.audioPermissionStatus = granted ? .authorized : .denied
            }
        }
    }

    func checkKeyboardShortcut() {
        DispatchQueue.main.async {
            self.isKeyboardShortcutSet = KeyboardShortcuts.getShortcut(for: .toggleMiniRecorder) != nil
        }
    }
}

struct PermissionCard: View {
    let icon: String
    let title: String
    let description: String
    let isGranted: Bool
    let buttonTitle: String
    let buttonAction: () -> Void
    let checkPermission: () -> Void
    @State private var isRefreshing = false

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(isGranted ? .green : Color.primary.opacity(0.45))
                    .frame(width: 18, alignment: .center)

                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.system(size: 13, weight: .semibold))
                    Text(description)
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)
                }

                Spacer()

                HStack(spacing: 10) {
                    Button(action: {
                        withAnimation(.easeInOut(duration: 0.4)) { isRefreshing = true }
                        checkPermission()
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { isRefreshing = false }
                    }) {
                        Image(systemName: "arrow.clockwise")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(Color.primary.opacity(0.35))
                            .rotationEffect(.degrees(isRefreshing ? 360 : 0))
                    }
                    .buttonStyle(.plain)

                    Image(systemName: isGranted ? "checkmark.circle.fill" : "xmark.circle.fill")
                        .font(.system(size: 15))
                        .foregroundColor(isGranted ? .green : Color.orange)
                }
            }

            if !isGranted {
                Button(action: buttonAction) {
                    HStack {
                        Text(buttonTitle)
                            .font(.system(size: 13, weight: .medium))
                        Spacer()
                        Image(systemName: "arrow.up.right")
                            .font(.system(size: 11))
                    }
                }
                .buttonStyle(.bordered)
                .controlSize(.regular)
                .padding(.leading, 30)
            }
        }
        .padding(16)
        .background(CardBackground(isSelected: false))
    }
}

struct PermissionsView: View {
    @EnvironmentObject private var hotkeyManager: HotkeyManager
    @StateObject private var permissionManager = PermissionManager()

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Text("Permissions")
                    .font(.system(size: 20, weight: .bold))
                    .padding(.bottom, 4)

                PermissionCard(
                    icon: "keyboard",
                    title: "Keyboard Shortcut",
                    description: "Create a quick shortcut to start recording from any app",
                    isGranted: hotkeyManager.selectedHotkey1 != .none,
                    buttonTitle: "Set Up Shortcut in Settings",
                    buttonAction: {
                        NotificationCenter.default.post(
                            name: .navigateToDestination,
                            object: nil,
                            userInfo: ["destination": "Settings"]
                        )
                    },
                    checkPermission: { permissionManager.checkKeyboardShortcut() }
                )

                PermissionCard(
                    icon: "mic",
                    title: "Microphone Access",
                    description: "Let VoiceInk listen to your voice to convert speech to text",
                    isGranted: permissionManager.audioPermissionStatus == .authorized,
                    buttonTitle: permissionManager.audioPermissionStatus == .notDetermined
                        ? "Request Permission"
                        : "Open System Settings",
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

                PermissionCard(
                    icon: "hand.raised",
                    title: "Text Pasting",
                    description: "Let VoiceInk automatically paste your transcription where you're typing",
                    isGranted: permissionManager.isAccessibilityEnabled,
                    buttonTitle: "Open System Settings",
                    buttonAction: {
                        if let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility") {
                            NSWorkspace.shared.open(url)
                        }
                    },
                    checkPermission: { permissionManager.checkAccessibilityPermissions() }
                )
            }
            .padding(24)
        }
        .background(Color(NSColor.controlBackgroundColor))
        .onAppear {
            permissionManager.checkAllPermissions()
        }
    }
}
