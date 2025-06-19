//
//  FolderDetailView.swift
//  scAIper
//
//  Created by Dominik Hommer on 17.03.25.
//

import SwiftUI

/// A view that displays the contents (files) of a specific document category folder.
/// Users can tap on documents to view their details or delete them from the list.
struct FolderDetailView: View {
    
    /// The name of the category (folder) whose contents are displayed.
    let category: String
    
    /// View model managing the list of files in the selected folder.
    @StateObject private var viewModel: FolderDetailViewModel

    /// Custom initializer to pass the category into the view model.
    /// - Parameter category: The selected document category (e.g., "Rechnung").
    init(category: String) {
        self.category = category
        _viewModel = StateObject(wrappedValue: FolderDetailViewModel(category: category))
    }
    
    var body: some View {
        List {
            // List each file in the folder with a navigation link to its details
            ForEach(viewModel.files, id: \.self) { file in
                NavigationLink(destination: DocumentDetailView(fileURL: file)) {
                    HStack {
                        Image(systemName: file.fileIcon) // Custom icon depending on file type
                        Text(file.lastPathComponent)     // File name
                    }
                }
            }
            // Allow file deletion via swipe-to-delete
            .onDelete(perform: viewModel.deleteDocument)
        }
        .navigationTitle(category) // Use the category name as the view title
        .onAppear {
            // Reload the files when the view appears
            viewModel.loadFiles()
        }
    }
}
