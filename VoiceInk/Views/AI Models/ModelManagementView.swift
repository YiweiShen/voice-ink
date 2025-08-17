import SwiftUI
import SwiftData
import AppKit
import UniformTypeIdentifiers


struct ModelManagementView: View {
    @ObservedObject var whisperState: WhisperState
    @State private var customModelToEdit: CustomCloudModel?
    @StateObject private var aiService = AIService()
    @StateObject private var customModelManager = CustomModelManager.shared
    @EnvironmentObject private var enhancementService: AIEnhancementService
    @Environment(\.modelContext) private var modelContext
    @StateObject private var whisperPrompt = WhisperPrompt()
    
    // Settings toggles moved from ModelSettingsView
    @AppStorage("IsTextFormattingEnabled") private var isTextFormattingEnabled = true
    @AppStorage("IsVADEnabled") private var isVADEnabled = true

    @State private var isShowingSettings = false
    
    // State for the unified alert
    @State private var isShowingDeleteAlert = false
    @State private var alertTitle = ""
    @State private var alertMessage = ""
    @State private var deleteActionClosure: () -> Void = {}

    var body: some View {
        ScrollViewReader { proxy in
            ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                defaultModelSection
                outputFormatSection
                settingsTogglesSection
                modelsActionButtonsSection(proxy: proxy)
                unifiedModelsSection
            }
            .padding(40)
            }
        }
        .frame(minWidth: 600, minHeight: 500)
        .background(Color(NSColor.controlBackgroundColor))
        .alert(isPresented: $isShowingDeleteAlert) {
            Alert(
                title: Text(alertTitle),
                message: Text(alertMessage),
                primaryButton: .destructive(Text("Delete"), action: deleteActionClosure),
                secondaryButton: .cancel()
            )
        }
    }
    
    private var defaultModelSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Default AI Model")
                .font(.largeTitle)
                .fontWeight(.bold)
                .foregroundColor(.primary)
            
            VStack(alignment: .leading, spacing: 8) {
                Text("Default Model")
                    .font(.headline)
                    .foregroundColor(.secondary)
                Text(whisperState.currentTranscriptionModel?.displayName ?? "Large V3 Turbo (Recommended)")
                    .font(.title2)
                    .fontWeight(.semibold)
            }
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(CardBackground(isSelected: false))
        .cornerRadius(10)
    }
    
    private var outputFormatSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Transcription Style")
                    .font(.headline)
                
                InfoTip(
                    title: "Transcription Style Guide",
                    message: "Voice recognition models follow the style of your examples rather than instructions. Write examples of how you want your text formatted instead of giving commands.",
                    learnMoreURL: "https://cookbook.openai.com/examples/whisper_prompting_guide#comparison-with-gpt-prompting"
                )
                
                Spacer()
                
                Button(action: {
                    if isShowingSettings {
                        // Save changes
                        whisperPrompt.setCustomPrompt(whisperPrompt.getLanguagePrompt(for: "auto"), for: "auto")
                        isShowingSettings = false
                    } else {
                        // Enter edit mode
                        isShowingSettings = true
                    }
                }) {
                    Text(isShowingSettings ? "Save" : "Edit")
                        .font(.caption)
                }
            }
            
            if isShowingSettings {
                TextEditor(text: .constant(whisperPrompt.getLanguagePrompt(for: "auto")))
                    .font(.system(size: 12))
                    .padding(8)
                    .frame(height: 80)
                    .overlay(
                        RoundedRectangle(cornerRadius: 6)
                            .stroke(Color.secondary.opacity(0.2), lineWidth: 1)
                    )
                
            } else {
                Text(whisperPrompt.getLanguagePrompt(for: "auto"))
                    .font(.system(size: 12))
                    .foregroundColor(.secondary)
                    .padding(8)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(
                        RoundedRectangle(cornerRadius: 6)
                            .fill(Color(.windowBackgroundColor).opacity(0.4))
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 6)
                            .stroke(Color.secondary.opacity(0.2), lineWidth: 1)
                    )
            }
        }
        .padding()
        .background(CardBackground(isSelected: false))
        .cornerRadius(10)
    }
    
    private var settingsTogglesSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Toggle(isOn: $isTextFormattingEnabled) {
                    Text("Smart text formatting")
                        .font(.system(size: 15, weight: .medium))
                }
                .toggleStyle(.switch)
                
                InfoTip(
                    title: "Smart Text Formatting",
                    message: "Automatically breaks up long text into readable paragraphs and improves formatting."
                )
                
                Spacer()
            }

            HStack {
                Toggle(isOn: $isVADEnabled) {
                    Text("Background noise filtering")
                        .font(.system(size: 15, weight: .medium))
                }
                .toggleStyle(.switch)
                
                InfoTip(
                    title: "Background Noise Filtering",
                    message: "Automatically detects when you're speaking and filters out background noise and silence for more accurate transcription."
                )
                
                Spacer()
            }
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(CardBackground(isSelected: false))
        .cornerRadius(10)
    }
    
    private func modelsActionButtonsSection(proxy: ScrollViewProxy) -> some View {
        HStack(spacing: 12) {
            Button(action: { presentImportPanel() }) {
                HStack(spacing: 8) {
                    Image(systemName: "plus")
                        .font(.system(size: 14, weight: .medium))
                    Text("Import Local Model")
                        .font(.system(size: 14, weight: .semibold))
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(Color.accentColor)
                .cornerRadius(12)
            }
            .buttonStyle(.plain)
            
            Button(action: { 
                withAnimation(.easeInOut(duration: 0.5)) {
                    proxy.scrollTo("addModelCard", anchor: .center)
                }
            }) {
                HStack(spacing: 8) {
                    Image(systemName: "plus")
                        .font(.system(size: 14, weight: .medium))
                    Text("Add Cloud Model")
                        .font(.system(size: 14, weight: .semibold))
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(Color.accentColor)
                .cornerRadius(12)
            }
            .buttonStyle(.plain)
        }
    }
    
    private var unifiedModelsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Available Models")
                .font(.headline)
                .foregroundColor(.primary)
                .padding(.bottom, 12)
                VStack(spacing: 20) {
                    // Local Models Section
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Text("Local & Native Models")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(.primary)
                            Spacer()
                        }
                        
                        ForEach(localModels, id: \.id) { model in
                            ModelCardRowView(
                                model: model,
                                whisperState: whisperState, 
                                isDownloaded: whisperState.availableModels.contains { $0.name == model.name },
                                isCurrent: whisperState.currentTranscriptionModel?.name == model.name,
                                downloadProgress: whisperState.downloadProgress,
                                modelURL: whisperState.availableModels.first { $0.name == model.name }?.url,
                                deleteAction: {
                                    if let downloadedModel = whisperState.availableModels.first(where: { $0.name == model.name }) {
                                        alertTitle = "Delete Model"
                                        alertMessage = "Are you sure you want to delete the model '\(downloadedModel.name)'?"
                                        deleteActionClosure = {
                                            Task {
                                                await whisperState.deleteModel(downloadedModel)
                                            }
                                        }
                                        isShowingDeleteAlert = true
                                    }
                                },
                                setDefaultAction: {
                                    Task {
                                        await whisperState.setDefaultTranscriptionModel(model)
                                    }
                                },
                                downloadAction: {
                                    if let localModel = model as? LocalModel {
                                        Task { await whisperState.downloadModel(localModel) }
                                    }
                                }
                            )
                        }
                    }
                    
                    Divider()
                    
                    // Custom Cloud Models Section
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Text("Cloud Models (OpenAI Compatible)")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(.primary)
                            Spacer()
                        }
                        
                        ForEach(customModels, id: \.id) { model in
                            ModelCardRowView(
                                model: model,
                                whisperState: whisperState, 
                                isDownloaded: true, // Cloud models are always "available"
                                isCurrent: whisperState.currentTranscriptionModel?.name == model.name,
                                downloadProgress: whisperState.downloadProgress,
                                modelURL: nil,
                                deleteAction: {
                                    if let customModel = model as? CustomCloudModel {
                                        alertTitle = "Delete Custom Model"
                                        alertMessage = "Are you sure you want to delete the custom model '\(customModel.displayName)'?"
                                        deleteActionClosure = {
                                            customModelManager.removeCustomModel(withId: customModel.id)
                                            whisperState.refreshAllAvailableModels()
                                        }
                                        isShowingDeleteAlert = true
                                    }
                                },
                                setDefaultAction: {
                                    Task {
                                        await whisperState.setDefaultTranscriptionModel(model)
                                    }
                                },
                                downloadAction: {},
                                editAction: { customModel in
                                    customModelToEdit = customModel
                                }
                            )
                        }
                        
                        // Add Custom Model Card
                        AddCustomModelCardView(
                            customModelManager: customModelManager,
                            editingModel: customModelToEdit
                        ) {
                            // Refresh the models when a new custom model is added
                            whisperState.refreshAllAvailableModels()
                            customModelToEdit = nil // Clear editing state
                        }
                        .id("addModelCard")
                    }
                }
            }
            .padding()
        }
    
    private var localModels: [any TranscriptionModel] {
        return whisperState.allAvailableModels.filter { model in
            model.provider == .local ||
            model.provider == .nativeApple ||
            model.provider == .parakeet
        }
    }
    
    private var customModels: [any TranscriptionModel] {
        return whisperState.allAvailableModels.filter { $0.provider == .custom }
    }

    // MARK: - Import Panel
    private func presentImportPanel() {
        let panel = NSOpenPanel()
        panel.allowedContentTypes = [.init(filenameExtension: "bin")!]
        panel.allowsMultipleSelection = false
        panel.canChooseDirectories = false
        panel.resolvesAliases = true
        panel.title = "Select a Whisper ggml .bin model"
        if panel.runModal() == .OK, let url = panel.url {
            Task { @MainActor in
                await whisperState.importLocalModel(from: url)
            }
        }
    }
}
