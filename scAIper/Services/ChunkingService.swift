//
//  ChunkingService.swift
//  scAIper
//
//  Created by Dominik Hommer on 10.04.25.
//

import Foundation

/// Service that handles text chunking using an LLM (Large Language Model).
final class ChunkingService {
    /// Shared singleton instance for global access.
    static let shared = ChunkingService()

    /// LLM client responsible for sending requests.
    private let client: LLMClientType

    /// The endpoint where chunking requests are sent.
    private let endpoint: URL

    /// Private initializer to enforce singleton pattern.
    ///
    /// - Parameters:
    ///   - client: Optional custom LLM client.
    ///   - endpoint: Optional custom endpoint URL.
    private init(
        client: LLMClientType = LLMClient(
            apiKey: AppConfig.Chunking.apiKey
        ),
        endpoint: URL = AppConfig.Chunking.endpoint
    ) {
        self.client = client
        self.endpoint = endpoint
    }

    /// Sends a request to the LLM to split a long text into logical content chunks.
    ///
    /// - Parameters:
    ///   - text: The full text to be chunked.
    ///   - completion: Completion handler returning either a list of chunks or an error.
    func chunkTextWithLLM(
        _ text: String,
        completion: @escaping (Result<[Chunk], Error>) -> Void
    ) {
        // System prompt with instruction for how chunking should be performed
        let system = ChatMessageLLM(role: .system, text: ChunkingModels.ChunkingInstruction)

        // Few-shot examples to guide the model behavior
        let fewShots = ChunkingModels.ChunkingFewShot

        // User message with actual text to chunk
        let user = ChatMessageLLM(role: .user, text: text)

        // Define the output schema expected from the LLM
        let schemaFormat = JSONSchemaResponseFormat(json_schema: ChunkingModels.ChunkingSchema)

        // Prepare the chat request payload
        let payload = ChatRequest(
            model: AppConfig.Chunking.model,
            temperature: 0.8,
            max_completion_tokens: 8000,
            top_p: 1.0,
            stream: false,
            response_format: schemaFormat,
            messages: [system] + fewShots + [user]
        )

        // Send request to LLM and decode the response into a list of chunks
        client.send(request: payload, endpoint: endpoint) { (result: Result<ChunkingModels.ChunkingResponse, Error>) in
            switch result {
            case .success(let wrapper):
                completion(.success(wrapper.items))
            case .failure(let err):
                completion(.failure(err))
            }
        }
    }
}
