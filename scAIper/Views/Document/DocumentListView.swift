//
//  DocumentListView.swift
//  scAIper
//
//  Created by Dominik Hommer on 17.03.25.
//


import SwiftUI

struct DocumentListView: View {
    @State private var folders: [DocumentFolder] = [
        DocumentFolder(name: "Verträge", documents: [
            Document(name: "Mietvertrag", date: Date()),
            Document(name: "Handyvertrag", date: Date())
        ]),
        DocumentFolder(name: "Lohnabrechnungen", documents: [
            Document(name: "Lohnabrechnung Januar", date: Date()),
            Document(name: "Lohnabrechnung Februar", date: Date())
        ])
    ]
    
    @State private var newFolderName: String = ""
    @State private var isAddingFolder = false

    var body: some View {
        NavigationView {
            List {
                ForEach(folders) { folder in
                    NavigationLink(destination: FolderDetailView(folder: folder, folders: $folders)) {
                        HStack {
                            Image(systemName: "folder.fill")
                                .foregroundColor(.yellow)
                            Text(folder.name)
                                .font(.headline)
                        }
                    }
                }
                .onDelete(perform: deleteFolder)
            }
            .navigationTitle("Meine Dokumente")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { isAddingFolder = true }) {
                        Label("Ordner hinzufügen", systemImage: "plus")
                    }
                }
            }
            .alert("Neuen Ordner erstellen", isPresented: $isAddingFolder) {
                TextField("Ordnername", text: $newFolderName)
                Button("Hinzufügen", action: addFolder)
                Button("Abbrechen", role: .cancel) { }
            }
        }
    }
    
    private func addFolder() {
        guard !newFolderName.isEmpty else { return }
        folders.append(DocumentFolder(name: newFolderName, documents: []))
        newFolderName = ""
    }

    private func deleteFolder(at offsets: IndexSet) {
        folders.remove(atOffsets: offsets)
    }
}

// Modell für Ordner mit Dokumenten
struct DocumentFolder: Identifiable {
    let id = UUID()
    var name: String
    var documents: [Document]
}

// Modell für Dokumente
struct Document: Identifiable {
    let id = UUID()
    let name: String
    let date: Date
}

#Preview {
    DocumentListView()
}
