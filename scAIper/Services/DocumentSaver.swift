//
//  DocumentSaver.swift
//  scAIper
//
//  Created by Dominik Hommer on 21.03.25.
//

import Foundation
import UIKit

/// Utility responsible for saving documents, organizing them by type, and initiating embedding generation.
struct DocumentSaver {

    /// Saves a document to the user's document directory, categorizes it by type, and triggers embedding computation.
    ///
    /// - Parameters:
    ///   - sourceURL: The source file URL of the document to be saved.
    ///   - fileName: The desired file name for the saved document.
    ///   - documentType: The category under which the document should be saved (e.g., invoice, payslip).
    ///   - layoutType: The layout type (e.g., table or text) used for this document.
    ///   - content: The raw content of the document (e.g., OCR output).
    ///   - keywords: Optional metadata keywords for enhancing document retrieval or filtering.
    ///   - completion: Optional callback executed after the document has been successfully saved and processed.
    static func saveDocument(
        sourceURL: URL,
        fileName: String,
        documentType: DocumentType,
        layoutType: LayoutType,
        content: String,
        keywords: [String: String]? = nil,
        completion: (() -> Void)? = nil
    ) {
        let fileManager = FileManager.default
        let documentsURL = fileManager.urls(for: .documentDirectory, in: .userDomainMask)[0]
        print("Documents directory: \(documentsURL)")

        // Create a subdirectory for the document type if it doesn't already exist
        let categoryURL = documentsURL.appendingPathComponent(documentType.rawValue)
        if !fileManager.fileExists(atPath: categoryURL.path) {
            do {
                try fileManager.createDirectory(at: categoryURL, withIntermediateDirectories: true, attributes: nil)
            } catch {
                print("Failed to create folder: \(error)")
                return
            }
        }

        // Save or replace the file in the appropriate directory
        let destinationURL = categoryURL.appendingPathComponent(fileName)
        do {
            if fileManager.fileExists(atPath: destinationURL.path) {
                try fileManager.removeItem(at: destinationURL)
            }
            try fileManager.copyItem(at: sourceURL, to: destinationURL)
            print("Document saved at \(destinationURL)")

            // Compute relative file path for embedding system
            let relativePath = destinationURL.path.replacingOccurrences(of: documentsURL.path + "/", with: "")

            // Compute embeddings for the document and update metadata
            RAGManager.shared.computeEmbeddingsForDocument(
                fileURL: relativePath,
                documentType: documentType,
                layoutType: layoutType,
                content: content
            ) { metadataList in
                for var metadata in metadataList {
                    metadata = DocumentMetadata(
                        documentID: metadata.documentID,
                        fileURL: metadata.fileURL,
                        documentType: metadata.documentType,
                        layoutType: metadata.layoutType,
                        lastModified: metadata.lastModified,
                        embedding: metadata.embedding,
                        content: metadata.content,
                        keywords: keywords
                    )
                    DocumentMetadataManager.shared.addMetadata(metadata)
                }

                DocumentMetadataManager.shared.printDocumentMetadataJSON()
                completion?()
            }

        } catch {
            print("Error while saving the document: \(error)")
            completion?()
        }
    }
}

