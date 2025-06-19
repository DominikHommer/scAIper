//
//  FolderListViewModel.swift
//  scAIper
//
//  Created by Dominik Hommer on 27.03.25.
//

import SwiftUI

/// ViewModel for managing document folder categories stored in the app's document directory.
class FolderListViewModel: ObservableObject {
    
    /// List of category folder names available in the document directory.
    @Published var categories: [String] = []

    /// Loads the list of folder categories from the user's document directory.
    /// Only non-hidden directories are considered.
    func loadCategories() {
        let fileManager = FileManager.default
        let documentsURL = fileManager.urls(for: .documentDirectory, in: .userDomainMask)[0]
        do {
            let folderURLs = try fileManager.contentsOfDirectory(at: documentsURL, includingPropertiesForKeys: nil, options: .skipsHiddenFiles)
            DispatchQueue.main.async {
                self.categories = folderURLs.filter { $0.hasDirectoryPath }
                    .map { $0.lastPathComponent }
            }
        } catch {
            print("Error loading categories: \(error)")
        }
    }

    /// Returns the number of documents (excluding subdirectories) in a given category folder.
    /// - Parameter category: The name of the folder category to count documents in.
    /// - Returns: The number of non-directory files in the category folder.
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
            print("Error loading files in \(category): \(error)")
            return 0
        }
    }

    /// Deletes the specified categories from the file system and removes their metadata.
    /// - Parameter offsets: The indices of the categories to delete.
    func deleteCategory(at offsets: IndexSet) {
        let fileManager = FileManager.default
        let documentsURL = fileManager.urls(for: .documentDirectory, in: .userDomainMask)[0]
        for index in offsets {
            let category = categories[index]
            let categoryURL = documentsURL.appendingPathComponent(category)
            do {
                try fileManager.removeItem(at: categoryURL)
                print("Folder \(category) deleted")
                DocumentMetadataManager.shared.removeMetadata(forCategory: category)
            } catch {
                print("Error deleting folder \(category): \(error)")
            }
        }
        loadCategories()
    }
}
