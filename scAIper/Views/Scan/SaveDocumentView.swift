//
//  SaveDocumentView.swift
//  scAIper
//
//  Created by Dominik Hommer on 20.03.25.
//

import SwiftUI

struct SaveDocumentView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var fileName: String = ""
    
    let documentType: DocumentType
    let layoutType: LayoutType
    let sourceURL: URL
    let documentContent: String
    
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
                
                Button("Dokument speichern") {
                    saveDocument()
                }
            }
            .navigationTitle("Dokument speichern")
        }
    }
    
    private func saveDocument() {
        // 1) Dateinamen bauen
        let trimmed = fileName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        
        let timestamp = DateFormatter("yyyyMMdd_HHmmss").string(from: Date())
        let fullFileName = "\(trimmed)_\(documentType.id)_\(layoutType.id)_\(timestamp)\(layoutType.fileSuffix)"
        
        if documentType == .rechnung || documentType == .lohnzettel {
            let extractor = KeywordLLMExtractor()
            extractor.extractKeywords(documentType: documentType, text: documentContent) { result in
                switch result {
                case .success(let keywords):
                    DispatchQueue.main.async {
                        DocumentSaver.saveDocument(
                            sourceURL: self.sourceURL,
                            fileName: fullFileName,
                            documentType: documentType,
                            layoutType: layoutType,
                            content: documentContent,
                            keywords: keywords
                        )
                        dismiss()
                    }
                case .failure(let error):
                    print("Keyword-Extraktion fehlgeschlagen:", error)
                    DispatchQueue.main.async {
                        DocumentSaver.saveDocument(
                            sourceURL: self.sourceURL,
                            fileName: fullFileName,
                            documentType: documentType,
                            layoutType: layoutType,
                            content: documentContent,
                            keywords: nil
                        )
                        dismiss()
                    }
                }
            }
        } else {
            DocumentSaver.saveDocument(
                sourceURL: sourceURL,
                fileName: fullFileName,
                documentType: documentType,
                layoutType: layoutType,
                content: documentContent,
                keywords: nil
            )
            dismiss()
        }
    }
}

private extension DateFormatter {
    convenience init(_ format: String) {
        self.init()
        dateFormat = format
    }
}





