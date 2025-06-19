//
//  SaveDocumentView.swift
//  scAIper
//
//  Created by Dominik Hommer on 20.03.25.
//

import SwiftUI

/// A view allowing the user to save a scanned document by specifying its name and type.
/// Depending on the document type, keywords may be extracted using an LLM.
struct SaveDocumentView: View {
    
    /// Dismisses the view.
    @Environment(\.dismiss) private var dismiss
    
    /// The file name entered by the user (without extension).
    @State private var fileName: String = ""
    
    /// The selected document type (e.g., invoice, salary slip).
    let documentType: DocumentType
    
    /// The selected layout type (e.g., PDF, CSV).
    let layoutType: LayoutType
    
    /// The source file URL of the document.
    let sourceURL: URL
    
    /// The raw content of the document (used for keyword extraction).
    let documentContent: String

    var body: some View {
        NavigationStack {
            Form {
                // Input field for the document name
                Section(header: Text("Dateiname")) {
                    HStack {
                        TextField("Name eingeben", text: $fileName)
                            .disableAutocorrection(true)
                        Text(layoutType.fileSuffix)
                            .foregroundColor(.gray)
                    }
                }

                // Save button
                Button("Dokument speichern") {
                    saveDocument()
                }
            }
            .navigationTitle("Dokument speichern")
        }
    }

    /// Saves the document with the selected metadata and optionally extracted keywords.
    private func saveDocument() {
        // 1) Build the full file name with timestamp and suffix
        let trimmed = fileName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        
        let timestamp = DateFormatter("yyyyMMdd_HHmmss").string(from: Date())
        let fullFileName = "\(trimmed)_\(documentType.id)_\(layoutType.id)_\(timestamp)\(layoutType.fileSuffix)"
        
        // 2) Handle special case for invoices or payslips where keyword extraction is required
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
            // 3) Save document without keyword extraction
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

/// A convenience initializer for `DateFormatter` to simplify one-liners with format strings.
private extension DateFormatter {
    /// Initializes a date formatter with a given date format.
    /// - Parameter format: The desired date format (e.g., "yyyyMMdd_HHmmss").
    convenience init(_ format: String) {
        self.init()
        dateFormat = format
    }
}
