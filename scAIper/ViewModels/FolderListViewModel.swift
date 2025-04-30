//
//  FolderListViewModel.swift
//  scAIper
//
//  Created by Dominik Hommer on 27.03.25.
//


import SwiftUI


class FolderListViewModel: ObservableObject {
    @Published var categories: [String] = []
    
    func loadCategories() {
        let fileManager = FileManager.default
        let documentsURL = fileManager.urls(for: .documentDirectory, in: .userDomainMask)[0]
        do {
            let folderURLs = try fileManager.contentsOfDirectory(at: documentsURL,
                                                                includingPropertiesForKeys: nil,
                                                                options: .skipsHiddenFiles)
            DispatchQueue.main.async {
                self.categories = folderURLs.filter { $0.hasDirectoryPath }
                    .map { $0.lastPathComponent }
            }
        } catch {
            print("Fehler beim Laden der Kategorien: \(error)")
        }
    }
    
    func documentCount(for category: String) -> Int {
        let fileManager = FileManager.default
        let documentsURL = fileManager.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let categoryURL = documentsURL.appendingPathComponent(category)
        do {
            let files = try fileManager.contentsOfDirectory(at: categoryURL,
                                                            includingPropertiesForKeys: nil,
                                                            options: .skipsHiddenFiles)
            return files.filter { !$0.hasDirectoryPath }.count
        } catch {
            print("Fehler beim Laden der Dateien in \(category): \(error)")
            return 0
        }
    }
    
    func deleteCategory(at offsets: IndexSet) {
        let fileManager = FileManager.default
        let documentsURL = fileManager.urls(for: .documentDirectory, in: .userDomainMask)[0]
        for index in offsets {
            let category = categories[index]
            let categoryURL = documentsURL.appendingPathComponent(category)
            do {
                try fileManager.removeItem(at: categoryURL)
                print("Ordner \(category) gelöscht")
                DocumentMetadataManager.shared.removeMetadata(forCategory: category)
            } catch {
                print("Fehler beim Löschen des Ordners \(category): \(error)")
            }
        }
        loadCategories()
    }

}
