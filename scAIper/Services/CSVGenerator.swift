//
//  CSVGenerator.swift
//  scAIper
//
//  Created by Dominik Hommer on 09.04.25.
//

import Foundation

/// A utility struct for converting a 2D grid of strings into CSV format.
struct CSVGenerator {

    /// Converts a 2D array (grid) of strings into CSV-formatted data using semicolon (`;`) as separator.
    ///
    /// - Parameters:
    ///   - grid: A 2D array of strings, where each sub-array represents a row in the CSV.
    ///   - completion: A closure that returns the generated CSV as `Data` and as `String`.
    ///                 If no valid content is detected (e.g. empty or whitespace-only), both values will be `nil`.
    static func createCSV(from grid: [[String]], completion: @escaping (Data?, String?) -> Void) {
        var csvString = ""
        
        for row in grid {
            let line = row.joined(separator: ";")
            csvString += line + "\n"
        }

        if csvString.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            print("Kein Text erkannt, CSV wird nicht erstellt.")
            completion(nil, nil)
            return
        }

        print("CSV-Vorschau:\n\(csvString)")
        let csvData = csvString.data(using: .utf8)
        completion(csvData, csvString)
    }
}

