//
//  DocumentDetailView.swift
//  scAIper
//
//  Created by Dominik Hommer on 17.03.25.
//


import SwiftUI



struct DocumentDetailView: View {
    let fileURL: URL
    @State private var documentText: String = ""
    
    var body: some View {
        Group {
            switch fileURL.pathExtension.lowercased() {
            case "pdf":
                PDFKitView(url: fileURL)
            case "csv":
                CSVTableView(csvURL: fileURL)
            case "txt":
                ScrollView {
                    Text(documentText)
                        .padding()
                }
                .onAppear {
                    loadTextDocument()
                }
            default:
                Text("Nicht unterstütztes Dateiformat")
                    .foregroundColor(.red)
            }
        }
        .navigationTitle(fileURL.lastPathComponent)
    }
    
    private func loadTextDocument() {
        do {
            documentText = try String(contentsOf: fileURL, encoding: .utf8)
        } catch {
            print("Fehler beim Laden des Dokuments: \(error)")
        }
    }
}





