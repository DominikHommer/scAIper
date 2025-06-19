//
//  ChatModels.swift
//  scAIper
//
//  Created by Dominik Hommer on 17.06.25.
//

import Foundation

/// Represents a content block within a chat message, which can be either plain text or an image URL.
public enum ChatContentBlock: Codable {
    case text(String)
    case imageURL(url: String)

    enum CodingKeys: String, CodingKey {
        case type
        case text
        case image_url
    }

    /// Encodes the content block into the given encoder.
    /// Differentiates between text and image URL content types.
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        switch self {
        case .text(let text):
            try container.encode("text", forKey: .type)
            try container.encode(text, forKey: .text)
        case .imageURL(let url):
            try container.encode("image_url", forKey: .type)
            try container.encode(["url": url], forKey: .image_url)
        }
    }

    /// Decodes the content block from the given decoder.
    /// Supports decoding both text and image URL blocks, throws on unknown type.
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let type = try container.decode(String.self, forKey: .type)
        switch type {
        case "text":
            let text = try container.decode(String.self, forKey: .text)
            self = .text(text)
        case "image_url":
            let urlDict = try container.decode([String: String].self, forKey: .image_url)
            guard let url = urlDict["url"] else {
                throw DecodingError.dataCorruptedError(forKey: .image_url, in: container, debugDescription: "Missing image URL")
            }
            self = .imageURL(url: url)
        default:
            throw DecodingError.dataCorruptedError(forKey: .type, in: container, debugDescription: "Unknown content type: \(type)")
        }
    }
}

/// Represents the content of a chat message which can be a plain string or an array of content blocks.
public enum ChatMessageContent: Codable {
    case string(String)
    case blocks([ChatContentBlock])

    /// Decodes the chat message content from the decoder.
    /// Tries to decode as string first, if that fails tries array of blocks.
    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        if let str = try? container.decode(String.self) {
            self = .string(str)
        } else if let blocks = try? container.decode([ChatContentBlock].self) {
            self = .blocks(blocks)
        } else {
            throw DecodingError.typeMismatch(
                ChatMessageContent.self,
                DecodingError.Context(
                    codingPath: decoder.codingPath,
                    debugDescription: "Expected string or [ChatContentBlock]"
                )
            )
        }
    }

    /// Encodes the chat message content to the encoder.
    /// Supports encoding as string or blocks.
    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        switch self {
        case .string(let str):
            try container.encode(str)
        case .blocks(let blocks):
            try container.encode(blocks)
        }
    }
}

/// Represents a single chat message for the LLM interaction, including its role and content.
public struct ChatMessageLLM: Codable {
    /// The role of the message sender in the chat context.
    public enum Role: String, Codable { case system, user, assistant }
    
    public let role: Role
    public let content: ChatMessageContent

    /// Convenience initializer for plain text content.
    public init(role: Role, text: String) {
        self.role = role
        self.content = .string(text)
    }

    /// Convenience initializer for content blocks.
    public init(role: Role, blocks: [ChatContentBlock]) {
        self.role = role
        self.content = .blocks(blocks)
    }
}

/// Represents a chat request payload sent to the LLM, parameterized by the response format type.
public struct ChatRequest<ResponseFormat: Encodable>: Encodable {
    public let model: String
    public let temperature: Double
    public let max_completion_tokens: Int
    public let top_p: Double
    public let stream: Bool
    public let response_format: ResponseFormat?
    public let messages: [ChatMessageLLM]
}

/// Represents the chat response from the LLM, wrapping the choices with their messages.
public struct ChatResponse<Content: Decodable>: Decodable {
    public struct Choice: Decodable {
        public struct Message: Decodable {
            public let content: String
        }
        public let message: Message
    }
    public let choices: [Choice]
}

