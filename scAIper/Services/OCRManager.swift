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
    static var modelNameDocCheck: String = "meta-llama/llama-4-maverick-17b-128e-instruct"

    // Diese Methode generiert ein PDF aus einem UIImage mithilfe von OCR.
    static func generatePDFWithOCR(from image: UIImage, completion: @escaping (Data?, String?) -> Void) {
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
            
            let sortedObservations = observations.sorted { obs1, obs2 in
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
            
            let combinedText = sortedObservations.compactMap { observation in
                observation.topCandidates(1).first?.string
            }.joined(separator: "\n")
            
            if combinedText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                print("Kein Text erkannt, kein PDF wird erstellt.")
                completion(nil, nil)
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
    
    // Diese Methode generiert eine CSV aus einem UIImage mithilfe von OCR.
    // Die eigentliche Logik wird in Hilfsstrukturen ausgelagert.
    static func generateCSVWithOCR(from image: UIImage, completion: @escaping (Data?, String?) -> Void) {
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
            for observation in observations {
                guard let candidate = observation.topCandidates(1).first else { continue }
                let text = candidate.string
                print(text)
                let tokenizer = NLTokenizer(unit: .word)
                tokenizer.string = text
                tokenizer.enumerateTokens(in: text.startIndex..<text.endIndex) { tokenRange, _ in
                    let word = String(text[tokenRange])
                    if let box = try? candidate.boundingBox(for: tokenRange) {
                        let midX = (box.topLeft.x + box.topRight.x + box.bottomLeft.x + box.bottomRight.x) / 4.0
                        let midY = (box.topLeft.y + box.topRight.y + box.bottomLeft.y + box.bottomRight.y) / 4.0
                        let normX = midX       // normiert (0 ... 1)
                        let normY = 1.0 - midY // Vision liefert y=0 oben
                        elements.append((word, normX, normY))
                    }
                    return true
                }
            }
            print("Elements:", elements)
            
            // Gruppierung der Elemente
            /*let groups = GridClustering.groupElementsByRadius(elements: elements, radius: 0.02)
            var mergedElements: [(text: String, x: CGFloat, y: CGFloat)] = []
            for group in groups {
                let mergedText = group.map { $0.text }.joined(separator: " ")
                let avgX = group.reduce(0, { $0 + $1.x }) / CGFloat(group.count)
                let avgY = group.reduce(0, { $0 + $1.y }) / CGFloat(group.count)
                mergedElements.append((text: mergedText, x: avgX, y: avgY))
            }
            print("mergedElements:", mergedElements)
            
            let yValues = mergedElements.map { $0.y }
            let xValues = mergedElements.map { $0.x }
            
            let epsCandidatesY = (1...50).map { CGFloat($0) * 0.001 }  // Bereich: 0.001 ... 0.05
            let epsCandidatesX = (5...200).map { CGFloat($0) * 0.001 }   // Bereich: 0.005 ... 0.2
            
            let (bestEpsY, bestScoreY) = GridClustering.bestEpsViaSilhouette(for: yValues, epsCandidates: epsCandidatesY, minSamples: 1)
            let (bestEpsX, bestScoreX) = GridClustering.bestEpsViaSilhouette(for: xValues, epsCandidates: epsCandidatesX, minSamples: 1)
            
            print("Best eps for y:", bestEpsY, "with score:", bestScoreY)
            print("Best eps for x:", bestEpsX, "with score:", bestScoreX)
            
            let dbscanOptimizedY = DBSCAN(eps: bestEpsY, minSamples: 1)
            let rowLabels = dbscanOptimizedY.fit(data: yValues)
            let dbscanOptimizedX = DBSCAN(eps: bestEpsX, minSamples: 1)
            let colLabels = dbscanOptimizedX.fit(data: xValues)
            
            print("rowLabels:", rowLabels)
            print("colLabels:", colLabels)
            
            let rowMapping = GridClustering.continuousLabelMapping(from: rowLabels)
            let colMapping = GridClustering.continuousLabelMapping(from: colLabels)
            let numberOfRows = rowMapping.count
            let numberOfCols = colMapping.count
            print("Ermittelte Zeilen: \(numberOfRows), Spalten: \(numberOfCols)")
            
            var grid: [[String]] = Array(
                repeating: Array(repeating: "", count: numberOfCols),
                count: numberOfRows
            )
            for (i, element) in mergedElements.enumerated() {
                let originalRowLabel = rowLabels[i]
                let originalColLabel = colLabels[i]
                guard let rowIndex = rowMapping[originalRowLabel],
                      let colIndex = colMapping[originalColLabel] else {
                    print("Element ohne Zuordnung: \(element)")
                    continue
                }
                if grid[rowIndex][colIndex].isEmpty {
                    grid[rowIndex][colIndex] = element.text
                } else {
                    grid[rowIndex][colIndex] += " " + element.text
                }
            }
            print("Initial Grid:", grid)*/
            
            OCRLLMService.sendLLMRequest(with: elements) { jsonResponse in
                guard
                    let jsonResponse = jsonResponse,
                    let structuredTable = jsonResponse["table"] as? [[String: Any]],
                    let header = jsonResponse["header"] as? [String]
                else {
                    print("Ungültige oder leere LLM-Antwort.")
                    CSVGenerator.createCSV(from: [["Keine Daten erkannt"]], completion: completion)
                    return
                }
                
                var newGrid: [[String]] = [header]
                for rowDict in structuredTable {
                    let rowArray: [String] = header.map { key in
                        if let value = rowDict[key] {
                            return "\(value)"
                        }
                        return ""
                    }
                    newGrid.append(rowArray)
                }
                print("Neues strukturiertes Grid (direkt vom LLM):", newGrid)
                
                CSVGenerator.createCSV(from: newGrid, completion: completion)
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

