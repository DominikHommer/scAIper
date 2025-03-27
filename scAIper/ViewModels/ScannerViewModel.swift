//
//  ScannerViewModel.swift
//  scAIper
//
//  Created by Dominik Hommer on 27.03.25.
//
import SwiftUI

class ScannerViewModel: ObservableObject {
    @Published var isShowingCamera = false
    @Published var scannedImage: UIImage? = nil
    @Published var navigateToOCR = false

    func scanTapped() {
        isShowingCamera = true
    }
    
    func didDismissCamera() {
        if scannedImage != nil {
            navigateToOCR = true
        }
    }
}
