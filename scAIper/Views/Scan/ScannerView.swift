//
//  ScannerView.swift
//  scAIper
//
//  Created by Dominik Hommer on 17.03.25.
//

import SwiftUI

/// A view that allows users to initiate a document scan process for a specific document type.
/// Shows a visual scan area and opens the camera when tapped.
struct ScannerView: View {
    
    /// The type of document being scanned, used to label the scan and pass to downstream views.
    let selectedDocument: DocumentType
    
    /// The view model managing scan state and navigation.
    @StateObject private var viewModel = ScannerViewModel()

    var body: some View {
        VStack {
            /// Title indicating which document type is being scanned.
            Text("Scanne: \(selectedDocument.rawValue)")
                .font(.largeTitle)
                .padding(.top, 20)
            
            Spacer()
            
            /// Stylized camera box with dashed border.
            ZStack {
                RoundedRectangle(cornerRadius: 12)
                    .strokeBorder(style: StrokeStyle(lineWidth: 2, dash: [10]))
                    .foregroundColor(.gray)
                    .frame(width: 250, height: 250)
                
                VStack {
                    Image(systemName: "camera.fill")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 80, height: 80)
                        .foregroundColor(.black)
                    
                    Text("Zum Scannen tippen")
                        .font(.headline)
                        .foregroundColor(.gray)
                }
            }
            /// Triggers the scanning process when tapped.
            .onTapGesture {
                viewModel.scanTapped()
            }
            .padding(.bottom, 40)
            
            Spacer()
        }
        /// Presents the camera interface in full screen when scanning is active.
        .fullScreenCover(isPresented: $viewModel.isShowingCamera, onDismiss: {
            viewModel.didDismissCamera()
        }) {
            DocumentScannerView(
                scannedImage: $viewModel.scannedImage,
                isPresented: $viewModel.isShowingCamera
            )
            .ignoresSafeArea()
        }
        /// Navigates to the OCR text view after a successful scan.
        .navigationDestination(isPresented: $viewModel.navigateToOCR) {
            OCRTextView(
                scannedImage: $viewModel.scannedImage,
                isShowingCamera: $viewModel.isShowingCamera,
                documentType: selectedDocument
            )
            .toolbar(.hidden, for: .tabBar)
        }
    }
}












