//
//  ChunkingPrompts.swift
//  scAIper
//
//  Created by Dominik Hommer on 17.06.25.
//

import Foundation

struct ChunkingModels {

    static let ChunkingInstruction = """
        Du bist ein intelligenter Assistent, der einen langen Text in sinnvoll gegliederte, thematisch zusammenhängende Abschnitte („Chunks“) aufteilt.

        Deine Ausgabe MUSS ausschließlich ein gültiges JSON-Array von Objekten sein – keine Einleitung, keine Erklärungen, kein Markdown, keine Kommentare.

        Regeln:
        - Jeder Chunk enthält ein Feld chunk_index (beginnend bei 0) und ein Feld text.
        - Der Text soll ca. 100–120 Wörter enthalten.
        - Jeder Chunk endet am Ende eines Satzes.
        - Antworte in folgendem JSON-Format:

        {
          "name": "ChunkedText",
          "type": "array",
          "items": {
            "type": "object",
            "properties": {
              "chunk_index": {
                "type": "integer",
                "description": "A zero-based index indicating the order of the chunk in the overall document."
              },
              "text": {
                "type": "string",
                "description": "A coherent paragraph or text section, ideally thematically grouped, ending at a sentence boundary and containing approximately 100–120 words."
              }
            },
            "required": ["chunk_index", "text"],
            "additionalProperties": false
          },
          "description": "An array of text chunks, each representing a meaningful section of the input text. Each chunk must include a chunk_index and the associated text content."
        }
        """

    /// Beispiel-Prompts als typisiertes Array
    static let ChunkingFewShot: [ChatMessageLLM] = [
        ChatMessageLLM(role: .user, content: """
            Zerlege diesen Lebenslauf in Abschnitte: Eva Musterfrau, geboren am 05.01.1982 in Hamburg. \
            Seit 11/2016: Dritte Station GmbH. Ausbildung: 10/2007 - 10/2011 BWL-Studium Universität Musterstadt.
            """),
        ChatMessageLLM(role: .assistant, content: """
            [{\"chunk_index\":0,\"text\":\"Eva Musterfrau, geboren am 05.01.1982 in Hamburg.\"},\
            {\"chunk_index\":1,\"text\":\"Seit 11/2016: Dritte Station GmbH.\"},\
            {\"chunk_index\":2,\"text\":\"Ausbildung: 10/2007 - 10/2011 BWL-Studium Universität Musterstadt.\"}]
            """)
    ]

    struct SchemaDefinition: Encodable {
        let type: String
        let items: ItemsDefinition
        let description: String

        struct ItemsDefinition: Encodable {
            let type: String
            let properties: [String: Property]
            let required: [String]
            let additionalProperties: Bool

            struct Property: Encodable {
                let type: String
                let description: String
            }
        }
    }

    struct SchemaWrapper: Encodable {
        let name: String
        let schema: SchemaDefinition
    }

    static let ChunkingSchema = SchemaWrapper(
        name: "ChunkedText",
        schema: .init(
            type: "array",
            items: .init(
                type: "object",
                properties: [
                    "chunk_index": .init(
                        type: "integer",
                        description: "Index der Reihenfolge"
                    ),
                    "text": .init(
                        type: "string",
                        description: "Abschnittstext mit 100–120 Wörtern"
                    )
                ],
                required: ["chunk_index", "text"],
                additionalProperties: false
            ),
            description: "Ein Array von Text-Chunks, each mit chunk_index und text."
        )
    )
    struct ChunkingResponse: Decodable {
        public let name: String
        public let items: [Chunk]
    }
}

