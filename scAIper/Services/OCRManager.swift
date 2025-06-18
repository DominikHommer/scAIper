//
//  OCRManager.swift
//  scAIper
//
//  Created by Dominik Hommer on 20.03.25.
//

import UIKit
import Vision
import NaturalLanguage

extension UIImage {
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

    func toBase64JPEG(resizeToMaxWidth maxWidth: CGFloat = 700) -> String? {
        let resizedImage = self.resizedToMaxWidth(maxWidth) ?? self
        guard let jpegData = resizedImage.jpegData(compressionQuality: 0.8) else { return nil }
        return jpegData.base64EncodedString()
    }
}

class OCRManager: NSObject {
    static let shared = OCRManager()
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
                    entries.append((
                        candidate.string.trimmingCharacters(in: .whitespacesAndNewlines),
                        wordBox.boundingBox
                    ))
                } else {
                    entries.append((
                        candidate.string.trimmingCharacters(in: .whitespacesAndNewlines),
                        obs.boundingBox
                    ))
                }
            }

            guard !entries.isEmpty else {
                completion(nil, nil)
                return
            }

            let data = UIGraphicsPDFRenderer(bounds: pageRect, format: UIGraphicsPDFRendererFormat()).pdfData { ctx in
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

            let all = entries.map { $0.0 }.joined(separator: " ")
            completion(data, all)
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
                print("Fehler bei der Texterkennung: \(error)")
                completion(nil, nil)
                return
            }
            guard let observations = request.results as? [VNRecognizedTextObservation] else {
                completion(nil, nil)
                return
            }

            let sorted = observations.sorted { o1, o2 in
                let top1 = o1.boundingBox.origin.y + o1.boundingBox.size.height
                let top2 = o2.boundingBox.origin.y + o2.boundingBox.size.height
                if abs(top1 - top2) > 0.05 {
                    return top1 > top2
                } else {
                    return o1.boundingBox.origin.x < o2.boundingBox.origin.x
                }
            }

            let combinedText = sorted
                .compactMap { $0.topCandidates(1).first?.string }
                .joined(separator: "\n")

            guard !combinedText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
                print("Kein Text erkannt, kein PDF wird erstellt.")
                completion(nil, nil)
                return
            }

            let format = UIGraphicsPDFRendererFormat()
            let renderer = UIGraphicsPDFRenderer(bounds: pageRect, format: format)
            let data = renderer.pdfData { ctx in
                ctx.beginPage()
                let margin: CGFloat = 20
                let textRect = CGRect(
                    x: margin,
                    y: margin,
                    width: pageRect.width - 2*margin,
                    height: pageRect.height - 2*margin
                )
                let style = NSMutableParagraphStyle()
                style.lineBreakMode = .byWordWrapping
                let attrs: [NSAttributedString.Key: Any] = [
                    .font: UIFont.systemFont(ofSize: 15),
                    .foregroundColor: UIColor.black,
                    .paragraphStyle: style
                ]
                let attrText = NSAttributedString(string: combinedText, attributes: attrs)
                attrText.draw(in: textRect)
            }

            completion(data, combinedText)
        }

        request.recognitionLevel = .accurate
        request.usesLanguageCorrection = true

        Task.detached(priority: .background) {
            let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
            do {
                try handler.perform([request])
            } catch {
                print("OCR-Fehler: \(error)")
                completion(nil, nil)
            }
        }
    }

    static func generateCSVWithOCRv2(
        from image: UIImage,
        completion: @escaping (Data?, String?) -> Void
    ) {
        print("LLM-Bildanalyse gestartet")

        guard let base64 = image.toBase64JPEG() else {
            print("Fehler beim Konvertieren des Bildes zu Base64")
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
                print("Strukturiertes Grid (Base64):", grid2d)
                CSVGenerator.createCSV(from: grid2d, completion: completion)

            case .failure(let error):
                print("LLM-Request mit Base64 fehlgeschlagen:", error)
                CSVGenerator.createCSV(from: [["Fehler beim Strukturieren"]], completion: completion)
            }
        }
    }


    static func generateCSVWithOCR(
        from image: UIImage,
        completion: @escaping (Data?, String?) -> Void
    ) {
        guard let cgImage = image.cgImage else {
            completion(nil, nil)
            return
        }
        print("OCR-CSV-Erstellung gestartet")

        let request = VNRecognizeTextRequest { request, error in
            if let error = error {
                print("Fehler bei der Texterkennung: \(error)")
                completion(nil, nil)
                return
            }
            guard let observations = request.results as? [VNRecognizedTextObservation] else {
                completion(nil, nil)
                return
            }

            var elements: [(text: String, x: CGFloat, y: CGFloat)] = []
            for obs in observations {
                guard let cand = obs.topCandidates(1).first else { continue }
                let text = cand.string
                let tokenizer = NLTokenizer(unit: .word)
                tokenizer.string = text
                tokenizer.enumerateTokens(in: text.startIndex..<text.endIndex) { range, _ in
                    let word = String(text[range])
                    if let box = try? cand.boundingBox(for: range) {
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
                    print("Strukturiertes Grid:", grid2d)
                    CSVGenerator.createCSV(from: grid2d, completion: completion)

                case .failure(let error):
                    print("LLM-Request fehlgeschlagen:", error)
                    CSVGenerator.createCSV(from: [["Fehler beim Strukturieren"]], completion: completion)
                }
            }
        }

        request.recognitionLevel = .accurate
        request.usesLanguageCorrection = true

        Task.detached(priority: .background) {
            let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
            do {
                try handler.perform([request])
            } catch {
                print("OCR-Fehler: \(error)")
                completion(nil, nil)
            }
        }
    }
}


