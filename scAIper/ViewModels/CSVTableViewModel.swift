//
//  CSVTableViewModel.swift
//  scAIper
//
//  Created by Dominik Hommer on 27.03.25.
//

import SwiftUI

/// ViewModel responsible for parsing and managing data from a CSV file.
class CSVTableViewModel: ObservableObject {
    /// 2D array representing rows and columns of the parsed CSV data.
    @Published var rows: [[String]] = []
    
    /// Stores the calculated width for each column to ensure proper display.
    @Published var columnWidths: [CGFloat] = []

    /// Loads and parses the CSV file from the given URL.
    ///
    /// - Parameter url: The URL pointing to the CSV file.
    /// This function reads the file, splits its content into lines and columns,
    /// filters out empty lines, and updates the `rows` property on the main thread.
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

    /// Calculates the display width of each column based on the content.
    ///
    /// Uses a monospaced system font to measure the size of each cell’s content
    /// and ensures a minimum width of 60 points plus padding.
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
                    maxWidth = max(maxWidth, size.width + 16)
                }
            }
            widths.append(maxWidth)
        }

        columnWidths = widths
    }
}

