//
//  LLMClientType.swift
//  scAIper
//
//  Created by Dominik Hommer on 17.06.25.
//

import Foundation
import UIKit

/// Protocol defining a general interface for sending requests to an LLM (Large Language Model) client.
public protocol LLMClientType {
    
    /// Sends a structured `ChatRequest` to the specified LLM endpoint.
    ///
    /// - Parameters:
    ///   - request: A `ChatRequest` wrapping the payload and chat metadata.
    ///   - endpoint: The URL to which the request is sent.
    ///   - completion: Closure called with either a decoded response or an error.
    func send<RequestFormat: Encodable, ResponseContent: Decodable>(
        request: ChatRequest<RequestFormat>,
        endpoint: URL,
        completion: @escaping (Result<ResponseContent, Error>) -> Void
    )
    
    /// Sends a generic JSON payload to the given endpoint.
    ///
    /// - Parameters:
    ///   - payload: A generic `Encodable` object to be sent.
    ///   - endpoint: The URL to which the payload is sent.
    ///   - completion: Closure called with either the decoded response or an error.
    func send<Req: Encodable, Resp: Decodable>(
        payload: Req,
        to endpoint: URL,
        completion: @escaping (Result<Resp, Error>) -> Void
    )
}

/// Concrete implementation of the `LLMClientType` for interacting with a language model API.
public final class LLMClient: LLMClientType {
    /// URLSession used to perform network requests.
    private let session: URLSession
    
    /// API key used for authentication with the LLM service.
    private let apiKey: String

    /// Initializes a new `LLMClient`.
    ///
    /// - Parameters:
    ///   - session: URLSession instance used for HTTP calls (default is `.shared`).
    ///   - apiKey: The API key required for LLM access.
    public init(session: URLSession = .shared, apiKey: String) {
        self.session = session
        self.apiKey = apiKey
    }

    /// Sends a structured chat request to the LLM endpoint and decodes a structured response.
    public func send<Req: Encodable, Resp: Decodable>(
        request: ChatRequest<Req>,
        endpoint: URL,
        completion: @escaping (Result<Resp, Error>) -> Void
    ) {
        var urlRequest = URLRequest(url: endpoint)
        urlRequest.httpMethod = "POST"
        urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
        urlRequest.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")

        do {
            urlRequest.httpBody = try JSONEncoder().encode(request)
            debugPrint("LLM Request Body:", String(data: urlRequest.httpBody!, encoding: .utf8)!)
        } catch {
            return completion(.failure(error))
        }

        session.dataTask(with: urlRequest) { data, resp, error in
            if let error = error {
                return completion(.failure(error))
            }
            guard let data = data else {
                return completion(.failure(URLError(.badServerResponse)))
            }
            debugPrint("LLM Raw Response:", String(data: data, encoding: .utf8) ?? "<nil>")

            do {
                // Decode the outer LLM response
                let topLevel = try JSONDecoder().decode(ChatResponse<Resp>.self, from: data)
                let contentString = topLevel.choices.first?.message.content ?? ""
                let contentData = Data(contentString.utf8)
                
                // Decode the inner content into the expected model
                let parsed = try JSONDecoder().decode(Resp.self, from: contentData)
                completion(.success(parsed))
            } catch {
                completion(.failure(error))
            }
        }.resume()
    }

    /// Sends a generic JSON payload (not necessarily a chat request) to the endpoint.
    public func send<Req: Encodable, Resp: Decodable>(
        payload: Req,
        to endpoint: URL,
        completion: @escaping (Result<Resp, Error>) -> Void
    ) {
        var req = URLRequest(url: endpoint)
        req.httpMethod = "POST"
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        req.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")

        do {
            req.httpBody = try JSONEncoder().encode(payload)
            debugPrint("-RAG Request Body-:", String(data: req.httpBody!, encoding: .utf8)!)
        } catch {
            return completion(.failure(error))
        }

        session.dataTask(with: req) { data, _, error in
            if let error = error {
                return completion(.failure(error))
            }
            guard let data = data else {
                return completion(.failure(URLError(.badServerResponse)))
            }
            debugPrint("-RAG Response-:", String(data: data, encoding: .utf8) ?? "<nil>")

            do {
                let decoded = try JSONDecoder().decode(Resp.self, from: data)
                completion(.success(decoded))
            } catch {
                completion(.failure(error))
            }
        }.resume()
    }
}
