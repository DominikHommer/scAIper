//
//  CSVTableView.swift
//  scAIper
//
//  Created by Dominik Hommer on 25.03.25.
//

import SwiftUI

/// A view that displays the contents of a CSV file in a scrollable grid-like layout.
struct CSVTableView: View {
    
    /// The URL of the CSV file to be displayed.
    let csvURL: URL
    
    /// The view model responsible for loading and parsing the CSV file.
    @StateObject private var viewModel = CSVTableViewModel()
    
    var body: some View {
        VStack(alignment: .leading) {
            // Header title
            Text("CSV Tabelle")
                .font(.headline)
                .padding(.horizontal)
            
            // Show loading state while CSV is being parsed
            if viewModel.rows.isEmpty {
                Text("Lade CSV…")
                    .padding()
                    .onAppear {
                        // Load CSV content once view appears
                        viewModel.loadCSV(from: csvURL)
                    }
            } else {
                // Display parsed CSV data in a scrollable grid (both directions)
                ScrollView([.vertical, .horizontal]) {
                    VStack(alignment: .leading, spacing: 4) {
                        ForEach(viewModel.rows.indices, id: \.self) { rowIndex in
                            HStack(spacing: 8) {
                                ForEach(viewModel.rows[rowIndex].indices, id: \.self) { columnIndex in
                                    Text(viewModel.rows[rowIndex][columnIndex])
                                        .font(.system(size: 14, design: .monospaced))
                                        .frame(minWidth: columnWidth(at: columnIndex), alignment: .leading)
                                        .padding(4)
                                        .background(Color(.systemGray6))
                                        .cornerRadius(4)
                                }
                            }
                        }
                    }
                    .padding()
                }
            }
        }
    }
    
    /// Returns the column width for the given index.
    /// - Parameter index: The index of the column.
    /// - Returns: The preferred minimum width for the column.
    private func columnWidth(at index: Int) -> CGFloat {
        guard index < viewModel.columnWidths.count else { return 60 }
        return viewModel.columnWidths[index]
    }
}
