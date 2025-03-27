
import SwiftUI
import UIKit


struct OCRTextView: View {
    @Environment(\.dismiss) var dismiss
    @StateObject private var viewModel = OcrViewModel()
    
    @Binding var scannedImage: UIImage?
    @Binding var isShowingCamera: Bool
    
    let documentType: DocumentType
    @State private var selectedLayout: LayoutType? = nil
    @State private var showFullScreenImage = false
    @State private var showSaveDocumentSheet = false
    @State private var showGenerationOptions = false
    
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
                                                viewModel.imageSize = proxy.size
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
                                            .frame(width: viewModel.imageSize.width, height: 4)
                                            .offset(y: viewModel.scanProgress)
                                        
                                        Circle()
                                            .fill(Color.white.opacity(0.9))
                                            .overlay(Circle().stroke(Color.blue, lineWidth: 1))
                                            .frame(width: 12, height: 12)
                                            .blur(radius: 3)
                                            .offset(x: viewModel.dotOffsetX, y: viewModel.scanProgress)
                                    }
                                }
                            }
                            .onAppear {
                                viewModel.scanProgress = -viewModel.imageSize.height / 2
                            }
                        }
                        .frame(height: 600)
                    }
                    
                    if viewModel.hasAttemptedExtraction {
                        if let sourceURL = viewModel.sourceURL {
                            if selectedLayout == .text {
                                PDFKitView(url: sourceURL)
                                    .frame(height: 400)
                                    .cornerRadius(10)
                                    .padding()
                            } else if selectedLayout == .tabelle {
                                CSVTableView(csvURL: sourceURL)
                                    .frame(minHeight: 300)
                                    .padding(.horizontal)
                            }
                        } else {
                            Text("Kein Text erkannt :(")
                                .foregroundColor(.gray)
                                .italic()
                                .padding()
                        }
                    }
                }
            }
            customTabBar
        }
        .navigationTitle("OCR Scan")
        .navigationBarTitleDisplayMode(.inline)
        .onChange(of: viewModel.isScanning) { _, newVal in
            if !newVal { viewModel.stopScanAnimation() }
        }
    }
    
    
    private var customTabBar: some View {
        HStack(spacing: 50) {
            Button {
                showGenerationOptions = true
            } label: {
                Image(systemName: "wand.and.sparkles")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 30, height: 30)
                    .foregroundColor(.blue)
            }
            .confirmationDialog("Generierungsoptionen", isPresented: $showGenerationOptions, titleVisibility: .visible) {
                Button("Als Fließtext generieren") {
                    guard let image = scannedImage else { return }
                    selectedLayout = .text
                    viewModel.startScanAnimation()
                    viewModel.startOcrAndGeneratePDF(on: image, layout: .text) { _ in
                        viewModel.stopScanAnimation()
                    }
                }
                
                Button("Als Tabelle generieren") {
                    guard let image = scannedImage else { return }
                    selectedLayout = .tabelle
                    viewModel.startScanAnimation()
                    viewModel.startOcrAndGenerateCSV(on: image, layout: .tabelle) { _ in
                        viewModel.stopScanAnimation()
                    }
                }
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
                    .foregroundColor(viewModel.sourceURL != nil ? .blue : .gray)
            }
            .disabled(viewModel.sourceURL == nil)
        }
        .padding(.vertical, 10)
        .frame(maxWidth: .infinity)
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .padding(.horizontal)
        .padding(.bottom, 10)
        .sheet(isPresented: $showSaveDocumentSheet) {
            if let sourceURL = viewModel.sourceURL {
                SaveDocumentView(
                    documentType: documentType,
                    layoutType: selectedLayout ?? .text,
                    sourceURL: sourceURL
                )
            }
        }
    }
    
    
    private func resetView() {
        isShowingCamera = true
        scannedImage = nil
        viewModel.reset()
    }
    
    private func cleanUpAndDismiss() {
        scannedImage = nil
        viewModel.reset()
        isShowingCamera = false
        dismiss()
    }
}




























