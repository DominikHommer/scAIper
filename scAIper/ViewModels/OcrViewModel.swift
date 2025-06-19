//
//  OCRViewModel.swift
//  scAIper
//
//  Created by Dominik Hommer on 20.03.25.
//

import Foundation
import UIKit
import PDFKit

/// Represents the layout type of the document – plain text or tabular data.
enum LayoutType: String, CaseIterable, Identifiable, Codable {
    case text = "Text"
    case tabelle = "Tabelle"
    
    var id: String { self.rawValue }

    /// Determines the file suffix based on layout type.
    var fileSuffix: String {
        switch self {
        case .text:
            return ".pdf"
        default:
            return ".csv"
        }
    }
}

/// ViewModel responsible for handling OCR-related logic and animation state.
class OcrViewModel: ObservableObject {
    @Published var extractedText: String = ""
    @Published var isScanning: Bool = false
    @Published var hasAttemptedExtraction: Bool = false
    @Published var sourceURL: URL? = nil

    // Animation state
    @Published var scanProgress: CGFloat = 0
    @Published var dotOffsetX: CGFloat = 0
    @Published var time: Double = 0.0
    @Published var imageSize: CGSize = .zero

    private var animationTimer: Timer? = nil

    /// Core OCR method for extracting text and saving output using a provided generator function.
    private func startOcrAndGenerate(
        for image: UIImage,
        layout: LayoutType,
        fileName: String,
        generator: (UIImage, @escaping (Data?, String?) -> Void) -> Void,
        completion: @escaping (URL?) -> Void
    ) {
        DispatchQueue.main.async {
            self.isScanning = true
            self.hasAttemptedExtraction = false
            self.extractedText = ""
            self.sourceURL = nil
        }

        generator(image) { [weak self] data, recognizedText in
            guard let self = self else { return }
            DispatchQueue.main.async {
                self.isScanning = false
                self.hasAttemptedExtraction = true

                if let recognizedText = recognizedText {
                    self.extractedText = recognizedText
                }

                guard let data = data else {
                    completion(nil)
                    return
                }

                let fileURL = FileManager.default.temporaryDirectory.appendingPathComponent(fileName)
                do {
                    try data.write(to: fileURL)
                    self.sourceURL = fileURL
                    completion(fileURL)
                } catch {
                    print("Error saving file: \(error)")
                    completion(nil)
                }
            }
        }
    }

    /// Starts LLM-only table extraction (no OCR engine) and generates CSV.
    func startLLMImageOnlyGenerateCSV(on image: UIImage, layout: LayoutType, completion: @escaping (URL?) -> Void) {
        startOcrAndGenerate(
            for: image,
            layout: layout,
            fileName: "ocr_output_llm_image.csv",
            generator: { image, completion in
                OCRManager.generateCSVWithOCRv2(from: image, completion: completion)
            },
            completion: completion
        )
    }

    /// Starts OCR with text layout and generates PDF.
    func startOcrAndGeneratePDF(on image: UIImage, layout: LayoutType, completion: @escaping (URL?) -> Void) {
        startOcrAndGenerate(
            for: image,
            layout: layout,
            fileName: "ocr_output.pdf",
            generator: OCRManager.generatePDFWithPositionedOCR,
            completion: completion
        )
    }

    /// Starts OCR with table layout and generates CSV.
    func startOcrAndGenerateCSV(on image: UIImage, layout: LayoutType, completion: @escaping (URL?) -> Void) {
        startOcrAndGenerate(
            for: image,
            layout: layout,
            fileName: "ocr_output.csv",
            generator: OCRManager.generateCSVWithOCR,
            completion: completion
        )
    }

    /// Starts the scanning animation by updating progress and dot position over time.
    func startScanAnimation() {
        time = 0.0
        scanProgress = -imageSize.height / 2

        animationTimer?.invalidate()
        animationTimer = Timer.scheduledTimer(withTimeInterval: 0.016, repeats: true) { [weak self] timer in
            guard let self = self else {
                timer.invalidate()
                return
            }
            self.time += 0.016
            self.dotOffsetX = (self.imageSize.width / 2 - 10) * CGFloat(sin(self.time * 2 * .pi))
            self.scanProgress += 1.5
            if self.scanProgress > self.imageSize.height / 2 {
                self.scanProgress = -self.imageSize.height / 2
            }
            if !self.isScanning {
                timer.invalidate()
            }
        }
    }

    /// Stops the scanning animation and resets relevant properties.
    func stopScanAnimation() {
        animationTimer?.invalidate()
        animationTimer = nil
        scanProgress = -imageSize.height / 2
        dotOffsetX = 0
    }

    /// Resets all OCR-related and animation-related state variables.
    func reset() {
        DispatchQueue.main.async {
            self.extractedText = ""
            self.isScanning = false
            self.hasAttemptedExtraction = false
            self.sourceURL = nil
            self.stopScanAnimation()
            self.scanProgress = 0
            self.dotOffsetX = 0
            self.time = 0.0
            self.imageSize = .zero
        }
    }
}

