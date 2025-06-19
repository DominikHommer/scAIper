//
//  ScannerViewModel.swift
//  scAIper
//
//  Created by Dominik Hommer on 27.03.25.
//

import SwiftUI

/// ViewModel responsible for managing the state of the document scanning process.
class ScannerViewModel: ObservableObject {
    /// Indicates whether the document camera should be presented.
    @Published var isShowingCamera = false
    
    /// Holds the scanned image result from the document scanner.
    @Published var scannedImage: UIImage? = nil
    
    /// Controls navigation to the OCR screen after a successful scan.
    @Published var navigateToOCR = false

    /// Called when the user taps the scan button.
    ///
    /// Triggers the presentation of the document scanner UI.
    func scanTapped() {
        isShowingCamera = true
    }

    /// Called when the document scanner is dismissed.
    ///
    /// If a scanned image is available, navigation to the OCR view is triggered.
    func didDismissCamera() {
        if scannedImage != nil {
            navigateToOCR = true
        }
    }
}

