//
//  DocumentDetailView.swift
//  scAIper
//
//  Created by Dominik Hommer on 17.03.25.
//


import SwiftUI


struct DocumentDetailView: View {
    let fileURL: URL
    @StateObject private var viewModel: DocumentDetailViewModel
    
    init(fileURL: URL) {
        self.fileURL = fileURL
        _viewModel = StateObject(wrappedValue: DocumentDetailViewModel(fileURL: fileURL))
    }
    
    var body: some View {
        Group {
            switch fileURL.pathExtension.lowercased() {
            case "pdf":
                PDFKitView(url: fileURL)
            case "csv":
                CSVTableView(csvURL: fileURL)
            case "txt":
                ScrollView {
                    Text(viewModel.documentText)
                        .padding()
                }
                .onAppear {
                    viewModel.loadDocument()
                }
            default:
                Text("Nicht unterstütztes Dateiformat")
                    .foregroundColor(.red)
            }
        }
        .navigationTitle(fileURL.lastPathComponent)
    }
}





