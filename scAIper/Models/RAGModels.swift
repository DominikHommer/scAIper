//
//  ScoredDocument.swift
//  scAIper
//
//  Created by Dominik Hommer on 10.04.25.
//
import Foundation

struct SimilarityRequest: Encodable {
    struct Inputs: Encodable {
        let source_sentence: String
        let sentences: [String]
    }
    let inputs: Inputs
    let options: [String: Bool]
}

/// Request-Payload für den Embedding-Endpoint
struct EmbeddingRequest: Encodable {
    let inputs: String
    let options: [String: Bool]
}

struct ScoredDocument {
    let metadata: DocumentMetadata
    let score: Double
    
}
