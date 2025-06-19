//
//  ChatMessage.swift
//  scAIper
//
//  Created by Dominik Hommer on 28.03.25.
//

import SwiftUI

/// A model representing a single message in a chat interface.
struct ChatMessage: Identifiable {
    
    /// Unique identifier for the message (used by SwiftUI for list rendering).
    let id = UUID()
    
    /// The textual content of the message.
    let text: String
    
    /// Indicates whether the message was sent by the user (`true`) or by the assistant (`false`).
    let isUser: Bool
    
    /// Optional flag to show a loading indicator (e.g. when awaiting AI response).
    var isLoading: Bool = false
}

