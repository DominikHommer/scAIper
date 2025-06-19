//
//  Chunk.swift
//  scAIper
//
//  Created by Dominik Hommer on 10.04.25.
//

/// Represents a segment of text extracted from a document.
/// Used when splitting long content into smaller, manageable pieces for processing.
struct Chunk: Codable {
    let chunk_index: Int     // The sequential index of the chunk within the original document
    let text: String         // The actual text content of the chunk
}
