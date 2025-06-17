//
//  scAIperApp.swift
//  scAIper
//
//  Created by Dominik Hommer on 17.03.25.
//

import SwiftUI


@main
struct scAIperApp: App {
    init() {
        DocumentMetadataManager.shared.validateMetadata()
        //DocumentMetadataManager.shared.printDocumentMetadataJSON()
        }
    var body: some Scene {
        WindowGroup {
            SplashScreenView()
        }
    }
}


