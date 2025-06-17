//
//  StructureLLMService.swift
//  scAIper
//
//  Created by Dominik Hommer on 09.04.25.
//

import Foundation
import UIKit

enum JSONValue: Decodable {
    case string(String)
    case number(Double)
    case bool(Bool)
    case array([JSONValue])
    case object([String: JSONValue])
    case null

    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        if   container.decodeNil()                     { self = .null }
        else if let b = try? container.decode(Bool.self)   { self = .bool(b) }
        else if let d = try? container.decode(Double.self) { self = .number(d) }
        else if let s = try? container.decode(String.self) { self = .string(s) }
        else if let a = try? container.decode([JSONValue].self)     { self = .array(a) }
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

struct StructureLLMService {
    private let client: LLMClientType
    private let endpoint: URL

    init(
        client: LLMClientType = LLMClient(
            apiKey: AppConfig.Structure.apiKey
        ),
        endpoint: URL = AppConfig.Structure.endpoint
    ) {
        self.client = client
        self.endpoint = endpoint
    }

    func sendLLMRequest(
        grid: [(text: String, x: CGFloat, y: CGFloat)],
        completion: @escaping (Result<StructureLLMModels.StructureResponse, Error>) -> Void
    ) {
        let system = ChatMessageLLM(role: .system, content: StructureLLMModels.LLMInstruction)
        let fewShots: [ChatMessageLLM] = StructureLLMModels.LLMFewShot
        let gridJSON: String = {
            let array = grid.map { ["text": $0.text, "x": Double($0.x), "y": Double($0.y)] }
            do {
                let d = try JSONSerialization.data(withJSONObject: array, options: [])
                return String(decoding: d, as: UTF8.self)
            } catch {
                print("Fehler beim Serialisieren des Grids:", error)
                return "[]"
            }
        }()

        let user = ChatMessageLLM(
            role: .user,
            content: "Here is the unstructured table grid:\n\(gridJSON)"
        )

        let schemaFormat = JSONSchemaResponseFormat(json_schema: StructureLLMModels.StructureLLMSchema)
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
                print("LLM-Request fehlgeschlagen:", err)
                completion(.failure(err))
            }
        }
    }
}





