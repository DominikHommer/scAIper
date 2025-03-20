//
//  OCRManager.swift
//  scAIper
//
//  Created by Dominik Hommer on 20.03.25.
//


import Vision
import UIKit

class OCRManager {
    
    static func recognizeText(
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
            
            Task.detached(priority: .background) {
                let recognizedString = processObservations(
                    observations,
                    image: image
                )
                
                await MainActor.run {
                    completion(recognizedString)
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
