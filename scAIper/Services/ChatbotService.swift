//
//  ChatbotService.swift
//  scAIper
//
//  Created by Dominik Hommer on 28.03.25.
//

import Foundation

/// Singleton class responsible for managing chatbot communication using an LLM client.
final class ChatbotService {
    /// Shared instance for global access.
    static let shared = ChatbotService()

    private let client: LLMClientType
    private let endpoint: URL
    private let historyQueue = DispatchQueue(label: "chatbot.history.queue")

    /// Initializes the service with the provided LLM client and API endpoint.
    private init(
        client: LLMClientType = LLMClient(
            apiKey: AppConfig.Chat.apiKey
        ),
        endpoint: URL = AppConfig.Chat.endpoint
    ) {
        self.client = client
        self.endpoint = endpoint
    }

    /// Stores the conversation history with a limited number of recent messages.
    private var messageHistory: [ChatMessageLLM] = []
    private let maxHistoryCount = 12

    /// Appends a user message to the history, ensuring history limit is respected.
    private func appendUserMessage(_ text: String) {
        let msg = ChatMessageLLM(role: .user, text: text)
        historyQueue.async {
            self.messageHistory.append(msg)
            self.trimHistoryIfNeeded()
        }
    }

    /// Appends an assistant message to the history, ensuring history limit is respected.
    private func appendAssistantMessage(_ text: String) {
        let msg = ChatMessageLLM(role: .assistant, text: text)
        historyQueue.async {
            self.messageHistory.append(msg)
            self.trimHistoryIfNeeded()
        }
    }

    /// Removes oldest messages if history exceeds the maximum count.
    private func trimHistoryIfNeeded() {
        let excess = messageHistory.count - maxHistoryCount
        if excess > 0 {
            messageHistory.removeFirst(excess)
        }
    }

    /// Clears the entire chat history.
    func resetHistory() {
        historyQueue.async {
            self.messageHistory.removeAll()
        }
    }

    /// Queries the LLM whether the current input requires document-based information (RAG).
    ///
    /// - Parameters:
    ///   - input: User input string to analyze.
    ///   - completion: Completion handler returning a Bool indicating document need or an Error.
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

    /// Sends a chat completion query and handles logic for RAG or normal completion.
    ///
    /// - Parameters:
    ///   - input: The user prompt.
    ///   - completion: Completion handler with either the assistant's response or an Error.
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
                // Path with Retrieval-Augmented Generation (RAG)
                RAGManager.shared.processRAG(for: input) { ragOutput in
                    let base = ChatbotModels.chatMessages(userInput: input, ragOutput: ragOutput)
                    guard let systemMessage = base.first(where: { $0.role == .system }) else {
                        completion(.failure(NSError(domain: "ChatbotService", code: -1, userInfo: [NSLocalizedDescriptionKey: "Failed to generate system prompt."])))
                        return
                    }

                    let ragUser = ChatMessageLLM(
                        role: .user,
                        text: "\(input)\n\nHere are the relevant document sections. Note that some documents may not be related to the question. Please ignore those:\n\(ragOutput)"
                    )

                    self.historyQueue.async {
                        let history = self.messageHistory
                        let final = [systemMessage] + history + [ragUser]

                        self.sendChat(messages: final) { result in
                            if case .success(let response) = result {
                                self.appendUserMessage(input)
                                self.appendAssistantMessage(response)
                            }
                            completion(result)
                        }
                    }
                }

            case .success(false):
                // Normal chat completion path
                let base = ChatbotModels.chatMessages(userInput: input)
                guard let systemMessage = base.first(where: { $0.role == .system }) else {
                    completion(.failure(NSError(domain: "ChatbotService", code: -1, userInfo: [NSLocalizedDescriptionKey: "Failed to generate system prompt."])))
                    return
                }

                let userMsg = ChatMessageLLM(role: .user, text: input)

                self.historyQueue.async {
                    let history = self.messageHistory
                    let final = [systemMessage] + history + [userMsg]

                    self.sendChat(messages: final) { result in
                        if case .success(let response) = result {
                            self.appendUserMessage(input)
                            self.appendAssistantMessage(response)
                        }
                        completion(result)
                    }
                }
            }
        }
    }

    /// Sends a structured chat request to the LLM.
    ///
    /// - Parameters:
    ///   - messages: The list of chat messages including system prompt and history.
    ///   - completion: Completion handler with either the trimmed assistant response or an Error.
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

