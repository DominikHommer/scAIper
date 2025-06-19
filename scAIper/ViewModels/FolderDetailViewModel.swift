//
//  FolderDetailViewModel.swift
//  scAIper
//
//  Created by Dominik Hommer on 27.03.25.
//

import SwiftUI

/// ViewModel responsible for managing documents inside a specific folder category.
class FolderDetailViewModel: ObservableObject {
    /// List of document file URLs in the given category.
    @Published var files: [URL] = []

    /// The name of the category (folder) whose contents are displayed.
    let category: String

    /// Initializes the ViewModel with a given category and loads its contents.
    /// - Parameter category: The name of the folder category.
    init(category: String) {
        self.category = category
        loadFiles()
    }

    /// Loads all non-hidden files in the specified category folder and sorts them alphabetically.
    func loadFiles() {
        let fileManager = FileManager.default
        let documentsURL = fileManager.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let categoryURL = documentsURL.appendingPathComponent(category)
        do {
            let fileURLs = try fileManager.contentsOfDirectory(
                at: categoryURL,
                includingPropertiesForKeys: nil,
                options: .skipsHiddenFiles
            )
            DispatchQueue.main.async {
                self.files = fileURLs.sorted { $0.lastPathComponent < $1.lastPathComponent }
            }
        } catch {
            print("Error loading files: \(error)")
        }
    }

    /// Deletes one or more selected documents from the file system and removes associated metadata.
    /// - Parameter offsets: The index set indicating which files in `files` should be deleted.
    func deleteDocument(at offsets: IndexSet) {
        let fileManager = FileManager.default
        for index in offsets {
            let file = files[index]
            do {
                try fileManager.removeItem(at: file)
                print("Deleted document: \(file.lastPathComponent)")
                DocumentMetadataManager.shared.removeMetadata(forFileURL: file)
            } catch {
                print("Error deleting file \(file.lastPathComponent): \(error)")
            }
        }
        loadFiles()
    }
}

/// Extension to determine which SF Symbol icon to use based on a file’s extension.
extension URL {
    /// Returns the appropriate SF Symbol name for the file type.
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
