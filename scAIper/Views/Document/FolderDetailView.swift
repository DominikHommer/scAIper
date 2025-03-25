//
//  FolderDetailView.swift
//  scAIper
//
//  Created by Dominik Hommer on 17.03.25.
//


import SwiftUI

struct FolderDetailView: View {
    let category: String
    @State private var files: [URL] = []
    
    var body: some View {
        List(files, id: \.self) { file in
            NavigationLink(destination: DocumentDetailView(fileURL: file)) {
                Text(file.lastPathComponent)
            }
        }
        .navigationTitle(category)
        .onAppear {
            loadFiles()
        }
    }
    
    func loadFiles() {
        let fileManager = FileManager.default
        let documentsURL = fileManager.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let categoryURL = documentsURL.appendingPathComponent(category)
        do {
            files = try fileManager.contentsOfDirectory(at: categoryURL, includingPropertiesForKeys: nil, options: .skipsHiddenFiles)
        } catch {
            print("Fehler beim Laden der Dateien: \(error)")
        }
    }
}
