//
//  DocumentDetailView.swift
//  scAIper
//
//  Created by Dominik Hommer on 17.03.25.
//


import SwiftUI
import PDFKit

struct DocumentDetailView: View {
    let fileURL: URL
    @State private var documentText: String = ""
    
    var body: some View {
        Group {
            switch fileURL.pathExtension.lowercased() {
            case "pdf":
                PDFKitView(url: fileURL)
            case "txt", "csv":
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

struct PDFKitView: UIViewRepresentable {
    let url: URL

    func makeUIView(context: Context) -> PDFView {
        let pdfView = PDFView()
        pdfView.autoScales = true
        return pdfView
    }

    func updateUIView(_ uiView: PDFView, context: Context) {
        if let document = PDFDocument(url: url) {
            uiView.document = document
        }
    }
}


