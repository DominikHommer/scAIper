//
//  MetadataManager.swift
//  scAIper
//
//  Created by Dominik Hommer on 29.03.25.
//
import Foundation

struct DocumentMetadataManager {
    static let shared = DocumentMetadataManager()
    private let metadataFileName = "document_metadata.json"
    
    private var metadataFileURL: URL {
        let documentsURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        return documentsURL.appendingPathComponent(metadataFileName)
    }
    
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
    
    func saveMetadataArray(_ metadataArray: [DocumentMetadata]) {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        if let data = try? encoder.encode(metadataArray) {
            do {
                try data.write(to: metadataFileURL)
            } catch {
                print("Fehler beim Schreiben der Metadaten: \(error)")
            }
        }
    }
    func removeMetadata(forCategory category: String) {
        var metadataArray = loadMetadata()
        metadataArray.removeAll { $0.documentType.rawValue == category }
        saveMetadataArray(metadataArray)
    }
    
    func removeMetadata(forFileURL fileURL: URL) {
        var metadataArray = loadMetadata()
        metadataArray.removeAll { $0.fileURL == fileURL.absoluteString }
        saveMetadataArray(metadataArray)
    }


    
    func addMetadata(_ metadata: DocumentMetadata) {
        var currentMetadata = loadMetadata()
        currentMetadata.append(metadata)
        saveMetadataArray(currentMetadata)
    }
    
    func addMetadataList(_ list: [DocumentMetadata]) {
        var currentMetadata = loadMetadata()
        currentMetadata.append(contentsOf: list)
        saveMetadataArray(currentMetadata)
    }

    
    func printDocumentMetadataJSON() {
        let fileURL = metadataFileURL
        do {
            let data = try Data(contentsOf: fileURL)
            if let jsonString = String(data: data, encoding: .utf8) {
                print("Inhalt von document_metadata.json:")
                print(jsonString)
            } else {
                print("Fehler: Daten konnten nicht als String dekodiert werden.")
            }
        } catch {
            print("Fehler beim Laden der Datei: \(error)")
        }
    }
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


