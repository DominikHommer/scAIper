//
//  DocumentDetailViewModel.swift
//  scAIper
//
//  Created by Dominik Hommer on 27.03.25.
//

import SwiftUI

/// ViewModel responsible for managing and loading the content of a specific document file.
class DocumentDetailViewModel: ObservableObject {
    /// The textual content of the loaded document.
    @Published var documentText: String = ""
    
    /// The URL of the document file to be displayed.
    let fileURL: URL

    /// Initializes the ViewModel with the given file URL.
    /// - Parameter fileURL: The URL of the document to be loaded.
    init(fileURL: URL) {
        self.fileURL = fileURL
    }

    /// Loads the content of the file into `documentText`, if it is a `.txt` file.
    ///
    /// This operation is performed asynchronously on a background thread
    /// to avoid blocking the main UI thread. Upon successful reading,
    /// the result is dispatched back to the main queue.
    func loadDocument() {
        guard fileURL.pathExtension.lowercased() == "txt" else { return }
        DispatchQueue.global(qos: .userInitiated).async {
            do {
                let text = try String(contentsOf: self.fileURL, encoding: .utf8)
                DispatchQueue.main.async {
                    self.documentText = text
                }
            } catch {
                print("Error loading document: \(error)")
            }
        }
    }
}
