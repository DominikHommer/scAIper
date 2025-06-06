//
//  OCRLLMService.swift
//  scAIper
//
//  Created by Dominik Hommer on 09.04.25.
//


import Foundation
import UIKit

struct OCRLLMService {
    static func sendLLMRequest(with grid: [(text: String, x: CGFloat, y: CGFloat)], completion: @escaping ([String: Any]?) -> Void) {
        let systemPrompt = """
        You are given a list of extracted text elements from a scanned table. Each element contains a `text` value along with its approximate `x` and `y` coordinates (normalized between 0 and 1). Your task is to reconstruct the original tabular structure.

        Use the `y` coordinate to group elements into rows — values with similar `y` positions belong to the same row. Use the `x` coordinate to assign each element to its appropriate column based on horizontal alignment. In addition, apply your domain knowledge and common sense to interpret and organize the table logically.

        Some values may be split across multiple elements (e.g., "L" and "001" should be combined into "L001"). Use contextual understanding and spatial proximity to merge such fragments when appropriate.

        The first row typically contains column headers. All subsequent rows represent data entries. Do not translate or reinterpret any values — keep the original text. Your only task is to reconstruct structure.

        Your output should be a structured representation of the table using the following JSON format:

        {
          "title": "GenericTable",
          "type": "object",
          "properties": {
            "header": {
              "type": "array",
              "items": {
                "type": "string"
              },
              "description": "An array of consolidated column headers, even if originally spread across several rows."
            },
            "table": {
              "type": "array",
              "items": {
                "type": "object",
                "additionalProperties": {
                  "type": ["string", "number", "boolean", "null"]
                }
              },
              "description": "A list of structured data rows matching the unified header."
            }
          },
          "required": ["header", "table"]
        }

        """
        let systemMessage: [String: String] = [
            "role": "system",
            "content": systemPrompt
        ]
        
        let gridJSONArray: [[String: Any]] = grid.map { ["text": $0.text, "x": $0.x, "y": $0.y] }

        let gridJSONString: String = {
            do {
                let jsonData = try JSONSerialization.data(withJSONObject: gridJSONArray, options: [.prettyPrinted])
                return String(data: jsonData, encoding: .utf8) ?? ""
            } catch {
                print("Fehler beim Serialisieren des Grids: \(error)")
                return ""
            }
        }()

        let fewShotMessages: [[String: String]] = [
            [
                "role": "user",
                "content": """
                Here is the unstructured table grid:
                [(text: "ID", x: 0.1, y: 0.01), (text: "Item", x: 0.3, y: 0.01), (text: "Qty", x: 0.5, y: 0.01),
                 (text: "A", x: 0.1, y: 0.1), (text: "1", x: 0.13, y: 0.1), (text: "Widget", x: 0.3, y: 0.1), (text: "10", x: 0.5, y: 0.1)]
                """
            ],
            [
                "role": "assistant",
                "content": """
                {
                  "header": ["ID", "Item", "Qty"],
                  "table": [
                    {"ID": "A1", "Item": "Widget", "Qty": 10}
                  ]
                }
                """
            ],
            [
                "role": "user",
                "content": """
                Here is the unstructured table grid:
                [(text: "Code", x: 0.1, y: 0.02), (text: "Name", x: 0.3, y: 0.02),
                 (text: "B", x: 0.1, y: 0.12), (text: "204", x: 0.15, y: 0.12), (text: "Bolt", x: 0.3, y: 0.12)]
                """
            ],
            [
                "role": "assistant",
                "content": """
                {
                  "header": ["Code", "Name"],
                  "table": [
                    {"Code": "B204", "Name": "Bolt"}
                  ]
                }
                """
            ]
        ]


        
        let userMessage: [String: String] = [
            "role": "user",
            "content": "Here is the unstructured table grid:\n\(gridJSONString)"
        ]
        
        let payload: [String: Any] = [
            "messages": [systemMessage] + fewShotMessages + [userMessage],
            "model": OCRManager.modelNameDocCheck,
            "temperature": 0.8,
            "max_completion_tokens": 8192,
            "top_p": 1.0,
            "seed": 42,
            "response_format": ["type": "json_object"],
            "stream": false,
            "stop": "None"
        ]
        
        guard let url = URL(string: "https://api.groq.com/openai/v1/chat/completions") else {
            print("Ungültige URL.")
            completion(nil)
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
        
        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: payload, options: [])
        } catch {
            print("Fehler beim Serialisieren des Payloads: \(error)")
            completion(nil)
            return
        }
        
        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                print("Fehler bei der Anfrage an das LLM: \(error)")
                completion(nil)
                return
            }
            
            guard let data = data else {
                print("Keine Daten vom LLM erhalten.")
                completion(nil)
                return
            }
            
            if let responseString = String(data: data, encoding: .utf8) {
                print("Raw LLM-Antwort: \(responseString)")
            } else {
                print("Die empfangenen Daten konnten nicht in einen String umgewandelt werden.")
            }
            
            do {
                if let outerJSON = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any],
                   let choices = outerJSON["choices"] as? [[String: Any]],
                   let firstChoice = choices.first,
                   let message = firstChoice["message"] as? [String: Any],
                   let content = message["content"] as? String {
                    
                    if let contentData = content.data(using: .utf8),
                       let structuredResponse = try JSONSerialization.jsonObject(with: contentData, options: []) as? [String: Any] {
                        completion(structuredResponse)
                    } else {
                        print("Fehler beim Parsen des Inhalts.")
                        completion(nil)
                    }
                } else {
                    print("Die Antwort entspricht nicht dem erwarteten Format.")
                    completion(nil)
                }
            } catch {
                print("Fehler beim Parsen der LLM-Antwort: \(error)")
                completion(nil)
            }
        }
        task.resume()
    }
}


