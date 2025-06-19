//
//  MetadataManager.swift
//  scAIper
//
//  Created by Dominik Hommer on 29.03.25.
//

import Foundation

/// Manages persistent storage and retrieval of document metadata, including
/// saving, loading, and validating metadata files associated with scanned documents.
struct DocumentMetadataManager {
    /// Shared singleton instance.
    static let shared = DocumentMetadataManager()
    
    /// File name used to store metadata JSON.
    private let metadataFileName = "document_metadata.json"
    
    /// Computed URL for the metadata JSON file in the documents directory.
    private var metadataFileURL: URL {
        let documentsURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        return documentsURL.appendingPathComponent(metadataFileName)
    }
    
    /// Loads and decodes all stored document metadata.
    ///
    /// - Returns: An array of `DocumentMetadata`, or an empty array if loading fails.
    func loadMetadata() -> [DocumentMetadata] {
        let fileURL = metadataFileURL
        guard let data = try? Data(contentsOf: fileURL) else {
            return []
        }
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        if let metadataArray = try? decoder.decode([DocumentMetadata].self, from: data) {
            return metadataArray
        }
        return []
    }
    
    /// Saves an array of `DocumentMetadata` to disk.
    ///
    /// - Parameter metadataArray: The array to be saved.
    func saveMetadataArray(_ metadataArray: [DocumentMetadata]) {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        if let data = try? encoder.encode(metadataArray) {
            do {
                try data.write(to: metadataFileURL)
            } catch {
                print("Error writing metadata: \(error)")
            }
        }
    }

    /// Removes all metadata entries associated with a given document category.
    ///
    /// - Parameter category: The document type category to be removed (e.g., "Contract").
    func removeMetadata(forCategory category: String) {
        var metadataArray = loadMetadata()
        metadataArray.removeAll { $0.documentType.rawValue == category }
        saveMetadataArray(metadataArray)
        DocumentMetadataManager.shared.printDocumentMetadataJSON()
    }

    /// Removes a specific metadata entry based on its file URL.
    ///
    /// - Parameter fileURL: The local URL of the file to be removed from metadata.
    func removeMetadata(forFileURL fileURL: URL) {
        var metadataArray = loadMetadata()
        let filename = fileURL.lastPathComponent
        metadataArray.removeAll {
            URL(string: $0.fileURL)?.lastPathComponent == filename
        }
        saveMetadataArray(metadataArray)
        print("File '\(filename)' removed from metadata.")
        DocumentMetadataManager.shared.printDocumentMetadataJSON()
    }

    /// Appends a single metadata entry to the stored list.
    ///
    /// - Parameter metadata: The metadata object to append.
    func addMetadata(_ metadata: DocumentMetadata) {
        var currentMetadata = loadMetadata()
        currentMetadata.append(metadata)
        saveMetadataArray(currentMetadata)
    }

    /// Appends a list of metadata entries to the stored list.
    ///
    /// - Parameter list: Array of metadata entries to append.
    func addMetadataList(_ list: [DocumentMetadata]) {
        var currentMetadata = loadMetadata()
        currentMetadata.append(contentsOf: list)
        saveMetadataArray(currentMetadata)
    }

    /// Prints the contents of the metadata file to the console.
    func printDocumentMetadataJSON() {
        let fileURL = metadataFileURL
        do {
            let data = try Data(contentsOf: fileURL)
            if let jsonString = String(data: data, encoding: .utf8) {
                print("Contents of document_metadata.json:")
                print(jsonString)
            } else {
                print("Error: Could not decode data as string.")
            }
        } catch {
            print("Error loading metadata file: \(error)")
        }
    }

    /// Validates all stored metadata by checking if the corresponding files still exist.
    ///
    /// Invalid metadata entries (pointing to non-existent files) are removed.
    func validateMetadata() {
        var metadataArray = loadMetadata()
        let fileManager = FileManager.default
        let documentsURL = fileManager.urls(for: .documentDirectory, in: .userDomainMask)[0]

        metadataArray.removeAll { metadata in
            let absoluteURL = documentsURL.appendingPathComponent(metadata.fileURL)
            return !fileManager.fileExists(atPath: absoluteURL.path)
        }
        saveMetadataArray(metadataArray)
    }
}

