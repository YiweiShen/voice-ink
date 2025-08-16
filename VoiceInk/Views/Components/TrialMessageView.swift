import SwiftUI

// Deprecated: License checks removed - this view no longer displays
struct TrialMessageView: View {
    let message: String
    let type: MessageType
    var onAddLicenseKey: (() -> Void)? = nil
    
    enum MessageType {
        case warning
        case expired
        case info
    }
    
    var body: some View {
        // No longer show trial messages - always licensed
        EmptyView()
    }
    
    private var icon: String {
        switch type {
        case .warning: return "exclamationmark.triangle.fill"
        case .expired: return "xmark.circle.fill"
        case .info: return "info.circle.fill"
        }
    }
    
    private var iconColor: Color {
        switch type {
        case .warning: return .orange
        case .expired: return .red
        case .info: return .blue
        }
    }
    
    private var title: String {
        switch type {
        case .warning: return "Trial Ending Soon"
        case .expired: return "Trial Expired"
        case .info: return "Trial Active"
        }
    }
    
    private var backgroundColor: Color {
        switch type {
        case .warning: return Color.orange.opacity(0.1)
        case .expired: return Color.red.opacity(0.1)
        case .info: return Color.blue.opacity(0.1)
        }
    }
} 