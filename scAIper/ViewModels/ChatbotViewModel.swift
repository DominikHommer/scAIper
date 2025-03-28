//
//  ChatbotViewModel.swift
//  scAIper
//
//  Created by Dominik Hommer on 28.03.25.
//
import SwiftUI

class ChatbotViewModel: ObservableObject {
    @Published var chatMessages: [ChatMessage] = [
        ChatMessage(text: "Hallo! Ich bin der Chatbot. Wie kann ich dir helfen?", isUser: false)
    ]
    
    private let service = ChatbotService.shared
    
    func sendMessage(_ userInput: String) {
        guard !userInput.isEmpty else { return }
        
        // Füge Nutzereingabe hinzu
        let userMessage = ChatMessage(text: userInput, isUser: true)
        chatMessages.append(userMessage)
        
        // Anfrage an den Service
        service.queryChatCompletion(input: userInput) { [weak self] result in
            DispatchQueue.main.async {
                switch result {
                case .success(let botResponse):
                    let botMessage = ChatMessage(text: botResponse, isUser: false)
                    self?.chatMessages.append(botMessage)
                case .failure(let error):
                    let errorMessage = ChatMessage(text: "Fehler: \(error.localizedDescription)", isUser: false)
                    self?.chatMessages.append(errorMessage)
                }
            }
        }
    }
}
