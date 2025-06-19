//
//  DocumentMetadata.swift
//  scAIper
//
//  Created by Dominik Hommer on 29.03.25.
//

import Foundation

/// A model representing metadata for a processed document,
/// including its embedding, type, layout, content, and optional keywords.
struct DocumentMetadata: Codable, Identifiable {
    
    /// The unique identifier used to conform to `Identifiable`.
    var id: String { documentID }
    
    /// A unique identifier for the document, e.g., "groupID-chunkIndex".
    let documentID: String

    /// The file path (URL) where the document is stored on device.
    let fileURL: String

    /// The semantic category of the document (e.g. payslip, invoice).
    let documentType: DocumentType

    /// The layout type (e.g. table, form, free text).
    let layoutType: LayoutType

    /// The last modification date of the document file.
    let lastModified: Date

    /// The vector embedding representation of the document content.
    let embedding: Embedding

    /// The text content extracted from the document.
    let content: String

    /// Optional dictionary of extracted keywords and their corresponding values.
    let keywords: [String: String]?
}

