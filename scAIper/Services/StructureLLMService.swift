//
//  StructureLLMService.swift
//  scAIper
//
//  Created by Dominik Hommer on 09.04.25.
//

import Foundation
import UIKit

/// Represents any valid JSON value using an enum structure.
enum JSONValue: Decodable {
    case string(String)
    case number(Double)
    case bool(Bool)
    case array([JSONValue])
    case object([String: JSONValue])
    case null

    /// Initializes a `JSONValue` from a decoder, attempting to decode various JSON-compatible types.
    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        if   container.decodeNil()                          { self = .null }
        else if let b = try? container.decode(Bool.self)    { self = .bool(b) }
        else if let d = try? container.decode(Double.self)  { self = .number(d) }
        else if let s = try? container.decode(String.self)  { self = .string(s) }
        else if let a = try? container.decode([JSONValue].self) { self = .array(a) }
        else if let o = try? container.decode([String: JSONValue].self) {
            self = .object(o)
        } else {
            throw DecodingError.dataCorruptedError(
                in: container,
                debugDescription: "Unsupported JSON value"
            )
        }
    }
}

/// Service responsible for interacting with the LLM to structure document data (grid or image).
struct StructureLLMService {
    private let client: LLMClientType
    private let endpoint: URL

    /// Initializes the service with optional custom client and endpoint.
    init(
        client: LLMClientType = LLMClient(
            apiKey: AppConfig.Structure.apiKey
        ),
        endpoint: URL = AppConfig.Structure.endpoint
    ) {
        self.client = client
        self.endpoint = endpoint
    }

    /// Sends a request to the LLM with the grid of text blocks to structure them into table form.
    ///
    /// - Parameters:
    ///   - grid: A list of text blocks with `text`, `x`, and `y` coordinates.
    ///   - completion: Completion handler with a structured response or error.
    func sendLLMRequest(
        grid: [(text: String, x: CGFloat, y: CGFloat)],
        completion: @escaping (Result<StructureLLMModels.StructureResponse, Error>) -> Void
    ) {
        let system = ChatMessageLLM(role: .system, text: StructureLLMModels.LLMInstruction)
        let fewShots: [ChatMessageLLM] = StructureLLMModels.LLMFewShot

        // Encode grid as JSON array of dictionaries for LLM prompt.
        let gridJSON: String = {
            let array = grid.map { ["text": $0.text, "x": Double($0.x), "y": Double($0.y)] }
            do {
                let d = try JSONSerialization.data(withJSONObject: array, options: [])
                return String(decoding: d, as: UTF8.self)
            } catch {
                print("Failed to serialize grid:", error)
                return "[]"
            }
        }()

        let user = ChatMessageLLM(role: .user, text: "Here is the unstructured table grid:\n\(gridJSON)")

        let schemaFormat = JSONSchemaResponseFormat(json_schema: StructureLLMModels.StructureLLMSchema)

        // Create and send LLM chat request
        let payload = ChatRequest(
            model: AppConfig.Structure.model,
            temperature: 0.8,
            max_completion_tokens: 8192,
            top_p: 1.0,
            stream: false,
            response_format: schemaFormat,
            messages: [system] + fewShots + [user]
        )

        client.send(request: payload, endpoint: endpoint) { (result: Result<StructureLLMModels.StructureResponse, Error>) in
            switch result {
            case .success(let resp):
                completion(.success(resp))
            case .failure(let err):
                print("LLM request failed:", err)
                completion(.failure(err))
            }
        }
    }
}

extension StructureLLMService {
    /// Sends a base64-encoded image to the LLM to extract table structure information.
    ///
    /// - Parameters:
    ///   - base64: The base64 string representing the JPEG image to be analyzed.
    ///   - completion: Completion handler with structured table data or an error.
    func sendImageAsBase64(base64: String, completion: @escaping (Result<StructureLLMModels.StructureResponse, Error>) -> Void) {
        let imageURL = "data:image/jpeg;base64,\(base64)"
        let system = ChatMessageLLM(role: .system, text: StructureLLMModels.LLMInstructionVision)

        let userMessage = ChatMessageLLM(
            role: .user,
            blocks: [
                .text("""
                    Please extract the table data from the image below. Return only the JSON data matching the given schema with keys "header" and "table".
                    Use empty strings ("") for missing values, and avoid special Unicode characters.
                    Do NOT return the schema or any extra explanation.
                    """),
                .imageURL(url: imageURL)
            ]
        )

        let schemaFormat = JSONSchemaResponseFormat(json_schema: StructureLLMModels.StructureLLMSchema)

        // Create and send image-based chat request
        let payload = ChatRequest(
            model: AppConfig.Structure.model,
            temperature: 0.8,
            max_completion_tokens: 4291,
            top_p: 1.0,
            stream: false,
            response_format: schemaFormat,
            messages: [system, userMessage]
        )

        client.send(request: payload, endpoint: endpoint) { (result: Result<StructureLLMModels.StructureResponse, Error>) in
            switch result {
            case .success(let resp): completion(.success(resp))
            case .failure(let err):  completion(.failure(err))
            }
        }
    }
}
