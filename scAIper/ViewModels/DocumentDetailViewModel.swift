//
//  DocumentDetailViewModel.swift
//  scAIper
//
//  Created by Dominik Hommer on 27.03.25.
//
import SwiftUI

class DocumentDetailViewModel: ObservableObject {
    @Published var documentText: String = ""
    let fileURL: URL
    
    init(fileURL: URL) {
        self.fileURL = fileURL
    }
    
    func loadDocument() {
        guard fileURL.pathExtension.lowercased() == "txt" else { return }
        DispatchQueue.global(qos: .userInitiated).async {
            do {
                let text = try String(contentsOf: self.fileURL, encoding: .utf8)
                DispatchQueue.main.async {
                    self.documentText = text
                }
            } catch {
                print("Fehler beim Laden des Dokuments: \(error)")
            }
        }
    }
}
