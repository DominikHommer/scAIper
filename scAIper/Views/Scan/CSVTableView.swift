//
//  CSVTableView.swift
//  scAIper
//
//  Created by Dominik Hommer on 25.03.25.
//


import SwiftUI

struct CSVTableView: View {
    let csvURL: URL
    @StateObject private var viewModel = CSVTableViewModel()
    
    var body: some View {
        VStack(alignment: .leading) {
            Text("CSV Tabelle")
                .font(.headline)
                .padding(.horizontal)
            
            if viewModel.rows.isEmpty {
                Text("Lade CSV…")
                    .padding()
                    .onAppear {
                        viewModel.loadCSV(from: csvURL)
                    }
            } else {
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
    
    private func columnWidth(at index: Int) -> CGFloat {
        guard index < viewModel.columnWidths.count else { return 60 }
        return viewModel.columnWidths[index]
    }
}

