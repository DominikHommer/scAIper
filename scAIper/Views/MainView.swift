//
//  MainView.swift
//  scAIper
//
//  Created by Dominik Hommer on 17.03.25.
//

import SwiftUI

/// The main tab-based navigation view of the scAIper app.
/// Provides access to scanning, document management, financial analysis, and chatbot functionality.
struct MainView: View {
    var body: some View {
        TabView {
            
            /// Tab for scanning documents using the camera.
            DocumentGridView()
                .tabItem {
                    Label("Scannen", systemImage: "camera.viewfinder")
                }
            
            /// Tab for browsing categorized document folders.
            FolderListView()
                .tabItem {
                    Label("Dokumente", systemImage: "folder.fill")
                }
            
            /// Tab for viewing financial insights based on scanned documents.
            FinancialAnalysisView()
                .tabItem {
                    Label("Finanzen", systemImage: "chart.pie.fill")
                }
            
            /// Tab for interacting with the document-aware AI chatbot.
            ChatbotView()
                .tabItem {
                    Label("scAIper", systemImage: "bubble.left.and.bubble.right.fill")
                }
        }
    }
}

#Preview {
    MainView()
}


