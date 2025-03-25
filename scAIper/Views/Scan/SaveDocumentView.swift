//
//  SaveDocumentView.swift
//  scAIper
//
//  Created by Dominik Hommer on 20.03.25.
//
import SwiftUI

struct SaveDocumentView: View {
    @Environment(\.dismiss) var dismiss
    @State private var fileName: String = ""
    @State private var selectedCategory: String = "Rechnungen"
    @State private var selectedFileSuffix: String = ".txt"

    let categories = ["Rechnungen", "Verträge", "Lohnbescheide", "Briefe", "Berichte", "Andere"]
    let fileCategories = [".txt", ".pdf", ".csv"]
    let documentText: String
    
    var body: some View {
        NavigationStack {
            Form {
                Section(header: Text("Dateiname")) {
                    TextField("Name eingeben", text: $fileName)
                        .disableAutocorrection(true)
                }
                Section(header: Text("Kategorie auswählen")) {
                    Picker("Kategorie", selection: $selectedCategory) {
                        ForEach(categories, id: \.self) { cat in
                            Text(cat)
                        }
                    }
                    .pickerStyle(.menu)
                }
                Section(header: Text("Speicherformat auswählen")) {
                    Picker("Speicherformat", selection: $selectedFileSuffix) {
                        ForEach(fileCategories, id: \.self) { cat in
                            Text(cat)
                        }
                    }
                    .pickerStyle(.segmented)
                }
                Button("Dokument speichern") {
                    guard !fileName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
                    Task(priority: .userInitiated) {
                        DocumentSaver.saveDocument(documentText: documentText, fileName: fileName, selectedCategory: selectedCategory, fileSuffix: selectedFileSuffix)
                        dismiss()
                    }
                }
            }
            .navigationTitle("Dokument speichern")
        }
    }
}


