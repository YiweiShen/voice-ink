import SwiftUI

struct AddCustomModelCardView: View {
    @ObservedObject var customModelManager: CustomModelManager
    var onModelAdded: () -> Void
    var editingModel: CustomCloudModel? = nil
    @Binding var forceExpanded: Bool
    
    @State private var isExpanded = false
    @State private var displayName = ""
    @State private var apiEndpoint = ""
    @State private var apiKey = ""
    @State private var modelName = ""
    @State private var isMultilingual = true
    
    @State private var validationErrors: [String] = []
    @State private var showingAlert = false
    @State private var isSaving = false
    
    var body: some View {
        VStack(spacing: 0) {
            // Expandable Form Section
            if isExpanded {
                VStack(alignment: .leading, spacing: 20) {
                    // Header
                    HStack {
                        Text(editingModel != nil ? "Edit Custom Model" : "Add Custom Model")
                            .font(.headline)
                            .foregroundColor(.primary)
                        
                        Spacer()
                        
                        Button(action: {
                            withAnimation(.interpolatingSpring(stiffness: 170, damping: 20)) {
                                isExpanded = false
                                forceExpanded = false
                                clearForm()
                            }
                        }) {
                            Image(systemName: "xmark")
                                .font(.system(size: 12, weight: .medium))
                                .foregroundColor(.secondary)
                        }
                        .buttonStyle(.plain)
                    }
                    
                    // Disclaimer
                    HStack(spacing: 6) {
                        Image(systemName: "info.circle")
                            .font(.system(size: 11))
                            .foregroundColor(Color.primary.opacity(0.4))
                        Text("Only OpenAI-compatible transcription APIs are supported")
                            .font(.system(size: 12))
                            .foregroundColor(.secondary)
                    }
                    .padding(.horizontal, 10)
                    .padding(.vertical, 7)
                    .background(Color.primary.opacity(0.04))
                    .cornerRadius(6)
                    
                    // Form fields
                    VStack(alignment: .leading, spacing: 16) {
                        FormField(title: "Display Name", text: $displayName, placeholder: "My Custom Model")
                        FormField(title: "API Endpoint", text: $apiEndpoint, placeholder: "https://api.example.com/v1/audio/transcriptions")
                        FormField(title: "API Key", text: $apiKey, placeholder: "your-api-key", isSecure: true)
                        FormField(title: "Model Name", text: $modelName, placeholder: "whisper-1")
                        
                        Toggle("Multilingual Model", isOn: $isMultilingual)
                    }
                    
                    // Action buttons
                    HStack(spacing: 12) {
                        Button(action: {
                            withAnimation(.interpolatingSpring(stiffness: 170, damping: 20)) {
                                isExpanded = false
                                forceExpanded = false
                                clearForm()
                            }
                        }) {
                            Text("Cancel")
                                .font(.system(size: 13, weight: .medium))
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.bordered)
                        .controlSize(.regular)
                        
                        Button(action: { addModel() }) {
                            HStack(spacing: 6) {
                                if isSaving {
                                    ProgressView().controlSize(.small)
                                } else {
                                    Image(systemName: editingModel != nil ? "checkmark.circle" : "plus.circle")
                                        .font(.system(size: 13))
                                }
                                Text(editingModel != nil ? "Update Model" : "Add Model")
                                    .font(.system(size: 13, weight: .medium))
                            }
                            .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.borderedProminent)
                        .controlSize(.regular)
                        .disabled(!isFormValid || isSaving)
                    }
                }
                .padding(16)
                .background(CardBackground(isSelected: false))
            }
        }
        .alert("Validation Errors", isPresented: $showingAlert) {
            Button("OK") { }
        } message: {
            Text(validationErrors.joined(separator: "\n"))
        }
        .onChange(of: editingModel) { oldValue, newValue in
            if newValue != nil {
                withAnimation(.interpolatingSpring(stiffness: 170, damping: 20)) {
                    isExpanded = true
                    // Pre-fill values from editing model
                    if let editing = newValue {
                        displayName = editing.displayName
                        apiEndpoint = editing.apiEndpoint
                        apiKey = editing.apiKey
                        modelName = editing.modelName
                        isMultilingual = editing.isMultilingualModel
                    }
                }
            }
        }
        .onChange(of: forceExpanded) { oldValue, newValue in
            if newValue && !isExpanded {
                withAnimation(.interpolatingSpring(stiffness: 170, damping: 20)) {
                    isExpanded = true
                    // Pre-fill some default values when adding new
                    if apiEndpoint.isEmpty {
                        apiEndpoint = "https://api.example.com/v1/audio/transcriptions"
                    }
                    if modelName.isEmpty {
                        modelName = "large-v3-turbo"
                    }
                }
            }
        }
    }
    
    private var isFormValid: Bool {
        !displayName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        !apiEndpoint.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        !apiKey.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        !modelName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
    
    private func clearForm() {
        displayName = ""
        apiEndpoint = ""
        apiKey = ""
        modelName = ""
        isMultilingual = true
    }
    
    private func addModel() {
        let trimmedDisplayName = displayName.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedApiEndpoint = apiEndpoint.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedApiKey = apiKey.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedModelName = modelName.trimmingCharacters(in: .whitespacesAndNewlines)
        
        // Generate a name from display name (lowercase, no spaces)
        let generatedName = trimmedDisplayName.lowercased().replacingOccurrences(of: " ", with: "-")
        
        validationErrors = customModelManager.validateModel(
            name: generatedName,
            displayName: trimmedDisplayName,
            apiEndpoint: trimmedApiEndpoint,
            apiKey: trimmedApiKey,
            modelName: trimmedModelName,
            excludingId: editingModel?.id
        )
        
        if !validationErrors.isEmpty {
            showingAlert = true
            return
        }
        
        isSaving = true
        
        // Simulate a brief save operation for better UX
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            if let editing = editingModel {
                // Update existing model
                let updatedModel = CustomCloudModel(
                    id: editing.id,
                    name: generatedName,
                    displayName: trimmedDisplayName,
                    description: "Custom transcription model",
                    apiEndpoint: trimmedApiEndpoint,
                    apiKey: trimmedApiKey,
                    modelName: trimmedModelName,
                    isMultilingual: isMultilingual
                )
                customModelManager.updateCustomModel(updatedModel)
            } else {
                // Add new model
                let customModel = CustomCloudModel(
                    name: generatedName,
                    displayName: trimmedDisplayName,
                    description: "Custom transcription model",
                    apiEndpoint: trimmedApiEndpoint,
                    apiKey: trimmedApiKey,
                    modelName: trimmedModelName,
                    isMultilingual: isMultilingual
                )
                customModelManager.addCustomModel(customModel)
            }
            
            onModelAdded()
            
            // Reset form and collapse
            withAnimation(.interpolatingSpring(stiffness: 170, damping: 20)) {
                isExpanded = false
                forceExpanded = false
                clearForm()
                isSaving = false
            }
        }
    }
}

struct FormField: View {
    let title: String
    @Binding var text: String
    let placeholder: String
    var isSecure: Bool = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundColor(.primary)
            
            if isSecure {
                SecureField(placeholder, text: $text)
                    .textFieldStyle(.roundedBorder)
            } else {
                TextField(placeholder, text: $text)
                    .textFieldStyle(.roundedBorder)
            }
        }
    }
} 