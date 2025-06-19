//
//  JSONSchemaResponseFormat.swift
//  scAIper
//
//  Created by Dominik Hommer on 17.06.25.
//

/// Represents a response format that requires the output to conform to a specific JSON schema.
/// This struct is used to specify the desired JSON schema for LLM responses.
public struct JSONSchemaResponseFormat<Schema: Encodable>: Encodable {
    /// The type of response format, defaults to "json_schema".
    public let type: String
    /// The JSON schema that the response should adhere to.
    public let json_schema: Schema

    /// Initializes the response format with a given JSON schema and optional type.
    /// - Parameters:
    ///   - json_schema: The schema definition to enforce on the response.
    ///   - type: The response format type, defaults to "json_schema".
    public init(json_schema: Schema, type: String = "json_schema") {
        self.type = type
        self.json_schema = json_schema
    }
}
