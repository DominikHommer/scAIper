//
//  OCRManager.swift
//  scAIper
//
//  Created by Dominik Hommer on 20.03.25.
//

import UIKit
import Vision
import NaturalLanguage

class OCRManager: NSObject {
    static let shared = OCRManager()

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


