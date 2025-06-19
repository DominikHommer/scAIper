//
//  OCRManager.swift
//  scAIper
//
//  Created by Dominik Hommer on 20.03.25.
//

import UIKit
import Vision
import NaturalLanguage

// MARK: - UIImage Extension

extension UIImage {
    /// Resizes the image proportionally to the given maximum width.
    func resizedToMaxWidth(_ maxWidth: CGFloat) -> UIImage? {
        let size = self.size
        guard size.width > maxWidth else { return self }
        let scale = maxWidth / size.width
        let newSize = CGSize(width: maxWidth, height: size.height * scale)
        UIGraphicsBeginImageContextWithOptions(newSize, false, 0.0)
        self.draw(in: CGRect(origin: .zero, size: newSize))
        let resizedImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return resizedImage
    }

    /// Converts the image to a base64-encoded JPEG string.
    func toBase64JPEG(resizeToMaxWidth maxWidth: CGFloat = 700) -> String? {
        let resizedImage = self.resizedToMaxWidth(maxWidth) ?? self
        guard let jpegData = resizedImage.jpegData(compressionQuality: 0.8) else { return nil }
        return jpegData.base64EncodedString()
    }
}

// MARK: - OCRManager

/// Handles all OCR-related operations including PDF and CSV generation.
class OCRManager: NSObject {
    static let shared = OCRManager()

    /// Performs OCR and generates a PDF where recognized text is drawn at its position.
    static func generatePDFWithPositionedOCR(
        from image: UIImage,
        completion: @escaping (Data?, String?) -> Void
    ) {
        guard let cgImage = image.cgImage else {
            completion(nil, nil)
            return
        }

        let a4Portrait = CGSize(width: 595, height: 842)
        let a4Landscape = CGSize(width: 842, height: 595)
        let imageAspectRatio = image.size.width / image.size.height
        let a4 = imageAspectRatio > 1 ? a4Landscape : a4Portrait
        let pageRect = CGRect(origin: .zero, size: a4)
        let lineHeight: CGFloat = a4.height / 28

        let request = VNRecognizeTextRequest { request, _ in
            guard let observations = request.results as? [VNRecognizedTextObservation] else {
                completion(nil, nil)
                return
            }

            var entries: [(String, CGRect)] = []

            for obs in observations {
                guard let candidate = obs.topCandidates(1).first else { continue }
                let fullRange = candidate.string.startIndex..<candidate.string.endIndex
                if let wordBox = try? candidate.boundingBox(for: fullRange) {
                    entries.append((candidate.string.trimmingCharacters(in: .whitespacesAndNewlines), wordBox.boundingBox))
                } else {
                    entries.append((candidate.string.trimmingCharacters(in: .whitespacesAndNewlines), obs.boundingBox))
                }
            }

            guard !entries.isEmpty else {
                completion(nil, nil)
                return
            }

            let data = UIGraphicsPDFRenderer(bounds: pageRect).pdfData { ctx in
                ctx.beginPage()
                for (text, bbox) in entries {
                    guard !text.isEmpty else { continue }

                    let x = bbox.minX * a4.width
                    let y = (1 - bbox.maxY) * a4.height
                    let w = bbox.width * a4.width
                    let h = bbox.height * a4.height
                    let fontSize = min(h * 0.8, lineHeight * 0.8)

                    let attrs: [NSAttributedString.Key: Any] = [
                        .font: UIFont.systemFont(ofSize: fontSize),
                        .foregroundColor: UIColor.black
                    ]

                    let rect = CGRect(x: x, y: y, width: w, height: h)
                    text.draw(in: rect, withAttributes: attrs)
                }
            }

            let allText = entries.map { $0.0 }.joined(separator: " ")
            completion(data, allText)
        }

        request.recognitionLevel = .accurate
        request.usesLanguageCorrection = true

        Task.detached {
            do {
                try VNImageRequestHandler(cgImage: cgImage, options: [:]).perform([request])
            } catch {
                completion(nil, nil)
            }
        }
    }

    /// Performs OCR and creates a simple PDF containing all recognized text in one block.
    static func generatePDFWithOCR(
        from image: UIImage,
        completion: @escaping (Data?, String?) -> Void
    ) {
        guard let cgImage = image.cgImage else {
            completion(nil, nil)
            return
        }

        let a4Size = CGSize(width: 595, height: 842)
        let pageRect = CGRect(origin: .zero, size: a4Size)

        let request = VNRecognizeTextRequest { request, error in
            if let error = error {
                print("Text recognition error: \(error)")
                completion(nil, nil)
                return
            }

            guard let observations = request.results as? [VNRecognizedTextObservation] else {
                completion(nil, nil)
                return
            }

            let sorted = observations.sorted {
                let top1 = $0.boundingBox.origin.y + $0.boundingBox.height
                let top2 = $1.boundingBox.origin.y + $1.boundingBox.height
                return abs(top1 - top2) > 0.05 ? top1 > top2 : $0.boundingBox.origin.x < $1.boundingBox.origin.x
            }

            let combinedText = sorted
                .compactMap { $0.topCandidates(1).first?.string }
                .joined(separator: "\n")

            guard !combinedText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
                print("No text found; skipping PDF creation.")
                completion(nil, nil)
                return
            }

            let renderer = UIGraphicsPDFRenderer(bounds: pageRect)
            let data = renderer.pdfData { ctx in
                ctx.beginPage()
                let margin: CGFloat = 20
                let textRect = CGRect(x: margin, y: margin, width: pageRect.width - 2 * margin, height: pageRect.height - 2 * margin)
                let paragraphStyle = NSMutableParagraphStyle()
                paragraphStyle.lineBreakMode = .byWordWrapping

                let attrs: [NSAttributedString.Key: Any] = [
                    .font: UIFont.systemFont(ofSize: 15),
                    .foregroundColor: UIColor.black,
                    .paragraphStyle: paragraphStyle
                ]

                NSAttributedString(string: combinedText, attributes: attrs).draw(in: textRect)
            }

            completion(data, combinedText)
        }

        request.recognitionLevel = .accurate
        request.usesLanguageCorrection = true

        Task.detached(priority: .background) {
            do {
                try VNImageRequestHandler(cgImage: cgImage, options: [:]).perform([request])
            } catch {
                print("OCR error: \(error)")
                completion(nil, nil)
            }
        }
    }

    /// Sends the base64-encoded image to an LLM-based table parser and generates a CSV.
    static func generateCSVWithOCRv2(
        from image: UIImage,
        completion: @escaping (Data?, String?) -> Void
    ) {
        print("Starting LLM image analysis...")

        guard let base64 = image.toBase64JPEG() else {
            print("Base64 conversion failed.")
            completion(nil, nil)
            return
        }

        StructureLLMService().sendImageAsBase64(base64: base64) { result in
            switch result {
            case .success(let resp):
                let header = resp.header
                var grid2d: [[String]] = [header]
                for row in resp.table {
                    let rowStrings = header.map { key in
                        switch row[key] {
                        case .string(let s): return s
                        case .number(let n): return "\(n)"
                        case .bool(let b):   return "\(b)"
                        default:             return ""
                        }
                    }
                    grid2d.append(rowStrings)
                }
                print("Structured grid (Base64):", grid2d)
                CSVGenerator.createCSV(from: grid2d, completion: completion)

            case .failure(let error):
                print("LLM request with base64 failed:", error)
                CSVGenerator.createCSV(from: [["Failed to structure data"]], completion: completion)
            }
        }
    }

    /// Uses OCR with token positions, sends layout to LLM, and generates a structured CSV.
    static func generateCSVWithOCR(
        from image: UIImage,
        completion: @escaping (Data?, String?) -> Void
    ) {
        guard let cgImage = image.cgImage else {
            completion(nil, nil)
            return
        }

        print("Starting OCR-based CSV generation...")

        let request = VNRecognizeTextRequest { request, error in
            if let error = error {
                print("Text recognition error: \(error)")
                completion(nil, nil)
                return
            }

            guard let observations = request.results as? [VNRecognizedTextObservation] else {
                completion(nil, nil)
                return
            }

            var elements: [(text: String, x: CGFloat, y: CGFloat)] = []

            for obs in observations {
                guard let candidate = obs.topCandidates(1).first else { continue }
                let text = candidate.string
                let tokenizer = NLTokenizer(unit: .word)
                tokenizer.string = text
                tokenizer.enumerateTokens(in: text.startIndex..<text.endIndex) { range, _ in
                    let word = String(text[range])
                    if let box = try? candidate.boundingBox(for: range) {
                        let midX = (box.topLeft.x + box.topRight.x + box.bottomLeft.x + box.bottomRight.x) / 4
                        let midY = (box.topLeft.y + box.topRight.y + box.bottomLeft.y + box.bottomRight.y) / 4
                        elements.append((word, midX, 1.0 - midY))
                    }
                    return true
                }
            }

            StructureLLMService().sendLLMRequest(grid: elements) { result in
                switch result {
                case .success(let resp):
                    let header = resp.header
                    var grid2d: [[String]] = [header]
                    for row in resp.table {
                        let rowStrings = header.map { key in
                            switch row[key] {
                            case .string(let s): return s
                            case .number(let n): return "\(n)"
                            case .bool(let b):   return "\(b)"
                            default:             return ""
                            }
                        }
                        grid2d.append(rowStrings)
                    }
                    print("Structured grid:", grid2d)
                    CSVGenerator.createCSV(from: grid2d, completion: completion)

                case .failure(let error):
                    print("LLM request failed:", error)
                    CSVGenerator.createCSV(from: [["Failed to structure data"]], completion: completion)
                }
            }
        }

        request.recognitionLevel = .accurate
        request.usesLanguageCorrection = true

        Task.detached(priority: .background) {
            do {
                try VNImageRequestHandler(cgImage: cgImage, options: [:]).perform([request])
            } catch {
                print("OCR error: \(error)")
                completion(nil, nil)
            }
        }
    }
}

