//
//  ScannerView.swift
//  scAIper
//
//  Created by Dominik Hommer on 17.03.25.
//
import SwiftUI

struct ScannerView: View {
    let selectedDocument: DocumentType
    @StateObject private var viewModel = ScannerViewModel()

    var body: some View {
        VStack {
            Text("Scanne: \(selectedDocument.rawValue)")
                .font(.largeTitle)
                .padding(.top, 20)
            
            Spacer()
            
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
            .onTapGesture {
                viewModel.scanTapped()
            }
            .padding(.bottom, 40)
            
            Spacer()
        }
        .fullScreenCover(isPresented: $viewModel.isShowingCamera, onDismiss: {
            viewModel.didDismissCamera()
        }) {
            DocumentScannerView(scannedImage: $viewModel.scannedImage, isPresented: $viewModel.isShowingCamera)
                .ignoresSafeArea()
        }
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











