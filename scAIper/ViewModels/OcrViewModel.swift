//
//  OCRViewModel.swift
//  scAIper
//
//  Created by Dominik Hommer on 20.03.25.
//

import Foundation
import UIKit
import PDFKit

class OcrViewModel: ObservableObject {
    @Published var extractedText: String = ""
    @Published var isScanning: Bool = false
    @Published var hasAttemptedExtraction: Bool = false
    @Published var pdfURL: URL? = nil


    func startOcr(on image: UIImage) { //bleibt vorerst drin, wird aber gerade nicht verwendet
        DispatchQueue.main.async {
            self.isScanning = true
            self.hasAttemptedExtraction = false
            self.extractedText = ""
        }

        OCRManager.recognizeText(from: image) { [weak self] recognizedString in
            guard let self = self else { return }
            DispatchQueue.main.async {
                self.isScanning = false
                self.hasAttemptedExtraction = true
                self.extractedText = recognizedString
            }
        }
    }

    func startOcrAndGeneratePDF(on image: UIImage, completion: @escaping (URL?) -> Void) {
        DispatchQueue.main.async {
            self.isScanning = true
            self.hasAttemptedExtraction = false
            self.extractedText = ""
        }

        OCRManager.generatePDFWithOCR(from: image) { [weak self] pdfData in
            guard let self = self else { return }

            DispatchQueue.main.async {
                self.isScanning = false
                self.hasAttemptedExtraction = true

                guard let data = pdfData else {
                    completion(nil)
                    return
                }

                let fileURL = FileManager.default.temporaryDirectory.appendingPathComponent("ocr_output.pdf")
                do {
                    try data.write(to: fileURL)
                    completion(fileURL)
                } catch {
                    print("Fehler beim Speichern des PDFs: \(error)")
                    completion(nil)
                }
            }
        }
    }

    func reset() {
        DispatchQueue.main.async {
            self.extractedText = ""
            self.isScanning = false
            self.hasAttemptedExtraction = false
            self.pdfURL = nil
        }
    }


}


