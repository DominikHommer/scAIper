//
//  scAIperApp.swift
//  scAIper
//
//  Created by Dominik Hommer on 17.03.25.
//

import SwiftUI

/// The main entry point for the scAIper application.
/// This struct initializes the app and sets the root view.
@main
struct scAIperApp: App {
    
    /// Initializes the app.
    /// During initialization, it validates the metadata and prints the current metadata JSON for debugging purposes.
    init() {
        DocumentMetadataManager.shared.validateMetadata()
        DocumentMetadataManager.shared.printDocumentMetadataJSON()
    }
    
    /// The main scene of the app, which launches the `SplashScreenView`.
    var body: some Scene {
        WindowGroup {
            SplashScreenView()
        }
    }
}



