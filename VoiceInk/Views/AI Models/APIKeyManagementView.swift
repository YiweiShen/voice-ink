import SwiftUI

struct APIKeyManagementView: View {
    @EnvironmentObject private var aiService: AIService
    @State private var showAlert = false
    @State private var alertMessage = ""
    @State private var ollamaBaseURL: String = UserDefaults.standard.string(forKey: "ollamaBaseURL") ?? "http://localhost:11434"
    @State private var ollamaModels: [OllamaService.OllamaModel] = []
    @State private var selectedOllamaModel: String = UserDefaults.standard.string(forKey: "ollamaSelectedModel") ?? "mistral"
    @State private var isCheckingOllama = false
    @State private var isEditingURL = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header Section
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Enhance your transcriptions with AI")
                        .font(.headline)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
            }
            
            // Provider Selection - Only Ollama is available
            HStack {
                Text("AI Provider:")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                Spacer()
                Text("Ollama (Local AI)")
                    .font(.subheadline)
                    .bold()
            }
            
            // Ollama Configuration
            VStack(alignment: .leading, spacing: 16) {
                    // Header with status
                    HStack {
                        Label("Ollama Configuration", systemImage: "server.rack")
                            .font(.headline)
                        
                        Spacer()
                        
                        HStack(spacing: 6) {
                            Circle()
                                .fill(isCheckingOllama ? Color.orange : (ollamaModels.isEmpty ? Color.red : Color.green))
                                .frame(width: 8, height: 8)
                            Text(isCheckingOllama ? "Checking..." : (ollamaModels.isEmpty ? "Disconnected" : "Connected"))
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.secondary.opacity(0.1))
                        .cornerRadius(6)
                    }
                    
                    // Server URL
                    HStack {
                        Label("Server URL", systemImage: "link")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        
                        Spacer()
                        
                        if isEditingURL {
                            TextField("Base URL", text: $ollamaBaseURL)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                                .frame(maxWidth: 200)
                            
                            Button("Save") {
                                aiService.updateOllamaBaseURL(ollamaBaseURL)
                                checkOllamaConnection()
                                isEditingURL = false
                            }
                            .buttonStyle(.bordered)
                            .controlSize(.small)
                        } else {
                            Text(ollamaBaseURL)
                                .font(.system(.body, design: .monospaced))
                                .foregroundColor(.primary)
                            
                            Button(action: { isEditingURL = true }) {
                                Image(systemName: "pencil")
                            }
                            .buttonStyle(.borderless)
                            .controlSize(.small)
                            
                            Button(action: {
                                ollamaBaseURL = "http://localhost:11434"
                                aiService.updateOllamaBaseURL(ollamaBaseURL)
                                checkOllamaConnection()
                            }) {
                                Image(systemName: "arrow.counterclockwise")
                            }
                            .buttonStyle(.borderless)
                            .foregroundColor(.secondary)
                            .controlSize(.small)
                        }
                    }
                    
                    // Model selection and refresh
                    HStack {
                        Label("Model", systemImage: "cpu")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        
                        Spacer()
                        
                        if ollamaModels.isEmpty {
                            HStack(spacing: 8) {
                                Image(systemName: "exclamationmark.triangle.fill")
                                    .foregroundColor(.orange)
                                Text("No models available")
                                    .foregroundColor(.secondary)
                                    .italic()
                            }
                        } else {
                            Picker("", selection: $selectedOllamaModel) {
                                ForEach(ollamaModels) { model in
                                    Text(model.name).tag(model.name)
                                }
                            }
                            .onChange(of: selectedOllamaModel) { oldValue, newValue in
                                aiService.updateSelectedOllamaModel(newValue)
                            }
                            .labelsHidden()
                            .frame(maxWidth: 150)
                        }
                        
                        Button(action: { checkOllamaConnection() }) {
                            Label(isCheckingOllama ? "Refreshing..." : "Refresh", systemImage: isCheckingOllama ? "arrow.triangle.2.circlepath" : "arrow.clockwise")
                                .font(.caption)
                        }
                        .disabled(isCheckingOllama)
                        .buttonStyle(.bordered)
                        .controlSize(.small)
                    }
                    
                    // Help text for troubleshooting
                    if ollamaModels.isEmpty {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Troubleshooting")
                                .font(.subheadline)
                                .bold()
                            
                            VStack(alignment: .leading, spacing: 4) {
                                bulletPoint("Ensure Ollama is installed and running")
                                bulletPoint("Check if the server URL is correct")
                                bulletPoint("Verify you have at least one model pulled")
                            }
                            
                            Button("Learn More") {
                                NSWorkspace.shared.open(URL(string: "https://ollama.ai/download")!)
                            }
                            .font(.caption)
                        }
                        .padding(12)
                        .background(Color.secondary.opacity(0.05))
                        .cornerRadius(8)
                    }
                }
                .padding()
                .background(Color.secondary.opacity(0.03))
                .cornerRadius(12)
        }
        .padding()
        .alert("Error", isPresented: $showAlert) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(alertMessage)
        }
        .onAppear {
            checkOllamaConnection()
        }
    }
    
    private func checkOllamaConnection() {
        isCheckingOllama = true
        aiService.checkOllamaConnection { connected in
            if connected {
                Task {
                    ollamaModels = await aiService.fetchOllamaModels()
                    isCheckingOllama = false
                }
            } else {
                ollamaModels = []
                isCheckingOllama = false
                alertMessage = "Could not connect to Ollama. Please check if Ollama is running and the base URL is correct."
                showAlert = true
            }
        }
    }
    
    private func bulletPoint(_ text: String) -> some View {
        HStack(alignment: .top, spacing: 4) {
            Text("•")
            Text(text)
        }
    }
    
    private func formatSize(_ bytes: Int64) -> String {
        let gigabytes = Double(bytes) / 1_000_000_000
        return String(format: "%.1f GB", gigabytes)
    }
}
