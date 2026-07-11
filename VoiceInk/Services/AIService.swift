import Foundation
import os

enum AIProvider: String, CaseIterable {
    case ollama = "Ollama"

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

    private let userDefaults = UserDefaults.standard
    private lazy var ollamaService = OllamaService()

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
}

