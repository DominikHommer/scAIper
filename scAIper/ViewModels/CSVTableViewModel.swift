//
//  CSVTableViewModel.swift
//  scAIper
//
//  Created by Dominik Hommer on 27.03.25.
//


import SwiftUI


class CSVTableViewModel: ObservableObject {
    @Published var rows: [[String]] = []
    @Published var columnWidths: [CGFloat] = []
    
    func loadCSV(from url: URL) {
        do {
            let content = try String(contentsOf: url, encoding: .utf8)
            let lines = content.components(separatedBy: .newlines)
            let loadedRows = lines
                .filter { !$0.isEmpty }
                .map { $0.components(separatedBy: ";") }
            DispatchQueue.main.async {
                self.rows = loadedRows
                self.calculateColumnWidths()
            }
        } catch {
            print("Error loading CSV: \(error)")
        }
    }
    
    private func calculateColumnWidths() {
        var widths: [CGFloat] = []
        let font = UIFont.monospacedSystemFont(ofSize: 14, weight: .regular)
        let maxColumns = rows.map { $0.count }.max() ?? 0
        
        for column in 0..<maxColumns {
            var maxWidth: CGFloat = 60
            for row in rows {
                if column < row.count {
                    let text = row[column]
                    let size = (text as NSString).size(withAttributes: [.font: font])
                    maxWidth = max(maxWidth, size.width + 16) // Padding berücksichtigen
                }
            }
            widths.append(maxWidth)
        }
        
        columnWidths = widths
    }
}
