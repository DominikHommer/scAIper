//
//  ChatbotPrompts.swift
//  scAIper
//
//  Created by Dominik Hommer on 28.03.25.
//

import Foundation

/// A container for all prompt models and schemas used in the chatbot logic.
struct ChatbotModels {
    
    /// System prompt instructing the assistant to check whether a user query refers to document-related content.
    static let baseDocCheckInstruction = """
    Du bist ein Assistent, der prüfen soll, ob der Nutzer Informationen zu Dokumenten oder persönlichen Daten abfragt \
    (z. B. Rechnungen, Verträge, Berichte, Lohnzettel). Antworte *ausschließlich* in JSON nach dem folgenden Schema – \
    keine Erklärungen, kein Extra-Text:
    """

    /// System prompt instructing the assistant to answer user questions based on provided document sections.
    static let baseChatInstruction = """
    Du bist scAIper, ein freundlicher, intelligenter Assistent. Beantworte Fragen zu Dokumenteninhalten basierend auf \
    bereitgestellten Abschnitten. Falls nicht vorhanden, antworte mit einem JSON-Objekt nach dem Schema unten – \
    erfinde nichts, keine Markdown-Formatierung:
    """

    /// JSON Schema property used in document intent detection.
    struct DocCheckProperty: Encodable {
        let type = "boolean"
        let description = "true, wenn die Frage mit Dokumenten bzw. persönlichen Daten zu tun hat"
    }

    /// JSON Schema for checking if the user input is document-related.
    struct DocCheckSchema: Encodable {
        let name = "DocCheck"
        let schema: SchemaDef

        /// Inner schema definition for DocCheckSchema.
        struct SchemaDef: Encodable {
            let type = "object"
            let properties: [String: DocCheckProperty]
            let required: [String]
            let additionalProperties = false
        }
    }

    /// JSON Schema property used in chatbot responses.
    struct ChatResponseProperty: Encodable {
        let type = "string"
        let description = "Die Antwort des Assistenten als reiner Text"
    }

    /// JSON Schema for structured chatbot responses.
    struct ChatResponseSchema: Encodable {
        let name = "ChatResponse"
        let schema: SchemaDef

        /// Inner schema definition for ChatResponseSchema.
        struct SchemaDef: Encodable {
            let type = "object"
            let properties: [String: ChatResponseProperty]
            let required: [String]
            let additionalProperties = false
        }
    }

    /// Constructs the message array for the document check LLM prompt.
    /// - Parameter userInput: The user's input string.
    /// - Returns: An array of system and user chat messages.
    static func docCheckMessages(userInput: String) -> [ChatMessageLLM] {
        let wrapper = DocCheckSchema(
            schema: .init(
                properties: ["wantsDocumentInfo": .init()],
                required: ["wantsDocumentInfo"]
            )
        )
        let systemContent = buildPromptWithSchema(
            base: baseDocCheckInstruction,
            wrapper: wrapper
        )
        
        return [
            ChatMessageLLM(role: .system, text: systemContent),
            ChatMessageLLM(role: .user, text: userInput)
        ]
    }

    /// Constructs the message array for answering user questions using context from RAG if available.
    /// - Parameters:
    ///   - userInput: The user’s question.
    ///   - ragOutput: Optional document context provided by a retrieval system.
    /// - Returns: An array of chat messages for the LLM.
    static func chatMessages(userInput: String, ragOutput: String? = nil) -> [ChatMessageLLM] {
        let wrapper = ChatResponseSchema(
            schema: .init(
                properties: ["content": .init()],
                required: ["content"]
            )
        )
        let systemContent = buildPromptWithSchema(
            base: baseChatInstruction,
            wrapper: wrapper
        )

        var msgs: [ChatMessageLLM] = [
            ChatMessageLLM(role: .system, text: systemContent)
        ]
        if let rag = ragOutput {
            let fullInput = """
            \(userInput)

            Hier die relevanten Dokumentabschnitte, beachte das Dokumente enthalten sein können die nichts mit der Fragestellung zu tun haben, ignoriere diese:
            \(rag)
            """
            msgs.append(ChatMessageLLM(role: .user, text: fullInput))
        } else {
            msgs.append(ChatMessageLLM(role: .user, text: userInput))
        }
        return msgs
    }

    /// Builds a system prompt by embedding a JSON schema into the base prompt.
    /// - Parameters:
    ///   - base: The base prompt text.
    ///   - wrapper: An encodable schema definition to embed in the prompt.
    /// - Returns: The full system prompt as a string.
    private static func buildPromptWithSchema<Wrapper: Encodable>(
        base: String,
        wrapper: Wrapper
    ) -> String {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        let schemaJSON: String
        if let data = try? encoder.encode(wrapper),
           let str = String(data: data, encoding: .utf8) {
            schemaJSON = str
        } else {
            schemaJSON = "{}"
        }
        return """
        \(base)

        \(schemaJSON)
        """
    }

    /// The structured response model for document check.
    struct DocCheckResponse: Decodable {
        let wantsDocumentInfo: Bool
    }

    /// The structured response model for chatbot replies.
    struct ChatCompletionResponse: Decodable {
        let content: String
    }
}

