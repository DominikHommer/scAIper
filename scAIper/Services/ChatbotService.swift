//
//  ChatbotService.swift
//  scAIper
//
//  Created by Dominik Hommer on 28.03.25.
//

import Foundation

final class ChatbotService {
    static let shared = ChatbotService()

    private let client: LLMClientType
    private let endpoint: URL

    private init(
        client: LLMClientType = LLMClient(
            apiKey: AppConfig.Chat.apiKey
        ),
        endpoint: URL = AppConfig.Chat.endpoint
    ) {
        self.client = client
        self.endpoint = endpoint
    }

    func queryDocumentCheck(
        input: String,
        completion: @escaping (Result<Bool, Error>) -> Void
    ) {
        let messages = ChatbotModels.docCheckMessages(userInput: input)

        let wrapper = ChatbotModels.DocCheckSchema(
            schema: .init(
                properties: ["wantsDocumentInfo": .init()],
                required: ["wantsDocumentInfo"]
            )
        )
        let responseFormat = JSONSchemaResponseFormat(json_schema: wrapper)

        let payload = ChatRequest(
            model: AppConfig.Chat.docCheckModel,
            temperature: 0.0,
            max_completion_tokens: 512,
            top_p: 1.0,
            stream: false,
            response_format: responseFormat,
            messages: messages
        )

        client.send(request: payload, endpoint: endpoint) { (result: Result<ChatbotModels.DocCheckResponse, Error>) in
            switch result {
            case .success(let resp):
                completion(.success(resp.wantsDocumentInfo))
            case .failure(let err):
                completion(.failure(err))
            }
        }
    }

    func queryChatCompletion(
        input: String,
        completion: @escaping (Result<String, Error>) -> Void
    ) {
        queryDocumentCheck(input: input) { [weak self] docCheck in
            guard let self = self else { return }
            switch docCheck {
            case .failure(let err):
                completion(.failure(err))

            case .success(true):
                RAGManager.shared.processRAG(for: input) { ragOutput in
                    let messages = ChatbotModels.chatMessages(userInput: input, ragOutput: ragOutput)
                    self.sendChat(messages: messages, completion: completion)
                }

            case .success(false):
                let messages = ChatbotModels.chatMessages(userInput: input)
                self.sendChat(messages: messages, completion: completion)
            }
        }
    }

    private func sendChat(
        messages: [ChatMessageLLM],
        completion: @escaping (Result<String, Error>) -> Void
    ) {
        let wrapper = ChatbotModels.ChatResponseSchema(
            schema: .init(
                properties: ["content": .init()],
                required: ["content"]
            )
        )
        let responseFormat = JSONSchemaResponseFormat(json_schema: wrapper)

        let payload = ChatRequest(
            model: AppConfig.Chat.completionModel,
            temperature: 1.0,
            max_completion_tokens: 512,
            top_p: 1.0,
            stream: false,
            response_format: responseFormat,
            messages: messages
        )

        client.send(request: payload, endpoint: endpoint) { (result: Result<ChatbotModels.ChatCompletionResponse, Error>) in
            switch result {
            case .success(let chatResp):
                completion(.success(chatResp.content.trimmingCharacters(in: .whitespacesAndNewlines)))
            case .failure(let err):
                completion(.failure(err))
            }
        }
    }
}
