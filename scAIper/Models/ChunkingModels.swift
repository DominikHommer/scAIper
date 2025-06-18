//
//  ChunkingPrompts.swift
//  scAIper
//
//  Created by Dominik Hommer on 17.06.25.
//

import Foundation

struct ChunkingModels {

    static let ChunkingInstruction = """
        Du bist ein intelligenter Assistent, der einen unstrukturierten oder semistrukturierten Text (z. B. eine Rechnung, ein Vertrag oder ein gescannter Brief) in sinnvolle Abschnitte („Chunks“) unterteilt. Diese Chunks sollen thematisch zusammenhängend und für eine spätere Analyse sinnvoll abgegrenzt sein.

        Deine Ausgabe MUSS ein **valides JSON-Array** von Objekten mit exakt den folgenden Feldern sein – **ohne** Kommentare, Einleitung oder sonstige Ausgaben.

        ### Chunk-Regeln:
        - Jeder Chunk hat:
          - `chunk_index` (beginnend bei 0)
          - `text` (mehrzeiliger Klartext, zusammengehörig)
        - Chunks sollen **nicht nur satzweise**, sondern **nach Sinnabschnitten** aufgeteilt werden. Beispiele:
          - Adressblock
          - Rechnungsnummer + Datum
          - Tabellenkopf + Einträge
          - Summenblock
          - Zahlungsinformationen
        - Leere Zeilen oder Formatierung können als Hinweis auf Chunk-Grenzen dienen.
        - Achte darauf, dass jeder Chunk **für sich verständlich** ist.
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
                "description": "A coherent paragraph or text section, ideally thematically grouped, ending at a sentence boundary."
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
        ChatMessageLLM(role: .user, text:"""
            Zerlege diesen Rechnungstext in sinnvolle Abschnitte:
            RECHNUNG
            RECHNUNG AN: VINCENT VOGELSTETTER JEDE STRASSE 123 12345 JEDE STADT
            RECHNUNG NR. 12345 28. APRIL 2030 FOTOGRAFIE - SARAH MARCHSREITER
            Beschreibung Anzahl Preis Summe
            Eventfotografie (4-stündiges Event) 4 125€ 500€
            Porträtfotoshooting 1 185€ 185€
            Bildbearbeitung (35 Bilder) 35 5€ 175€
            Zwischensumme 860€
            Steuer (0 %) 0 €
            Summe 860€
            ZAHLUNGSINFORMATIONEN:
            EMPFÄNGER: SARAH MARCHSREITER
            KONTONUMMER: 0123 4567 8901
            """),
        ChatMessageLLM(role: .assistant, text: """
            [{\"chunk_index\": 0, \"text\": \"RECHNUNG\"},
             {\"chunk_index\": 1, \"text\": \"RECHNUNG AN: VINCENT VOGELSTETTER JEDE STRASSE 123 12345 JEDE STADT\"},
             {\"chunk_index\": 2, \"text\": \"RECHNUNG NR. 12345 28. APRIL 2030 FOTOGRAFIE - SARAH MARCHSREITER\"},
             {\"chunk_index\": 3, \"text\": \"Beschreibung Anzahl Preis Summe\\nEventfotografie (4-stündiges Event) 4 125€ 500€\\nPorträtfotoshooting 1 185€ 185€\\nBildbearbeitung (35 Bilder) 35 5€ 175€\"},
             {\"chunk_index\": 4, \"text\": \"Zwischensumme 860€\\nSteuer (0 %) 0 €\\nSumme 860€\"},
             {\"chunk_index\": 5, \"text\": \"ZAHLUNGSINFORMATIONEN:\\nEMPFÄNGER: SARAH MARCHSREITER\\nKONTONUMMER: 0123 4567 8901\"}]
            """
        )
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
                        description: "A zero-based index indicating the order of the chunk in the overall document."
                    ),
                    "text": .init(
                        type: "string",
                        description: "A coherent paragraph or text section, ideally thematically grouped, ending at a sentence boundary."
                    )
                ],
                required: ["chunk_index", "text"],
                additionalProperties: false
            ),
            description: "An array of text chunks, each representing a meaningful section of the input text. Each chunk must include a chunk_index and the associated text content."
        )
    )
    struct ChunkingResponse: Decodable {
        public let name: String
        public let items: [Chunk]
    }
}

