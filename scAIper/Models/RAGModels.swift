//
//  ScoredDocument.swift
//  scAIper
//
//  Created by Dominik Hommer on 10.04.25.
//

import Foundation

/// Request body for sentence similarity models.
/// Used to compute similarity between a source sentence and multiple candidate sentences.
struct SimilarityRequest: Encodable {
    struct Inputs: Encodable {
        let source_sentence: String       // The sentence used as reference for comparison
        let sentences: [String]           // The list of sentences to compare against the source
    }
    
    let inputs: Inputs
    let options: [String: Bool]          // Additional model options (e.g., `"wait_for_model": true`)
}

/// Request body for obtaining an embedding vector for a given input string.
struct EmbeddingRequest: Encodable {
    let inputs: String                   // The text to be embedded
    let options: [String: Bool]         // Model options, e.g., `"wait_for_model": true`
}

/// Associates a document with a similarity score, e.g., from a vector search.
/// This is useful when ranking documents by relevance to a query.
struct ScoredDocument {
    let metadata: DocumentMetadata       // The document metadata
    let score: Double                    // The similarity score (e.g., cosine similarity)
}

