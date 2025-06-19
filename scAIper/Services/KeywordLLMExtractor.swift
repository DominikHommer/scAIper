//
//  KeywordLLMExtractor.swift
//  scAIper
//
//  Created by Dominik Hommer on 06.06.25.
//

import Foundation

/// A service that uses a large language model (LLM) to extract structured keywords from OCRed document text.
struct KeywordLLMExtractor {
    /// Client to communicate with the LLM API.
    private let client: LLMClientType
    
    /// Endpoint where the keyword extraction request is sent.
    private let endpoint: URL

    /// Initializes the extractor with a default or custom LLM client and endpoint.
    ///
    /// - Parameters:
    ///   - client: The LLM client to use. Defaults to the one using the `AppConfig.Keywords.apiKey`.
    ///   - endpoint: The endpoint URL. Defaults to `AppConfig.Keywords.endpoint`.
    init(
        client: LLMClientType = LLMClient(
            apiKey: AppConfig.Keywords.apiKey
        ),
        endpoint: URL = AppConfig.Keywords.endpoint
    ) {
        self.client = client
        self.endpoint = endpoint
    }

    /// Extracts keywords from the provided text using an LLM, based on the document type.
    ///
    /// - Parameters:
    ///   - documentType: The type of the document (e.g. invoice, pay slip, contract).
    ///   - text: The full OCR output from the document.
    ///   - completion: Closure called with either a dictionary of extracted keywords or an error.
    func extractKeywords(
        documentType: DocumentType,
        text: String,
        completion: @escaping (Result<[String: String], Error>) -> Void
    ) {
        // System message with instructions tailored to the document type
        let system = ChatMessageLLM(
            role: .system,
            text: KeywordModels.instruction(for: documentType)
        )

        // Optional few-shot examples to guide the LLM’s behavior for this document type
        let fewShots = KeywordModels.fewShots(for: documentType)

        // User message containing the OCR text
        let user = ChatMessageLLM(
            role: .user,
            text: "OCR-Text:\n\"\"\"\n\(text)\n\"\"\""
        )

        // Schema for expected JSON output format (key-value pairs)
        let schemaWrapper = KeywordModels.schemaWrapper(for: documentType)
        let responseFormat = JSONSchemaResponseFormat(json_schema: schemaWrapper)

        // Construct the payload for the LLM API request
        let payload = ChatRequest(
            model: AppConfig.Keywords.model,
            temperature: 0.2,  // Low temperature for deterministic keyword extraction
            max_completion_tokens: 1024,
            top_p: 1.0,
            stream: false,
            response_format: responseFormat,
            messages: [system] + fewShots + [user]
        )

        // Send the request to the model
        client.send(request: payload, endpoint: endpoint) { (result: Result<[String: String], Error>) in
            switch result {
            case .success(let dict):
                if dict.isEmpty {
                    print("Keine Keywords erkannt.")
                } else {
                    print("Erkannte Keywords (\(dict.count)):")
                    for (key, value) in dict {
                        print(" - \(key): \(value)")
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
