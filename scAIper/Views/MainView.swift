//
//  MainView.swift
//  scAIper
//
//  Created by Dominik Hommer on 17.03.25.
//

import SwiftUI

struct MainView: View {
    var body: some View {
        TabView {
            ScannerView()
                .tabItem {
                    Label("Scannen", systemImage: "camera.viewfinder")
                }
            
            DocumentListView()
                .tabItem {
                    Label("Dokumente", systemImage: "folder.fill")
                }
            
            ExpenseOverviewView()
                .tabItem {
                    Label("Ausgaben", systemImage: "chart.pie.fill")
                }
            
            ChatbotView()
                .tabItem {
                    Label("Chatbot", systemImage: "bubble.left.and.bubble.right.fill")
                }
        }
    }
}

#Preview {
    MainView()
}

