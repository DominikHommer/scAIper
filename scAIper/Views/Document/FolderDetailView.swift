//
//  FolderDetailView.swift
//  scAIper
//
//  Created by Dominik Hommer on 17.03.25.
//


import SwiftUI

struct FolderDetailView: View {
    let category: String
    @StateObject private var viewModel: FolderDetailViewModel
    
    init(category: String) {
        self.category = category
        _viewModel = StateObject(wrappedValue: FolderDetailViewModel(category: category))
    }
    
    var body: some View {
        List {
            ForEach(viewModel.files, id: \.self) { file in
                NavigationLink(destination: DocumentDetailView(fileURL: file)) {
                    HStack {
                        Image(systemName: file.fileIcon)
                        Text(file.lastPathComponent)
                    }
                }
            }
            .onDelete(perform: viewModel.deleteDocument)
        }
        .navigationTitle(category)
        .onAppear {
            viewModel.loadFiles()
        }
    }
}

#Preview {
    FolderDetailView(category: "Rechnung")
}

