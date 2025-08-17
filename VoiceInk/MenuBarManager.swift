import SwiftUI
import LaunchAtLogin
import SwiftData
import AppKit

class MenuBarManager: ObservableObject {
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
    
    init(whisperState: WhisperState, 
         container: ModelContainer,
         enhancementService: AIEnhancementService,
         aiService: AIService,
         hotkeyManager: HotkeyManager) {
        self.isMenuBarOnly = UserDefaults.standard.object(forKey: "IsMenuBarOnly") != nil ? UserDefaults.standard.bool(forKey: "IsMenuBarOnly") : true
        self.whisperState = whisperState
        self.container = container
        self.enhancementService = enhancementService
        self.aiService = aiService
        self.hotkeyManager = hotkeyManager
        updateAppActivationPolicy()
    }
    
    func toggleMenuBarOnly() {
        isMenuBarOnly.toggle()
    }
    
    private func updateAppActivationPolicy() {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            
            // Clean up existing window if switching to menu bar mode
            if self.isMenuBarOnly && self.mainWindow != nil {
                self.mainWindow?.close()
                self.mainWindow = nil
            }
            
            // Update activation policy
            if self.isMenuBarOnly {
                NSApp.setActivationPolicy(.accessory)
            } else {
                NSApp.setActivationPolicy(.regular)
            }
        }
    }
    
    func openMainWindowAndNavigate(to destination: String) {
        print("MenuBarManager: Navigating to \(destination)")
        
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            
            // Always set to regular when opening main window to ensure it shows
            NSApp.setActivationPolicy(.regular)
            
            // Activate the app and bring to front
            NSApp.activate(ignoringOtherApps: true)
            NSApp.unhide(nil)
            
            // Find any existing main content windows (including SwiftUI WindowGroup windows)
            let existingWindows = NSApp.windows.filter { window in
                // Check for main content windows by looking for ContentView in the hierarchy
                func hasContentView(in view: NSView?) -> Bool {
                    guard let view = view else { return false }
                    
                    // Check if it's a hosting view with ContentView
                    if view.className.contains("NSHostingView") {
                        return true
                    }
                    
                    // Recursively check subviews
                    for subview in view.subviews {
                        if hasContentView(in: subview) {
                            return true
                        }
                    }
                    return false
                }
                
                // Filter out recorder windows and other system windows
                guard window.title == "VoiceInk" && !window.title.contains("Recorder") else {
                    return false
                }
                
                // Check if this window contains ContentView
                return hasContentView(in: window.contentView)
            }
            
            if let existingWindow = existingWindows.first {
                // Use the existing window (whether SwiftUI WindowGroup or manually created)
                existingWindow.makeKeyAndOrderFront(nil)
                existingWindow.orderFrontRegardless()
                NSApp.activate(ignoringOtherApps: true)
                print("MenuBarManager: Reusing existing window")
                
                // Clear our stored reference if it's different
                if self.mainWindow != existingWindow {
                    self.mainWindow = nil
                }
            } else {
                // Clean up existing window if it's no longer valid
                if let existingWindow = self.mainWindow, !existingWindow.isVisible {
                    self.mainWindow = nil
                }
                
                // Get or create main window only if none exists
                if self.mainWindow == nil {
                    self.mainWindow = self.createMainWindow()
                }
                
                guard let window = self.mainWindow else { return }
                
                // Make the window key and order front
                window.makeKeyAndOrderFront(nil)
                window.center()
                window.orderFrontRegardless()
                NSApp.activate(ignoringOtherApps: true)
                print("MenuBarManager: Created new window")
            }
            
            // Post a notification to navigate to the desired destination
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                NotificationCenter.default.post(
                    name: .navigateToDestination,
                    object: nil,
                    userInfo: ["destination": destination]
                )
                print("MenuBarManager: Posted navigation notification for \(destination)")
            }
        }
    }
    
    private func createMainWindow() -> NSWindow {
        print("MenuBarManager: Creating new main window")
        
        // Create the content view with all required environment objects
        let contentView = ContentView()
            .environmentObject(whisperState)
            .environmentObject(hotkeyManager)
            .environmentObject(self)
            .environmentObject(enhancementService)
            .environmentObject(aiService)
            .environment(\.modelContext, ModelContext(container))
            .onDisappear {
                Task {
                    await self.whisperState.unloadModel()
                }
            }
        
        // Create window using WindowManager
        let hostingView = NSHostingView(rootView: contentView)
        let window = WindowManager.shared.createMainWindow(contentView: hostingView)
        
        // Set window delegate to handle window closing
        let delegate = WindowDelegate { [weak self] in
            self?.mainWindow = nil
        }
        window.delegate = delegate
        
        print("MenuBarManager: Window setup complete")
        
        return window
    }
}

// Window delegate to handle window closing
class WindowDelegate: NSObject, NSWindowDelegate {
    let onClose: () -> Void
    
    init(onClose: @escaping () -> Void) {
        self.onClose = onClose
        super.init()
    }
    
    func windowWillClose(_ notification: Notification) {
        onClose()
    }
}

