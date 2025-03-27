//
//  FolderDetailViewModel.swift
//  scAIper
//
//  Created by Dominik Hommer on 27.03.25.
//


import SwiftUI


class FolderDetailViewModel: ObservableObject {
    @Published var files: [URL] = []
    let category: String
    
    init(category: String) {
        self.category = category
        loadFiles()
    }
    
    func loadFiles() {
        let fileManager = FileManager.default
        let documentsURL = fileManager.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let categoryURL = documentsURL.appendingPathComponent(category)
        do {
            let fileURLs = try fileManager.contentsOfDirectory(at: categoryURL,
                                                                includingPropertiesForKeys: nil,
                                                                options: .skipsHiddenFiles)
            DispatchQueue.main.async {
                // Dateien alphabetisch sortieren
                self.files = fileURLs.sorted { $0.lastPathComponent < $1.lastPathComponent }
            }
        } catch {
            print("Fehler beim Laden der Dateien: \(error)")
        }
    }
    
    func deleteDocument(at offsets: IndexSet) {
        let fileManager = FileManager.default
        for index in offsets {
            let file = files[index]
            do {
                try fileManager.removeItem(at: file)
                print("Dokument \(file.lastPathComponent) gelöscht")
            } catch {
                print("Fehler beim Löschen der Datei \(file.lastPathComponent): \(error)")
            }
        }
        loadFiles()
    }
}


extension URL {
    var fileIcon: String {
        let ext = self.pathExtension.lowercased()
        switch ext {
        case "pdf":
            return "doc.richtext"
        case "csv":
            return "tablecells"
        default:
            return "doc"
        }
    }
}
