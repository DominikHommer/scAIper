//
//  ChatbotViewModel.swift
//  scAIper
//
//  Created by Dominik Hommer on 28.03.25.
//

import SwiftUI

class ChatbotViewModel: ObservableObject {
    @Published var chatMessages: [ChatMessage] = [
        ChatMessage(text: "Hallo! Ich bin scAIper. Wie kann ich dir helfen?", isUser: false)
    ]

    private let service = ChatbotService.shared

    func sendMessage(_ userInput: String) {
        guard !userInput.isEmpty else { return }

        // 1) Nutzer-Nachricht anhängen
        let userMessage = ChatMessage(text: userInput, isUser: true)
        chatMessages.append(userMessage)

        // 2) Lade-Platzhalter
        let loadingMessage = ChatMessage(text: "", isUser: false, isLoading: true)
        chatMessages.append(loadingMessage)

        // 3) Anfrage ans Service
        service.queryChatCompletion(input: userInput) { [weak self] result in
            DispatchQueue.main.async {
                // Lade-Platzhalter entfernen
                self?.chatMessages.removeAll(where: { $0.isLoading })

                switch result {
                case .success(let botResponse):
                    let botMessage = ChatMessage(text: botResponse, isUser: false)
                    self?.chatMessages.append(botMessage)

                case .failure(let error):
                    let errorMessage = ChatMessage(
                        text: "Fehler: \(error.localizedDescription)",
                        isUser: false
                    )
                    self?.chatMessages.append(errorMessage)
                }
            }
        }
    }

    func resetHistory() {
        service.resetHistory()
        chatMessages = [
            ChatMessage(text: "Hallo! Ich bin scAIper. Wie kann ich dir helfen?", isUser: false)
        ]
    }
}


