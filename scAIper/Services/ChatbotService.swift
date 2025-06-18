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
    private let historyQueue = DispatchQueue(label: "chatbot.history.queue")

    private init(
        client: LLMClientType = LLMClient(
            apiKey: AppConfig.Chat.apiKey
        ),
        endpoint: URL = AppConfig.Chat.endpoint
    ) {
        self.client = client
        self.endpoint = endpoint
    }

    private var messageHistory: [ChatMessageLLM] = []
    private let maxHistoryCount = 12

    private func appendUserMessage(_ text: String) {
        let msg = ChatMessageLLM(role: .user, content: text)
        historyQueue.async {
            self.messageHistory.append(msg)
            self.trimHistoryIfNeeded()
        }
    }

    private func appendAssistantMessage(_ text: String) {
        let msg = ChatMessageLLM(role: .assistant, content: text)
        historyQueue.async {
            self.messageHistory.append(msg)
            self.trimHistoryIfNeeded()
        }
    }

    private func trimHistoryIfNeeded() {
        let excess = messageHistory.count - maxHistoryCount
        if excess > 0 {
            messageHistory.removeFirst(excess)
        }
    }

    func resetHistory() {
        historyQueue.async {
            self.messageHistory.removeAll()
        }
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
                // RAG-Pfad
                RAGManager.shared.processRAG(for: input) { ragOutput in
                    // System-Prompt extrahieren
                    let base = ChatbotModels.chatMessages(userInput: input, ragOutput: ragOutput)
                    guard let systemMessage = base.first(where: { $0.role == .system }) else {
                        completion(.failure(NSError(domain: "ChatbotService", code: -1, userInfo: [NSLocalizedDescriptionKey: "Fehler beim Erzeugen des System-Prompts"])))
                        return
                    }
                    // User-Nachricht mit RAG-Output
                    let ragUser = ChatMessageLLM(role: .user, content: "\(input)\n\nHier die relevanten Dokumentabschnitte, beachte das Dokumente enthalten sein können die nichts mit der Fragestellung zu tun haben, ignoriere diese:\n\(ragOutput)")

                    // Nachrichten zusammenstellen: System, History, RAG-User
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
                // Standard-Pfad
                let base = ChatbotModels.chatMessages(userInput: input)
                guard let systemMessage = base.first(where: { $0.role == .system }) else {
                    completion(.failure(NSError(domain: "ChatbotService", code: -1, userInfo: [NSLocalizedDescriptionKey: "Fehler beim Erzeugen des System-Prompts"])))
                    return
                }
                let userMsg = ChatMessageLLM(role: .user, content: input)

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
