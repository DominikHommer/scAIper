//
//  ChatMessage.swift
//  scAIper
//
//  Created by Dominik Hommer on 28.03.25.
//

import SwiftUI

struct ChatMessage: Identifiable {
    let id = UUID()
    let text: String
    let isUser: Bool
    var isLoading: Bool = false
}

