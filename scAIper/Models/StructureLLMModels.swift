//
//  StructureLLMPrompts.swift
//  scAIper
//
//  Created by Dominik Hommer on 17.06.25.
//

import Foundation

struct StructureLLMModels{
    private static let baseInstructionVision = """
    You are given an image of a table. Extract the table content as JSON matching the schema below. Do NOT return the schema itself, but the actual data matching the schema. Output must be valid JSON strictly matching the schema.

    - Do not include null values, instead use empty strings ("") for missing data.
    - Avoid special Unicode characters like µ, ä, ö, ü; use plain ASCII characters.
    - Output must be valid JSON strictly matching the schema.
    """

    
    private static let baseInstruction = """
    You are given a list of extracted text elements from a scanned table. Each element contains a `text` value along with its approximate `x` and `y` coordinates (normalized between 0 and 1). Your task is to reconstruct the original tabular structure.

    Use the `y` coordinate to group elements into rows — values with similar `y` positions belong to the same row. Use the `x` coordinate to assign each element to its appropriate column based on horizontal alignment. In addition, apply your domain knowledge and common sense to interpret and organize the table logically.

    Some values may be split across multiple elements (e.g., "L" and "001" should be combined into "L001"). Use contextual understanding and spatial proximity to merge such fragments when appropriate.

    The first row typically contains column headers. All subsequent rows represent data entries. Do not translate or reinterpret any values — keep the original text. Your only task is to reconstruct structure.

    Your output must exactly match the JSON schema below (no extra keys, no Markdown, no explanation):
    """

    static var LLMInstruction: String {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        let schemaJSON: String
        do {
            let data = try encoder.encode(StructureLLMSchema)
            schemaJSON = String(decoding: data, as: UTF8.self)
        } catch {
            return baseInstruction + "\n\n<ERROR SERIALIZING SCHEMA>\n"
        }

        return """
        \(baseInstruction)

        \(schemaJSON)
        """
    }
    static var LLMInstructionVision: String {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        let schemaJSON: String
        do {
            let data = try encoder.encode(StructureLLMSchema)
            schemaJSON = String(decoding: data, as: UTF8.self)
        } catch {
            return baseInstructionVision + "\n\n<ERROR SERIALIZING SCHEMA>\n"
        }

        return """
        \(baseInstruction)

        \(schemaJSON)
        """
    }

    static let LLMFewShot: [ChatMessageLLM] = [
        ChatMessageLLM(role: .user, text: """
            Here is the unstructured table grid:
            [(text: "ID", x: 0.1, y: 0.01), (text: "Item", x: 0.3, y: 0.01), (text: "Qty", x: 0.5, y: 0.01),
             (text: "A", x: 0.1, y: 0.1), (text: "1", x: 0.13, y: 0.1), (text: "Widget", x: 0.3, y: 0.1), (text: "10", x: 0.5, y: 0.1)]
        """),
        ChatMessageLLM(role: .assistant, text: """
            {
              "header": ["ID", "Item", "Qty"],
              "table": [
                {"ID": "A1", "Item": "Widget", "Qty": 10}
              ]
            }
        """),
        ChatMessageLLM(role: .user, text: """
            Here is the unstructured table grid:
            [(text: "Code", x: 0.1, y: 0.02), (text: "Name", x: 0.3, y: 0.02),
             (text: "B", x: 0.1, y: 0.12), (text: "204", x: 0.15, y: 0.12), (text: "Bolt", x: 0.3, y: 0.12)]
        """),
        ChatMessageLLM(role: .assistant, text: """
            {
              "header": ["Code", "Name"],
              "table": [
                {"Code": "B204", "Name": "Bolt"}
              ]
            }
        """)
    ]




    /// Definition für `additionalProperties` bei Objects
    struct AdditionalPropertiesDef: Encodable {
        let type: [String]
    }

    /// Definition für Array-Items
    struct ItemsDefinition: Encodable {
        let type: String
        let additionalProperties: AdditionalPropertiesDef?
    }

    /// Definition für jeden Property-Eintrag
    struct PropertyDefinition: Encodable {
        let type: String
        let description: String
        let items: ItemsDefinition?
        let additionalProperties: AdditionalPropertiesDef?

        init(
            type: String,
            description: String,
            items: ItemsDefinition? = nil,
            additionalProperties: AdditionalPropertiesDef? = nil
        ) {
            self.type = type
            self.description = description
            self.items = items
            self.additionalProperties = additionalProperties
        }
    }

    /// Top-Level Schema-Definition
    struct SchemaDefinition: Encodable {
        let title: String
        let type: String
        let properties: [String: PropertyDefinition]
        let required: [String]
    }

    /// Wrapper, wie ihn der LLM-Client erwartet
    struct SchemaWrapper: Encodable {
        let name: String
        let schema: SchemaDefinition
    }


    static let StructureLLMSchema = SchemaWrapper(
        name: "GenericTable",
        schema: SchemaDefinition(
            title: "GenericTable",
            type: "object",
            properties: [
                "header": PropertyDefinition(
                    type: "array",
                    description: "An array of consolidated column headers, even if originally spread across several rows.",
                    items: ItemsDefinition(type: "string", additionalProperties: nil)
                ),
                "table": PropertyDefinition(
                    type: "array",
                    description: "A list of structured data rows matching the unified header.",
                    items: ItemsDefinition(
                        type: "object",
                        additionalProperties: AdditionalPropertiesDef(type: ["string", "number", "boolean", "null"])
                    )
                )
            ],
            required: ["header", "table"]
        )
    )
    struct StructureResponse: Decodable {
        let header: [String]
        let table: [[String: JSONValue]]
    }
}

