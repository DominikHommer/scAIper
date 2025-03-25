//
//  ScannerView.swift
//  scAIper
//
//  Created by Dominik Hommer on 17.03.25.
//
import SwiftUI

struct ScannerView: View {
    let selectedDocument: DocumentType
    
    @State private var isShowingCamera = false
    @State private var scannedImage: UIImage? = nil
    @State private var navigateToOCR = false
    
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
                isShowingCamera = true
            }
            .padding(.bottom, 40)
            
            Spacer()
        }
        .fullScreenCover(isPresented: $isShowingCamera, onDismiss: {
            if scannedImage != nil {
                navigateToOCR = true
            }
        }) {
            DocumentScannerView(scannedImage: $scannedImage, isPresented: $isShowingCamera)
                .ignoresSafeArea()
        }
        .navigationDestination(isPresented: $navigateToOCR) {
            OCRTextView(
                scannedImage: $scannedImage,
                isShowingCamera: $isShowingCamera,
                documentType: selectedDocument
            )
            .toolbar(.hidden, for: .tabBar)
        }
    }
}











