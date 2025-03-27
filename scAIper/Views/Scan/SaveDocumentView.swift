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
    
    let documentType: DocumentType
    let layoutType: LayoutType
    let sourceURL: URL
    
    var body: some View {
        NavigationStack {
            Form {
                Section(header: Text("Dateiname")) {
                    HStack {
                        TextField("Name eingeben", text: $fileName)
                            .disableAutocorrection(true)
                        Text(layoutType.fileSuffix)
                            .foregroundColor(.gray)
                    }
                }
                Section {
                    Button("Dokument speichern") {
                        let dateFormatter = DateFormatter()
                        dateFormatter.dateFormat = "yyyyMMdd_HHmmss"
                        let timestampString = dateFormatter.string(from: Date())
                        
                        guard !fileName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
                        let fullFileName = "\(fileName)_\(documentType.id)_\(layoutType.id)_\(timestampString)\(layoutType.fileSuffix)"
                        Task(priority: .userInitiated) {
                            DocumentSaver.saveDocument(sourceURL: sourceURL, fileName: fullFileName, documentType: documentType, layoutType: layoutType)
                            dismiss()
                        }
                    }
                }
            }
            .navigationTitle("Dokument speichern")
        }
    }
}



