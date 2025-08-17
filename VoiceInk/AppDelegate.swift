import Cocoa
import SwiftUI

class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationDidFinishLaunching(_ notification: Notification) {
        // Default to menu bar only mode on first launch
        if UserDefaults.standard.object(forKey: "IsMenuBarOnly") == nil {
            UserDefaults.standard.set(true, forKey: "IsMenuBarOnly")
        }
        updateActivationPolicy()
        cleanupLegacyUserDefaults()
    }

    func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
        updateActivationPolicy()
        
        if !flag {
            createMainWindowIfNeeded()
        }
        return true
    }
    
    func applicationDidBecomeActive(_ notification: Notification) {
        updateActivationPolicy()
    }
    
    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        return false
    }
    
    func applicationShouldTerminate(_ sender: NSApplication) -> NSApplication.TerminateReply {
        // Allow normal Command+Q termination
        return .terminateNow
    }
    
    private func updateActivationPolicy() {
        let isMenuBarOnly = UserDefaults.standard.object(forKey: "IsMenuBarOnly") != nil ? UserDefaults.standard.bool(forKey: "IsMenuBarOnly") : false
        if isMenuBarOnly {
            NSApp.setActivationPolicy(.accessory)
        } else {
            NSApp.setActivationPolicy(.regular)
        }
    }
    
    private func createMainWindowIfNeeded() {
        // Find existing main windows first
        let existingWindows = NSApp.windows.filter { window in
            window.title == "VoiceInk" && !window.title.contains("Recorder")
        }
        
        if let existingWindow = existingWindows.first {
            existingWindow.makeKeyAndOrderFront(nil)
            NSApp.activate(ignoringOtherApps: true)
        } else {
            // Need to get the app's shared services to create a proper window
            // This will be handled by the MenuBarManager when it creates windows
            // For now, just ensure the activation policy is correct
            NSApp.setActivationPolicy(.regular)
            NSApp.activate(ignoringOtherApps: true)
        }
    }

    private func cleanupLegacyUserDefaults() {
        let defaults = UserDefaults.standard
        // Clean up Power Mode related settings
        defaults.removeObject(forKey: "defaultPowerModeConfigV2")
        defaults.removeObject(forKey: "isPowerModeEnabled")
        defaults.removeObject(forKey: "powerModeConfigurations")
        defaults.removeObject(forKey: "activePowerModeConfiguration")
    }
}
