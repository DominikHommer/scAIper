//
//  OCRViewModel.swift
//  scAIper
//
//  Created by Dominik Hommer on 20.03.25.
//
import Foundation
import UIKit
import PDFKit

enum LayoutType: String, CaseIterable, Identifiable {
    case text = "Text"
    case tabelle = "Tabelle"
    var id: String { self.rawValue }
    
    var fileSuffix: String {
        switch self {
        case .text:
            return ".pdf"
        default:
            return ".csv"
        }
    }
}

class OcrViewModel: ObservableObject {
    // OCR-Generierung
    @Published var extractedText: String = ""
    @Published var isScanning: Bool = false
    @Published var hasAttemptedExtraction: Bool = false
    @Published var sourceURL: URL? = nil

    // Zustände für die Scan-Animation
    @Published var scanProgress: CGFloat = 0
    @Published var dotOffsetX: CGFloat = 0
    @Published var time: Double = 0.0
    @Published var imageSize: CGSize = .zero

    private var animationTimer: Timer? = nil

    // Gemeinsame Methode zum Starten der OCR-Generierung
    private func startOcrAndGenerate(
        for image: UIImage,
        layout: LayoutType,
        fileName: String,
        generator: (UIImage, @escaping (Data?) -> Void) -> Void,
        completion: @escaping (URL?) -> Void
    ) {
        DispatchQueue.main.async {
            self.isScanning = true
            self.hasAttemptedExtraction = false
            self.extractedText = ""
            self.sourceURL = nil
        }

        generator(image) { [weak self] data in
            guard let self = self else { return }
            DispatchQueue.main.async {
                self.isScanning = false
                self.hasAttemptedExtraction = true

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
                    print("Fehler beim Speichern der Datei: \(error)")
                    completion(nil)
                }
            }
        }
    }

    func startOcrAndGeneratePDF(on image: UIImage, layout: LayoutType, completion: @escaping (URL?) -> Void) {
        startOcrAndGenerate(
            for: image,
            layout: layout,
            fileName: "ocr_output.pdf",
            generator: OCRManager.generatePDFWithOCR,
            completion: completion
        )
    }

    func startOcrAndGenerateCSV(on image: UIImage, layout: LayoutType, completion: @escaping (URL?) -> Void) {
        startOcrAndGenerate(
            for: image,
            layout: layout,
            fileName: "ocr_output.csv",
            generator: OCRManager.generateCSVWithOCR,
            completion: completion
        )
    }


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
    
    func stopScanAnimation() {
        animationTimer?.invalidate()
        animationTimer = nil
        scanProgress = -imageSize.height / 2
        dotOffsetX = 0
    }
    

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




