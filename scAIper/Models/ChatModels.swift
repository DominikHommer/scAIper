//
//  ChatModels.swift
//  scAIper
//
//  Created by Dominik Hommer on 17.06.25.
//

import Foundation

public enum ChatContentBlock: Codable {
    case text(String)
    case imageURL(url: String)

    enum CodingKeys: String, CodingKey {
        case type
        case text
        case image_url
    }

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

public enum ChatMessageContent: Codable {
    case string(String)
    case blocks([ChatContentBlock])

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

public struct ChatMessageLLM: Codable {
    public enum Role: String, Codable { case system, user, assistant }
    public let role: Role
    public let content: ChatMessageContent

    public init(role: Role, text: String) {
        self.role = role
        self.content = .string(text)
    }

    public init(role: Role, blocks: [ChatContentBlock]) {
        self.role = role
        self.content = .blocks(blocks)
    }
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


