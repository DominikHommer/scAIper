//
//  DocumentListView.swift
//  scAIper
//
//  Created by Dominik Hommer on 17.03.25.
//

import SwiftUI

/// A view that displays a list of document folders (categories) with navigation links to view their contents.
/// Users can delete entire categories or navigate into them to view documents.
struct FolderListView: View {
    
    /// View model responsible for handling category data and related logic.
    @StateObject private var viewModel = FolderListViewModel()
    
    var body: some View {
        NavigationStack {
            List {
                ForEach(viewModel.categories, id: \.self) { category in
                    // Navigation to the detail view of the selected category
                    NavigationLink(destination: FolderDetailView(category: category)) {
                        HStack {
                            Image(systemName: "folder")
                                .foregroundColor(.accentColor)
                            Text(category)
                            Spacer()
                            // Display the document count in that category
                            Text("\(viewModel.documentCount(for: category))")
                                .foregroundColor(.secondary)
                        }
                    }
                }
                // Allows deletion of categories from the list
                .onDelete(perform: viewModel.deleteCategory)
            }
            .navigationTitle("Dokumente")
            .onAppear {
                // Loads the available document categories when the view appears
                viewModel.loadCategories()
            }
            .toolbar {
                // Edit button for enabling deletion mode
                EditButton()
            }
        }
    }
}

