//
//  ChatbotService.swift
//  scAIper
//
//  Created by Dominik Hommer on 28.03.25.
//

import SwiftUI

class ChatbotService {
    static let shared = ChatbotService()
    
    private init() {
        resetConversation()
    }

    private let apiUrlString = "https://api.groq.com/openai/v1/chat/completions"
    private let modelNameCompletion = "llama-3.3-70b-specdec"
    private let modelNameDocCheck = "llama-3.3-70b-specdec"
    private let systemMessageContent = """
    Du bist ein freundlicher, intelligenter und hilfsbereiter Assistent namens scAIper, der Nutzern dabei hilft, Informationen aus gescannten Dokumenten zu extrahieren und verständlich aufzubereiten. Deine Hauptaufgaben umfassen:
     - Fragen zu Inhalten aus eingescannten Tabellen, Rechnungen, Verträgen, Lohnabrechnungen und anderen Dokumententypen klar und präzise zu beantworten.
     - Wichtige Termine und Fristen (z. B. Kündigungsfristen aus Verträgen, Zahlungsfristen von Rechnungen) automatisch zu erkennen und auf Anfrage mitzuteilen.
     - Überblick und Analysen zu persönlichen Finanzen oder anderen dokumentbasierten Informationen verständlich zusammenzufassen.
     - Nutzer bei der Verwaltung und Organisation ihrer digitalen Dokumente aktiv zu unterstützen.
     - Antworte stets freundlich, klar und strukturiert, und achte darauf, Informationen präzise und zuverlässig bereitzustellen. Wenn Informationen nicht verfügbar oder unklar sind, weise höflich darauf hin und biete weitere Hilfestellungen an.
    
    """

    private var conversationHistory: [[String: Any]] = []
    
    func resetConversation() {
        conversationHistory = [
            [
                "role": "system",
                "content": systemMessageContent
            ]
        ]
    }
    
    private func appendMessage(role: String, content: String) {
        let message: [String: Any] = [
            "role": role,
            "content": content
        ]
        conversationHistory.append(message)
    }

    func queryDocumentCheck(input: String, completion: @escaping (Result<Bool, Error>) -> Void) {
        let fewShotMessages: [[String: Any]] = [
            [
                "role": "system",
                "content": "Du sollst prüfen, ob der Nutzer Informationen zu Dokumenten oder spezifische persönliche Daten abfragt. Es könnte um Rechnungen, Verträge, Berichte, Lohnzettel oder Andere Dokumente gehen. Antworte ausschließlich mit 'ja' oder 'nein'!"
            ],
            [
                "role": "user",
                "content": "Hat folgende Frage/Aussage/Satz etwas mit persönlichen Daten oder Dokumenten zu tun? : Kannst du meinen Vertrag analysieren?"
            ],
            [
                "role": "assistant",
                "content": "ja"
            ],
            [
                "role": "user",
                "content": "Hat folgende Frage/Aussage/Satz etwas mit persönlichen Daten oder Dokumenten zu tun? : Wie ist das Wetter heute?"
            ],
            [
                "role": "assistant",
                "content": "nein"
            ],
            [
                "role": "user",
                "content": "Hat folgende Frage/Aussage/Satz etwas mit persönlichen Daten oder Dokumenten zu tun? : Zeig mir meine letzten Rechnungen."
            ],
            [
                "role": "assistant",
                "content": "ja"
            ],
            [
                "role": "user",
                "content": "Hat folgende Frage/Aussage/Satz etwas mit persönlichen Daten oder Dokumenten zu tun? : Erzähl mir einen Witz."
            ],
            [
                "role": "assistant",
                "content": "nein"
            ]
        ]
        let actualUserMessage: [String: Any] = [
            "role": "user",
            "content": "Hat folgende Frage/Aussage/Satz etwas mit persönlichen Daten oder Dokumenten zu tun? : " + input
        ]

        let payload: [String: Any] = [
            "messages": fewShotMessages + [actualUserMessage],
            "model": self.modelNameDocCheck,
            "temperature": 1.0,
            "max_completion_tokens": 4096,
            "top_p": 1.0,
            "stream": false,
            "stop": "None"
        ]
        
        performRequest(with: payload) { result in
            switch result {
            case .success(let jsonResponse):
                if let content = self.extractContent(from: jsonResponse) {
                    let extracted = self.extractAfterThink(from: content)
                    print("Extracted:", extracted)
                    let answer = extracted.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
                    print("Answer", answer)
                    
                    completion(.success(answer == "ja"))
                } else {
                    let error = NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Ungültige JSON-Struktur beim Dokumentencheck"])
                    completion(.failure(error))
                }
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
    

    func queryChatCompletion(input: String, completion: @escaping (Result<String, Error>) -> Void) {
        queryDocumentCheck(input: input) { [weak self] result in
            guard let self = self else { return }
            switch result {
            case .success(let wantsDocumentInfo):
                if wantsDocumentInfo {
                    RAGManager.shared.processRAG(for: input) { ragOutput in
                        print(input, ragOutput)
                        self.appendMessage(
                            role: "user",
                            content:
                            """
                            \(input)

                            Das hier sind passende Dokumentabschnitte zu meiner Frage:
                            \(ragOutput)

                            **Wichtiger Hinweis für dich**: Solltest du die Informationen dort nicht finden, erfinde bitte keine Informationen! Gib stattdessen ehrlich an, dass du in den Dokumenten nichts finden konntest.
                            """
                        )

                        
                        let payload: [String: Any] = [
                            "messages": self.conversationHistory,
                            "model": self.modelNameCompletion,
                            "temperature": 1.0,
                            "max_completion_tokens": 4096,
                            "top_p": 1.0,
                            "stream": false,
                            "stop": "None"
                        ]
                        self.performRequest(with: payload) { result in
                            switch result {
                            case .success(let jsonResponse):
                                if let content = self.extractContent(from: jsonResponse) {
                                    self.appendMessage(role: "assistant", content: content)
                                    let extracted = self.extractAfterThink(from: content)
                                    completion(.success(extracted))
                                } else {
                                    let error = NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Ungültige JSON-Struktur bei RAG Chat Completion"])
                                    completion(.failure(error))
                                }
                            case .failure(let error):
                                completion(.failure(error))
                            }
                        }
                    }
                } else {
                    self.appendMessage(role: "user", content: input)
                    let payload: [String: Any] = [
                        "messages": self.conversationHistory,
                        "model": self.modelNameCompletion,
                        "temperature": 1.0,
                        "max_completion_tokens": 4096,
                        "top_p": 1.0,
                        "stream": false,
                        "stop": "None"
                    ]
                    self.performRequest(with: payload) { result in
                        switch result {
                        case .success(let jsonResponse):
                            if let content = self.extractContent(from: jsonResponse) {
                                self.appendMessage(role: "assistant", content: content)
                                let extracted = self.extractAfterThink(from: content)
                                completion(.success(extracted))
                            } else {
                                let error = NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Ungültige JSON-Struktur bei Chat Completion"])
                                completion(.failure(error))
                            }
                        case .failure(let error):
                            completion(.failure(error))
                        }
                    }
                }
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }

    
    private func performRequest(with payload: [String: Any], completion: @escaping (Result<[String: Any], Error>) -> Void) {
        guard let url = URL(string: apiUrlString) else {
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
        
        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: payload, options: [])
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
                if let jsonResponse = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any] {
                    completion(.success(jsonResponse))
                } else {
                    let error = NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Ungültige JSON-Struktur"])
                    completion(.failure(error))
                }
            } catch {
                completion(.failure(error))
            }
        }.resume()
    }
    
    private func extractContent(from jsonResponse: [String: Any]) -> String? {
        guard let choices = jsonResponse["choices"] as? [[String: Any]],
              let firstChoice = choices.first,
              let messageDict = firstChoice["message"] as? [String: Any],
              let content = messageDict["content"] as? String else {
            print("Fehler beim Parsen der Chat Completion Antwort. Antwort war:", jsonResponse)
            return nil
        }
        return content
    }

    
    private func extractAfterThink(from content: String) -> String {
        if let range = content.range(of: "</think>") {
            return String(content[range.upperBound...]).trimmingCharacters(in: .whitespacesAndNewlines)
        }
        return content
    }
}



