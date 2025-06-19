//
//  ChatbotViewModel.swift
//  scAIper
//
//  Created by Dominik Hommer on 28.03.25.
//

import SwiftUI

/// ViewModel responsible for managing chatbot messages and interactions with the chat service.
class ChatbotViewModel: ObservableObject {
    
    /// The list of chat messages exchanged between the user and the chatbot.
    @Published var chatMessages: [ChatMessage] = [
        ChatMessage(text: "Hallo! Ich bin scAIper. Wie kann ich dir helfen?", isUser: false)
    ]

    /// Singleton instance of the chatbot service used for message completion.
    private let service = ChatbotService.shared

    /// Sends a message from the user and appends the chatbot's response to the conversation.
    /// - Parameter userInput: The user's input message to send to the chatbot.
    func sendMessage(_ userInput: String) {
        print("sendMessage called with: \(userInput)")
        // Do not send empty messages
        guard !userInput.isEmpty else { return }

        // Append the user's message to the conversation
        let userMessage = ChatMessage(text: userInput, isUser: true)
        chatMessages.append(userMessage)

        // Append a loading indicator message while waiting for the response
        let loadingMessage = ChatMessage(text: "", isUser: false, isLoading: true)
        chatMessages.append(loadingMessage)

        // Send the message to the chatbot service
        service.queryChatCompletion(input: userInput) { [weak self] result in
            DispatchQueue.main.async {
                // Remove the loading indicator message
                self?.chatMessages.removeAll(where: { $0.isLoading })

                // Append the result from the chatbot
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

    /// Resets the chat history to the initial welcome message and clears backend memory.
    func resetHistory() {
        service.resetHistory()
        chatMessages = [
            ChatMessage(text: "Hallo! Ich bin scAIper. Wie kann ich dir helfen?", isUser: false)
        ]
    }
}

