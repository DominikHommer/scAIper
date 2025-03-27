//
//  DocumentListView.swift
//  scAIper
//
//  Created by Dominik Hommer on 17.03.25.
//

import SwiftUI

struct FolderListView: View {
    @StateObject private var viewModel = FolderListViewModel()
    
    var body: some View {
        NavigationStack {
            List {
                ForEach(viewModel.categories, id: \.self) { category in
                    NavigationLink(destination: FolderDetailView(category: category)) {
                        HStack {
                            Image(systemName: "folder")
                                .foregroundColor(.accentColor)
                            Text(category)
                            Spacer()
                            Text("\(viewModel.documentCount(for: category))")
                                .foregroundColor(.secondary)
                        }
                    }
                }
                .onDelete(perform: viewModel.deleteCategory)
            }
            .navigationTitle("Dokumente")
            .onAppear {
                viewModel.loadCategories()
            }
            .toolbar {
                EditButton()  
                // NavigationLink("Neu", destination: SaveDocumentView(documentText: "Hier steht der erkannte Text"))
            }
        }
    }
}




