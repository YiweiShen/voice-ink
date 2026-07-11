import Foundation
import os

class CustomModelManager: ObservableObject {
    static let shared = CustomModelManager()

    private let logger = Logger(subsystem: "com.yiweishen.voiceink", category: "CustomModelManager")
    private let userDefaults = UserDefaults.standard
    private let customModelsKey = "customCloudModels"

    @Published var customModels: [CustomCloudModel] = []

    private init() {
        loadCustomModels()
    }

    // MARK: - Persistence

    private func loadCustomModels() {
        guard let data = userDefaults.data(forKey: customModelsKey) else {
            logger.info("No custom models found in UserDefaults")
            return
        }

        do {
            customModels = try JSONDecoder().decode([CustomCloudModel].self, from: data)
        } catch {
            logger.error("Failed to decode custom models: \(error.localizedDescription)")
            customModels = []
        }
    }

}
