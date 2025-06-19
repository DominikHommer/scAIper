//
//  ChatbotView.swift
//  scAIper
//
//  Created by Dominik Hommer on 17.03.25.
//

import SwiftUI

/// A view that displays a simple chat interface where users can interact with the AI chatbot named scAIper.
struct ChatbotView: View {
    
    /// View model managing chat messages and logic.
    @StateObject private var viewModel = ChatbotViewModel()
    
    /// Stores the user's current input.
    @State private var userInput: String = ""
    
    /// Manages keyboard focus state for the text field.
    @FocusState private var isTextFieldFocused: Bool

    var body: some View {
        VStack {
            // Chat history scrollable view
            ScrollView {
                VStack(alignment: .leading, spacing: 10) {
                    ForEach(viewModel.chatMessages) { message in
                        ChatBubble(message: message)
                    }
                }
                .padding(.horizontal)
            }

            // User input and send button
            HStack {
                TextField("Frage scAIper...", text: $userInput)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .focused($isTextFieldFocused)
                    .onSubmit {
                        sendUserInput()
                    }

                Button(action: {
                    sendUserInput()
                }) {
                    HStack {
                        Image(systemName: "paperplane.fill")
                    }
                    .foregroundColor(userInput.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? .gray : .blue)
                }
                .disabled(userInput.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }
            .padding()
        }
        .navigationTitle("scAIper")
        .navigationBarTitleDisplayMode(.large)
        .toolbar {
            // Button to reset the chat history
            ToolbarItem(placement: .navigationBarTrailing) {
                Button {
                    viewModel.resetHistory()
                } label: {
                    Label("Reset", systemImage: "arrow.counterclockwise")
                }
                .accessibilityLabel("Reset Chatverlauf")
            }
        }
        // Tap gesture to dismiss keyboard when tapping outside
        .onTapGesture {
            isTextFieldFocused = false
        }
        // Fix for NavigationStack: view appears after returning from another screen
        .onAppear {
            isTextFieldFocused = false
            print("ChatbotView erscheint erneut")
        }
    }

    /// Handles sending the user input to the chatbot and resetting the input field.
    private func sendUserInput() {
        let trimmedInput = userInput.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedInput.isEmpty else { return }

        print("Button tapped with: \(trimmedInput)")
        viewModel.sendMessage(trimmedInput)
        userInput = ""
        isTextFieldFocused = false
    }
}


/// A reusable view that displays a single chat message bubble, either from the user or the AI.
struct ChatBubble: View {
    
    /// The chat message to display.
    let message: ChatMessage

    var body: some View {
        HStack {
            if message.isUser {
                // User messages aligned right
                Spacer()
                Text(message.text)
                    .padding()
                    .background(Color.blue.opacity(0.8))
                    .foregroundColor(.white)
                    .cornerRadius(12)
                    .frame(maxWidth: 250, alignment: .trailing)
            } else {
                if message.isLoading {
                    // Loading indicator for AI response
                    LoadingIndicatorView()
                        .padding()
                        .background(Color.gray.opacity(0.2))
                        .cornerRadius(12)
                        .frame(maxWidth: 250, alignment: .leading)
                } else {
                    // AI messages aligned left
                    Text(message.text)
                        .padding()
                        .background(Color.gray.opacity(0.2))
                        .foregroundColor(.black)
                        .cornerRadius(12)
                        .frame(maxWidth: 250, alignment: .leading)
                }
                Spacer()
            }
        }
    }
}
