import Foundation
import os

enum CloudTranscriptionError: Error, LocalizedError {
    case unsupportedProvider
    case missingAPIKey
    case invalidAPIKey
    case audioFileNotFound
    case apiRequestFailed(statusCode: Int, message: String)
    case networkError(Error)
    case noTranscriptionReturned
    case dataEncodingError
    
    var errorDescription: String? {
        switch self {
        case .unsupportedProvider:
            return "The model provider is not supported by this service."
        case .missingAPIKey:
            return "API key for this service is missing. Please configure it in the settings."
        case .invalidAPIKey:
            return "The provided API key is invalid."
        case .audioFileNotFound:
            return "The audio file to transcribe could not be found."
        case .apiRequestFailed(let statusCode, let message):
            return "The API request failed with status code \(statusCode): \(message)"
        case .networkError(let error):
            return "A network error occurred: \(error.localizedDescription)"
        case .noTranscriptionReturned:
            return "The API returned an empty or invalid response."
        case .dataEncodingError:
            return "Failed to encode the request body."
        }
    }
}

class CloudTranscriptionService: TranscriptionService {
    
    func transcribe(audioURL: URL, model: any TranscriptionModel) async throws -> String {
        // Cloud transcription is no longer supported - only local models are available
        throw CloudTranscriptionError.unsupportedProvider
    }
} 