//
//  ChatbotService.swift
//  scAIper
//
//  Created by Dominik Hommer on 28.03.25.
//
import SwiftUI

struct ChatbotService {
    static let shared = ChatbotService()
    
    func queryChatCompletion(input: String, completion: @escaping (Result<String, Error>) -> Void) {
        guard let url = URL(string: "https://api.groq.com/openai/v1/chat/completions") else {
            completion(.failure(URLError(.badURL)))
            return
        }
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        if let apiKey = Bundle.main.infoDictionary?["GROQ_API_KEY"] as? String {
            request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        } else {
            print("API-Key nicht gefunden!")
        }
        
        let messageDict: [String: Any] = [
            "role": "user",
            "content": input
        ]
        let json: [String: Any] = [
            "messages": [messageDict],
            "model": "deepseek-r1-distill-llama-70b",
            "temperature": 0.6,
            "max_completion_tokens": 4096,
            "top_p": 0.95,
            "stream": false,
            "stop": NSNull()
        ]
        
        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: json, options: [])
        } catch {
            completion(.failure(error))
            return
        }
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            guard let data = data else {
                completion(.failure(URLError(.badServerResponse)))
                return
            }
            
            do {
                if let jsonResponse = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any],
                   let choices = jsonResponse["choices"] as? [[String: Any]],
                   let firstChoice = choices.first,
                   let messageDict = firstChoice["message"] as? [String: Any],
                   let content = messageDict["content"] as? String {
                    
                    // Falls ein spezieller Marker existiert, Text extrahieren
                    if let range = content.range(of: "</think>") {
                        let extracted = String(content[range.upperBound...]).trimmingCharacters(in: .whitespacesAndNewlines)
                        completion(.success(extracted))
                    } else {
                        completion(.success(content))
                    }
                } else {
                    let error = NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Ungültige JSON-Struktur"])
                    completion(.failure(error))
                }
            } catch {
                completion(.failure(error))
            }
        }.resume()
    }
}
