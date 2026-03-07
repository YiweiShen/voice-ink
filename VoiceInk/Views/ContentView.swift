import SwiftUI
import SwiftData
import KeyboardShortcuts
import AppKit

// ViewType enum with all cases
enum ViewType: String, CaseIterable {
    case metrics = "Dashboard"
    case history = "History"
    case models = "AI Models"
    case permissions = "Permissions"
    case audioInput = "Audio Input"
    case dictionary = "Dictionary"
    case settings = "Settings"

    var icon: String {
        switch self {
        case .metrics: return "gauge.medium"
        case .history: return "doc.text"
        case .models: return "cpu"
        case .permissions: return "shield"
        case .audioInput: return "mic"
        case .dictionary: return "character.book.closed"
        case .settings: return "gearshape"
        }
    }
}

struct VisualEffectView: NSViewRepresentable {
    let material: NSVisualEffectView.Material
    let blendingMode: NSVisualEffectView.BlendingMode

    func makeNSView(context: Context) -> NSVisualEffectView {
        let visualEffectView = NSVisualEffectView()
        visualEffectView.material = material
        visualEffectView.blendingMode = blendingMode
        visualEffectView.state = .active
        return visualEffectView
    }

    func updateNSView(_ visualEffectView: NSVisualEffectView, context: Context) {
        visualEffectView.material = material
        visualEffectView.blendingMode = blendingMode
    }
}

struct DynamicSidebar: View {
    @Binding var selectedView: ViewType
    @Binding var hoveredView: ViewType?

    private let appVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"

    var body: some View {
        VStack(spacing: 0) {
            // App Header
            HStack(spacing: 8) {
                if let appIcon = NSImage(named: "AppIcon") {
                    Image(nsImage: appIcon)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 20, height: 20)
                        .cornerRadius(5)
                }

                Text("VoiceInk")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(.primary)

                Spacer()
            }
            .padding(.horizontal, 12)
            .padding(.top, 16)
            .padding(.bottom, 12)

            // Navigation Items
            VStack(spacing: 1) {
                ForEach(ViewType.allCases, id: \.self) { viewType in
                    DynamicSidebarButton(
                        title: viewType.rawValue,
                        systemImage: viewType.icon,
                        isSelected: selectedView == viewType,
                        isHovered: hoveredView == viewType
                    ) {
                        selectedView = viewType
                    }
                    .onHover { isHovered in
                        hoveredView = isHovered ? viewType : nil
                    }
                }
            }
            .padding(.horizontal, 6)

            Spacer()

            // Version footer
            HStack {
                Text("v\(appVersion)")
                    .font(.system(size: 11))
                    .foregroundColor(Color.primary.opacity(0.3))
                Spacer()
            }
            .padding(.horizontal, 14)
            .padding(.bottom, 12)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

struct DynamicSidebarButton: View {
    let title: String
    let systemImage: String
    let isSelected: Bool
    let isHovered: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                Image(systemName: systemImage)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(isSelected ? .primary : Color.primary.opacity(0.45))
                    .frame(width: 18, alignment: .center)

                Text(title)
                    .font(.system(size: 13, weight: isSelected ? .medium : .regular))
                    .foregroundColor(isSelected ? .primary : Color.primary.opacity(0.6))
                    .lineLimit(1)

                Spacer()
            }
            .frame(height: 30)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 8)
            .background(
                Group {
                    if isSelected || isHovered {
                        RoundedRectangle(cornerRadius: 6)
                            .fill(Color.primary.opacity(isSelected ? 0.08 : 0.04))
                    }
                }
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.colorScheme) private var colorScheme
    @EnvironmentObject private var whisperState: WhisperState
    @EnvironmentObject private var hotkeyManager: HotkeyManager
    @State private var selectedView: ViewType = .metrics
    @State private var hoveredView: ViewType?
    @State private var hasLoadedData = false
    let appVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0.0"

    private var isSetupComplete: Bool {
        hasLoadedData &&
        whisperState.currentTranscriptionModel != nil &&
        hotkeyManager.selectedHotkey1 != .none &&
        AXIsProcessTrusted()
    }

    var body: some View {
        NavigationSplitView {
            DynamicSidebar(
                selectedView: $selectedView,
                hoveredView: $hoveredView
            )
            .frame(width: 190)
            .navigationSplitViewColumnWidth(190)
        } detail: {
            detailView
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .toolbar(.hidden, for: .automatic)
                .navigationTitle("")
        }
        .navigationSplitViewStyle(.balanced)
        .frame(minWidth: 940, minHeight: 730)
        .onAppear {
            hasLoadedData = true
        }
        .onReceive(NotificationCenter.default.publisher(for: .navigateToDestination)) { notification in
            if let destination = notification.userInfo?["destination"] as? String {
                switch destination {
                case "Dashboard":
                    selectedView = .metrics
                case "Settings":
                    selectedView = .settings
                case "AI Models":
                    selectedView = .models
                case "History":
                    selectedView = .history
                case "Permissions":
                    selectedView = .permissions
                default:
                    break
                }
            }
        }
    }

    @ViewBuilder
    private var detailView: some View {
        switch selectedView {
        case .metrics:
            if isSetupComplete {
                MetricsView(skipSetupCheck: true)
            } else {
                MetricsSetupView()
                    .environmentObject(hotkeyManager)
            }
        case .models:
            ModelManagementView(whisperState: whisperState)
        case .history:
            TranscriptionHistoryView()
        case .audioInput:
            AudioInputSettingsView()
        case .dictionary:
            DictionarySettingsView(whisperPrompt: whisperState.whisperPrompt)
        case .settings:
            SettingsView()
                .environmentObject(whisperState)
        case .permissions:
            PermissionsView()
        }
    }
}
