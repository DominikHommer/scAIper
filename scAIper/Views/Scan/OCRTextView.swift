
import SwiftUI
import UIKit

struct OCRTextView: View {
    @Environment(\.dismiss) var dismiss
    
    @StateObject private var viewModel = OcrViewModel()
    
    @Binding var scannedImage: UIImage?
    @Binding var isShowingCamera: Bool
    
    @State private var scanProgress: CGFloat = 0
    @State private var dotOffsetX: CGFloat = 0
    @State private var time: Double = 0.0
    @State private var imageSize: CGSize = .zero
    @State private var showFullScreenImage = false
    
    var body: some View {
        ScrollView {
            VStack {
                if let image = scannedImage {
                    GeometryReader { geo in
                        ZStack {
                            Image(uiImage: image)
                                .resizable()
                                .scaledToFit()
                                .background(
                                    GeometryReader { proxy in
                                        Color.clear.onAppear {
                                            imageSize = proxy.size
                                        }
                                    }
                                )
                                .frame(width: geo.size.width, height: geo.size.height)
                                .onTapGesture {
                                    showFullScreenImage = true
                                }
                                .fullScreenCover(isPresented: $showFullScreenImage) {
                                    FullScreenImageView(image: image)
                                }
                            
                            if viewModel.isScanning {
                                ZStack {
                                    Rectangle()
                                        .fill(Color.white.opacity(0.8))
                                        .frame(width: imageSize.width, height: 4)
                                        .offset(y: scanProgress)
                                        .animation(
                                            .linear(duration: 2.0)
                                            .repeatForever(autoreverses: true),
                                            value: scanProgress
                                        )
                                    
                                    Circle()
                                        .fill(Color.white.opacity(0.9))
                                        .overlay(
                                            Circle().stroke(Color.white, lineWidth: 1)
                                        )
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
                
                HStack {
                    Button {
                        guard let image = scannedImage else { return }
                        viewModel.startOcr(on: image)
                        startScanAnimation()
                    } label: {
                        Image(systemName: "lasso.badge.sparkles")
                            .resizable()
                            .frame(width: 50, height: 50)
                            .foregroundColor(.green)
                    }
                    .padding()
                    
                    Button {
                        resetView()
                    } label: {
                        Image(systemName: "arrow.clockwise.circle.fill")
                            .resizable()
                            .frame(width: 50, height: 50)
                            .foregroundColor(.red)
                    }
                    .padding()
                    
                    Button {
                        cleanUpAndDismiss()
                    } label: {
                        Image(systemName: "trash")
                            .resizable()
                            .frame(width: 50, height: 50)
                            .foregroundColor(.red)
                    }
                    .padding()
                }
                
                if viewModel.hasAttemptedExtraction {
                    if viewModel.extractedText.isEmpty {
                        Text("Kein Text erkannt :(")
                            .foregroundColor(.gray)
                            .italic()
                            .padding()
                    } else {
                        Text(viewModel.extractedText)
                            .padding()
                    }
                }
            }
        }
        .onChange(of: viewModel.isScanning) { _, newVal in
            if !newVal {
                stopScanAnimation()
            }
        }
    }
}

extension OCRTextView {
    private func startScanAnimation() {
        withAnimation(.linear(duration: 2.0).repeatForever(autoreverses: true)) {
            scanProgress = imageSize.height / 2
        }
        
        time = 0.0
        Timer.scheduledTimer(withTimeInterval: 0.016, repeats: true) { timer in
            time += 0.016
            dotOffsetX = (imageSize.width / 2 - 10) * CGFloat(sin(time * 2 * .pi))
            
            if !viewModel.isScanning {
                timer.invalidate()
            }
        }
    }
    
    private func stopScanAnimation() {
        scanProgress = 0
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



























