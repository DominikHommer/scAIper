
import SwiftUI
import UIKit

struct OCRTextView: View {
    
    @Environment(\.dismiss) var dismiss
    @StateObject private var viewModel = OcrViewModel()
    
    @Binding var scannedImage: UIImage?
    @Binding var isShowingCamera: Bool
    
    let documentType: DocumentType
    
    @State private var scanProgress: CGFloat = 0
    @State private var dotOffsetX: CGFloat = 0
    @State private var time: Double = 0.0
    @State private var imageSize: CGSize = .zero
    @State private var showFullScreenImage = false
    @State private var showSaveDocumentSheet = false
    @State private var animationTimer: Timer?

    
    var body: some View {
            ZStack(alignment: .bottom) {
                ScrollView {
                    VStack(spacing: 20) {
                        if let image = scannedImage {
                            GeometryReader { geo in
                                ZStack {
                                    Image(uiImage: image)
                                        .resizable()
                                        .scaledToFit()
                                        .cornerRadius(5)
                                        .background(
                                            GeometryReader { proxy in
                                                Color.clear.onAppear {
                                                    imageSize = proxy.size
                                                }
                                            }
                                        )
                                        .frame(width: geo.size.width, height: geo.size.height)
                                        .onTapGesture { showFullScreenImage = true }
                                        .fullScreenCover(isPresented: $showFullScreenImage) {
                                            FullScreenImageView(image: image)
                                        }
                                    
                                    if viewModel.isScanning {
                                        ZStack {
                                            Rectangle()
                                                .fill(Color.white.opacity(0.8))
                                                .frame(width: imageSize.width, height: 4)
                                                .offset(y: scanProgress)
                                            
                                            Circle()
                                                .fill(Color.white.opacity(0.9))
                                                .overlay(Circle().stroke(Color.blue, lineWidth: 1))
                                                .frame(width: 12, height: 12)
                                                .blur(radius: 3)
                                                .offset(x: dotOffsetX, y: scanProgress)
                                        }
                                    }
                                }
                                .onAppear {
                                    scanProgress = -geo.size.height / 2
                                }
                            }
                            .frame(height: 400)
                        }
                        
                        if viewModel.hasAttemptedExtraction {
                            if let pdfURL = viewModel.pdfURL {
                                PDFKitView(url: pdfURL)
                                    .frame(height: 400)
                                    .cornerRadius(10)
                                    .padding()
                            } else {
                                Text("Kein Text erkannt :(")
                                    .foregroundColor(.gray)
                                    .italic()
                                    .padding()
                            }
                        }
                        Spacer().frame(height: 100)
                    }

                }
                customTabBar
            }
            .navigationTitle("OCR Scan")
            .navigationBarTitleDisplayMode(.inline)
        .onChange(of: viewModel.isScanning) { _, newVal in
            if !newVal { stopScanAnimation() }
        }
    }
        
    private var customTabBar: some View {
        HStack(spacing: 50) {
            Button {
                guard let image = scannedImage else { return }

                startScanAnimation()

                viewModel.startOcrAndGeneratePDF(on: image) { pdfURL in
                    DispatchQueue.main.async {
                        stopScanAnimation()

                        guard let url = pdfURL else {
                            print("PDF-Erstellung fehlgeschlagen.")
                            return
                        }

                        viewModel.pdfURL = url
                        viewModel.hasAttemptedExtraction = true
                    }
                }


            }
            label: {
                Image(systemName: "wand.and.sparkles")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 30, height: 30)
                    .foregroundColor(.blue)
            }
            
            Button {
                resetView()
            } label: {
                Image(systemName: "arrow.clockwise")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 30, height: 30)
                    .foregroundColor(.blue)
            }
            
            Button {
                cleanUpAndDismiss()
            } label: {
                Image(systemName: "trash")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 30, height: 30)
                    .foregroundColor(.blue)
            }
            Button {
                showSaveDocumentSheet.toggle()
            } label: {
                Image(systemName: "square.and.arrow.down")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 30, height: 30)
                    .foregroundColor(viewModel.pdfURL != nil ? .blue : .gray)
            }
            .disabled(viewModel.pdfURL == nil)
        }
        .padding(.vertical, 10)
        .frame(maxWidth: .infinity)
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .padding(.horizontal)
        .padding(.bottom, 10)
        .sheet(isPresented: $showSaveDocumentSheet) {
            SaveDocumentView(documentText: viewModel.extractedText)
        }
    }
}

extension OCRTextView {
    private func startScanAnimation() {
        time = 0.0
        scanProgress = -imageSize.height / 2

        animationTimer?.invalidate()
        animationTimer = Timer.scheduledTimer(withTimeInterval: 0.016, repeats: true) { timer in
            time += 0.016

            dotOffsetX = (imageSize.width / 2 - 10) * CGFloat(sin(time * 2 * .pi))

            scanProgress += 1.5
            if scanProgress > imageSize.height / 2 {
                scanProgress = -imageSize.height / 2
            }

            if !viewModel.isScanning {
                timer.invalidate()
            }
        }
    }

    
    private func stopScanAnimation() {
        animationTimer?.invalidate()
        animationTimer = nil
        scanProgress = -imageSize.height / 2
        dotOffsetX = 0
    }

    
    private func resetView() {
        isShowingCamera = true
        scannedImage = nil
        viewModel.reset()
        stopScanAnimation()
        
        
    }
    
    private func cleanUpAndDismiss() {
        scannedImage = nil
        viewModel.reset()
        isShowingCamera = false
        
        stopScanAnimation()
        time = 0.0
        imageSize = .zero
        
        dismiss()
    }
}



























