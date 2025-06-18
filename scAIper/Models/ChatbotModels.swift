//
//  ChatbotPrompts.swift
//  scAIper
//
//  Created by Dominik Hommer on 28.03.25.
//

import Foundation

struct ChatbotModels {
    static let baseDocCheckInstruction = """
    Du bist ein Assistent, der prüfen soll, ob der Nutzer Informationen zu Dokumenten oder persönlichen Daten abfragt \
    (z. B. Rechnungen, Verträge, Berichte, Lohnzettel). Antworte *ausschließlich* in JSON nach dem folgenden Schema – \
    keine Erklärungen, kein Extra-Text:
    """

    static let baseChatInstruction = """
    Du bist scAIper, ein freundlicher, intelligenter Assistent. Beantworte Fragen zu Dokumenteninhalten basierend auf \
    bereitgestellten Abschnitten. Falls nicht vorhanden, antworte mit einem JSON-Objekt nach dem Schema unten – \
    erfinde nichts, keine Markdown-Formatierung:
    """

    struct DocCheckProperty: Encodable {
        let type = "boolean"
        let description = "true, wenn die Frage mit Dokumenten bzw. persönlichen Daten zu tun hat"
    }
    struct DocCheckSchema: Encodable {
        let name = "DocCheck"
        let schema: SchemaDef
        struct SchemaDef: Encodable {
            let type = "object"
            let properties: [String: DocCheckProperty]
            let required: [String]
            let additionalProperties = false
        }
    }

    struct ChatResponseProperty: Encodable {
        let type = "string"
        let description = "Die Antwort des Assistenten als reiner Text"
    }
    struct ChatResponseSchema: Encodable {
        let name = "ChatResponse"
        let schema: SchemaDef
        struct SchemaDef: Encodable {
            let type = "object"
            let properties: [String: ChatResponseProperty]
            let required: [String]
            let additionalProperties = false
        }
    }


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
    struct DocCheckResponse: Decodable {
        let wantsDocumentInfo: Bool
    }

    struct ChatCompletionResponse: Decodable {
        let content: String
    }
}



