//
//  JSONSchemaResponseFormat.swift
//  scAIper
//
//  Created by Dominik Hommer on 17.06.25.
//


public struct JSONSchemaResponseFormat<Schema: Encodable>: Encodable {
    public let type: String
    public let json_schema: Schema

    public init(json_schema: Schema, type: String = "json_schema") {
        self.type = type
        self.json_schema = json_schema
    }
}
