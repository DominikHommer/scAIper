//
//  ChatbotView.swift
//  scAIper
//
//  Created by Dominik Hommer on 17.03.25.
//

import SwiftUI

struct ChatbotView: View {
    @StateObject private var viewModel = ChatbotViewModel()
    @State private var userInput: String = ""
    
    var body: some View {
        VStack {
            Text("Dokumenten-Chatbot")
                .font(.title)
                .fontWeight(.bold)
                .padding(.top, 20)
            
            ScrollView {
                VStack(alignment: .leading, spacing: 10) {
                    ForEach(viewModel.chatMessages) { message in
                        ChatBubble(message: message)
                    }
                }
            }
            .padding()
            
            HStack {
                TextField("Frage den Chatbot...", text: $userInput)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                
                Button {
                    viewModel.sendMessage(userInput)
                    userInput = ""
                } label: {
                    Image(systemName: "paperplane.fill")
                        .foregroundColor(.blue)
                }
            }
            .padding()
        }
    }
}

// UI-Komponente für Chat-Nachrichten
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



