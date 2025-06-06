//
//  DocumentMetadata.swift
//  scAIper
//
//  Created by Dominik Hommer on 29.03.25.
//
import Foundation

struct DocumentMetadata: Codable, Identifiable {
    var id: String { documentID }
    let documentID: String
    let fileURL: String
    let documentType: DocumentType
    let layoutType: LayoutType
    let lastModified: Date
    let embedding: Embedding
    let content: String
    let keywords: [String: String]?
}



