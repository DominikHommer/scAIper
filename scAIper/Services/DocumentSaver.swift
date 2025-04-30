//
//  DocumentSaver.swift
//  scAIper
//
//  Created by Dominik Hommer on 21.03.25.
//
import Foundation
import UIKit

struct DocumentSaver {
    static func saveDocument(sourceURL: URL, fileName: String, documentType: DocumentType, layoutType: LayoutType, content: String, completion: (() -> Void)? = nil) {
        let fileManager = FileManager.default
        let documentsURL = fileManager.urls(for: .documentDirectory, in: .userDomainMask)[0]
        print("Documents-Verzeichnis: \(documentsURL)")

        let categoryURL = documentsURL.appendingPathComponent(documentType.rawValue)
        if !fileManager.fileExists(atPath: categoryURL.path) {
            do {
                try fileManager.createDirectory(at: categoryURL, withIntermediateDirectories: true, attributes: nil)
            } catch {
                print("Fehler beim Erstellen des Ordners: \(error)")
                return
            }
        }

        let destinationURL = categoryURL.appendingPathComponent(fileName)
        do {
            if fileManager.fileExists(atPath: destinationURL.path) {
                try fileManager.removeItem(at: destinationURL)
            }
            try fileManager.copyItem(at: sourceURL, to: destinationURL)
            print("Dokument gespeichert unter \(destinationURL)")

            let relativePath = destinationURL.path.replacingOccurrences(of: documentsURL.path + "/", with: "")

            RAGManager.shared.computeEmbeddingsForDocument(
                fileURL: relativePath,
                documentType: documentType,
                layoutType: layoutType,
                content: content
            ) { metadataList in
                for metadata in metadataList {
                    DocumentMetadataManager.shared.addMetadata(metadata)
                }

                DocumentMetadataManager.shared.printDocumentMetadataJSON()
                completion?()
            }

        } catch {
            print("Fehler beim Speichern des Dokuments: \(error)")
            completion?()
        }
    }
}





