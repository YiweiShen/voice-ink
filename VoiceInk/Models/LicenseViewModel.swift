import Foundation
import AppKit

@MainActor
class LicenseViewModel: ObservableObject {
    enum LicenseState: Equatable {
        case licensed
    }
    
    @Published private(set) var licenseState: LicenseState = .licensed
    @Published var licenseKey: String = ""
    @Published var isValidating = false
    @Published var validationMessage: String?
    @Published private(set) var activationsLimit: Int = 0
    
    private let userDefaults = UserDefaults.standard
    
    init() {
        licenseState = .licensed
    }
    
    // No-op functions for compatibility
    func startTrial() {
        // Always licensed, no trial needed
    }
    
    var canUseApp: Bool {
        return true
    }
    
    func openPurchaseLink() {
        if let url = URL(string: "https://tryvoiceink.com/buy") {
            NSWorkspace.shared.open(url)
        }
    }
    
    func validateLicense() async {
        // Always validate successfully
        isValidating = true
        licenseState = .licensed
        validationMessage = "License activated successfully!"
        NotificationCenter.default.post(name: .licenseStatusChanged, object: nil)
        isValidating = false
    }
    
    func removeLicense() {
        // No-op - always licensed
        licenseState = .licensed
        validationMessage = nil
        NotificationCenter.default.post(name: .licenseStatusChanged, object: nil)
    }
}


// Add UserDefaults extensions for storing activation ID
extension UserDefaults {
    var activationId: String? {
        get { string(forKey: "VoiceInkActivationId") }
        set { set(newValue, forKey: "VoiceInkActivationId") }
    }
}
