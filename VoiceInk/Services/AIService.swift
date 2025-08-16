import Foundation
import os

enum AIProvider: String, CaseIterable {
    case ollama = "Ollama"


    var baseURL: String {
        switch self {
        case .ollama:
            return UserDefaults.standard.string(forKey: "ollamaBaseURL") ?? "http://localhost:11434"
        }
    }

    var defaultModel: String {
        switch self {
        case .ollama:
            return UserDefaults.standard.string(forKey: "ollamaSelectedModel") ?? "mistral"
        }
    }

    var availableModels: [String] {
        switch self {
        case .ollama:
            return []
        }
    }

    var requiresAPIKey: Bool {
        switch self {
        case .ollama:
            return false
        }
    }
}

class AIService: ObservableObject {
    private let logger = Logger(subsystem: "com.yiweishen.voiceink", category: "AIService")

    @Published var apiKey: String = ""
    @Published var isAPIKeyValid: Bool = false
    @Published var customBaseURL: String = UserDefaults.standard.string(forKey: "customProviderBaseURL") ?? "" {
        didSet {
            userDefaults.set(customBaseURL, forKey: "customProviderBaseURL")
        }
    }
    @Published var customModel: String = UserDefaults.standard.string(forKey: "customProviderModel") ?? "" {
        didSet {
            userDefaults.set(customModel, forKey: "customProviderModel")
        }
    }
    @Published var selectedProvider: AIProvider {
        didSet {
            userDefaults.set(selectedProvider.rawValue, forKey: "selectedAIProvider")
            if selectedProvider.requiresAPIKey {
                if let savedKey = userDefaults.string(forKey: "\(selectedProvider.rawValue)APIKey") {
                    self.apiKey = savedKey
                    self.isAPIKeyValid = true
                } else {
                    self.apiKey = ""
                    self.isAPIKeyValid = false
                }
            } else {
                self.apiKey = ""
                self.isAPIKeyValid = true
                if selectedProvider == .ollama {
                    Task {
                        await ollamaService.checkConnection()
                        await ollamaService.refreshModels()
                    }
                }
            }
            NotificationCenter.default.post(name: .AppSettingsDidChange, object: nil)
        }
    }

    @Published private var selectedModels: [AIProvider: String] = [:]
    private let userDefaults = UserDefaults.standard
    private lazy var ollamaService = OllamaService()


    var connectedProviders: [AIProvider] {
        AIProvider.allCases.filter { provider in
            if provider == .ollama {
                return ollamaService.isConnected
            } else if provider.requiresAPIKey {
                return userDefaults.string(forKey: "\(provider.rawValue)APIKey") != nil
            }
            return false
        }
    }

    var currentModel: String {
        if let selectedModel = selectedModels[selectedProvider],
           !selectedModel.isEmpty,
           (selectedProvider == .ollama && !selectedModel.isEmpty) || availableModels.contains(selectedModel) {
            return selectedModel
        }
        return selectedProvider.defaultModel
    }

    var availableModels: [String] {
        if selectedProvider == .ollama {
            return ollamaService.availableModels.map { $0.name }
        }
        return selectedProvider.availableModels
    }

    init() {
        if let savedProvider = userDefaults.string(forKey: "selectedAIProvider"),
           let provider = AIProvider(rawValue: savedProvider) {
            self.selectedProvider = provider
        } else {
            self.selectedProvider = .ollama
        }

        if selectedProvider.requiresAPIKey {
            if let savedKey = userDefaults.string(forKey: "\(selectedProvider.rawValue)APIKey") {
                self.apiKey = savedKey
                self.isAPIKeyValid = true
            }
        } else {
            self.isAPIKeyValid = true
        }

        loadSavedModelSelections()
    }

    private func loadSavedModelSelections() {
        for provider in AIProvider.allCases {
            let key = "\(provider.rawValue)SelectedModel"
            if let savedModel = userDefaults.string(forKey: key), !savedModel.isEmpty {
                selectedModels[provider] = savedModel
            }
        }
    }


    func selectModel(_ model: String) {
        guard !model.isEmpty else { return }

        selectedModels[selectedProvider] = model
        let key = "\(selectedProvider.rawValue)SelectedModel"
        userDefaults.set(model, forKey: key)

        if selectedProvider == .ollama {
            updateSelectedOllamaModel(model)
        }

        objectWillChange.send()
        NotificationCenter.default.post(name: .AppSettingsDidChange, object: nil)
    }

    func saveAPIKey(_ key: String, completion: @escaping (Bool) -> Void) {
        guard selectedProvider.requiresAPIKey else {
            completion(true)
            return
        }

        verifyAPIKey(key) { [weak self] isValid in
            guard let self = self else { return }
            DispatchQueue.main.async {
                if isValid {
                    self.apiKey = key
                    self.isAPIKeyValid = true
                    self.userDefaults.set(key, forKey: "\(self.selectedProvider.rawValue)APIKey")
                    NotificationCenter.default.post(name: .aiProviderKeyChanged, object: nil)
                } else {
                    self.isAPIKeyValid = false
                }
                completion(isValid)
            }
        }
    }

    func verifyAPIKey(_ key: String, completion: @escaping (Bool) -> Void) {
        guard selectedProvider.requiresAPIKey else {
            completion(true)
            return
        }
        
        // Ollama doesn't require API key verification
        completion(true)
    }


    func clearAPIKey() {
        guard selectedProvider.requiresAPIKey else { return }

        apiKey = ""
        isAPIKeyValid = false
        userDefaults.removeObject(forKey: "\(selectedProvider.rawValue)APIKey")
        NotificationCenter.default.post(name: .aiProviderKeyChanged, object: nil)
    }

    func checkOllamaConnection(completion: @escaping (Bool) -> Void) {
        Task { [weak self] in
            guard let self = self else { return }
            await self.ollamaService.checkConnection()
            DispatchQueue.main.async {
                completion(self.ollamaService.isConnected)
            }
        }
    }

    func fetchOllamaModels() async -> [OllamaService.OllamaModel] {
        await ollamaService.refreshModels()
        return ollamaService.availableModels
    }

    func enhanceWithOllama(text: String, systemPrompt: String) async throws -> String {
        logger.notice("🔄 Sending transcription to Ollama for enhancement (model: \(self.ollamaService.selectedModel))")
        do {
            let result = try await ollamaService.enhance(text, withSystemPrompt: systemPrompt)
            logger.notice("✅ Ollama enhancement completed successfully (\(result.count) characters)")
            return result
        } catch {
            logger.notice("❌ Ollama enhancement failed: \(error.localizedDescription)")
            throw error
        }
    }

    func updateOllamaBaseURL(_ newURL: String) {
        ollamaService.baseURL = newURL
        userDefaults.set(newURL, forKey: "ollamaBaseURL")
    }

    func updateSelectedOllamaModel(_ modelName: String) {
        ollamaService.selectedModel = modelName
        userDefaults.set(modelName, forKey: "ollamaSelectedModel")
    }

}


