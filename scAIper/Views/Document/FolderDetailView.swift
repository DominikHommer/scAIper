//
//  FolderDetailView.swift
//  scAIper
//
//  Created by Dominik Hommer on 17.03.25.
//


import SwiftUI

struct FolderDetailView: View {
    let folder: DocumentFolder
    @Binding var folders: [DocumentFolder]
    
    @State private var newDocumentName: String = ""
    @State private var isAddingDocument = false
    
    var body: some View {
        List {
            ForEach(folder.documents) { document in
                NavigationLink(destination: DocumentDetailView(document: document)) {
                    HStack {
                        Image(systemName: "doc.text")
                            .foregroundColor(.blue)
                        
                        VStack(alignment: .leading) {
                            Text(document.name)
                                .font(.headline)
                            Text(document.date, format: .dateTime.day().month().year())
                                .font(.subheadline)
                                .foregroundColor(.gray)
                        }
                    }
                }
            }
            .onDelete(perform: deleteDocument)
        }
        .navigationTitle(folder.name)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: { isAddingDocument = true }) {
                    Label("Dokument hinzufügen", systemImage: "plus")
                }
            }
        }
        .alert("Neues Dokument hinzufügen", isPresented: $isAddingDocument) {
            TextField("Dokumentname", text: $newDocumentName)
            Button("Hinzufügen", action: addDocument)
            Button("Abbrechen", role: .cancel) { }
        }
    }
    
    private func addDocument() {
        guard !newDocumentName.isEmpty else { return }
        
        if let index = folders.firstIndex(where: { $0.id == folder.id }) {
            folders[index].documents.append(Document(name: newDocumentName, date: Date()))
        }
        
        newDocumentName = ""
    }

    private func deleteDocument(at offsets: IndexSet) {
        if let index = folders.firstIndex(where: { $0.id == folder.id }) {
            folders[index].documents.remove(atOffsets: offsets)
        }
    }
}

#Preview {
    FolderDetailView(folder: DocumentFolder(name: "Verträge", documents: [
        Document(name: "Mietvertrag", date: Date())
    ]), folders: .constant([]))
}
