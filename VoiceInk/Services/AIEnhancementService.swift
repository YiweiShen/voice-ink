import Foundation
import SwiftData
import AppKit
import os

enum EnhancementPrompt {
    case transcriptionEnhancement
    case aiAssistant
}

class AIEnhancementService: ObservableObject {
    private let logger = Logger(subsystem: "com.voiceink.enhancement", category: "AIEnhancementService")
    
    @Published var isEnhancementEnabled: Bool {
        didSet {
            UserDefaults.standard.set(isEnhancementEnabled, forKey: "isAIEnhancementEnabled")
            if isEnhancementEnabled && selectedPromptId == nil {
                selectedPromptId = customPrompts.first?.id
            }
            NotificationCenter.default.post(name: .AppSettingsDidChange, object: nil)
            NotificationCenter.default.post(name: .enhancementToggleChanged, object: nil)
        }
    }
    
    @Published var useClipboardContext: Bool {
        didSet {
            UserDefaults.standard.set(useClipboardContext, forKey: "useClipboardContext")
        }
    }
    
    
    @Published var customPrompts: [CustomPrompt] {
        didSet {
            if let encoded = try? JSONEncoder().encode(customPrompts) {
                UserDefaults.standard.set(encoded, forKey: "customPrompts")
            }
        }
    }
    
    @Published var selectedPromptId: UUID? {
        didSet {
            UserDefaults.standard.set(selectedPromptId?.uuidString, forKey: "selectedPromptId")
            NotificationCenter.default.post(name: .AppSettingsDidChange, object: nil)
            NotificationCenter.default.post(name: .promptSelectionChanged, object: nil)
        }
    }
    
    var activePrompt: CustomPrompt? {
        allPrompts.first { $0.id == selectedPromptId }
    }
    
    var allPrompts: [CustomPrompt] {
        return customPrompts
    }
    
    private let aiService: AIService
    private let baseTimeout: TimeInterval = 30
    private let rateLimitInterval: TimeInterval = 1.0
    private var lastRequestTime: Date?
    private let modelContext: ModelContext
    
    init(aiService: AIService = AIService(), modelContext: ModelContext) {
        self.aiService = aiService
        self.modelContext = modelContext
        
        self.isEnhancementEnabled = UserDefaults.standard.bool(forKey: "isAIEnhancementEnabled")
        self.useClipboardContext = UserDefaults.standard.bool(forKey: "useClipboardContext")
        
        self.customPrompts = PromptMigrationService.migratePromptsIfNeeded()
        
        if let savedPromptId = UserDefaults.standard.string(forKey: "selectedPromptId") {
            self.selectedPromptId = UUID(uuidString: savedPromptId)
        }
        
        if isEnhancementEnabled && (selectedPromptId == nil || !allPrompts.contains(where: { $0.id == selectedPromptId })) {
            self.selectedPromptId = allPrompts.first?.id
        }
        
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleAPIKeyChange),
            name: .aiProviderKeyChanged,
            object: nil
        )
        
        initializePredefinedPrompts()
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    @objc private func handleAPIKeyChange() {
        DispatchQueue.main.async {
            self.objectWillChange.send()
            if !self.aiService.isAPIKeyValid {
                self.isEnhancementEnabled = false
            }
        }
    }
    
    func getAIService() -> AIService? {
        return aiService
    }
    
    var isConfigured: Bool {
        aiService.isAPIKeyValid
    }
    
    private func waitForRateLimit() async throws {
        if let lastRequest = lastRequestTime {
            let timeSinceLastRequest = Date().timeIntervalSince(lastRequest)
            if timeSinceLastRequest < rateLimitInterval {
                try await Task.sleep(nanoseconds: UInt64((rateLimitInterval - timeSinceLastRequest) * 1_000_000_000))
            }
        }
        lastRequestTime = Date()
    }
    
    private func getSystemMessage(for mode: EnhancementPrompt) -> String {
        let selectedText = SelectedTextService.fetchSelectedText()
        
        if let activePrompt = activePrompt,
           activePrompt.id == PredefinedPrompts.assistantPromptId,
           let selectedText = selectedText, !selectedText.isEmpty {
            
            let selectedTextContext = "\n\nSelected Text: \(selectedText)"
            let contextSection = "\n\n<CONTEXT_INFORMATION>\(selectedTextContext)\n</CONTEXT_INFORMATION>"
            return activePrompt.promptText + contextSection
        }
        
        let clipboardContext = if useClipboardContext,
                              let clipboardText = NSPasteboard.general.string(forType: .string),
                              !clipboardText.isEmpty {
            "\n\nAvailable Clipboard Context: \(clipboardText)"
        } else {
            ""
        }
        
        let contextSection = if !clipboardContext.isEmpty {
            "\n\n<CONTEXT_INFORMATION>\(clipboardContext)\n</CONTEXT_INFORMATION>"
        } else {
            ""
        }
        
        guard let activePrompt = activePrompt else {
            // Use default prompt when none is selected
            if let defaultPrompt = allPrompts.first(where: { $0.id == PredefinedPrompts.defaultPromptId }) {
                var systemMessage = String(format: AIPrompts.customPromptTemplate, defaultPrompt.promptText)
                systemMessage += contextSection
                return systemMessage
            }
            return AIPrompts.assistantMode + contextSection
        }
        
        if activePrompt.id == PredefinedPrompts.assistantPromptId {
            return activePrompt.promptText + contextSection
        }
        
        var systemMessage = String(format: AIPrompts.customPromptTemplate, activePrompt.promptText)
        systemMessage += contextSection
        return systemMessage
    }
    
    private func makeRequest(text: String, mode: EnhancementPrompt) async throws -> String {
        guard isConfigured else {
            throw EnhancementError.notConfigured
        }
        
        guard !text.isEmpty else {
            return "" // Silently return empty string instead of throwing error
        }
        
        let formattedText = "\n<TRANSCRIPT>\n\(text)\n</TRANSCRIPT>"
        let systemMessage = getSystemMessage(for: mode)
        
        // Log the message being sent to AI enhancement
        logger.notice("AI Enhancement - System Message: \(systemMessage, privacy: .public)")
        logger.notice("AI Enhancement - User Message: \(formattedText, privacy: .public)")
        
        if aiService.selectedProvider == .ollama {
            do {
                let result = try await aiService.enhanceWithOllama(text: formattedText, systemPrompt: systemMessage)
                let filteredResult = AIEnhancementOutputFilter.filter(result)
                return filteredResult
            } catch {
                if let localError = error as? LocalAIError {
                    throw EnhancementError.customError(localError.errorDescription ?? "An unknown Ollama error occurred.")
                } else {
                    throw EnhancementError.customError(error.localizedDescription)
                }
            }
        }
        
        // Since we only support Ollama now, this code path should not be reached
        throw EnhancementError.customError("Only Ollama is supported for AI enhancement")
    }
    
    func enhance(_ text: String) async throws -> (String, TimeInterval) {
        let startTime = Date()
        let enhancementPrompt: EnhancementPrompt = .transcriptionEnhancement
        
        do {
            let result = try await makeRequest(text: text, mode: enhancementPrompt)
            let endTime = Date()
            let duration = endTime.timeIntervalSince(startTime)
            return (result, duration)
        } catch {
            throw error
        }
    }
    
    
    func addPrompt(title: String, promptText: String, icon: PromptIcon = .documentFill, description: String? = nil, triggerWords: [String] = []) {
        let newPrompt = CustomPrompt(title: title, promptText: promptText, icon: icon, description: description, isPredefined: false, triggerWords: triggerWords)
        customPrompts.append(newPrompt)
        if customPrompts.count == 1 {
            selectedPromptId = newPrompt.id
        }
    }
    
    func updatePrompt(_ prompt: CustomPrompt) {
        if let index = customPrompts.firstIndex(where: { $0.id == prompt.id }) {
            customPrompts[index] = prompt
        }
    }
    
    func deletePrompt(_ prompt: CustomPrompt) {
        customPrompts.removeAll { $0.id == prompt.id }
        if selectedPromptId == prompt.id {
            selectedPromptId = allPrompts.first?.id
        }
    }
    
    func setActivePrompt(_ prompt: CustomPrompt) {
        selectedPromptId = prompt.id
    }
    
    private func initializePredefinedPrompts() {
        let predefinedTemplates = PredefinedPrompts.createDefaultPrompts()
        
        for template in predefinedTemplates {
            if let existingIndex = customPrompts.firstIndex(where: { $0.id == template.id }) {
                var updatedPrompt = customPrompts[existingIndex]
                updatedPrompt = CustomPrompt(
                    id: updatedPrompt.id,
                    title: template.title,
                    promptText: template.promptText,
                    isActive: updatedPrompt.isActive,
                    icon: template.icon,
                    description: template.description,
                    isPredefined: true,
                    triggerWords: updatedPrompt.triggerWords
                )
                customPrompts[existingIndex] = updatedPrompt
            } else {
                customPrompts.append(template)
            }
        }
    }
}

enum EnhancementError: Error {
    case notConfigured
    case invalidResponse
    case enhancementFailed
    case networkError
    case customError(String)
}

extension EnhancementError: LocalizedError {
    var errorDescription: String? {
        switch self {
        case .notConfigured:
            return "AI provider not configured. Please check your API key."
        case .invalidResponse:
            return "Invalid response from AI provider."
        case .enhancementFailed:
            return "AI enhancement failed to process the text."
        case .networkError:
            return "Network connection failed. Check your internet."
        case .customError(let message):
            return message
        }
    }
}
