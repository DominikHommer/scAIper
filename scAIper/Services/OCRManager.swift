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
        
        let a4Size = CGSize(width: 595, height: 842)
        let pageRect = CGRect(origin: .zero, size: a4Size)
        
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
            
            let sortedObservations = observations.sorted { (obs1, obs2) -> Bool in
                let box1 = obs1.boundingBox
                let box2 = obs2.boundingBox
                let top1 = box1.origin.y + box1.size.height
                let top2 = box2.origin.y + box2.size.height
                if abs(top1 - top2) > 0.05 {
                    return top1 > top2
                } else {
                    return box1.origin.x < box2.origin.x
                }
            }
            
            let combinedText = sortedObservations.compactMap { observation -> String? in
                return observation.topCandidates(1).first?.string
            }.joined(separator: "\n")
            
            if combinedText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                print("Kein Text erkannt, kein PDF wird erstellt.")
                completion(nil)
                return
            }
            
            let format = UIGraphicsPDFRendererFormat()
            let renderer = UIGraphicsPDFRenderer(bounds: pageRect, format: format)
            
            let data = renderer.pdfData { context in
                context.beginPage()
                let margin: CGFloat = 20
                let textRect = CGRect(x: margin, y: margin, width: pageRect.width - 2 * margin, height: pageRect.height - 2 * margin)
                
                let paragraphStyle = NSMutableParagraphStyle()
                paragraphStyle.lineBreakMode = .byWordWrapping
                
                let attributes: [NSAttributedString.Key: Any] = [
                    .font: UIFont.systemFont(ofSize: 15),
                    .foregroundColor: UIColor.black,
                    .paragraphStyle: paragraphStyle
                ]
                
                let attributedText = NSAttributedString(string: combinedText, attributes: attributes)
                attributedText.draw(in: textRect)
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


    static func generateCSVWithOCR(from image: UIImage, completion: @escaping (Data?) -> Void) {
        guard let cgImage = image.cgImage else {
            completion(nil)
            return
        }
        
        print("OCR-CSV-Erstellung gestartet")
        
        let imageWidth = image.size.width
        let imageHeight = image.size.height

        let request = VNRecognizeTextRequest { request, error in
            if let error = error {
                print(" Fehler bei der Texterkennung: \(error)")
                completion(nil)
                return
            }

            guard let observations = request.results as? [VNRecognizedTextObservation] else {
                completion(nil)
                return
            }

            var elements: [(text: String, x: CGFloat, y: CGFloat)] = []

            for observation in observations {
                guard let candidate = observation.topCandidates(1).first else { continue }

                let box = observation.boundingBox
                let x = box.origin.x * imageWidth
                let y = (1.0 - box.origin.y - box.size.height) * imageHeight
                elements.append((candidate.string, x, y))
            }


            let xThreshold: CGFloat = 40.0
            let yThreshold: CGFloat = 30.0

            func clusterPositions(_ positions: [CGFloat], threshold: CGFloat) -> [CGFloat] {
                let sorted = positions.sorted()
                var clusters: [[CGFloat]] = []

                for pos in sorted {
                    if let lastCluster = clusters.last, let last = lastCluster.last,
                       abs(pos - last) < threshold {
                        clusters[clusters.count - 1].append(pos)
                    } else {
                        clusters.append([pos])
                    }
                }

                return clusters.map { cluster in
                    let sum = cluster.reduce(0, +)
                    return sum / CGFloat(cluster.count)
                }
            }

            let columnCenters = clusterPositions(elements.map { $0.x }, threshold: xThreshold)
            let rowCenters = clusterPositions(elements.map { $0.y }, threshold: yThreshold)

            print(" Spalten erkannt: \(columnCenters.count), Zeilen erkannt: \(rowCenters.count)")

            var grid: [[String]] = Array(
                repeating: Array(repeating: "", count: columnCenters.count),
                count: rowCenters.count
            )

            for element in elements {
                guard let rowIndex = rowCenters.firstIndex(where: { abs($0 - element.y) < yThreshold }),
                      let colIndex = columnCenters.firstIndex(where: { abs($0 - element.x) < xThreshold }) else {
                    continue
                }

                grid[rowIndex][colIndex] = element.text
            }

            var csvString = ""
            for row in grid {
                let line = row.joined(separator: ";")
                csvString += line + "\n"
            }
            
            if csvString.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                print("Kein Text erkannt, CSV wird nicht erstellt.")
                completion(nil)
                return
            }

            print("CSV-Vorschau:\n\(csvString)")

            let csvData = csvString.data(using: .utf8)
            completion(csvData)
        }

        request.recognitionLevel = .accurate
        request.usesLanguageCorrection = true

        Task.detached(priority: .background) {
            let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
            do {
                try handler.perform([request])
            } catch {
                print(" OCR-Fehler: \(error)")
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
            

            for i in 0..<lines.count {
                lines[i].sort {
                    $0.observation.boundingBox.midX < $1.observation.boundingBox.midX
                }
            }
            
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
