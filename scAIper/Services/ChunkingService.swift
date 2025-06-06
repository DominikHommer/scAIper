//
//  ChunkingService.swift
//  scAIper
//
//  Created by Dominik Hommer on 10.04.25.
//


import Foundation

final class ChunkingService {
    static let shared = ChunkingService()
    private init() {}
    func chunkTextWithLLM(_ text: String, completion: @escaping (Result<[Chunk], Error>) -> Void) {
        guard let url = URL(string: "https://api.groq.com/openai/v1/chat/completions") else {
            completion(.failure(URLError(.badURL)))
            return
        }

        let systemPrompt = """
        Du bist ein intelligenter Assistent, der einen langen Text in sinnvoll gegliederte, thematisch zusammenhängende Abschnitte („Chunks“) aufteilt.

        Deine Ausgabe MUSS ausschließlich ein gültiges JSON-Array von Objekten sein – keine Einleitung, keine Erklärungen, kein Markdown, keine Kommentare.

        Regeln:
        - Jeder Chunk enthält ein Feld chunk_index (beginnend bei 0) und ein Feld text.
        - Der Text soll ca. 100–120 Wörter enthalten.
        - Jeder Chunk endet am Ende eines Satzes.
        - Antworte in folgendem JSON-Format:

        {
          "name": "ChunkedText",
          "type": "array",
          "items": {
            "type": "object",
            "properties": {
              "chunk_index": {
                "type": "integer",
                "description": "A zero-based index indicating the order of the chunk in the overall document."
              },
              "text": {
                "type": "string",
                "description": "A coherent paragraph or text section, ideally thematically grouped, ending at a sentence boundary and containing approximately 100–120 words."
              }
            },
            "required": ["chunk_index", "text"],
            "additionalProperties": false
          },
          "description": "An array of text chunks, each representing a meaningful section of the input text. Each chunk must include a chunk_index and the associated text content."
        }

        """

        let fewShotExamples: [[String: Any]] = [
            [
                "role": "user",
                "content": "Zerlege diesen Lebenslauf in Abschnitte: Eva Musterfrau, geboren am 05.01.1982 in Hamburg. Seit 11/2016: Dritte Station GmbH. Ausbildung: 10/2007 - 10/2011 BWL-Studium Universität Musterstadt."
            ],
            [
                "role": "assistant",
                "content": "[{\"chunk_index\":0,\"text\":\"Eva Musterfrau, geboren am 05.01.1982 in Hamburg.\"},{\"chunk_index\":1,\"text\":\"Seit 11/2016: Dritte Station GmbH.\"},{\"chunk_index\":2,\"text\":\"Ausbildung: 10/2007 - 10/2011 BWL-Studium Universität Musterstadt.\"}]"
            ]
        ]


        let messages: [[String: Any]] = [
            ["role": "system", "content": systemPrompt]
        ] + fewShotExamples + [
            ["role": "user", "content": text]
        ]
        // 1. Definiere zuerst nur den reinen Schema‐Teil (ohne „name“):
        let chunkSchemaDef: [String: Any] = [
            "type": "array",
            "items": [
                "type": "object",
                "properties": [
                    "chunk_index": [
                        "type": "integer",
                        "description": "Index der Reihenfolge"
                    ],
                    "text": [
                        "type": "string",
                        "description": "Abschnittstext mit 100–120 Wörtern"
                    ]
                ],
                "required": ["chunk_index", "text"],
                "additionalProperties": false
            ],
            "description": "Ein Array von Text-Chunks, each mit chunk_index und text."
        ]

        // 2. Packe diesen Teil unter „schema“ und gib zusätzlich den „name“ an:
        let fullJsonSchema: [String: Any] = [
            "name": "ChunkedText",
            "schema": chunkSchemaDef
        ]

        // 3. Setze response_format entsprechend:
        let payload: [String: Any] = [
            "model": "meta-llama/llama-4-maverick-17b-128e-instruct",
            "temperature": 0.8,
            "top_p": 1,
            "stream": false,
            "max_completion_tokens": 8000,
            "response_format": [
                "type": "json_schema",
                "json_schema": fullJsonSchema
            ],
            "messages": messages
        ]



        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        if let apiKey = Bundle.main.infoDictionary?["GROQ_API_KEY"] as? String {
            request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        } else {
            print("Kein API-Key gefunden!")
        }

        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: payload, options: .prettyPrinted)
            if let body = request.httpBody, let bodyString = String(data: body, encoding: .utf8) {
                print("Request Body:\n\(bodyString)")
            }
        } catch {
            completion(.failure(error))
            return
        }

        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                print("Request-Fehler:", error)
                completion(.failure(error))
                return
            }

            if let httpResponse = response as? HTTPURLResponse {
                print("HTTP-Status: \(httpResponse.statusCode)")
                print("Headers: \(httpResponse.allHeaderFields)")
            }

            guard let data = data else {
                completion(.failure(URLError(.badServerResponse)))
                return
            }

            if let rawResponse = String(data: data, encoding: .utf8) {
                print("Raw Response Body:\n\(rawResponse)")
            }

            do {
                let topLevel = try JSONSerialization.jsonObject(with: data) as? [String: Any]

                if let errorDict = topLevel?["error"] as? [String: Any],
                   let failed = errorDict["failed_generation"] as? String {
                    let fallback = "[\(failed)]"
                    if let fallbackData = fallback.data(using: .utf8) {
                        let chunks = try JSONDecoder().decode([Chunk].self, from: fallbackData)
                        completion(.success(chunks))
                        return
                    }
                }

                if let content = (topLevel?["choices"] as? [[String: Any]])?.first?["message"] as? [String: Any],
                   let contentString = content["content"] as? String {
                    
                    if let range = contentString.range(of: #"(?s)\[\s*\{.*?\}\s*\]"#, options: .regularExpression) {
                        let jsonString = String(contentString[range])
                        if let jsonData = jsonString.data(using: .utf8) {
                            let chunks = try JSONDecoder().decode([Chunk].self, from: jsonData)
                            completion(.success(chunks))
                            return
                        }
                    }

                    throw NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Konnte kein gültiges JSON-Array im Antworttext finden."])
                }
                else {
                    throw NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Ungültige JSON-Struktur beim Chunking von Groq-Antwort"])
                }
            } catch {
                print("Fehler beim Parsen der JSON-Antwort:", error)
                completion(.failure(error))
            }
        }.resume()
    }
}
