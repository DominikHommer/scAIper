//
//  DocumentListView.swift
//  scAIper
//
//  Created by Dominik Hommer on 17.03.25.
//


import SwiftUI

struct DocumentListView: View {
    @State private var categories: [String] = []
    
    var body: some View {
        NavigationStack {
            List(categories, id: \.self) { category in
                NavigationLink(destination: FolderDetailView(category: category)) {
                    Text(category)
                }
            }
            .navigationTitle("Dokumente")
            .onAppear {
                loadCategories()
            }
            .toolbar {
                NavigationLink("Neu", destination: SaveDocumentView(documentText: "Hier steht der erkannte Text"))
            }
        }
    }
    
    func loadCategories() {
        let fileManager = FileManager.default
        let documentsURL = fileManager.urls(for: .documentDirectory, in: .userDomainMask)[0]
        do {
            let folderURLs = try fileManager.contentsOfDirectory(at: documentsURL, includingPropertiesForKeys: nil, options: .skipsHiddenFiles)
            categories = folderURLs.filter { $0.hasDirectoryPath }.map { $0.lastPathComponent }
        } catch {
            print("Fehler beim Laden der Kategorien: \(error)")
        }
    }
}


#Preview {
    DocumentListView()
}
