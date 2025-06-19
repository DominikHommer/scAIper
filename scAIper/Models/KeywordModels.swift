//
//  KeywordPrompts.swift
//  scAIper
//
//  Created by Dominik Hommer on 06.06.25.
//

import Foundation

/// Defines prompts and schemas for extracting keywords from documents using an LLM.
struct KeywordModels {

    /// Returns the base instruction string depending on the document type (invoice or payslip).
    private static func baseInstruction(for docType: DocumentType) -> String {
        let typeName = docType == .rechnung ? "Rechnung" : "Gehaltsabrechnung"
        return """
        Extract the key information from the OCR text of a \(typeName). \
        Return the result exclusively as JSON – without explanations, markdown, or extra fields.
        """
    }

    /// Builds the complete instruction including the JSON schema for the specified document type.
    static func instruction(for docType: DocumentType) -> String {
        let base = baseInstruction(for: docType)
        let wrapper = schemaWrapper(for: docType)
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        let jsonSchema: String
        do {
            let data = try encoder.encode(wrapper)
            jsonSchema = String(decoding: data, as: UTF8.self)
        } catch {
            jsonSchema = "{}"
        }
        return """
        \(base)

        \(jsonSchema)
        """
    }

    /// Provides few-shot example messages for the given document type to guide the LLM.
    static func fewShots(for docType: DocumentType) -> [ChatMessageLLM] {
        switch docType {
        case .rechnung:
            return [
                ChatMessageLLM(role: .user, text: """
                    OCR-Text:
                    \"\"\"
                    Rechnung Nr. 123456 vom 01.01.2024
                    Gesamtbetrag: 345,67 EUR
                    IBAN: DE12345678901234567890
                    USt-ID: DE999999999
                    \"\"\"
                    """),
                ChatMessageLLM(role: .assistant, text: """
                    {
                      "Rechnungsnummer": "123456",
                      "Rechnungsdatum": "01.01.2024",
                      "Gesamtbetrag": "345,67 EUR",
                      "IBAN": "DE12345678901234567890",
                      "USt-ID": "DE999999999"
                    }
                    """)
            ]
        case .lohnzettel:
            return [
                ChatMessageLLM(role: .user, text: """
                    OCR-Text:
                    \"\"\"
                    Bruttolohn: 4000€
                    Nettolohn: 2600€
                    Steuerklasse: 1
                    Sozialversicherung: 700€
                    Zeitraum: Januar 2024
                    \"\"\"
                    """),
                ChatMessageLLM(role: .assistant, text: """
                    {
                      "Bruttolohn": "4000€",
                      "Nettolohn": "2600€",
                      "Steuerklasse": "1",
                      "Sozialversicherung": "700€",
                      "Zeitraum": "Januar 2024"
                    }
                    """)
            ]
        default:
            return []
        }
    }

    /// Defines a JSON schema property of type string.
    struct PropertyDef: Encodable {
        let type: String = "string"
    }

    /// Defines the JSON schema structure for keyword extraction response.
    struct SchemaDef: Encodable {
        let type: String = "object"
        let properties: [String: PropertyDef]
        let required: [String]
        let additionalProperties: Bool = false
    }

    /// Wraps the schema with a name for encoding.
    struct SchemaWrapper: Encodable {
        let name: String
        let schema: SchemaDef
    }

    /// Returns the appropriate schema wrapper for the given document type.
    static func schemaWrapper(for docType: DocumentType) -> SchemaWrapper {
        switch docType {
        case .rechnung:
            let fields = ["Rechnungsnummer", "Rechnungsdatum", "Gesamtbetrag", "IBAN", "USt-ID"]
            let props = Dictionary(uniqueKeysWithValues: fields.map { ($0, PropertyDef()) })
            let schema = SchemaDef(properties: props, required: fields)
            return .init(name: "InvoiceKeywords", schema: schema)
        case .lohnzettel:
            let fields = ["Bruttolohn", "Nettolohn", "Steuerklasse", "Sozialversicherung", "Zeitraum"]
            let props = Dictionary(uniqueKeysWithValues: fields.map { ($0, PropertyDef()) })
            let schema = SchemaDef(properties: props, required: fields)
            return .init(name: "SalaryKeywords", schema: schema)
        default:
            let schema = SchemaDef(properties: [:], required: [])
            return .init(name: "GenericKeywords", schema: schema)
        }
    }
}
