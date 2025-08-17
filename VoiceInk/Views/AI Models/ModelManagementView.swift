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
    @State private var expandAddCloudModel = false

    // State for the unified alert
    @State private var isShowingDeleteAlert = false
    @State private var alertTitle = ""
    @State private var alertMessage = ""
    @State private var deleteActionClosure: () -> Void = {}

    var body: some View {
        ScrollViewReader { proxy in
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    // Section 1: Local & Native Models (with import button)
                    localModelsSection(proxy: proxy)
                    
                    // Section 2: Cloud Models (with add button)
                    cloudModelsSection(proxy: proxy)
                    
                    // Section 3: Other Configurations
                    otherConfigurationsSection
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 6)
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

    private var otherConfigurationsSection: some View {
        SettingsSection(
            icon: "gearshape.fill",
            title: "Transcription Configuration",
            subtitle: "Customize transcription style, formatting, and processing options"
        ) {
            VStack(alignment: .leading, spacing: 20) {
                // Transcription Style Section
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Text("Start Text & Style Examples")
                            .font(.system(size: 15, weight: .medium))
                            .foregroundColor(.primary)

                        InfoTip(
                            title: "Transcription Style Guide",
                            message: "Voice recognition models follow the style of your examples rather than instructions. Write examples of how you want your text formatted instead of giving commands.",
                            learnMoreURL: "https://cookbook.openai.com/examples/whisper_prompting_guide#comparison-with-gpt-prompting"
                        )

                        Spacer()

                        Button(action: {
                            if isShowingSettings {
                                whisperPrompt.setCustomPrompt(whisperPrompt.getLanguagePrompt(for: "auto"), for: "auto")
                                isShowingSettings = false
                            } else {
                                isShowingSettings = true
                            }
                        }) {
                            Text(isShowingSettings ? "Save" : "Edit")
                                .font(.system(size: 13, weight: .medium))
                                .foregroundColor(.accentColor)
                        }
                        .buttonStyle(.plain)
                    }

                    if isShowingSettings {
                        TextEditor(text: .constant(whisperPrompt.getLanguagePrompt(for: "auto")))
                            .font(.system(size: 12, design: .monospaced))
                            .padding(8)
                            .frame(height: 80)
                            .background(Color(.textBackgroundColor))
                            .overlay(
                                RoundedRectangle(cornerRadius: 6)
                                    .stroke(Color.secondary.opacity(0.3), lineWidth: 1)
                            )
                    } else {
                        Text(whisperPrompt.getLanguagePrompt(for: "auto"))
                            .font(.system(size: 12, design: .monospaced))
                            .foregroundColor(.secondary)
                            .padding(8)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(Color(.controlBackgroundColor))
                            .overlay(
                                RoundedRectangle(cornerRadius: 6)
                                    .stroke(Color.secondary.opacity(0.2), lineWidth: 1)
                            )
                    }
                }
                
                Divider()
                
                // Processing Options Section
                VStack(alignment: .leading, spacing: 16) {
                    Text("Processing Options")
                        .font(.system(size: 15, weight: .medium))
                        .foregroundColor(.primary)
                    
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Toggle(isOn: $isTextFormattingEnabled) {
                                Text("Smart text formatting")
                                    .font(.system(size: 14))
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
                                    .font(.system(size: 14))
                            }
                            .toggleStyle(.switch)

                            InfoTip(
                                title: "Background Noise Filtering",
                                message: "Automatically detects when you're speaking and filters out background noise and silence for more accurate transcription."
                            )

                            Spacer()
                        }
                    }
                }
            }
        }
    }


    private func localModelsSection(proxy: ScrollViewProxy) -> some View {
        SettingsSection(
            icon: "cpu.fill",
            title: "Local & Native Models",
            subtitle: "Models that run on your device for maximum privacy"
        ) {
            VStack(alignment: .leading, spacing: 16) {
                Text("These models run directly on your Mac without sending data to external servers.")
                    .settingsDescription()
                
                VStack(alignment: .leading, spacing: 12) {
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
                
                Button(action: { presentImportPanel() }) {
                    HStack(spacing: 8) {
                        Image(systemName: "plus.circle.fill")
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
            }
        }
    }

    private func cloudModelsSection(proxy: ScrollViewProxy) -> some View {
        SettingsSection(
            icon: "cloud.fill",
            title: "Cloud Models",
            subtitle: "OpenAI-compatible APIs for advanced transcription"
        ) {
            VStack(alignment: .leading, spacing: 16) {
                Text("Connect to OpenAI-compatible transcription APIs for enhanced features and accuracy.")
                    .settingsDescription()
                
                if customModels.isEmpty {
                    VStack(spacing: 12) {
                        Image(systemName: "cloud.slash")
                            .font(.system(size: 32))
                            .foregroundColor(.secondary.opacity(0.7))
                        
                        Text("No cloud models configured")
                            .font(.headline)
                            .foregroundColor(.secondary)
                        
                        Text("Add your first cloud model API to get started with advanced transcription features.")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 20)
                } else {
                    VStack(alignment: .leading, spacing: 12) {
                        ForEach(customModels, id: \.id) { model in
                            ModelCardRowView(
                                model: model,
                                whisperState: whisperState,
                                isDownloaded: true,
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
                    }
                }
                
                Button(action: {
                    withAnimation(.easeInOut(duration: 0.5)) {
                        proxy.scrollTo("addModelCard", anchor: .center)
                    }
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                        expandAddCloudModel = true
                    }
                }) {
                    HStack(spacing: 8) {
                        Image(systemName: "plus.circle.fill")
                            .font(.system(size: 14, weight: .medium))
                        Text(customModels.isEmpty ? "Add Your First Cloud Model" : "Add Another Cloud Model")
                            .font(.system(size: 14, weight: .semibold))
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(Color.accentColor)
                    .cornerRadius(12)
                }
                .buttonStyle(.plain)
                
                // Add Custom Model Card
                AddCustomModelCardView(
                    customModelManager: customModelManager,
                    onModelAdded: {
                        whisperState.refreshAllAvailableModels()
                        customModelToEdit = nil
                    },
                    editingModel: customModelToEdit,
                    forceExpanded: $expandAddCloudModel
                )
                .id("addModelCard")
            }
        }
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
