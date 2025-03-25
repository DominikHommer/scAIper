//
//  OCRManager.swift
//  scAIper
//
//  Created by Dominik Hommer on 20.03.25.
//
import PDFKit
import CoreGraphics
import UIKit
import Vision

class OCRManager {

    static func generatePDFWithOCR(from image: UIImage, completion: @escaping (Data?) -> Void) {
        guard let cgImage = image.cgImage else {
            completion(nil)
            return
        }

        let imageWidth = image.size.width
        let imageHeight = image.size.height
        let pageRect = CGRect(x: 0, y: 0, width: imageWidth, height: imageHeight)

        let request = VNRecognizeTextRequest { request, error in
            if let error = error {
                print("Fehler bei der Texterkennung: \(error)")
                completion(nil)
                return
            }

            guard let observations = request.results as? [VNRecognizedTextObservation] else {
                completion(nil)
                return
            }

            let format = UIGraphicsPDFRendererFormat()
            let renderer = UIGraphicsPDFRenderer(bounds: pageRect, format: format)

            let data = renderer.pdfData { context in
                context.beginPage()

                for observation in observations {
                    guard let candidate = observation.topCandidates(1).first else { continue }
                    let text = candidate.string

                    let box = observation.boundingBox
                    let x = box.origin.x * imageWidth
                    let y = (1.0 - box.origin.y - box.size.height) * imageHeight
                    let width = box.size.width * imageWidth
                    let height = box.size.height * imageHeight
                    let rect = CGRect(x: x, y: y, width: width, height: height)

                    let attributes: [NSAttributedString.Key: Any] = [
                        .font: UIFont.systemFont(ofSize: 15),
                        .foregroundColor: UIColor.black
                    ]
                    let attributedText = NSAttributedString(string: text, attributes: attributes)
                    attributedText.draw(in: rect)
                }
            }

            completion(data)
        }

        request.recognitionLevel = .accurate
        request.usesLanguageCorrection = true

        Task.detached(priority: .background) {
            let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
            do {
                try handler.perform([request])
            } catch {
                print("OCR-Fehler: \(error)")
                completion(nil)
            }
        }
    }
    

    
    
    static func recognizeText( //bleibt vorerst drin, wird aber gerade nicht verwendet
        from image: UIImage,
        completion: @escaping (String) -> Void
    ) {
        guard let cgImage = image.cgImage else {
            completion("")
            return
        }
        
        let request = VNRecognizeTextRequest { request, error in
            if let error = error {
                print("Fehler bei der Texterkennung: \(error)")
                completion("")
                return
            }
            guard let observations = request.results as? [VNRecognizedTextObservation] else {
                completion("")
                return
            }
            
            let sortedObservations = observations.sorted {
                let box0 = $0.boundingBox
                let box1 = $1.boundingBox
                
                if abs(box0.midY - box1.midY) > 0.01 {
                    return box0.midY > box1.midY
                } else {
                    return box0.midX < box1.midX
                }
            }
            
            let lineThreshold: CGFloat = 0.005
            var lines: [[(observation: VNRecognizedTextObservation, text: String)]] = []
            
            for observation in sortedObservations {
                guard let candidate = observation.topCandidates(1).first else { continue }
                let obsMidY = observation.boundingBox.midY
                
                var addedToLine = false
                for i in 0..<lines.count {
                    let lineMidY = lines[i].first!.observation.boundingBox.midY
                    if abs(lineMidY - obsMidY) < lineThreshold {
                        lines[i].append((observation, candidate.string))
                        addedToLine = true
                        break
                    }
                }
                
                if !addedToLine {
                    lines.append([(observation, candidate.string)])
                }
            }
            
            // Sortiere Texte innerhalb jeder Zeile von links nach rechts
            for i in 0..<lines.count {
                lines[i].sort {
                    $0.observation.boundingBox.midX < $1.observation.boundingBox.midX
                }
            }
            
            // Baue finalen String
            let recognizedString = lines.map { line in
                line.map { $0.text }.joined(separator: " ")
            }.joined(separator: "\n")
            
            let output = recognizedString
            
            Task.detached(priority: .background) {
                await MainActor.run {
                    completion(output)
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
                completion("")
            }
        }
    }
    
    fileprivate static func processObservations(
        _ observations: [VNRecognizedTextObservation],
        image: UIImage
    ) -> String {
        let clusters = clusterObservations(
            observations,
            imageSize: image.size,
            distanceThreshold: 150.0,
            overlapRatioThreshold: 0.0000000000000001
        )
        
        let recognizedString = buildOutputString(from: clusters)
        return recognizedString
    }
}
