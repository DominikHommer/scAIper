//  KeywordLLMExtractor.swift
//  scAIper
//
//  Created by Dominik Hommer on 06.06.25.
//

import Foundation

struct KeywordLLMExtractor {
    static func extractKeywords(documentType: DocumentType, text: String, completion: @escaping ([String: String]?) -> Void) {
        // 1) Definiere das JSON-Schema als Swift-Dictionary, abhängig vom Dokumenttyp:
        let (schemaName, schemaDefinition): (String, [String: Any]) = {
            if documentType == .rechnung {
                let fields = [
                    "Rechnungsnummer",
                    "Rechnungsdatum",
                    "Gesamtbetrag",
                    "IBAN",
                    "USt-ID"
                ]
                // Schema-Definition für Rechnung
                var props: [String: Any] = [:]
                for field in fields {
                    props[field] = ["type": "string"]
                }
                return (
                    "InvoiceKeywords",
                    [
                        "type": "object",
                        "properties": props,
                        "required": fields,
                        "additionalProperties": false
                    ]
                )
            } else {
                let fields = [
                    "Bruttolohn",
                    "Nettolohn",
                    "Steuerklasse",
                    "Sozialversicherung",
                    "Zeitraum"
                ]
                // Schema-Definition für Gehaltsabrechnung
                var props: [String: Any] = [:]
                for field in fields {
                    props[field] = ["type": "string"]
                }
                return (
                    "SalaryKeywords",
                    [
                        "type": "object",
                        "properties": props,
                        "required": fields,
                        "additionalProperties": false
                    ]
                )
            }
        }()
        
        // 2) Vollständiges json_schema-Objekt mit "name" und "schema":
        let fullJsonSchema: [String: Any] = [
            "name": schemaName,
            "schema": schemaDefinition
        ]
        let schemaFieldsList = (documentType == .rechnung)
            ? """
            {
              "Rechnungsnummer": "string",
              "Rechnungsdatum": "string",
              "Gesamtbetrag": "string",
              "IBAN": "string",
              "USt-ID": "string"
            }
            """
            : """
            {
              "Bruttolohn": "string",
              "Nettolohn": "string",
              "Steuerklasse": "string",
              "Sozialversicherung": "string",
              "Zeitraum": "string"
            }
            """

        let systemPrompt = """
        Extrahiere die wichtigsten Informationen aus dem OCR-Text einer \(documentType.rawValue). Gib das Ergebnis im JSON-Format basierend auf folgendem Schema zurück:

        \(schemaFieldsList)
        """

        let systemMessage: [String: String] = [
            "role": "system",
            "content": systemPrompt
        ]

        // 4) Few-Shot-Beispiele bleiben unverändert (für Vergleichszwecke):
        let fewShotMessages: [[String: String]] = (documentType == .rechnung) ? [
            [
                "role": "user",
                "content": """
                OCR-Text:
                \"\"\"
                Rechnung Nr. 123456 vom 01.01.2024
                Gesamtbetrag: 345,67 EUR
                IBAN: DE12345678901234567890
                USt-ID: DE999999999
                \"\"\"
                """
            ],
            [
                "role": "assistant",
                "content": """
                {
                  "Rechnungsnummer": "123456",
                  "Rechnungsdatum": "01.01.2024",
                  "Gesamtbetrag": "345,67 EUR",
                  "IBAN": "DE12345678901234567890",
                  "USt-ID": "DE999999999"
                }
                """
            ]
        ] : [
            [
                "role": "user",
                "content": """
                OCR-Text:
                \"\"\"
                Bruttolohn: 4000€
                Nettolohn: 2600€
                Steuerklasse: 1
                Sozialversicherung: 700€
                Zeitraum: Januar 2024
                \"\"\"
                """
            ],
            [
                "role": "assistant",
                "content": """
                {
                  "Bruttolohn": "4000€",
                  "Nettolohn": "2600€",
                  "Steuerklasse": "1",
                  "Sozialversicherung": "700€",
                  "Zeitraum": "Januar 2024"
                }
                """
            ]
        ]

        let userMessage: [String: String] = [
            "role": "user",
            "content": "OCR-Text:\n\"\"\"\n\(text)\n\"\"\""
        ]

        // 5) Baue das Payload mit response_format: json_schema auf
        let payload: [String: Any] = [
            "model": OCRManager.modelNameDocCheck,
            "messages": [systemMessage] + fewShotMessages + [userMessage],
            "temperature": 0.2,
            "top_p": 1.0,
            "max_completion_tokens": 1024,
            "stream": false,
            // response_format mit type "json_schema" und dem fullJsonSchema
            "response_format": [
                "type": "json_schema",
                "json_schema": fullJsonSchema
            ]
        ]

        // 6) Debug-Ausgaben: Payload als JSON-String
        if let payloadData = try? JSONSerialization.data(withJSONObject: payload, options: [.prettyPrinted]),
           let payloadString = String(data: payloadData, encoding: .utf8) {
            print("==== KeywordLLMExtractor Payload ====")
            print(payloadString)
            print("=====================================")
        }

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

        // 7) Sende die Anfrage und füge Debugging für Status-Code und Header hinzu
        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                print("Fehler bei der LLM-Anfrage: \(error)")
                completion(nil)
                return
            }

            if let httpResponse = response as? HTTPURLResponse {
                print("---- HTTP Response ----")
                print("Status Code: \(httpResponse.statusCode)")
                print("Headers: \(httpResponse.allHeaderFields)")
                print("-----------------------")
            }

            guard let data = data else {
                print("Keine Daten vom LLM erhalten.")
                completion(nil)
                return
            }

            // 8) Roh-Antwort ausgeben
            if let responseString = String(data: data, encoding: .utf8) {
                print("Raw LLM-Antwort: \(responseString)")
            } else {
                print("Die empfangenen Daten konnten nicht in einen String umgewandelt werden.")
            }

            do {
                // 9) Parsen der Antwortstruktur
                if let outerJSON = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any],
                   let choices = outerJSON["choices"] as? [[String: Any]],
                   let firstChoice = choices.first,
                   let message = firstChoice["message"] as? [String: Any],
                   let content = message["content"] as? String {
                    
                    // 10) Debug-Ausgabe: content-Feld
                    print("---- Parsed 'content' Feld ----")
                    print(content)
                    print("-------------------------------")
                    
                    if let contentData = content.data(using: .utf8),
                       let dict = try? JSONDecoder().decode([String: String].self, from: contentData) {
                        completion(dict)
                    } else {
                        print("Fehler beim Parsen des Inhalts als [String:String].")
                        completion(nil)
                    }
                } else {
                    print("Antwortstruktur unerwartet. Erwartet 'choices' -> 'message' -> 'content'.")
                    completion(nil)
                }
            } catch {
                print("Parsing-Fehler: \(error)")
                completion(nil)
            }
        }
        task.resume()
    }
}

