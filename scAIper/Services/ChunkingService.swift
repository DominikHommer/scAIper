//
//  ChunkingService.swift
//  scAIper
//
//  Created by Dominik Hommer on 10.04.25.
//

import Foundation

final class ChunkingService {
    static let shared = ChunkingService()
    private let client: LLMClientType
    private let endpoint: URL

    private init(
        client: LLMClientType = LLMClient(
            apiKey: AppConfig.Chunking.apiKey
        ),
        endpoint: URL = AppConfig.Chunking.endpoint
    ) {
        self.client = client
        self.endpoint = endpoint
    }

    func chunkTextWithLLM(
        _ text: String,
        completion: @escaping (Result<[Chunk], Error>) -> Void
    ) {
        let system   = ChatMessageLLM(role: .system, text: ChunkingModels.ChunkingInstruction)
        let fewShots = ChunkingModels.ChunkingFewShot
        let user     = ChatMessageLLM(role: .user, text: text)


        // 4) Hier den ganzen Wrapper nutzen
        let schemaFormat = JSONSchemaResponseFormat(json_schema: ChunkingModels.ChunkingSchema)

        let payload = ChatRequest(
            model: AppConfig.Chunking.model,
            temperature: 0.8,
            max_completion_tokens: 8000,
            top_p: 1.0,
            stream: false,
            response_format: schemaFormat,
            messages: [system] + fewShots + [user]
        )

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



