//
//  DocumentDetailView.swift
//  scAIper
//
//  Created by Dominik Hommer on 17.03.25.
//

import SwiftUI

/// A view that displays the content of a selected document.
/// Supports PDF, CSV, and TXT file formats.
struct DocumentDetailView: View {
    
    /// The file URL of the document to be displayed.
    let fileURL: URL
    
    /// Stores the text content if the document is a `.txt` file.
    @State private var documentText: String = ""
    
    var body: some View {
        Group {
            switch fileURL.pathExtension.lowercased() {
            case "pdf":
                // Display PDF using PDFKit
                PDFKitView(url: fileURL)
            case "csv":
                // Display CSV in a tabular format
                CSVTableView(csvURL: fileURL)
            case "txt":
                // Display plain text in a scrollable view
                ScrollView {
                    Text(documentText)
                        .padding()
                }
                .onAppear {
                    loadTextDocument()
                }
            default:
                // Show unsupported format message
                Text("Nicht unterstütztes Dateiformat")
                    .foregroundColor(.red)
            }
        }
        .navigationTitle(fileURL.lastPathComponent) // Display filename as the title
    }
    
    /// Loads text content from a `.txt` file.
    private func loadTextDocument() {
        do {
            documentText = try String(contentsOf: fileURL, encoding: .utf8)
        } catch {
            print("Fehler beim Laden des Dokuments: \(error)")
        }
    }
}

