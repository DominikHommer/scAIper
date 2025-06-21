//
//  DocumentScannerView.swift
//  scAIper
//
//  Created by Dominik Hommer on 24.03.25.
//

import SwiftUI
import VisionKit

/// A SwiftUI wrapper for `VNDocumentCameraViewController`, allowing users to scan documents using the device camera.
/// The scanned image is passed back to the parent via bindings.
struct DocumentScannerView: UIViewControllerRepresentable {
    
    /// The image resulting from the scan. Will be set after a successful scan.
    @Binding var scannedImage: UIImage?
    
    /// Controls whether the scanner view is currently presented.
    @Binding var isPresented: Bool

    /// Creates the coordinator which acts as a delegate for the document camera.
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    /// Creates the underlying `VNDocumentCameraViewController`.
    func makeUIViewController(context: Context) -> VNDocumentCameraViewController {
        let scanner = VNDocumentCameraViewController()
        scanner.delegate = context.coordinator
        return scanner
    }

    /// Updates the underlying view controller. Not used in this implementation.
    func updateUIViewController(_ uiViewController: VNDocumentCameraViewController, context: Context) {
        // No updates needed.
    }

    /// A coordinator class that acts as the delegate for `VNDocumentCameraViewController`.
    class Coordinator: NSObject, VNDocumentCameraViewControllerDelegate {
        
        /// A reference to the parent view.
        var parent: DocumentScannerView

        /// Initializes the coordinator with a reference to the parent view.
        /// - Parameter parent: The `DocumentScannerView` instance.
        init(_ parent: DocumentScannerView) {
            self.parent = parent
        }

        /// Called when the user finishes scanning documents.
        /// - Parameters:
        ///   - controller: The document scanner view controller.
        ///   - scan: The scan result containing one or more pages.
        func documentCameraViewController(_ controller: VNDocumentCameraViewController, didFinishWith scan: VNDocumentCameraScan) {
            if scan.pageCount > 0 {
                let image = scan.imageOfPage(at: 0)
                parent.scannedImage = image
            }
            parent.isPresented = false
        }

        /// Called when the user cancels the scanning operation.
        func documentCameraViewControllerDidCancel(_ controller: VNDocumentCameraViewController) {
            parent.isPresented = false
        }

        /// Called when the scanning operation fails with an error.
        /// - Parameters:
        ///   - controller: The document scanner view controller.
        ///   - error: The error that occurred.
        func documentCameraViewController(_ controller: VNDocumentCameraViewController, didFailWithError error: Error) {
            print("Document scanning failed: \(error.localizedDescription)")
            parent.isPresented = false
        }
    }
}
