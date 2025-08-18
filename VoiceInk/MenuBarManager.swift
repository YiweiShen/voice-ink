import SwiftUI
import LaunchAtLogin
import SwiftData
import AppKit

class MenuBarManager: NSObject, ObservableObject {

    @Published var isMenuBarOnly: Bool {
        didSet {
            UserDefaults.standard.set(isMenuBarOnly, forKey: "IsMenuBarOnly")
            updateAppActivationPolicy()
        }
    }

    private var whisperState: WhisperState
    private var container: ModelContainer
    private var enhancementService: AIEnhancementService
    private var aiService: AIService
    private var hotkeyManager: HotkeyManager
    private var mainWindow: NSWindow?  // Store window reference

    init(
        whisperState: WhisperState,
        container: ModelContainer,
        enhancementService: AIEnhancementService,
        aiService: AIService,
        hotkeyManager: HotkeyManager
    ) {
        self.isMenuBarOnly = UserDefaults.standard.object(forKey: "IsMenuBarOnly") != nil
            ? UserDefaults.standard.bool(forKey: "IsMenuBarOnly")
            : true

        self.whisperState = whisperState
        self.container = container
        self.enhancementService = enhancementService
        self.aiService = aiService
        self.hotkeyManager = hotkeyManager

        super.init()
        updateAppActivationPolicy()
    }

    // MARK: - Toggle Menu Bar Mode

    func toggleMenuBarOnly() {
        isMenuBarOnly.toggle()
    }

    private func updateAppActivationPolicy() {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }

            if self.isMenuBarOnly, let window = self.mainWindow {
                window.close()
                self.mainWindow = nil
            }

            NSApp.setActivationPolicy(self.isMenuBarOnly ? .accessory : .regular)
            print("MenuBarManager: Activation policy set to \(self.isMenuBarOnly ? "accessory" : "regular")")
        }
    }

    // MARK: - Open Main Window

    func openMainWindowAndNavigate(to destination: String) {
        print("MenuBarManager: Navigating to \(destination)")

        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }

            // Temporarily set to regular to show window, but manage dock icon separately
            NSApp.setActivationPolicy(.regular)

            if let existingWindow = self.findExistingMainWindow() {
                self.activateAppAndWindow(existingWindow)
                print("MenuBarManager: Reusing existing window")

                if self.mainWindow != existingWindow {
                    self.mainWindow = nil
                }
            } else {
                if let window = self.mainWindow, !window.isVisible {
                    self.mainWindow = nil
                }

                if self.mainWindow == nil {
                    self.mainWindow = self.createMainWindow()
                }

                if let window = self.mainWindow {
                    self.activateAppAndWindow(window)
                    print("MenuBarManager: Created new window")
                }
            }

            // Post navigation notification
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { [weak self] in
                guard self != nil else { return }
                NotificationCenter.default.post(
                    name: .navigateToDestination,
                    object: nil,
                    userInfo: ["destination": destination]
                )
                print("MenuBarManager: Posted navigation notification for \(destination)")
                
                // Don't reset activation policy while window is visible
                // This prevents other windows from coming to front
            }
        }
    }

    // MARK: - Helpers

    private func activateAppAndWindow(_ window: NSWindow) {
        // Set window level higher to ensure it appears on top
        window.level = .floating
        
        // Activate the application first
        NSApp.activate(ignoringOtherApps: true)
        NSApp.unhide(nil)
        
        // Then show and focus the window
        window.orderFrontRegardless()
        window.makeKeyAndOrderFront(nil)
        window.makeKey()
        
        // Reset window level after a brief delay to ensure it stays visible
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
            window.level = .normal
            window.makeFirstResponder(window.contentView)
            
            // Ensure window stays active even after policy changes
            NSApp.activate(ignoringOtherApps: true)
            window.makeKeyAndOrderFront(nil)
        }
    }

    private func findExistingMainWindow() -> NSWindow? {
        NSApp.windows.first { window in
            // Skip non-main windows (mini recorder, notch recorder, etc.)
            guard !window.title.contains("Recorder") && !window.title.contains("Debug") else { return false }
            guard window.isVisible && !window.isMiniaturized else { return false }
            
            // Check for ContentView in the window hierarchy (both SwiftUI and custom windows)
            return containsContentView(window.contentView)
        }
    }

    private func containsContentView(_ view: NSView?) -> Bool {
        guard let view = view else { return false }
        
        // Check if this view is a ContentView hosting view
        if view is NSHostingView<ContentView> { return true }
        
        // Check if this is a SwiftUI hosting view that contains ContentView
        if let hostingView = view as? NSHostingView<AnyView> { return true }
        if String(describing: type(of: view)).contains("NSHostingView") { return true }
        
        // Recursively check subviews
        return view.subviews.contains(where: containsContentView)
    }

    private func setupContentView() -> some View {
        ContentView()
            .environmentObject(whisperState)
            .environmentObject(hotkeyManager)
            .environmentObject(self)
            .environmentObject(enhancementService)
            .environmentObject(aiService)
            .environment(\.modelContext, ModelContext(container))
            .onDisappear { Task { await self.whisperState.unloadModel() } }
    }

    private func createMainWindow() -> NSWindow {
        print("MenuBarManager: Creating new main window")

        let contentView = setupContentView()
        let hostingView = NSHostingView(rootView: contentView)
        let window = WindowManager.shared.createMainWindow(contentView: hostingView)

        // Set delegate to self
        window.delegate = self

        print("MenuBarManager: Window setup complete")
        return window
    }
}

// MARK: - NSWindowDelegate

extension MenuBarManager: NSWindowDelegate {
    func windowWillClose(_ notification: Notification) {
        mainWindow = nil
        
        // Reset to accessory policy when window closes if in menu bar only mode
        if isMenuBarOnly {
            NSApp.setActivationPolicy(.accessory)
        }
        
        print("MenuBarManager: Main window closed")
    }
    
    func windowDidBecomeKey(_ notification: Notification) {
        // Don't activate app unnecessarily when window becomes key
        // This prevents dock icon from showing when not needed
        print("MenuBarManager: Window became key")
    }
}
