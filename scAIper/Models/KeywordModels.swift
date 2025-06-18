//
//  KeywordPrompts.swift
//  scAIper
//
//  Created by Dominik Hommer on 06.06.25.
//

import Foundation

struct KeywordModels {

    private static func baseInstruction(for docType: DocumentType) -> String {
        let typeName = docType == .rechnung ? "Rechnung" : "Gehaltsabrechnung"
        return """
        Extrahiere die wichtigsten Informationen aus dem OCR-Text einer \(typeName). \
        Gib das Ergebnis ausschließlich als JSON zurück – ohne Erklärungen, Markdown oder Zusatzfelder.
        """
    }

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
    // MARK: – Few-Shot-Beispiele
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




    struct PropertyDef: Encodable {
        let type: String = "string"
    }

    struct SchemaDef: Encodable {
        let type: String = "object"
        let properties: [String: PropertyDef]
        let required: [String]
        let additionalProperties: Bool = false
    }

    struct SchemaWrapper: Encodable {
        let name: String
        let schema: SchemaDef
    }


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

