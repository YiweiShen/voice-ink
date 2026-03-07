import SwiftUI
import AppKit

// MARK: - Cloud Model Card View
struct CloudModelCardView: View {
    let model: CloudModel
    let isCurrent: Bool
    var setDefaultAction: () -> Void
    
    @EnvironmentObject private var whisperState: WhisperState
    @StateObject private var aiService = AIService()
    @State private var isExpanded = false
    @State private var apiKey = ""
    @State private var isVerifying = false
    @State private var verificationStatus: VerificationStatus = .none
    @State private var isConfiguredState: Bool = false
    
    enum VerificationStatus {
        case none, verifying, success, failure
    }
    
    private var isConfigured: Bool {
        guard let savedKey = UserDefaults.standard.string(forKey: "\(providerKey)APIKey") else {
            return false
        }
        return !savedKey.isEmpty
    }
    
    private var providerKey: String {
        switch model.provider {
        case .groq:
            return "GROQ"
        case .deepgram:
            return "Deepgram"
        default:
            return model.provider.rawValue
        }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(spacing: 10) {
                VStack(alignment: .leading, spacing: 3) {
                    HStack(spacing: 6) {
                        Text(model.displayName)
                            .font(.system(size: 13, weight: .medium))
                            .foregroundColor(Color(.labelColor))
                        statusBadge
                    }
                    Text("\(model.provider.rawValue) · \(model.language) · Cloud")
                        .font(.system(size: 11))
                        .foregroundColor(Color(.tertiaryLabelColor))
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                actionSection
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 10)

            if isExpanded {
                Divider()
                configurationSection
                    .padding(14)
            }
        }
        .background(CardBackground(isSelected: isCurrent, useAccentGradientWhenSelected: isCurrent))
        .onAppear {
            loadSavedAPIKey()
            isConfiguredState = isConfigured
        }
    }

    private var statusBadge: some View {
        Group {
            if isCurrent {
                Text("Default")
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundColor(.accentColor)
                    .padding(.horizontal, 5)
                    .padding(.vertical, 1)
                    .background(RoundedRectangle(cornerRadius: 3).fill(Color.accentColor.opacity(0.1)))
            } else if isConfiguredState {
                Text("Configured")
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundColor(Color(.systemGreen))
                    .padding(.horizontal, 5)
                    .padding(.vertical, 1)
                    .background(RoundedRectangle(cornerRadius: 3).fill(Color(.systemGreen).opacity(0.1)))
            } else {
                Text("Setup Required")
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundColor(Color(.systemOrange))
                    .padding(.horizontal, 5)
                    .padding(.vertical, 1)
                    .background(RoundedRectangle(cornerRadius: 3).fill(Color(.systemOrange).opacity(0.1)))
            }
        }
    }

    private var actionSection: some View {
        HStack(spacing: 6) {
            if isConfiguredState && !isCurrent {
                Button(action: setDefaultAction) {
                    Text("Set Default")
                        .font(.system(size: 12))
                }
                .buttonStyle(.bordered)
                .controlSize(.small)
            } else if !isConfiguredState {
                Button(action: {
                    withAnimation(.interpolatingSpring(stiffness: 170, damping: 20)) {
                        isExpanded.toggle()
                    }
                }) {
                    Label("Configure", systemImage: "gear")
                        .font(.system(size: 12))
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.small)
            }

            if isConfiguredState {
                Menu {
                    Button { clearAPIKey() } label: {
                        Label("Remove API Key", systemImage: "trash")
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                        .font(.system(size: 14))
                        .foregroundColor(Color.primary.opacity(0.4))
                }
                .menuStyle(.borderlessButton)
                .menuIndicator(.hidden)
                .frame(width: 20, height: 20)
            }
        }
    }

    private var configurationSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("API Key")
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(Color(.labelColor))

            HStack(spacing: 8) {
                SecureField("Enter your \(model.provider.rawValue) API key", text: $apiKey)
                    .textFieldStyle(.roundedBorder)
                    .disabled(isVerifying)

                Button(action: verifyAPIKey) {
                    HStack(spacing: 4) {
                        if isVerifying {
                            ProgressView().scaleEffect(0.7).frame(width: 12, height: 12)
                        } else {
                            Image(systemName: verificationStatus == .success ? "checkmark" : "checkmark.shield")
                                .font(.system(size: 12))
                        }
                        Text(isVerifying ? "Verifying…" : "Verify")
                            .font(.system(size: 12))
                    }
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.regular)
                .disabled(apiKey.isEmpty || isVerifying)
            }

            if verificationStatus == .failure {
                Text("Invalid API key. Please check and try again.")
                    .font(.system(size: 11))
                    .foregroundColor(Color(.systemRed))
            } else if verificationStatus == .success {
                Text("API key verified.")
                    .font(.system(size: 11))
                    .foregroundColor(Color(.systemGreen))
            }
        }
    }
    
    private func loadSavedAPIKey() {
        if let savedKey = UserDefaults.standard.string(forKey: "\(providerKey)APIKey") {
            apiKey = savedKey
            verificationStatus = .success
        }
    }
    
    private func verifyAPIKey() {
        guard !apiKey.isEmpty else { return }
        
        isVerifying = true
        verificationStatus = .verifying
        
        // Cloud models are no longer supported - all should use Ollama
        print("Warning: Cloud models are no longer supported. Please use Ollama instead.")
        isVerifying = false
        verificationStatus = .failure
        return
    }
    
    private func clearAPIKey() {
        UserDefaults.standard.removeObject(forKey: "\(providerKey)APIKey")
        apiKey = ""
        verificationStatus = .none
        isConfiguredState = false
        
        // If this model is currently the default, clear it
        if isCurrent {
            Task {
                await MainActor.run {
                    whisperState.currentTranscriptionModel = nil
                    UserDefaults.standard.removeObject(forKey: "CurrentTranscriptionModel")
                }
            }
        }
        
        withAnimation(.easeInOut(duration: 0.3)) {
            isExpanded = false
        }
    }
}
