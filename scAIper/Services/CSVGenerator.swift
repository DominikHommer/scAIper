//
//  CSVGenerator.swift
//  scAIper
//
//  Created by Dominik Hommer on 09.04.25.
//


import Foundation

struct CSVGenerator {
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
