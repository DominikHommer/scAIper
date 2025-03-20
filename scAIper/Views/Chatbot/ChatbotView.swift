//
//  ChatbotView.swift
//  scAIper
//
//  Created by Dominik Hommer on 17.03.25.
//


import SwiftUI

struct ChatbotView: View {
    @State private var userInput: String = ""
    @State private var chatMessages: [ChatMessage] = [
        ChatMessage(text: "Hallo! Ich kann dir helfen, deine Dokumente zu verstehen. Frage mich etwas!", isUser: false)
    ]
    
    var body: some View {
        VStack {
            Text("Dokumenten-Chatbot")
                .font(.title)
                .fontWeight(.bold)
                .padding(.top, 20)
            
            ScrollView {
                VStack(alignment: .leading, spacing: 10) {
                    ForEach(chatMessages) { message in
                        ChatBubble(message: message)
                    }
                }
            }
            .padding()
            
            // Eingabezeile
            HStack {
                TextField("Frage den Chatbot...", text: $userInput)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                
                Button(action: sendMessage) {
                    Image(systemName: "paperplane.fill")
                        .foregroundColor(.blue)
                }
            }
            .padding()
        }
    }
    
    private func sendMessage() {
        guard !userInput.isEmpty else { return }
        
        // Füge die Nutzernachricht hinzu
        let userMessage = ChatMessage(text: userInput, isUser: true)
        chatMessages.append(userMessage)
        
        // Simulierte KI-Antwort
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            let botResponse = ChatMessage(text: "Ich habe deine Frage erhalten: \"\(userInput)\". Leider kann ich derzeit noch keine genaue Antwort geben.", isUser: false)
            chatMessages.append(botResponse)
        }
        
        // Eingabe leeren
        userInput = ""
    }
}

// Modell für Chat-Nachricht
struct ChatMessage: Identifiable {
    let id = UUID()
    let text: String
    let isUser: Bool
}

// UI für Chat-Bubble
struct ChatBubble: View {
    let message: ChatMessage
    
    var body: some View {
        HStack {
            if message.isUser {
                Spacer()
                Text(message.text)
                    .padding()
                    .background(Color.blue.opacity(0.8))
                    .foregroundColor(.white)
                    .cornerRadius(12)
                    .frame(maxWidth: 250, alignment: .trailing)
            } else {
                Text(message.text)
                    .padding()
                    .background(Color.gray.opacity(0.2))
                    .foregroundColor(.black)
                    .cornerRadius(12)
                    .frame(maxWidth: 250, alignment: .leading)
                Spacer()
            }
        }
    }
}

#Preview {
    ChatbotView()
}
