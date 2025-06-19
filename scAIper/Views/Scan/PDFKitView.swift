//
//  PDFKitView.swift
//  scAIper
//
//  Created by Dominik Hommer on 27.03.25.
//

import SwiftUI
import PDFKit

/// A SwiftUI wrapper for `PDFView` using `UIViewRepresentable`.
/// This view displays a PDF document from a given file URL.
struct PDFKitView: UIViewRepresentable {
    
    /// The URL of the PDF document to display.
    let url: URL

    /// Creates the underlying `PDFView` instance to be used in SwiftUI.
    /// - Parameter context: A context structure containing information about the current state of the system.
    /// - Returns: A configured `PDFView` instance.
    func makeUIView(context: Context) -> PDFView {
        let pdfView = PDFView()
        pdfView.autoScales = true // Automatically scales the PDF to fit the view
        return pdfView
    }

    /// Updates the `PDFView` when the SwiftUI state changes.
    /// - Parameters:
    ///   - uiView: The `PDFView` instance being updated.
    ///   - context: A context structure containing information about the current update cycle.
    func updateUIView(_ uiView: PDFView, context: Context) {
        if let document = PDFDocument(url: url) {
            uiView.document = document
        }
    }
}

