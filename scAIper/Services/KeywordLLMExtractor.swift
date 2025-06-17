//
//  KeywordLLMExtractor.swift
//  scAIper
//
//  Created by Dominik Hommer on 06.06.25.
//

import Foundation

struct KeywordLLMExtractor {
    private let client: LLMClientType
    private let endpoint: URL

    init(
        client: LLMClientType = LLMClient(
            apiKey: AppConfig.Keywords.apiKey
        ),
        endpoint: URL = AppConfig.Keywords.endpoint
    ) {
        self.client = client
        self.endpoint = endpoint
    }

    func extractKeywords(
        documentType: DocumentType,
        text: String,
        completion: @escaping (Result<[String: String], Error>) -> Void
    ) {
        let system = ChatMessageLLM(
            role: .system,
            content: KeywordModels.instruction(for: documentType)
        )

        // 2) Few-Shot-Beispiele
        let fewShots = KeywordModels.fewShots(for: documentType)

        // 3) User-Prompt
        let user = ChatMessageLLM(
            role: .user,
            content: "OCR-Text:\n\"\"\"\n\(text)\n\"\"\""
        )

        // 4) Schema-Wrapper
        let schemaWrapper = KeywordModels.schemaWrapper(for: documentType)
        let responseFormat = JSONSchemaResponseFormat(json_schema: schemaWrapper)

        // 5) Baue den ChatRequest-Payload
        let payload = ChatRequest(
            model: AppConfig.Keywords.model,
            temperature: 0.2,
            max_completion_tokens: 1024,
            top_p: 1.0,
            stream: false,
            response_format: responseFormat,
            messages: [system] + fewShots + [user]
        )

        client.send(request: payload, endpoint: endpoint) { (result: Result<[String: String], Error>) in
                    switch result {
                    case .success(let dict):
                        if dict.isEmpty {
                            print("Keine Keywords erkannt.")
                        } else {
                            print("Erkannte Keywords (\(dict.count)):")
                            for (key, value) in dict {
                                print(" • \(key): \(value)")
                            }
                        }
                        completion(.success(dict))

                    case .failure(let error):
                        print("Keyword-Extraktion fehlgeschlagen: \(error)")
                        completion(.failure(error))
                    }
                }
    }
}


