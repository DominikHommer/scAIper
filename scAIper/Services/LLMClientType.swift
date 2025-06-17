//
//  LLMClientType.swift
//  scAIper
//
//  Created by Dominik Hommer on 17.06.25.
//


import Foundation
import UIKit

public protocol LLMClientType {
    func send<RequestFormat: Encodable, ResponseContent: Decodable>(
        request: ChatRequest<RequestFormat>,
        endpoint: URL,
        completion: @escaping (Result<ResponseContent, Error>) -> Void
      )
    func send<Req: Encodable, Resp: Decodable>(
      payload: Req,
      to endpoint: URL,
      completion: @escaping (Result<Resp, Error>) -> Void
    )
}

    public final class LLMClient: LLMClientType {
      private let session: URLSession
      private let apiKey: String

      public init(session: URLSession = .shared, apiKey: String) {
        self.session = session
        self.apiKey = apiKey
      }

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
          if let error = error { return completion(.failure(error)) }
          guard let data = data else {
            return completion(.failure(URLError(.badServerResponse)))
          }
          debugPrint("LLM Raw Response:", String(data: data, encoding: .utf8) ?? "<nil>")
          do {
            let topLevel = try JSONDecoder().decode(ChatResponse<Resp>.self, from: data)
            let contentString = topLevel.choices.first?.message.content ?? ""
            let contentData = Data(contentString.utf8)
            let parsed = try JSONDecoder().decode(Resp.self, from: contentData)
            completion(.success(parsed))
          } catch {
            completion(.failure(error))
          }
        }.resume()
      }
    
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
            debugPrint("---------------RAGGG Request Body-------:", String(data: req.httpBody!, encoding: .utf8)!)

        } catch {
          return completion(.failure(error))
        }

        session.dataTask(with: req) { data, _, error in
          if let error = error { return completion(.failure(error)) }
          guard let data = data else {
            return completion(.failure(URLError(.badServerResponse)))
          }
        debugPrint("---------------RAGGG Response-------:", String(data: data, encoding: .utf8) ?? "<nil>")

          do {
            let decoded = try JSONDecoder().decode(Resp.self, from: data)
            completion(.success(decoded))
          } catch {
            completion(.failure(error))
          }
        }.resume()
      }
}
