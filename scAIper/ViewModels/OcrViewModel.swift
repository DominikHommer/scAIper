//
//  OCRViewModel.swift
//  scAIper
//
//  Created by Dominik Hommer on 20.03.25.
//

import Foundation
import UIKit

class OcrViewModel: ObservableObject {
    @Published var extractedText: String = ""
    
    @Published var isScanning: Bool = false
    
    @Published var hasAttemptedExtraction: Bool = false
    
    func startOcr(on image: UIImage) {
        isScanning = true
        hasAttemptedExtraction = false
        extractedText = ""
        
        OCRManager.recognizeText(from: image) { [weak self] recognizedString in
            guard let self = self else { return }
            self.isScanning = false
            self.hasAttemptedExtraction = true
            self.extractedText = recognizedString
        }
    }
    
    func reset() {
        extractedText = ""
        isScanning = false
        hasAttemptedExtraction = false
    }
}

