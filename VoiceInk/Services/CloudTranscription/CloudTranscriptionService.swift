import Foundation
import os

enum CloudTranscriptionError: Error, LocalizedError {
    case unsupportedProvider

    var errorDescription: String? {
        switch self {
        case .unsupportedProvider:
            return "The model provider is not supported by this service."
        }
    }
}

class CloudTranscriptionService: TranscriptionService {
    
    func transcribe(audioURL: URL, model: any TranscriptionModel) async throws -> String {
        // Cloud transcription is no longer supported - only local models are available
        throw CloudTranscriptionError.unsupportedProvider
    }
} 