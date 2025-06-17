//
//  ChatModels.swift
//  scAIper
//
//  Created by Dominik Hommer on 17.06.25.
//

import Foundation

public struct ChatMessageLLM: Codable {
    public enum Role: String, Codable { case system, user, assistant }
    public let role: Role
    public let content: String
}

public struct ChatRequest<ResponseFormat: Encodable>: Encodable {
    public let model: String
    public let temperature: Double
    public let max_completion_tokens: Int
    public let top_p: Double
    public let stream: Bool
    public let response_format: ResponseFormat?
    public let messages: [ChatMessageLLM]
}

public struct ChatResponse<Content: Decodable>: Decodable {
    public struct Choice: Decodable {
        public struct Message: Decodable {
            public let content: String
        }
        public let message: Message
    }
    public let choices: [Choice]
}

