//
//  OCRLLMService.swift
//  scAIper
//
//  Created by Dominik Hommer on 09.04.25.
//


import Foundation
import UIKit

struct OCRLLMService {
    static func sendLLMRequest(with grid: [[String]], completion: @escaping ([String: Any]?) -> Void) {
        let systemPrompt = """
        You are a helpful data assistant. Your task is to process extremely unstructured tables and return them as clean, structured JSON.

        The input will be a table represented as a list of rows (nested lists). These rows may contain:
        - partial or fully shifted data,
        - missing entries,
        - multiple header rows that must be merged into one consistent header,
        - and irrelevant or noisy filler data.

        Your responsibilities:
        1. **Detect and merge** the correct header row. The header may be split across several rows (e.g. ["Hire", "Date"] and ["Years", "of", "Service"]). Combine these into clear column names such as "Hire Date", "Years of Service", etc.
        2. **Ignore filler rows** that contain only one or two words (e.g. "Status", "Store", "Job", "T", or "S") or are obviously incomplete.
        3. Create structured rows where each dictionary key matches the final header structure.
        4. Fill missing values with `null`.
        5. Remove any trailing noise or values that do not align with the structure.
        6. Provide your answer in **valid JSON**, following this schema:

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
        
        let gridJSONString: String = {
            do {
                let jsonData = try JSONSerialization.data(withJSONObject: grid, options: [.prettyPrinted])
                return String(data: jsonData, encoding: .utf8) ?? ""
            } catch {
                print("Fehler beim Serialisieren des Grids: \(error)")
                return "\(grid)"
            }
        }()
        let fewShotMessages: [[String: String]] = [
            [
                "role": "user",
                "content": "Here is the unstructured table grid:\n[[\"Name\", \"Age\", \"City\"], [\"Alice\", \"30\", \"Berlin\"], [\"Bob\", \"28\", \"Munich\"]]"
            ],
            [
                "role": "assistant",
                "content": "{\n  \"header\": [\"Name\", \"Age\", \"City\"],\n  \"table\": [\n    {\"Name\": \"Alice\", \"Age\": \"30\", \"City\": \"Berlin\"},\n    {\"Name\": \"Bob\", \"Age\": \"28\", \"City\": \"Munich\"}\n  ]\n}"
            ],
            [
                "role": "user",
                "content": "Here is the unstructured table grid:\n[[\"First\", \"Last\"], [\"Name\", \"Name\"], [\"Alice\", \"Smith\"], [\"Bob\", \"\"]]"
            ],
            [
                "role": "assistant",
                "content": "{\n  \"header\": [\"First Name\", \"Last Name\"],\n  \"table\": [\n    {\"First Name\": \"Alice\", \"Last Name\": \"Smith\"},\n    {\"First Name\": \"Bob\", \"Last Name\": null}\n  ]\n}"
            ]
        ]
        
        let userMessage: [String: String] = [
            "role": "user",
            "content": "Here is the unstructured table grid:\n\(gridJSONString)"
        ]
        
        let payload: [String: Any] = [
            "messages": [systemMessage] + fewShotMessages + [userMessage],
            "model": OCRManager.modelNameDocCheck,
            "temperature": 1.0,
            "max_completion_tokens": 8000,
            "top_p": 1.0,
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
