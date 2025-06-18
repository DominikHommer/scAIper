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
    @FocusState private var isTextFieldFocused: Bool

    var body: some View {
        NavigationStack {
            VStack {
                ScrollView {
                    VStack(alignment: .leading, spacing: 10) {
                        ForEach(viewModel.chatMessages) { message in
                            ChatBubble(message: message)
                        }
                    }
                    .padding(.horizontal)
                }

                HStack {
                    TextField("Frage scAIper...", text: $userInput)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .focused($isTextFieldFocused)

                    Button {
                        viewModel.sendMessage(userInput)
                        userInput = ""
                        isTextFieldFocused = false
                    } label: {
                        Image(systemName: "paperplane.fill")
                            .foregroundColor(.blue)
                    }
                }
                .padding()
            }
            .navigationTitle("scAIper")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        viewModel.resetHistory()
                    } label: {
                        Image(systemName: "arrow.counterclockwise")
                            .imageScale(.large)
                    }
                    .accessibilityLabel("Reset Chatverlauf")
                }
            }
        }
        .onTapGesture {
            isTextFieldFocused = false
        }
    }
}




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
                if message.isLoading {
                    LoadingIndicatorView()
                        .padding()
                        .background(Color.gray.opacity(0.2))
                        .cornerRadius(12)
                        .frame(maxWidth: 250, alignment: .leading)
                } else {
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


#Preview {
    ChatbotView()
}










